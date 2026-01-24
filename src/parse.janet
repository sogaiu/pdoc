(import ./location :as l)
(import ./jipper :as j)
(import ./random :as rnd)

(defn dprintf
  [fmt & args]
  (when (os/getenv "VERBOSE")
    (eprintf fmt ;args)))

# XXX: does not have integers, strings, structs, and alias for repeat
# XXX: hard-wiring -- is there a better way?
(def specials
  (tabseq [k :in ['! '$ '% '* '+ '-> '/ '<- '> '?
                  'accumulate 'any 'argument 'at-least 'at-most
                  'backmatch 'backref 'between
                  'capture 'choice 'cmt 'column 'constant
                  'drop
                  'error
                  'group
                  'if 'if-not 'int 'int-be
                  'lenprefix 'line 'look
                  'not 'number
                  'opt
                  'position
                  'quote
                  'range 'repeat 'replace
                  'sequence 'set 'some
                  'thru 'to
                  'uint 'uint-be 'unref]]
    (string k) true))

# XXX: outline
#
# * (rewrite-test test-zloc)
#   * (find-peg-match-call test-zloc)
#     * (rewrite-peg-match-call peg-match-zloc)
#       * (find-grammar-argument peg-match-zloc)
#         * (find-peg-specials grammar-zloc)
#           * (choose-peg-special peg-special-zlocs)
#             * (blank-peg-special peg-special-zloc)

# XXX: list cases not handled
#
#      * integer (handled in find-peg-specials)
#      * keyword (handled in find-peg-specials)
#      * string long-string (handled in find-peg-specials)
#      * constant (handled in find-peg-specials)
#      * other?
(defn is-peg-special?
  [a-sym]
  (get specials a-sym))

# XXX: might be issues with cmt and replace -- could rethink as
#      "what to blank" instead of just looking for peg specials
(defn find-peg-specials
  [grammar-zloc]
  (def results @[])
  # compare against this to determine whether still a descendant
  (def grammar-path-len
    (length (j/path grammar-zloc)))
  (var curr-zloc grammar-zloc)
  (while (not (j/end? curr-zloc))
    (match (j/node curr-zloc)
      [:symbol _ content]
      (when (is-peg-special? content)
        (array/push results curr-zloc))
      [:number]
      (array/push results curr-zloc)
      [:keyword]
      (array/push results curr-zloc)
      [:constant]
      (array/push results curr-zloc)
      [:string]
      (array/push results curr-zloc)
      [:long-string]
      (array/push results curr-zloc))
    (set curr-zloc
         (j/df-next curr-zloc))
    # XXX: not 100% sure whether this is something that can be relied on
    (when (or (j/end? curr-zloc)
              # no longer a descendant of grammar-zloc
              # XXX: verify relying on this is solid
              (<= (length (j/path curr-zloc))
                  grammar-path-len))
      (break)))
  #
  results)

(comment

  (def src
    ``
    ~(sequence "#"
               (capture (to "=>"))
               "=>"
               (capture (thru -1)))
    ``)

  (map |(j/node $)
       (find-peg-specials (-> (l/par src)
                              j/zip-down)))
  # =>
  '@[(:symbol @{:bc 3 :bl 1 :ec 11 :el 1} "sequence")
     (:string @{:bc 12 :bl 1 :ec 15 :el 1} "\"#\"")
     (:symbol @{:bc 13 :bl 2 :ec 20 :el 2} "capture")
     (:symbol @{:bc 22 :bl 2 :ec 24 :el 2} "to")
     (:string @{:bc 25 :bl 2 :ec 29 :el 2} "\"=>\"")
     (:string @{:bc 12 :bl 3 :ec 16 :el 3} "\"=>\"")
     (:symbol @{:bc 13 :bl 4 :ec 20 :el 4} "capture")
     (:symbol @{:bc 22 :bl 4 :ec 26 :el 4} "thru")
     (:number @{:bc 27 :bl 4 :ec 29 :el 4} "-1")]

  )

(defn blank-peg-special
  [peg-special-zloc]
  (def node-type
    (get (j/node peg-special-zloc) 0))
  (var blanked-item nil)
  (var new-peg-special-zloc nil)
  (cond
    (or (= :symbol node-type)
        (= :constant node-type)
        (= :number node-type)
        (= :string node-type)
        (= :long-string node-type)
        (= :keyword node-type))
    (set new-peg-special-zloc
         (j/edit peg-special-zloc
                 |(let [original-item (get $ 2)]
                    (set blanked-item original-item)
                    [node-type
                     (get $ 1)
                     (string/repeat "_" (length original-item))])))
    #
    (do
      (eprintf "Unexpected node-type: %s" node-type)
      (set new-peg-special-zloc peg-special-zloc)))
  [new-peg-special-zloc blanked-item])

(comment

    (def src
    ``
    ~(sequence "#"
               (capture (to "=>"))
               "=>"
               (capture (thru -1)))
    ``)

  (def ps-zloc
    (first (find-peg-specials (-> (l/par src)
                                  j/zip-down))))

  (def [new-peg-special blanked-item]
    (blank-peg-special ps-zloc))

  (j/node new-peg-special)
  # =>
  [:symbol @{:bc 3 :bl 1 :ec 11 :el 1} "________"]

  blanked-item
  # =>
  "sequence"

  (->> (blank-peg-special ps-zloc)
       first
       j/root
       l/gen)
  # =>
  ``
  ~(________ "#"
             (capture (to "=>"))
             "=>"
             (capture (thru -1)))
  ``

  )

(defn find-grammar-argument
  [peg-match-call-zloc]
  (when-let [pm-sym-zloc
             (j/search-from peg-match-call-zloc
                            |(match (j/node $)
                               [:symbol _ "peg/match"]
                               true))]
    # this should be the first argument
    (j/right-skip-wsc pm-sym-zloc)))

(comment

  (def src
    ``
    (peg/match ~(capture (range "09"))
               "123")
    ``)

  (j/node (find-grammar-argument (->> (l/par src)
                                      j/zip-down)))
  # =>
  '(:quasiquote
     @{:bc 12 :bl 1 :ec 35 :el 1}
     (:tuple @{:bc 13 :bl 1 :ec 35 :el 1}
             (:symbol @{:bc 14 :bl 1 :ec 21 :el 1} "capture")
             (:whitespace @{:bc 21 :bl 1 :ec 22 :el 1} " ")
             (:tuple @{:bc 22 :bl 1 :ec 34 :el 1}
                     (:symbol @{:bc 23 :bl 1 :ec 28 :el 1} "range")
                     (:whitespace @{:bc 28 :bl 1 :ec 29 :el 1} " ")
                     (:string @{:bc 29 :bl 1 :ec 33 :el 1} "\"09\""))))

  )

