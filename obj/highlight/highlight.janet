(import ../grammar :prefix "")
(import ./mono :prefix "")
(import ./theme :prefix "")

(def hl/jg-capture-ast
  # jg is a struct, need something mutable
  (let [jca (table ;(kvs g/jg))]
    # override things that need to be captured
    (each kwd [:buffer :comment :constant :keyword :long-buffer
               :long-string :number :string :symbol :whitespace]
      (put jca kwd
               ~(cmt (capture ,(in jca kwd))
                     ,|[kwd $])))
    (each kwd [:fn :quasiquote :quote :splice :unquote]
      (put jca kwd
               ~(cmt (capture ,(in jca kwd))
                     ,|[kwd ;(slice $& 0 -2)])))
    (each kwd [:array :bracket-array :bracket-tuple :table :tuple :struct]
      (put jca kwd
           (tuple # array needs to be converted
                  ;(put (array ;(in jca kwd))
                        2 ~(cmt (capture ,(get-in jca [kwd 2]))
                                ,|[kwd ;(slice $& 0 -2)])))))
    # tried using a table with a peg but had a problem, so use a struct
    (table/to-struct jca)))

(comment

  (peg/match hl/jg-capture-ast "")
  # =>
  nil

  (peg/match hl/jg-capture-ast ".0")
  # =>
  @[[:number ".0"]]

  (peg/match hl/jg-capture-ast "@\"i am a buffer\"")
  # =>
  @[[:buffer "@\"i am a buffer\""]]

  (peg/match hl/jg-capture-ast "# hello")
  # =>
  @[[:comment "# hello"]]

  (peg/match hl/jg-capture-ast ":a")
  # =>
  @[[:keyword ":a"]]

  (peg/match hl/jg-capture-ast "@``i am a long buffer``")
  # =>
  @[[:long-buffer "@``i am a long buffer``"]]

  (peg/match hl/jg-capture-ast "``hello``")
  # =>
  @[[:long-string "``hello``"]]

  (peg/match hl/jg-capture-ast "\"\\u0001\"")
  # =>
  @[[:string "\"\\u0001\""]]

  (peg/match hl/jg-capture-ast "|(+ $ 2)")
  # =>
  '@[(:fn
       (:tuple
         (:symbol "+") (:whitespace " ")
         (:symbol "$") (:whitespace " ")
         (:number "2")))]

  (peg/match hl/jg-capture-ast "@{:a 1}")
  # =>
  '@[(:table
       (:keyword ":a") (:whitespace " ")
       (:number "1"))]

  )

(def hl/jg-capture-top-level-ast
  # jg is a struct, need something mutable
  (let [jca (table ;(kvs hl/jg-capture-ast))]
    (put jca
         :main ~(sequence :input (position)))
    # tried using a table with a peg but had a problem, so use a struct
    (table/to-struct jca)))

(defn hl/par
  [src &opt start single]
  (default start 0)
  (if single
    (if-let [[tree position]
             (peg/match hl/jg-capture-top-level-ast src start)]
      [@[:code tree] position]
      [@[:code] nil])
    (if-let [tree (peg/match hl/jg-capture-ast src start)]
      (array/insert tree 0 :code)
      @[:code])))

(comment

  (hl/par "(+ 1 1)")
  # =>
  '@[:code
     (:tuple
       (:symbol "+") (:whitespace " ")
       (:number "1") (:whitespace " ")
       (:number "1"))]

  )

