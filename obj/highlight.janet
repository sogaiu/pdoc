(import ./grammar :prefix "")

(def hl/m/none
  [nil])

(defn hl/m/mono-str
  [text _ignored]
  text)

(defn hl/m/mono-prin
  [msg _color]
  (prin msg))

(def hl/m/mono-separator-color
  hl/m/none)

(def hl/color/red :red)

(def hl/color/yellow :yellow)

(def hl/color/green :green)

(def hl/color/blue :blue)

(def hl/color/cyan :cyan)

(def hl/color/magenta :magenta)

(def hl/color/white :white)

(def hl/color/black :black)

(def hl/color/none nil)

(defn hl/color/color-str
  [msg color]
  (if color
    (let [color-num (match color
                      :black 30
                      :blue 34
                      :cyan 36
                      :green 32
                      :magenta 35
                      :red 31
                      :white 37
                      :yellow 33)]
      (string "\e[" color-num "m"
              msg
              "\e[0m"))
    msg))

(defn hl/color/color-prin
  [msg color]
  (prin (hl/color/color-str msg color)))

(def hl/color/color-separator-color hl/color/blue)

# color names (except "none") from M-x list-colors-display

(def hl/rgb/red [0xff 0x00 0x00])

(def hl/rgb/dark-orange
  [0xff 0x8c 0x00])

(def hl/rgb/yellow
  [0xff 0xff 0x00])

(def hl/rgb/chartreuse
  [0x7f 0xff 0x00])

(def hl/rgb/cyan
  [0x00 0xff 0xff])

(def hl/rgb/blue
  [0x00 0x00 0xff])

(def hl/rgb/purple
  [0xa0 0x20 0xf0])

(def hl/rgb/magenta
  [0xff 0x00 0xff])

(def hl/rgb/white
  [0xff 0xff 0xff])

(def hl/rgb/none
  [nil nil nil])

(defn hl/rgb/rgb-str
  [text [r g b]]
  (if (nil? r)
    text
    # https://en.wikipedia.org/wiki/ANSI_escape_code#24-bit
    # ESC[38;2;⟨r⟩;⟨g⟩;⟨b⟩ m Select RGB foreground color     # ] <- hack
    (string "\e[38;2;" r ";" g ";" b "m"
            text
            "\e[0m")))

(defn hl/rgb/rgb-prin
  [msg [r g b]]
  (prin (hl/rgb/rgb-str msg [r g b])))

(def hl/rgb/rgb-separator-color hl/rgb/blue)

(defn hl/rgb-theme
  [node-type]
  (cond
    (= :constant node-type)
    hl/rgb/magenta
    #
    (= :symbol node-type)
    hl/rgb/chartreuse
    #
    (= :keyword node-type)
    hl/rgb/magenta
    #
    (= :string node-type)
    hl/rgb/yellow
    #
    (= :number node-type)
    hl/rgb/cyan
    #
    hl/rgb/none))

(defn hl/color-theme
  [node-type]
  (cond
    (= :constant node-type)
    hl/color/magenta
    #
    (= :symbol node-type)
    hl/color/green
    #
    (= :keyword node-type)
    hl/color/magenta
    #
    (= :string node-type)
    hl/color/yellow
    #
    (= :number node-type)
    hl/color/cyan
    #
    hl/color/none))

(defn hl/mono-theme
  [_]
  hl/m/none)

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
    (buffer/push-string buf ((dyn :pdoc-hl-str hl/m/mono-str)
                              (in an-ast 1)
                              ((dyn :pdoc-theme hl/mono-theme) :buffer)))
    :comment
    (buffer/push-string buf ((dyn :pdoc-hl-str hl/m/mono-str)
                              (in an-ast 1)
                              ((dyn :pdoc-theme hl/mono-theme) :comment)))
    :constant
    (buffer/push-string buf ((dyn :pdoc-hl-str hl/m/mono-str)
                              (in an-ast 1)
                              ((dyn :pdoc-theme hl/mono-theme) :constant)))
    :keyword
    (buffer/push-string buf ((dyn :pdoc-hl-str hl/m/mono-str)
                              (in an-ast 1)
                              ((dyn :pdoc-theme hl/mono-theme) :keyword)))
    :long-buffer
    (buffer/push-string buf ((dyn :pdoc-hl-str hl/m/mono-str)
                              (in an-ast 1)
                              ((dyn :pdoc-theme hl/mono-theme) :long-buffer)))
    :long-string
    (buffer/push-string buf ((dyn :pdoc-hl-str hl/m/mono-str)
                              (in an-ast 1)
                              ((dyn :pdoc-theme hl/mono-theme) :long-string)))
    :number
    (buffer/push-string buf ((dyn :pdoc-hl-str hl/m/mono-str)
                              (in an-ast 1)
                              ((dyn :pdoc-theme hl/mono-theme) :number)))
    :string
    (buffer/push-string buf ((dyn :pdoc-hl-str hl/m/mono-str)
                              (in an-ast 1)
                              ((dyn :pdoc-theme hl/mono-theme) :string)))
    :symbol
    (buffer/push-string buf ((dyn :pdoc-hl-str hl/m/mono-str)
                              (in an-ast 1)
                              ((dyn :pdoc-theme hl/mono-theme) :symbol)))
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