# XXX: not perfect but close enough?
(defn find-peg-match-call
  [test-zloc]
  (when-let [pm-sym-zloc
             (j/search-from test-zloc
                            |(match (j/node $)
                               [:symbol _ "peg/match"]
                               true))]
    # this should be the tuple the peg/match symbol is a child of
    (j/up pm-sym-zloc)))

(comment

  (def src
    ``
    (try
      (peg/match ~(error (capture "a"))
                 "a")
      ([e] e))
    ``)

  (j/node (find-peg-match-call (->> (l/par src)
                                    j/zip-down)))
  # ->
  '(:tuple
     @{:bc 3 :bl 2 :ec 18 :el 3}
     (:symbol @{:bc 4 :bl 2 :ec 13 :el 2} "peg/match")
     (:whitespace @{:bc 13 :bl 2 :ec 14 :el 2} " ")
     (:quasiquote @{:bc 14 :bl 2 :ec 36 :el 2}
                  (:tuple @{:bc 15 :bl 2 :ec 36 :el 2}
                          (:symbol @{:bc 16 :bl 2 :ec 21 :el 2} "error")
                          (:whitespace @{:bc 21 :bl 2 :ec 22 :el 2} " ")
                          (:tuple @{:bc 22 :bl 2 :ec 35 :el 2}
                                  (:symbol @{:bc 23 :bl 2 :ec 30 :el 2}
                                           "capture")
                                  (:whitespace @{:bc 30 :bl 2 :ec 31 :el 2}
                                               " ")
                                  (:string @{:bc 31 :bl 2 :ec 34 :el 2}
                                           "\"a\""))))
     (:whitespace @{:bc 36 :bl 2 :ec 1 :el 3} "\n")
     (:whitespace @{:bc 1 :bl 3 :ec 14 :el 3} "             ")
     (:string @{:bc 14 :bl 3 :ec 17 :el 3} "\"a\""))

  (def src
    ``
    (peg/match ~(if 1 "a")
               "a")
    ``)

  (j/node (find-peg-match-call (->> (l/par src)
                                    j/zip-down)))
  # =>
  '(:tuple
     @{:bc 1 :bl 1 :ec 16 :el 2}
     (:symbol @{:bc 2 :bl 1 :ec 11 :el 1} "peg/match")
     (:whitespace @{:bc 11 :bl 1 :ec 12 :el 1} " ")
     (:quasiquote @{:bc 12 :bl 1 :ec 23 :el 1}
                  (:tuple @{:bc 13 :bl 1 :ec 23 :el 1}
                          (:symbol @{:bc 14 :bl 1 :ec 16 :el 1} "if")
                          (:whitespace @{:bc 16 :bl 1 :ec 17 :el 1} " ")
                          (:number @{:bc 17 :bl 1 :ec 18 :el 1} "1")
                          (:whitespace @{:bc 18 :bl 1 :ec 19 :el 1} " ")
                          (:string @{:bc 19 :bl 1 :ec 22 :el 1} "\"a\"")))
     (:whitespace @{:bc 23 :bl 1 :ec 1 :el 2} "\n")
     (:whitespace @{:bc 1 :bl 2 :ec 12 :el 2} "           ")
     (:string @{:bc 12 :bl 2 :ec 15 :el 2} "\"a\""))

  )