(defn hl/gen*
  [an-ast buf]
  (case (first an-ast)
    :code
    (each elt (drop 1 an-ast)
      (hl/gen* elt buf))
    #
    :buffer
    (buffer/push-string buf ((dyn :pdoc-hl-str m/mono-str)
                              (in an-ast 1)
                              ((dyn :pdoc-theme th/mono-theme) :buffer)))
    :comment
    (buffer/push-string buf ((dyn :pdoc-hl-str m/mono-str)
                              (in an-ast 1)
                              ((dyn :pdoc-theme th/mono-theme) :comment)))
    :constant
    (buffer/push-string buf ((dyn :pdoc-hl-str m/mono-str)
                              (in an-ast 1)
                              ((dyn :pdoc-theme th/mono-theme) :constant)))
    :keyword
    (buffer/push-string buf ((dyn :pdoc-hl-str m/mono-str)
                              (in an-ast 1)
                              ((dyn :pdoc-theme th/mono-theme) :keyword)))
    :long-buffer
    (buffer/push-string buf ((dyn :pdoc-hl-str m/mono-str)
                              (in an-ast 1)
                              ((dyn :pdoc-theme th/mono-theme) :long-buffer)))
    :long-string
    (buffer/push-string buf ((dyn :pdoc-hl-str m/mono-str)
                              (in an-ast 1)
                              ((dyn :pdoc-theme th/mono-theme) :long-string)))
    :number
    (buffer/push-string buf ((dyn :pdoc-hl-str m/mono-str)
                              (in an-ast 1)
                              ((dyn :pdoc-theme th/mono-theme) :number)))
    :string
    (buffer/push-string buf ((dyn :pdoc-hl-str m/mono-str)
                              (in an-ast 1)
                              ((dyn :pdoc-theme th/mono-theme) :string)))
    :symbol
    (buffer/push-string buf ((dyn :pdoc-hl-str m/mono-str)
                              (in an-ast 1)
                              ((dyn :pdoc-theme th/mono-theme) :symbol)))
    :whitespace
    (buffer/push-string buf (in an-ast 1))
    #
    :array
    (do
      (buffer/push-string buf "@(")
      (each elt (drop 1 an-ast)
        (hl/gen* elt buf))
      (buffer/push-string buf ")"))
    :bracket-array
    (do
      (buffer/push-string buf "@[")
      (each elt (drop 1 an-ast)
        (hl/gen* elt buf))
      (buffer/push-string buf "]"))
    :bracket-tuple
    (do
      (buffer/push-string buf "[")
      (each elt (drop 1 an-ast)
        (hl/gen* elt buf))
      (buffer/push-string buf "]"))
    :tuple
    (do
      (buffer/push-string buf "(")
      (each elt (drop 1 an-ast)
        (hl/gen* elt buf))
      (buffer/push-string buf ")"))
    :struct
    (do
      (buffer/push-string buf "{")
      (each elt (drop 1 an-ast)
        (hl/gen* elt buf))
      (buffer/push-string buf "}"))
    :table
    (do
      (buffer/push-string buf "@{")
      (each elt (drop 1 an-ast)
        (hl/gen* elt buf))
      (buffer/push-string buf "}"))
    #
    :fn
    (do
      (buffer/push-string buf "|")
      (each elt (drop 1 an-ast)
        (hl/gen* elt buf)))
    :quasiquote
    (do
      (buffer/push-string buf "~")
      (each elt (drop 1 an-ast)
        (hl/gen* elt buf)))
    :quote
    (do
      (buffer/push-string buf "'")
      (each elt (drop 1 an-ast)
        (hl/gen* elt buf)))
    :splice
    (do
      (buffer/push-string buf ";")
      (each elt (drop 1 an-ast)
        (hl/gen* elt buf)))
    :unquote
    (do
      (buffer/push-string buf ",")
      (each elt (drop 1 an-ast)
        (hl/gen* elt buf)))
    ))

(defn hl/gen
  [an-ast]
  (let [buf @""]
    (hl/gen* an-ast buf)
    (string buf)))

(comment

  (hl/gen
    [:code])
  # =>
  ""

  (hl/gen
    [:code
     [:buffer "@\"buffer me\""]])
  # =>
  `@"buffer me"`

  (hl/gen
    [:comment "# i am a comment"])
  # =>
  "# i am a comment"

  (hl/gen
    [:long-string "```longish string```"])
  # =>
  "```longish string```"

  (hl/gen
    '(:fn
       (:tuple
         (:symbol "-") (:whitespace " ")
         (:symbol "$") (:whitespace " ")
         (:number "8"))))
  # =>
  "|(- $ 8)"

  (hl/gen
    '(:array
       (:keyword ":a") (:whitespace " ")
       (:keyword ":b")))
  # =
  "@(:a :b)"

  (hl/gen
    '@(:struct
       (:keyword ":a") (:whitespace " ")
       (:number "1")))
  # =>
  "{:a 1}"

  )

(defn hl/colorize
  [src]
  (hl/gen (hl/par src)))

(comment

  (def src "{:x  :y \n :z  [:a  :b    :c]}")

  (hl/colorize src)

  (def src-2 "(peg/match ~(any \"a\") \"abc\")")

  (hl/colorize src-2)

  )