(defn rewrite-test-zloc
  [test-zloc]
  # XXX: why is this printing a function...
  (dprintf "%M" j/path)
  (when-let [pm-call-zloc
             (find-peg-match-call test-zloc)
             grammar-zloc
             (find-grammar-argument pm-call-zloc)]
    (dprintf "test:")
    (dprintf (l/gen (j/node test-zloc)))
    (dprintf "grammar:")
    (dprintf (l/gen (j/node grammar-zloc)))
    # find how many "steps" back are needed to "get back" to original spot
    (var steps 0)
    (var chosen-special-zloc nil)
    # XXX: better to factor out so it can be recursive?
    (def grammar-node-type
      (get (j/node grammar-zloc) 0))
    (cond
      (or (= :string grammar-node-type)
          (= :long-string grammar-node-type)
          (= :keyword grammar-node-type)
          (= :constant grammar-node-type)
          (= :number grammar-node-type))
      (do
        (dprintf "grammar was a %s" grammar-node-type)
        (set chosen-special-zloc grammar-zloc))
      #
      (get {:tuple true
            :bracket-tuple true
            :quote true
            :quasiquote true
            :splice true
            :struct true
            :table true} grammar-node-type)
      (let [specials (find-peg-specials grammar-zloc)]
        # XXX
        (dprintf "grammar was a %s" grammar-node-type)
        # XXX
        (dprintf "Number of specials found: %d" (length specials))
        (when (empty? specials)
          # XXX
          (eprint "Failed to find a special")
          (break [nil nil]))
        (each sp specials
          (dprintf (l/gen (j/node sp))))
        (set chosen-special-zloc
             (rnd/choose specials))
        (dprintf "chosen: %s" (l/gen (j/node chosen-special-zloc))))
      #
      (do
        (eprint "Unexpected node-type:" grammar-node-type)
        (break [nil nil])))
    # find how many steps away we are from test-zloc's node
    (var curr-zloc chosen-special-zloc)
    # XXX: compare (attrs ...) results instead of gen / node
    (def test-str
      (l/gen (j/node test-zloc)))
    (while curr-zloc
      # XXX: expensive?
      # XXX: compare (attrs ...) results instead -- should be faster
      #      attrs should be unique inside the tree(?)
      (when (= (l/gen (j/node curr-zloc))
               test-str)
        (break))
      (set curr-zloc
           (j/df-prev curr-zloc))
      (++ steps))
    # XXX
    (dprintf "steps: %d" steps)
    # XXX: check not nil?
    (var [curr-zloc blanked-item]
      (->> chosen-special-zloc
           blank-peg-special))
    # get back to "test-zloc" position
    (for i 0 steps
      (set curr-zloc
           (j/df-prev curr-zloc)))
    # XXX
    #(dprintf "curr-zloc: %M" curr-zloc)
    #
    [curr-zloc blanked-item]))

(defn rewrite-test
  [test-zloc]
  (when-let [[rewritten-zloc blanked-item]
             (rewrite-test-zloc test-zloc)]
    [(->> rewritten-zloc
         j/root
         l/gen)
     blanked-item]))

(comment

  (def src
    ``
    (try
      (peg/match ~(error (capture "a"))
                 "a")
      ([e] e))
    ``)

  (def [result blanked-item]
    (rewrite-test (->> (l/par src)
                       j/zip-down)))

  (or (= "error" blanked-item)
      (= "\"a\"" blanked-item)
      (= "capture" blanked-item))
  # =>
  true

  (or (= result
         ``
         (try
           (peg/match ~(error (_______ "a"))
                      "a")
           ([e] e))
         ``)
      (= result
         ``
         (try
           (peg/match ~(_____ (capture "a"))
                      "a")
           ([e] e))
         ``)
      (= result
         ``
         (try
           (peg/match ~(error (capture ___))
                      "a")
           ([e] e))
         ``)
      (= result
         ``
         (try
           (peg/match ~(error (capture "a"))
                      ___)
           ([e] e))
         ``))
  # =>
  true

  )

# ti == test indicator, which can look like any of:
#
# # =>
# # before =>
# # => after
# # before => after

(defn find-test-indicator
  [zloc]
  (var label-left nil)
  (var label-right nil)
  [(j/right-until zloc
                  |(match (j/node $)
                     [:comment _ content]
                     (if-let [[l r]
                              (peg/match ~(sequence "#"
                                                    (capture (to "=>"))
                                                    "=>"
                                                    (capture (thru -1)))
                                         content)]
                       (do
                         (set label-left (string/trim l))
                         (set label-right (string/trim r))
                         true)
                       false)))
   label-left
   label-right])

(comment

  (def src
    ``
    (+ 1 1)
    # =>
    2
    ``)

  (let [[zloc l r]
        (find-test-indicator (-> (l/par src)
                                 j/zip-down))]
    (and zloc
         (empty? l)
         (empty? r)))
  # =>
  true

  (def src
    ``
    (+ 1 1)
    # before =>
    2
    ``)

  (let [[zloc l r]
        (find-test-indicator (-> (l/par src)
                                 j/zip-down))]
    (and zloc
         (= "before" l)
         (empty? r)))
  # =>
  true

  (def src
    ``
    (+ 1 1)
    # => after
    2
    ``)

  (let [[zloc l r]
        (find-test-indicator (-> (l/par src)
                                 j/zip-down))]
    (and zloc
         (empty? l)
         (= "after" r)))
  # =>
  true

  )

(defn find-test-expr
  [ti-zloc]
  # check for appropriate conditions "before"
  (def before-zlocs @[])
  (var curr-zloc ti-zloc)
  (var found-before nil)
  (while curr-zloc
    (set curr-zloc
         (j/left curr-zloc))
    (when (nil? curr-zloc)
      (break))
    (match (j/node curr-zloc)
      [:comment]
      (array/push before-zlocs curr-zloc)
      #
      [:whitespace]
      (array/push before-zlocs curr-zloc)
      #
      (do
        (set found-before true)
        (array/push before-zlocs curr-zloc)
        (break))))
  #
  (cond
    (nil? curr-zloc)
    :no-test-expression
    #
    (and found-before
         (->> (slice before-zlocs 0 -2)
              (filter |(not (match (j/node $)
                              [:whitespace]
                              true)))
              length
              zero?))
    curr-zloc
    #
    :unexpected-result))

(comment

  (def src
    ``
    (comment

      (def a 1)

      (put @{} :a 2)
      # =>
      @{:a 2}

      )
    ``)

  (def [ti-zloc _ _]
    (find-test-indicator (-> (l/par src)
                             j/zip-down
                             j/down)))

  (j/node ti-zloc)
  # =>
  '(:comment @{:bc 3 :bl 6 :ec 7 :el 6} "# =>")

  (def test-expr-zloc
    (find-test-expr ti-zloc))

  (j/node test-expr-zloc)
  # =>
  '(:tuple @{:bc 3 :bl 5 :ec 17 :el 5}
           (:symbol @{:bc 4 :bl 5 :ec 7 :el 5} "put")
           (:whitespace @{:bc 7 :bl 5 :ec 8 :el 5} " ")
           (:table @{:bc 8 :bl 5 :ec 11 :el 5})
           (:whitespace @{:bc 11 :bl 5 :ec 12 :el 5} " ")
           (:keyword @{:bc 12 :bl 5 :ec 14 :el 5} ":a")
           (:whitespace @{:bc 14 :bl 5 :ec 15 :el 5} " ")
           (:number @{:bc 15 :bl 5 :ec 16 :el 5} "2"))

  (-> (j/left test-expr-zloc)
      j/node)
  # =>
  '(:whitespace @{:bc 1 :bl 5 :ec 3 :el 5} "  ")

  )

(defn find-expected-expr
  [ti-zloc]
  (def after-zlocs @[])
  (var curr-zloc ti-zloc)
  (var found-comment nil)
  (var found-after nil)
  #
  (while curr-zloc
    (set curr-zloc
         (j/right curr-zloc))
    (when (nil? curr-zloc)
      (break))
    (match (j/node curr-zloc)
      [:comment]
      (do
        (set found-comment true)
        (break))
      #
      [:whitespace]
      (array/push after-zlocs curr-zloc)
      #
      (do
        (set found-after true)
        (array/push after-zlocs curr-zloc)
        (break))))
  #
  (cond
    (or (nil? curr-zloc)
        found-comment)
    :no-expected-expression
    #
    (and found-after
         (match (j/node (first after-zlocs))
           [:whitespace _ "\n"]
           true))
    (if-let [from-next-line (drop 1 after-zlocs)
             next-line (take-until |(match (j/node $)
                                      [:whitespace _ "\n"]
                                      true)
                                   from-next-line)
             target (->> next-line
                         (filter |(match (j/node $)
                                    [:whitespace]
                                    false
                                    #
                                    true))
                         first)]
      target
      :no-expected-expression)
    #
    :unexpected-result))

(comment

  (def src
    ``
    (comment

      (def a 1)

      (put @{} :a 2)
      # =>
      @{:a 2}

      )
    ``)

  (def [ti-zloc _ _]
    (find-test-indicator (-> (l/par src)
                             j/zip-down
                             j/down)))

  (j/node ti-zloc)
  # =>
  '(:comment @{:bc 3 :bl 6 :ec 7 :el 6} "# =>")

  (def expected-expr-zloc
    (find-expected-expr ti-zloc))

  (j/node expected-expr-zloc)
  # =>
  '(:table @{:bc 3 :bl 7 :ec 10 :el 7}
           (:keyword @{:bc 5 :bl 7 :ec 7 :el 7} ":a")
           (:whitespace @{:bc 7 :bl 7 :ec 8 :el 7} " ")
           (:number @{:bc 8 :bl 7 :ec 9 :el 7} "2"))

  (-> (j/left expected-expr-zloc)
      j/node)
  # =>
  '(:whitespace @{:bc 1 :bl 7 :ec 3 :el 7} "  ")

  (def src
    ``
    (comment

      (butlast @[:a :b :c])
      # => @[:a :b]

      (butlast [:a])
      # => []

    )
    ``)

  (def [ti-zloc _ _]
    (find-test-indicator (-> (l/par src)
                             j/zip-down
                             j/down)))

  (j/node ti-zloc)
  # =>
  '(:comment @{:bc 3 :bl 4 :ec 16 :el 4} "# => @[:a :b]")

  (find-expected-expr ti-zloc)
  # =>
  :no-expected-expression

  )

(defn find-test-exprs
  [ti-zloc]
  # look for a test expression
  (def test-expr-zloc
    (find-test-expr ti-zloc))
  (case test-expr-zloc
    :no-test-expression
    (break [nil nil])
    #
    :unexpected-result
    (errorf "unexpected result from `find-test-expr`: %p"
            test-expr-zloc))
  # look for an expected value expression
  (def expected-expr-zloc
    (find-expected-expr ti-zloc))
  (case expected-expr-zloc
    :no-expected-expression
    (break [test-expr-zloc nil])
    #
    :unexpected-result
    (errorf "unexpected result from `find-expected-expr`: %p"
            expected-expr-zloc))
  #
  [test-expr-zloc expected-expr-zloc])

# XXX: new content from here

(defn extract-tests-from-comment-zloc
  [comment-zloc]
  # move into comment block
  (var curr-zloc (j/down comment-zloc))
  (def tests @[])
  # process comment block content
  (while (not (j/end? curr-zloc))
    (def [ti-zloc label-left label-right]
      (find-test-indicator curr-zloc))
    (unless ti-zloc
      (break))
    (def [test-expr-zloc expected-expr-zloc]
      (find-test-exprs ti-zloc))
    # found a complete test
    (if (and test-expr-zloc
             expected-expr-zloc)
      (do
        (array/push tests [test-expr-zloc
                           expected-expr-zloc])
        (set curr-zloc
             (j/right expected-expr-zloc)))
      (set curr-zloc
           (j/right curr-zloc))))
  #
  tests)

(comment

  (def src
    ``
    (comment

      (def a 1)

      (put @{} :a 2)
      # left =>
      @{:a 2}

      (+ 1 1)
      # => right
      2

      )
    ``)

  (def tests
    (-> (l/par src)
        j/zip-down
        extract-tests-from-comment-zloc))

  (l/gen (j/node (get-in tests [0 0])))
  # =>
  "(put @{} :a 2)"

  (l/gen (j/node (get-in tests [0 1])))
  # =>
  "@{:a 2}"

  (l/gen (j/node (get-in tests [1 0])))
  # =>
  "(+ 1 1)"

  (l/gen (j/node (get-in tests [1 1])))
  # =>
  "2"

  )

(defn extract-test-zlocs
  [src]
  (var tests @[])
  (var curr-zloc
    (-> (l/par src)
        j/zip-down
        # XXX: leading newline is a hack to prevent very first thing
        #      from being a comment block
        (j/insert-left [:whitespace @{} "\n"])
        # XXX: once the newline is inserted, need to move to it
        j/left))
  #
  (while (not (j/end? curr-zloc))
    # try to find a top-level comment block
    (if-let [comment-zloc
             (j/right-until curr-zloc
                            |(match (j/node $)
                               [:tuple _ [:symbol _ "comment"]]
                               true))]
      (do
        (let [results (extract-tests-from-comment-zloc comment-zloc)]
          (unless (empty? results)
            (array/push tests ;results))
          (set curr-zloc comment-zloc)))
      (break)))
  #
  tests)

(comment

  (def src
    ``
    (comment

      (def a 1)

      (put @{}
           :a 2)
      # left =>
      @{:a 2}

      (+ 1 1)
      # => right
      2

      )

    (comment

      (string/slice "hallo" 1)
      # =>
      "allo"

      )
    ``)

  (def test-zlocs
    (extract-test-zlocs src))

  # XXX: the indentation for all lines after the first one is off by 2
  #      because all lines are indented by 2 within the comment form.
  #      the first part of the test (on the first line) is not
  #      indented because the first non-whitespace character is
  #      what is identified as the starting position
  (l/gen (j/node (get-in test-zlocs [0 0])))
  # =>
  ``
  (put @{}
         :a 2)
  ``

  (l/gen (j/node (get-in test-zlocs [0 1])))
  # =>
  "@{:a 2}"

  (l/gen (j/node (get-in test-zlocs [2 0])))
  # =>
  "(string/slice \"hallo\" 1)"

  (l/gen (j/node (get-in test-zlocs [2 1])))
  # =>
  "\"allo\""

  )

# XXX: not perfect, but mostly ok?
(defn get-indentation
  [a-zloc]
  (when-let [left-zloc (j/left a-zloc)]
    (let [[the-type _ content] (j/node left-zloc)]
      (when (= :whitespace the-type)
        # found indentation
        (when (empty? (string/trim content))
          # early return
          (break content)))))
  # no indentation
  "")

(comment

  (def src
    ``
    (comment

      (def a 1)

      (put @{} :a 2)
      # =>
      @{:a 2}

      )
    ``)

  (def [ti-zloc _ _]
    (find-test-indicator (-> (l/par src)
                             j/zip-down
                             j/down)))

  (get-indentation (find-test-expr ti-zloc))
  # =>
  "  "

  )

(defn indent-node-gen
  [a-zloc]
  (string (get-indentation a-zloc) (l/gen (j/node a-zloc))))

(defn extract-tests
  [src]
  (def test-zlocs
    (extract-test-zlocs src))
  (map |(let [[t-zloc e-zloc] $]
          [(indent-node-gen t-zloc)
           (indent-node-gen e-zloc)])
       test-zlocs))

# only operate on first comment form
(defn extract-first-test-set-zlocs
  [src]
  (var tests @[])
  (var curr-zloc
    (-> (l/par src)
        j/zip-down
        # XXX: leading newline is a hack to prevent very first thing
        #      from being a comment block
        (j/insert-left [:whitespace @{} "\n"])
        # XXX: once the newline is inserted, need to move to it
        j/left))
  #
  (while (not (j/end? curr-zloc))
    # try to find a top-level comment block
    (if-let [comment-zloc
             (j/right-until curr-zloc
                            |(match (j/node $)
                               [:tuple _ [:symbol _ "comment"]]
                               true))]
      (do
        (let [results (extract-tests-from-comment-zloc comment-zloc)]
          (unless (empty? results)
            (array/push tests ;results))
          (break)))
      (break)))
  #
  tests)

# only operate on first comment form
(defn extract-first-test-set
  [src]
  (def test-zlocs
    (extract-first-test-set-zlocs src))
  (map |(let [[t-zloc e-zloc] $]
          [(indent-node-gen t-zloc)
           (indent-node-gen e-zloc)])
       test-zlocs))

