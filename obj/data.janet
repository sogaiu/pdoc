(def data/_boolean
  `````
(import ../margaret/meg :as peg)

# `true` or `false`

# Equivalent to `0` and `(not 0)` respectively.

(comment

  (peg/match true "")
  # =>
  @[]

  (peg/match false "")
  # =>
  nil

  (peg/match true "a")
  # =>
  @[]

  (peg/match false "a")
  # =>
  nil

  (peg/match '(choice "a" true) "a")
  # =>
  @[]

  (peg/match '(choice "a" true) "")
  # =>
  @[]

  (peg/match '(choice "a" false) "a")
  # =>
  @[]

  (peg/match '(choice "a" false) "")
  # =>
  nil

  )

  `````
)

(def data/_buffer
  `````
(import ../margaret/meg :as peg)

# `@"<b>"` -- where <s> is buffer content

# Matches a literal buffer, and advances a corresponding number of characters.

(comment

  (peg/match @"cat" "cat")
  # =>
  @[]

  (peg/match @"cat" "cat1")
  # =>
  @[]

  (peg/match @"" "")
  # =>
  @[]

  (peg/match @"" "a")
  # =>
  @[]

  (peg/match @"cat" "dog")
  # =>
  nil

  )

  `````
)

(def data/_dictionary
  `````
(import ../margaret/meg :as peg)

# `{:main <rule> ...}`

# or

# `@{:main <rule> ...}`

# where <rule> is a peg (see below for ...)

# The feature that makes PEGs so much more powerful than pattern
# matching solutions like (vanilla) regex is mutual recursion.

# To do recursion in a PEG, you can wrap multiple patterns in a
# grammar, which is a Janet dictionary (i.e. a struct or a table).

# The patterns must be named by keywords, which can then be used in
# all sub-patterns in the grammar.

# Each grammar, defined by a dictionary, must also have a main rule,
# called `:main`, that is the pattern that the entire grammar is
# defined by.

(comment

  (peg/match '{:main 1} "a")
  # =>
  @[]

  (peg/match '{:main :fun
               :fun 1}
             "a")
  # =>
  @[]

  (peg/match ~{:main (some :fun)
               :fun (choice :play :relax)
               :play "1"
               :relax "0"}
             "0110111001")
  # =>
  @[]

  )

(comment

  (def my-grammar
    '{:a (* "a" :b "a")
      :b (* "b" (+ :a 0) "b")
      :main (* "(" :b ")")})

  # alternative expression of `my-grammar`
  (def my-grammar-alt
    '@{# :b wrapped in parens
       :main (sequence "("
                       :b
                       ")")
       # :a or nothing wrapped in lowercase b's
       :b (sequence "b"
                    (choice :a 0)
                    "b")
       # :b wrapped in lowercase a's
       :a (sequence "a"
                    :b
                    "a")})

  # simplest match
  (peg/match my-grammar-alt "(bb)")
  # =>
  @[]

  # next simplest match
  (peg/match my-grammar-alt "(babbab)")
  # =>
  @[]

  # non-match
  (peg/match my-grammar-alt "(baab)")
  # =>
  nil

  (all |(deep= (peg/match my-grammar $)
               (peg/match my-grammar-alt $))
       ["(bb)" "(babbab)" "(baab)"])
  # =>
  true

  )

  `````
)

(def data/_integer
  `````
(import ../margaret/meg :as peg)

# `<n>` -- where <n> is an integer

# For n >= 0, try to match n characters, and if successful, advance
# that many characters.

# For n < 0, matches only if there aren't |n| characters, and do not
# advance.

# For example, -1 will match the end of a string because the length of
# the empty string is 0, which is less than 1 (i.e. |-1| = 1 and there
# aren't that many characters).

(comment

  (peg/match 0 "")
  # =>
  @[]

  (peg/match 1 "")
  # =>
  nil

  (peg/match 1 "a")
  # =>
  @[]

  (peg/match 3 "cat")
  # =>
  @[]

  (peg/match 2 "cat")
  # =>
  @[]

  (peg/match 4 "cat")
  # =>
  nil

  (peg/match -1 "")
  # =>
  @[]

  (peg/match -2 "")
  # =>
  @[]

  (peg/match -1 "cat")
  # =>
  nil

  (peg/match -2 "o")
  # =>
  @[]

  )

  `````
)

(def data/_string
  `````
(import ../margaret/meg :as peg)

# `"<s>"` -- where <s> is string content

# Matches a literal string, and advances a corresponding number of characters.

(comment

  (peg/match "cat" "cat")
  # =>
  @[]

  (peg/match "cat" "cat1")
  # =>
  @[]

  (peg/match "" "")
  # =>
  @[]

  (peg/match "" "a")
  # =>
  @[]

  (peg/match "cat" "dog")
  # =>
  nil

  )

  `````
)

(def data/accumulate
  `````
(import ../margaret/meg :as peg)

# `(accumulate patt ?tag)`

# Capture a string that is the concatenation of all captures in `patt`.

# `(% patt ?tag)` is an alias for `(accumulate patt ?tag)`

(comment

  (peg/match ~(accumulate (sequence (capture 1)
                                    (capture 1)
                                    (capture 1)))
             "abc")
  # =>
  @["abc"]

  (peg/match ~(sequence (accumulate (sequence (capture "a")
                                              (capture "b"))
                                    :my-tag)
                        (backref :my-tag))
             "abc")
  # =>
  @["ab" "ab"]

  (peg/match ~(accumulate (sequence (capture "a")
                                    (capture "b")
                                    (capture "c")))
             "abc")
  # =>
  @["abc"]

  (peg/match ~(accumulate (sequence (capture "a")
                                    (position)
                                    (capture "b")
                                    (position)
                                    (capture "c")
                                    (position)))
             "abc")
  # =>
  @["a1b2c3"]

  (peg/match ~(% (sequence (capture "a")
                           (capture "b")
                           (capture "c")))
             "abc")
  # =>
  @["abc"]

  (peg/match ~(% (sequence (capture "a")
                           (position)
                           (capture "b")
                           (position)
                           (capture "c")
                           (position)))
             "abc")
  # =>
  @["a1b2c3"]

  )

  `````
)

(def data/any
  `````
(import ../margaret/meg :as peg)

# `(any patt)`

# Matches 0 or more repetitions of `patt`

(comment

  # any with empty string
  (peg/match ~(any "a")
             "")
  # =>
  @[]

  # any
  (peg/match ~(any "a")
             "aa")
  # =>
  @[]

  # any with capture
  (peg/match ~(capture (any "a"))
             "aa")
  # =>
  @["aa"]

  )

  `````
)

(def data/argument
  `````
(import ../margaret/meg :as peg)

# `(argument n ?tag)`

# Captures the nth extra argument to the `match` function and does not advance.

(comment

  (peg/match ~(sequence "abc"
                        (argument 0))
             "abc"
             0
             :smile)
  # =>
  @[:smile]

  (peg/match ~(argument 0) "whatever"
             0
             :zero :one :two)
  # =>
  @[:zero]

  (peg/match ~(argument 2) "whatever"
             0
             :zero :one :two)
  # =>
  @[:two]

  (peg/match ~(sequence (argument 0 :tag)
                        (backref :tag))
             "ignored"
             0
             :smile)
  # =>
  @[:smile :smile]

  )

  `````
)

(def data/at-least
  `````
(import ../margaret/meg :as peg)

# `(at-least n patt)`

# Matches at least n repetitions of patt

(comment

  (peg/match ~(at-least 3 "z")
             "zz")
  # =>
  nil

  (peg/match ~(at-least 3 "z")
             "zzz")
  # =>
  @[]

  )

  `````
)

(def data/at-most
  `````
(import ../margaret/meg :as peg)

# `(at-most n patt)`

# Matches at most n repetitions of patt

(comment

  (peg/match ~(at-most 3 "z") "zz")
  # =>
  @[]

  (peg/match ~(sequence (at-most 3 "z") "z")
             "zzz")
  # =>
  nil

  )

  `````
)

(def data/backmatch
  `````
(import ../margaret/meg :as peg)

# `(backmatch ?tag)`

# If `tag` is provided, matches against the tagged capture.

# If no tag is provided, matches against the last capture, but only if that
# capture is untagged.

# The peg advances if there was a match.

(comment

  (peg/match ~(sequence (capture "a")
                        "b"
                        (capture (backmatch)))
             "aba")
  # =>
  @["a" "a"]

  (peg/match ~(sequence (capture "a" :a)
                        (capture "b")
                        (capture (backmatch)))
             "abb")
  # =>
  @["a" "b" "b"]

  (peg/match ~(sequence (capture "a" :a)
                        (capture "b")
                        (capture (backmatch :a)))
             "aba")
  # =>
  @["a" "b" "a"]

  (peg/match ~(sequence (capture "a" :target)
                        (capture (some "b"))
                        (capture (backmatch :target)))
             "abbba")
  # =>
  @["a" "bbb" "a"]

  (peg/match ~(sequence (capture "a")
                        (capture (some "b"))
                        (capture (backmatch))) # referring to captured "b"s
             "abbba")
  # =>
  nil

  (peg/match ~(sequence (capture "a")
                        (some "b")
                        (capture (backmatch))) # referring to captured "a"
             "abbba")
  # =>
  @["a" "a"]

  )

(comment

  (def backmatcher-1
    '(sequence (capture (any "x") :1)
               "y"
               (backmatch :1)
               -1))

  (peg/match backmatcher-1 "y")
  # =>
  @[""]

  (peg/match backmatcher-1 "xyx")
  # =>
  @["x"]

  (peg/match backmatcher-1 "xxxxxxxyxxxxxxx")
  # =>
  @["xxxxxxx"]

  (peg/match backmatcher-1 "xyxx")
  # =>
  nil

  (peg/match backmatcher-1
             (string "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
                     "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxy"))
  # =>
  nil

  (def backmatcher-2
    '(sequence '(any "x")
               "y"
               (backmatch)
               -1))

  (peg/match backmatcher-2 "y")
  # =>
  @[""]

  (peg/match backmatcher-2 "xyx")
  # =>
  @["x"]

  (peg/match backmatcher-2 "xxxxxxxyxxxxxxx")
  # =>
  @["xxxxxxx"]

  (peg/match backmatcher-2 "xyxx")
  # =>
  nil

  (peg/match backmatcher-2
             (string "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
                     "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxy"))
  # =>
  nil

  (peg/match backmatcher-2
             (string (string/repeat "x" 1000) "y"))
  # =>
  nil

  (peg/match backmatcher-2
             (string (string/repeat "x" 1000)
                     "y"
                     (string/repeat "x" 1000)))
  # =>
  (array (string/repeat "x" 1000))

  (def longstring-2
    '(sequence (capture (any "`"))
               (any (if-not (backmatch) 1))
               (backmatch)
               -1))

  (peg/match longstring-2 "`john")
  # =>
  nil

  (peg/match longstring-2 "abc")
  # =>
  nil

  (peg/match longstring-2 "` `")
  # =>
  @["`"]

  (peg/match longstring-2 "`  `")
  # =>
  @["`"]

  (peg/match longstring-2 "``  ``")
  # =>
  @["``"]

  (peg/match longstring-2 "``` `` ```")
  # =>
  @["```"]

  (peg/match longstring-2 "``  ```")
  # =>
  nil

  )

  `````
)

(def data/backref
  `````
(import ../margaret/meg :as peg)

# `(backref prev-tag ?tag)`

# Duplicates the last capture with tag `prev-tag`.

# If no such capture exists then the match fails.

# `(-> prev-tag ?tag)` is an alias for `(backref prev-tag ?tag)`

(comment

  (peg/match ~(sequence (capture 1 :a)
                        (backref :a))
             "a")
  # =>
  @["a" "a"]

  (peg/match ~(sequence (capture "a" :target)
                        (backref :target))
             "b")
  # =>
  nil

  (peg/match ~(sequence (capture 1 :a)
                        (backref :a)
                        (capture 1))
             "ab")
  # =>
  @["a" "a" "b"]

  (peg/match ~(sequence (capture "a" :target)
                        (capture "b" :target-2)
                        (backref :target-2)
                        (backref :target))
             "ab")
  # =>
  @["a" "b" "b" "a"]

  (peg/match ~(sequence (capture "a" :target)
                        (-> :target))
             "a")
  # =>
  @["a" "a"]

  (peg/match ~(sequence (capture "a" :target)
                        (capture "b" :target-2)
                        (-> :target-2)
                        (-> :target))
             "ab")
  # =>
  @["a" "b" "b" "a"]

  (peg/match ~(sequence (capture "a" :target)
                        (-> :target))
             "b")
  # =>
  nil

  )

  `````
)

(def data/between
  `````
(import ../margaret/meg :as peg)

# `(between min max patt)`

# Matches between `min` and `max` (inclusive) repetitions of `patt`

# `(opt patt)` and `(? patt)` are aliases for `(between 0 1 patt)`

(comment

  # between
  (peg/match ~(between 1 3 "a")
             "aa")
  # =>
  @[]

  # between matching max
  (peg/match ~(between 0 1 "a")
             "a")
  # =>
  @[]

  # between matching min 0 on empty string
  (peg/match ~(between 0 1 "a")
             "")
  # =>
  @[]

  # between matching 0 occurrences
  (peg/match ~(between 0 8 "b")
             "")
  # =>
  @[]

  # between with sequence
  (peg/match ~(sequence (between 0 2 "c")
                        "c")
             "ccc")
  # =>
  @[]

  # between matched max, so sequence fails
  (peg/match ~(sequence (between 0 3 "c")
                        "c")
             "ccc")
  # =>
  nil

  # opt
  (peg/match ~(opt "a")
             "a")
  # =>
  @[]

  # opt with empty string
  (peg/match ~(opt "a")
             "")
  # =>
  @[]

  (peg/match ~(? "a") "a")
  # =>
  @[]

  (peg/match ~(? "a") "")
  # =>
  @[]

  )

(comment

  # issue 1554 case 1
  (peg/match '(any (> '1)) "abc")
  # =>
  @["a"]

  # issue 1554 case 2
  (peg/match '(any (? (> '1))) "abc")
  # =>
  @["a"]

  # issue 1554 case 3
  (peg/match '(any (> (? '1))) "abc")
  # =>
  @["a"]

  # issue 1554 case 4
  (peg/match '(* "a" (> '1)) "abc")
  # =>
  @["b"]

  # issue 1554 case 5
  (peg/match '(* "a" (? (> '1))) "abc")
  # =>
  @["b"]

  # issue 1554 case 6
  (peg/match '(* "a" (> (? '1))) "abc")
  # =>
  @["b"]

  )

  `````
)

(def data/capture
  `````
(import ../margaret/meg :as peg)

# `(capture patt ?tag)`

# Capture all of the text in `patt` if `patt` matches.

# If `patt` contains any captures, then those captures will be pushed on to
# the capture stack before the total text.

# `(<- patt ?tag)` is an alias for `(capture patt ?tag)`

# `(quote patt ?tag)` is an alias for `(capture patt ?tag)`

# This allows code like `'patt` to capture a pattern

(comment

  (peg/match '(capture 1) "a")
  # =>
  @["a"]

  (peg/match ~(capture "a") "a")
  # =>
  @["a"]

  (peg/match ~(<- "a") "a")
  # =>
  @["a"]

  (peg/match ~(capture 2) "hi")
  # =>
  @["hi"]

  (peg/match ~(quote 2) "hi")
  # =>
  @["hi"]

  (peg/match ~'2 "hi")
  # =>
  @["hi"]

  (peg/match ~(capture -1) "")
  # =>
  @[""]

  (peg/match '(capture 1 :a) "a")
  # =>
  @["a"]

  (peg/match ~(sequence (capture :d+ :a)
                        (backref :a))
             "78")
  # =>
  @["78" "78"]

  (peg/match ~(capture (range "ac")) "b")
  # =>
  @["b"]

  )

(comment

  (let [text (if (< (math/random) 0.5)
               "b"
               "y")
        [cap] (peg/match ~(capture (range "ac" "xz"))
                         text)]
    (or (= cap "b")
        (= cap "y")))
  # =>
  true

  (peg/match ~(capture (set "cat")) "cat")
  # =>
  @["c"]

  (peg/match ~(<- 2) "hi")
  # =>
  @["hi"]

  (peg/match ~(<- -1) "")
  # =>
  @[""]

  (peg/match ~(<- (range "ac")) "b")
  # =>
  @["b"]

  (let [text (if (< (math/random) 0.5)
               "b"
               "y")
        [cap] (peg/match ~(<- (range "ac" "xz"))
                         text)]
    (or (= cap "b")
        (= cap "y")))
  # =>
  true

  (peg/match ~(<- (set "cat")) "cat")
  # =>
  @["c"]

  (peg/match ~(quote "a") "a")
  # =>
  @["a"]

  (peg/match ~'"a" "a")
  # =>
  @["a"]

  (peg/match ~(quote -1) "")
  # =>
  @[""]

  (peg/match ~'-1 "")
  # =>
  @[""]

  (peg/match ~(quote (range "ac")) "b")
  # =>
  @["b"]

  (peg/match ~'(range "ac") "b")
  # =>
  @["b"]

  (let [text (if (< (math/random) 0.5)
               "b"
               "y")
        [cap] (peg/match ~(quote (range "ac" "xz"))
                         text)]
    (or (= cap "b")
        (= cap "y")))
  # =>
  true

  (let [text (if (< (math/random) 0.5)
               "b"
               "y")
        [cap] (peg/match ~'(range "ac" "xz")
                         text)]
    (or (= cap "b")
        (= cap "y")))
  # =>
  true

  (peg/match ~(quote (set "cat")) "cat")
  # =>
  @["c"]

  (peg/match ~'(set "cat") "cat")
  # =>
  @["c"]

  )

  `````
)

(def data/choice
  `````
(import ../margaret/meg :as peg)

# `(choice patt-1 patt-2 ...)`

# Tries to match patt-1, then patt-2, and so on.

# Will succeed on the first successful match, and fails if none of the
# arguments match the text.

# `(+ patt-1 patt-2 ...)` is an alias for `(choice patt-1 patt-2 ...)`

(comment

  (peg/match ~(choice) "")
  # =>
  nil

  (peg/match ~(choice) "a")
  # =>
  nil

  (peg/match ~(choice 1)
             "a")
  # =>
  @[]

  (peg/match ~(choice (capture 1))
             "a")
  # =>
  @["a"]

  (peg/match ~(choice "a" "b")
             "a")
  # =>
  @[]

  (peg/match ~(+ "a" "b")
             "a")
  # =>
  @[]

  (peg/match ~(choice "a" "b")
             "b")
  # =>
  @[]

  (peg/match ~(choice "a" "b")
             "c")
  # =>
  nil

  )

  `````
)

(def data/cms
  `````
(import ../margaret/meg :as peg)

# `(cms patt fun ?tag)`

# Invokes `fun` with all of the captures of `patt` as arguments (if
# `patt` matches).

# If the result is an indexed type, then captures the elements of the
# result.  If the result is not an indexed type, then captures the
# result.

# The whole expression fails if `fun` returns false or nil.

(comment

  (peg/match ~(cms (sequence 1 (capture 1) 1)
                   ,|[$ $ $])
             "abc")
  # =>
  @["b" "b" "b"]

  (peg/match ~(cms (sequence 1 1 (capture 1))
                   ,|@[$ $ $])
             "abc")
  # =>
  @["c" "c" "c"]

  (peg/match ~(cms (capture 1)
                   ,(fn [cap]
                      (= cap "a")))
             "a")
  # =>
  @[true]

  (peg/match ~(cms (capture 1)
                   ,(fn [cap]
                      (= cap "a")))
             "b")
  # =>
  nil

  (peg/match ~(cms (capture "hello")
                   ,(fn [cap]
                      (string cap "!")))
             "hello")
  # =>
  @["hello!"]

  (peg/match ~(cms (sequence (capture "hello")
                             (some (set " ,"))
                             (capture "world"))
                   ,(fn [cap1 cap2]
                      (string cap2 ": yes, " cap1 "!")))
             "hello, world")
  # =>
  @["world: yes, hello!"]

  )

(comment

  (peg/match ~{:main :pair
               :pair (sequence (cms (capture :key)
                                    ,identity)
                               "="
                               (cms (capture :value)
                                    ,identity))
               :key (any (sequence (not "=")
                                   1))
               :value (any (sequence (not "&")
                                     1))}
             "name=tao")
  # =>
  @["name" "tao"]

  )

  `````
)

(def data/cmt
  `````
(import ../margaret/meg :as peg)

# `(cmt patt fun ?tag)`

# Invokes `fun` with all of the captures of `patt` as arguments (if
# `patt` matches).

# If the result is truthy, then captures the result.

# The whole expression fails if `fun` returns false or nil.

(comment

  (peg/match ~(cmt (sequence 1 (capture 1) 1)
                   ,|[$ $ $])
             "abc")
  # =>
  @[["b" "b" "b"]]

  (peg/match ~(cmt (sequence 1 1 (capture 1))
                   ,|@[$ $ $])
             "abc")
  # =>
  @[@["c" "c" "c"]]

  (peg/match ~(cmt (capture 1)
                   ,(fn [cap]
                      (= cap "a")))
             "a")
  # =>
  @[true]

  (peg/match ~(cmt (capture 1)
                   ,(fn [cap]
                      (= cap "a")))
             "b")
  # =>
  nil

  (peg/match ~(cmt (capture "hello")
                   ,(fn [cap]
                      (string cap "!")))
             "hello")
  # =>
  @["hello!"]

  (peg/match ~(cmt (sequence (capture "hello")
                             (some (set " ,"))
                             (capture "world"))
                   ,(fn [cap1 cap2]
                      (string cap2 ": yes, " cap1 "!")))
             "hello, world")
  # =>
  @["world: yes, hello!"]

  )

(comment

  (peg/match ~{:main :pair
               :pair (sequence (cmt (capture :key)
                                    ,identity)
                               "="
                               (cmt (capture :value)
                                    ,identity))
               :key (any (sequence (not "=")
                                   1))
               :value (any (sequence (not "&")
                                     1))}
             "name=tao")
  # =>
  @["name" "tao"]

  )

  `````
)

(def data/column
  `````
(import ../margaret/meg :as peg)

# `(column ?tag)`

# Captures the column of the current index into the text and advances no input.

(comment

  (peg/match ~(column)
             "a")
  # =>
  @[1]

  (peg/match ~(sequence "a"
                        (column))
             "ab")
  # =>
  @[2]

  (peg/match ~(sequence "a\n"
                        (column))
             "a\nb")
  # =>
  @[1]

  (peg/match ~(sequence "a\nb"
                        (column))
             "a\nb")
  # =>
  @[2]

  (peg/match ~(sequence "ab"
                        (column)
                        (capture "c"))
             "abc")
  # =>
  @[3 "c"]

  )

  `````
)

(def data/constant
  `````
(import ../margaret/meg :as peg)

# `(constant k ?tag)`

# Captures a constant value and advances no characters.

(comment

  (peg/match ~(constant "smile")
             "whatever")
  # =>
  @["smile"]

  (peg/match ~(constant {:fun :value})
             "whatever")
  # =>
  @[{:fun :value}]

  (peg/match ~(sequence (constant :relax)
                        (position))
             "whatever")
  # =>
  @[:relax 0]

  )

  `````
)

(def data/drop
  `````
(import ../margaret/meg :as peg)

# `(drop patt)`

# Ignores (drops) all captures from `patt`.

(comment

  (peg/match ~(drop (capture 1))
             "a")
  # =>
  @[]

  (peg/match ~(sequence (drop (cmt (capture 3)
                                   ,scan-number))
                        (capture (any 1)))
             "-1.89")
  # =>
  @["89"]

  )

  `````
)

(def data/error
  `````
(import ../margaret/meg :as peg)

# `(error ?patt)`

# Throws a Janet error.

# The error thrown will be the last capture of `patt`, or a generic error if
# `patt` produces no captures or `patt` is not specified.

# If `patt` does not match, no error will be thrown.

(comment

  # error match failure
  (peg/match ~(error "ho")
             "")
  # =>
  nil

  )

(comment

  (try
    (peg/match ~(sequence "a"
                          "\n"
                          "b"
                          "\n"
                          "c"
                          (error))
               "a\nb\nc")
    ([e] e))
  # =>
  "match error at line 3, column 2"

  (try
    (peg/match ~(error (capture "a"))
               "a")
    ([e] e))
  # =>
  "a"

  (try
    (peg/match ~(sequence "a"
                          (error (sequence (capture "b")
                                           (capture "c"))))
               "abc")
    ([err]
      err))
  # =>
  "c"

  (try
    (peg/match ~(choice "a"
                        "b"
                        (error ""))
               "c")
    ([err]
      err))
  # =>
  "match error at line 1, column 1"

  (try
    (peg/match ~(choice "a"
                        "b"
                        (error))
               "c")
    ([err]
      :match-error))
  # =>
  :match-error

  )
  `````
)

(def data/group
  `````
(import ../margaret/meg :as peg)

# `(group patt ?tag)`

# Captures an array of all of the captures in `patt`

(comment

  (peg/match ~(group (sequence (capture 1)
                               (capture 1)
                               (capture 1)))
           "abc")
  # =>
  @[@["a" "b" "c"]]

  (first
    (peg/match ~(group (sequence (capture "(")
                                 (capture (any (if-not ")" 1)))
                                 (capture ")")))
               "(defn hi [] 1)"))
  # =>
  @["(" "defn hi [] 1" ")"]

  (peg/match ~(group (sequence (capture "a")
                               (group (capture "b"))))
             "ab")
  # =>
  @[@["a" @["b"]]]

  )

  `````
)

(def data/if-not
  `````
(import ../margaret/meg :as peg)

# `(if-not cond patt)`

# Tries to match only if `cond` does not match.

# `cond` will not produce any captures.

(comment

  (peg/match ~(if-not 2 "a")
             "a")
  # =>
  @[]

  (peg/match ~(if-not 5 (set "iknw"))
             "wink")
  # =>
  @[]

  # https://github.com/janet-lang/janet/issues/1026
  (peg/match ~(if-not (sequence (constant 7) "a") "hello")
             "hello")
  # =>
  @[]

  # https://github.com/janet-lang/janet/issues/1026
  (peg/match ~(if-not (drop (sequence (constant 7) "a")) "hello")
             "hello")
  # =>
  @[]

  )

  `````
)

(def data/if
  `````
(import ../margaret/meg :as peg)

# `(if cond patt)`

# Tries to match `patt` only if `cond` matches as well.

# `cond` will not produce any captures.

(comment

  (peg/match ~(if 1 "a")
             "a")
  # =>
  @[]

  (peg/match ~(if 5 (set "eilms"))
             "smile")
  # =>
  @[]

  (peg/match ~(if 5 (set "eilms"))
             "wink")
  # =>
  nil

  )

  `````
)

(def data/int-be
  `````
(import ../margaret/meg :as peg)

# `(int-be n ?tag)`

# Captures `n` bytes interpreted as a big endian integer.

(comment

  (peg/match '(int-be 1) "a")
  # =>
  @[(chr "a")]

  (peg/match ~(int-be 2) "ab")
  # =>
  @[24930]

  (deep=
    (peg/match ~(int-be 8) "abcdefgh")
    @[(int/s64 "7017280452245743464")])
  # =>
  true

  (peg/match ~(sequence (int-be 2 :a)
                        (backref :a))
             "ab")
  # =>
  @[24930 24930]

  (peg/match '(int-be 1) "\xFF")
  # =>
  @[-1]

  (peg/match '(int-be 2) "\x7f\xff")
  # =>
  @[0x7fff]

  )

  `````
)

(def data/int
  `````
(import ../margaret/meg :as peg)

# `(int n ?tag)`

# Captures `n` bytes interpreted as a little endian integer.

(comment

  (peg/match ~(int 1) "a")
  # =>
  @[97]

  (peg/match ~(int 2) "ab")
  # =>
  @[25185]

  (peg/match ~(int 8) "abcdefgh")
  # =>
  @[(int/s64 "7523094288207667809")]

  (peg/match ~(sequence (int 2 :a)
                        (backref :a))
             "ab")
  # =>
  @[25185 25185]

  (peg/match '(int 1) "\xFF")
  # =>
  @[-1]

  (peg/match '(int 2) "\xFF\x7f")
  # =>
  @[0x7fff]

  (peg/match '(int 8)
             "\xff\x7f\x00\x00\x00\x00\x00\x00")
  # =>
  @[(int/s64 0x7fff)]

  (peg/match '(int 7)
             "\xff\x7f\x00\x00\x00\x00\x00")
  # =>
  @[(int/s64 0x7fff)]

  (peg/match '(sequence (int 2) -1)
             "123")
  # =>
  nil

  )

  `````
)

(def data/lenprefix
  `````
(import ../margaret/meg :as peg)

# `(lenprefix n patt)`

# Matches `n` repetitions of `patt`, where `n` is supplied from other parsed
# input and is not constant.

# `n` is obtained from the capture stack.

(comment

  (peg/match ~(lenprefix (number :d) 1)
             "2xy")
  # =>
  @[]

  (peg/match ~(capture (lenprefix (number :d) 1))
             "2xy")
  # =>
  @["2xy"]

  (peg/match ~(sequence (number :d nil :tag)
                        (capture (lenprefix (backref :tag)
                                            1)))
             "3abc")
  # =>
  @[3 "abc"]

  (peg/match ~(replace (sequence (number :d 10 :tag)
                                 (capture (lenprefix (backref :tag)
                                                     1)))
                       ,(fn [num cap]
                          cap))
             "3abc")
  # =>
  @["abc"]

  (peg/match
    ~(repeat 2
       (replace (lenprefix (number :d+) (capture 1))
                ,|(string ;$&)))
    "2aa1b")
  # =>
  @["aa" "b"]

  (peg/match
    ~(repeat 2
       (accumulate (lenprefix (number :d+) (capture 1))))
    "2aa1b")
  # =>
  @["aa" "b"]

  (peg/match ~(lenprefix
                (replace (sequence (capture (any (if-not ":" 1)))
                                   ":")
                         ,scan-number)
                1)
             "8:abcdefgh")
  # =>
  @[]

  )

(comment

  (def lenprefix-peg
    ~(sequence
       (lenprefix
         (replace (sequence (capture (any (if-not ":" 1)))
                            ":")
                  ,scan-number)
         1)
       -1))

  (peg/match lenprefix-peg "5:abcde")
  # =>
  @[]

  (peg/match lenprefix-peg "5:abcdef")
  # =>
  nil

  (peg/match lenprefix-peg "5:abcd")
  # =>
  nil

  )

  `````
)

(def data/line
  `````
(import ../margaret/meg :as peg)

# `(line ?tag)`

# Captures the line of the current index into the text and advances no input.

(comment

  (peg/match ~(line)
             "a")
  # =>
  @[1]

  (peg/match ~(sequence "a\n"
                        (line))
             "a\nb")
  # =>
  @[2]

  (peg/match ~(sequence "a"
                        (line)
                        (capture "b"))
             "ab")
  # =>
  @[1 "b"]

  )

  `````
)

(def data/look
  `````
(import ../margaret/meg :as peg)

# `(look ?offset patt)`

# Matches only if `patt` matches at a fixed offset.  `offset` should
# be an integer and defaults to 0.

# The peg will not advance any characters.

# `(> offset patt)` is an alias for `(look offset patt)`

(comment

  (peg/match ~(look 3 "cat")
             "my cat")
  # =>
  @[]

  (peg/match ~(look 3 (capture "cat"))
             "my cat")
  # =>
  @["cat"]

  (peg/match ~(look -4 (capture "cat"))
             "my cat")
  # =>
  nil

  (peg/match ~(sequence (look 3 "cat")
                        "my")
             "my cat")
  # =>
  @[]

  (peg/match ~(sequence "my"
                        (look -2 "my")
                        " "
                        (capture "cat"))
             "my cat")
  # =>
  @["cat"]

  (peg/match ~(capture (look 3 "cat"))
             "my cat")
  # =>
  @[""]

 (peg/match '(sequence (look 2) (capture 1)) "a")
  # =>
  nil

  (peg/match '(sequence (look 2) (capture 1)) "ab")
  # =>
  @["a"]

  (peg/match ~(> 3 "cat")
             "my cat")
  # =>
  @[]

  (peg/match ~(sequence (> 3 "cat")
                        "my")
             "my cat")
  # =>
  @[]

  )

  `````
)

(def data/not
  `````
(import ../margaret/meg :as peg)

# `(not patt)`

# Matches only if `patt` does not match.

# Will not produce captures or advance any characters.

# `(! patt)` is an alias for `(not patt)`

(comment

  (peg/match ~(not "cat") "dog")
  # =>
  @[]

  (peg/match ~(sequence (not "cat")
                        (set "dgo"))
             "dog")
  # =>
  @[]

  (peg/match ~(! "cat") "dog")
  # =>
  @[]

  # https://github.com/janet-lang/janet/issues/1026
  (peg/match ~(not (sequence (constant 7) "a"))
             "hello")
  # =>
  @[]

  # https://github.com/janet-lang/janet/issues/1026
  (peg/match ~(if (not (sequence (constant 7) "a")) "hello")
             "hello")
  # =>
  @[]

  )

  `````
)

(def data/nth
  `````
(import ../margaret/meg :as peg)

# `(nth index patt ?tag)`

# Capture one of the captures in `patt` at `index`.  If no such
# capture exists, then the match fails.

(comment

  (peg/match ~(nth 2 (sequence (capture 1)
                               (capture 1)
                               (capture 1)))
             "xyz")
  # =>
  @["z"]

  (peg/match ~{:main (some (nth 1 (* :prefix ":" :word)))
               :prefix (number :d+ nil :n)
               :word (capture (lenprefix (backref :n) :w))}
             "3:fox8:elephant")
  # =>
  @["fox" "elephant"]

  )

  `````
)

(def data/number
  `````
(import ../margaret/meg :as peg)

# `(number patt ?base ?tag)`

# Capture a number if `patt` matches and the matched text scans as a number.

# If specified, `base` should be a number between 2 and 36 inclusive or nil.
# If `base` is not nil, interpreting the string will be done according to
# radix `base`.  If `base` is nil,  interpreting the string will be done
# via `scan-number` as-is.

# Note that if the capture is tagged, the captured content available via
# the tag (e.g. using `backref`) is a number and not a string.

(comment

  (peg/match '(number :d+) "18")
  # =>
  @[18]

  (peg/match ~(number :w+) "0xab")
  # =>
  @[171]

  (peg/match ~(number :w+ 8) "10")
  # =>
  @[8]

  (peg/match '(number (sequence (some (choice :d "_"))))
             "60_000 ganges rivers")
  # =>
  @[60000]

  (peg/match ~(number :d+ nil :my-tag) "18")
  # =>
  @[18]

  (peg/match '(number :w+ nil :your-tag) "0xab")
  # =>
  @[171]

  (peg/match ~(sequence (number :d+ nil :a)
                        (backref :a))
             "28")
  # =>
  @[28 28]

  )

(comment

  (let [chunked
        (string "4\r\n"
                "Wiki\r\n"
                "6\r\n"
                "pedia \r\n"
                "E\r\n"
                "in \r\n"
                "\r\n"
                "chunks.\r\n"
                "0\r\n"
                "\r\n")]
    (peg/match ~(some (sequence
                        (number :h+ 16 :length)
                        "\r\n"
                        (capture
                          (lenprefix (backref :length)
                                     1))
                        "\r\n"))
               chunked))
  # =>
  @[4 "Wiki" 6 "pedia " 14 "in \r\n\r\nchunks." 0 ""]

  )

  `````
)

(def data/only-tags
  `````
(import ../margaret/meg :as peg)

# `(only-tags patt)`

# Ignores all captures from `patt`, while making tagged captures
# within `patt` available for future back-referencing.

(comment

  (peg/match ~(sequence (only-tags (sequence (capture 1 :a)
                                             (capture 2 :b)))
                        (backref :a))
             "xyz")
  # =>
  @["x"]

  (peg/match
    ~{:main (some (sequence (only-tags (sequence :prefix ":" :word))
                            (backref :target)))
      :prefix (number :d+ nil :n)
      :word (capture (lenprefix (backref :n) :w)
                     :target)}
    "3:ant3:bee6:flower")
  # =>
  @["ant" "bee" "flower"]

  )

  `````
)

(def data/position
  `````
(import ../margaret/meg :as peg)

# `(position ?tag)`

# Captures the current index into the text and advances no input.

# `($ ?tag)` is an alias for `(position ?tag)`

(comment

  (peg/match ~(position) "a")
  # =>
  @[0]

  (peg/match ~(sequence "a"
                        (position))
             "ab")
  # =>
  @[1]

  (peg/match ~(sequence (capture "w")
                        (position :p)
                        (backref :p))
             "whatever")
  # =>
  @["w" 1 1]

  (peg/match ~($) "a")
  # =>
  @[0]

  (peg/match ~(sequence "a"
                        ($))
             "ab")
  # =>
  @[1]

  )

(comment

  (def rand-int
    (-> (os/cryptorand 3)
        math/rng
        (math/rng-int 90)
        inc))

  (def a-buf
    (buffer/new-filled rand-int 66))

  rand-int
  # =>
  (- (- ;(peg/match ~(sequence (position)
                               (some 1)
                               -1
                               (position))
                    a-buf)))

  )

  `````
)

(def data/range
  `````
(import ../margaret/meg :as peg)

# `(range r1 ?r2 .. ?rn)`

# Matches characters in a range and advances 1 character.

(comment

  (peg/match ~(range "aa")
             "a")
  # =>
  @[]

  (peg/match ~(capture (range "az"))
             "c")
  # =>
  @["c"]

  (peg/match ~(capture (range "az" "AZ"))
             "J")
  # =>
  @["J"]

  (peg/match ~(capture (range "09"))
             "123")
  # =>
  @["1"]

  )

(comment

  (let [text (if (< (math/random) 0.5)
               "b"
               "y")]
    (peg/match ~(range "ac" "xz")
               text))
  # =>
  @[]

  )

  `````
)

(def data/repeat
  `````
(import ../margaret/meg :as peg)

# `(repeat n patt)`

# Matches exactly n repetitions of x

# `(n patt)` is an alias for `(repeat n patt)`

(comment

  (peg/match ~(repeat 3 "m")
             "mmm")
  # =>
  @[]

  (peg/match ~(repeat 2 "m")
             "m")
  # =>
  nil

  (peg/match ~(3 "m")
             "mmm")
  # =>
  @[]

  (peg/match ~(2 "m")
             "m")
  # =>
  nil

  )

  `````
)

(def data/replace
  `````
(import ../margaret/meg :as peg)

# `(replace patt subst ?tag)`

# Replaces the captures produced by `patt` by applying `subst` to them.

# If `subst` is a table or struct, will push `(get subst last-capture)` to
# the capture stack after removing the old captures.

# If `subst` is a function, will call `subst` with the captures of `patt`
# as arguments and push the result to the capture stack.

# Otherwise, will push `subst` literally to the capture stack.

# `(/ patt subst ?tag)` is an alias for `(replace patt subst ?tag)`

(comment

  (peg/match ~(replace (capture "cat")
                       {"cat" "tiger"})
             "cat")
  # =>
  @["tiger"]

  (peg/match ~(/ (capture "cat")
                 {"cat" "tiger"})
             "cat")
  # =>
  @["tiger"]

  (peg/match ~(replace (sequence (capture "ant")
                                 (capture "bee"))
                       {"ant" "fox"
                        "bee" "elephant"})
             "antbee")
  # =>
  @["elephant"]

  (peg/match ~(replace (capture "cat")
                       ,(fn [original]
                          (string original "alog")))
             "cat")
  # =>
  @["catalog"]

  (peg/match ~(replace (sequence (capture "ca")
                                 (capture "t"))
                       ,(fn [one two]
                          (string one two "alog")))
             "cat")
  # =>
  @["catalog"]

  )

(comment

  (peg/match ~(replace (capture "cat")
                       "dog")
             "cat")
  # =>
  @["dog"]

  (peg/match ~(/ (capture "cat")
                 ,(fn [original]
                    (string original "alog")))
             "cat")
  # =>
  @["catalog"]

  (peg/match ~(/ (capture "cat")
                 "dog")
             "cat")
  # =>
  @["dog"]

  (peg/match ~(replace (capture "cat")
                       :hi)
             "cat")
  # =>
  @[:hi]

  (peg/match ~(capture (replace (capture "cat")
                                :hi))
             "cat")
  # =>
  @[:hi "cat"]

  )

  `````
)

(def data/sequence
  `````
(import ../margaret/meg :as peg)

# `(sequence patt-1 patt-2 ...)`

# Tries to match patt-1, patt-2, and so on in sequence.

# If any of these arguments fail to match the text, the whole pattern fails.

# `(* patt-1 patt-2 ...)` is an alias for `(sequence patt-1 patt-2 ...)`

(comment

  (peg/match ~(sequence) "a")
  # =>
  @[]

  (peg/match ~(sequence "a" "b" "c")
             "abc")
  # =>
  @[]

  (peg/match ~(* "a" "b" "c")
             "abc")
  # =>
  @[]

  (peg/match ~(sequence "a" "b" "c")
             "abcd")
  # =>
  @[]

  (peg/match ~(sequence "a" "b" "c")
             "abx")
  # =>
  nil

  (peg/match ~(sequence (capture 1 :a)
                        (capture 1)
                        (capture 1 :c))
             "abc")
  # =>
  @["a" "b" "c"]

  )

(comment

  (peg/match
    ~(sequence (capture "a"))
    "a")
  # =>
  @["a"]

  (peg/match
    ~(capture "a")
    "a")
  # =>
  (peg/match
    ~(sequence (capture "a"))
    "a")

  (peg/match
    ~(sequence (capture (choice "a" "b")))
    "a")
  # =>
  @["a"]

  (peg/match
    ~(capture (+ "GET" "POST" "PATCH" "DELETE"))
    "PATCH")
  # =>
  @["PATCH"]

  # thanks pepe
  (peg/match
    ~(capture (choice "GET" "POST" "PATCH" "DELETE"))
    "PATCH")
  # =>
  (peg/match
    ~(sequence (capture (choice "GET" "POST" "PATCH" "DELETE")))
    "PATCH")

  )

  `````
)

(def data/set
  `````
(import ../margaret/meg :as peg)

# `(set chars)`

# Match any character in the argument string. Advances 1 character.

(comment

  (peg/match ~(set "act")
             "cat")
  # =>
  @[]

  (peg/match ~(set "act!")
             "cat!")
  # =>
  @[]

  (peg/match ~(set "bo")
             "bob")
  # =>
  @[]

  (peg/match ~(capture (set "act"))
             "cat")
  # =>
  @["c"]

  )

  `````
)

(def data/some
  `````
(import ../margaret/meg :as peg)

# `(some patt)`

# Matches 1 or more repetitions of `patt`

(comment

  # some with empty string
  (peg/match ~(some "a")
             "")
  # =>
  nil

  # some
  (peg/match ~(some "a")
             "aa")
  # =>
  @[]

  # some with capture
  (peg/match ~(capture (some "a"))
             "aa")
  # =>
  @["aa"]

  )

  `````
)

(def data/split
  `````
(import ../margaret/meg :as peg)

# `(split separator-patt patt)`

# Split the remaining input by `separator-patt`, and execute `patt` on
# each substring.

# `patt` will execute with its input constrained to the next instance of
# `separator-patt`, as if narrowed by `(sub (to separator-patt) ...)`.

# `split` will continue to match separators and patterns until it reaches
# the end of the input; if you don't want to match to the end of the
# input you should first narrow it with `(sub ... (split ...))`.

(comment

  (peg/match ~(split "," (capture 1))
             "a,b,c")
  # =>
  @["a" "b" "c"]

  # drops captures from separator pattern
  (peg/match ~(split (capture ",") (capture 1))
             "a,b,c")
  # =>
  @["a" "b" "c"]

  # can match empty subpatterns
  (peg/match ~(split "," (capture :w*))
             ",a,,bar,,,c,,")
  # =>
  @["" "a" "" "bar" "" "" "c" "" ""]

  # subpattern is limited to only text before the separator
  (peg/match ~(split "," (capture (to -1)))
             "a,,bar,c")
  # =>
  @["a" "" "bar" "c"]

  # fails if any subpattern fails
  (peg/match ~(split "," (capture "a"))
             "a,a,b")
  # =>
  nil

  # separator does not have to match anything
  (peg/match ~(split "x" (capture (to -1)))
             "a,a,b")
  # =>
  @["a,a,b"]

  # always consumes entire input
  (peg/match ~(split 1 (capture ""))
             "abc")
  # =>
  @["" "" "" ""]

  # separator can be an arbitrary PEG
  (peg/match ~(split :s+ (capture (to -1)))
             "a   b      c")
  # =>
  @["a" "b" "c"]

  # does not advance past the end of the input
  (peg/match ~(sequence (split "," (capture :w+)) 0)
             "a,b,c")
  # =>
  @["a" "b" "c"]

  # issue #1539 at janet repository
  (peg/match ~(split "" (capture (to -1)))
             "hello there friends")
  # =>
  nil

  )

  `````
)

(def data/sub
  `````
(import ../margaret/meg :as peg)

# `(sub window-patt patt)`

# Match `window-patt` and if it succeeds, match `patt` against the
# bytes that `window-patt` matched.

# `patt` cannot match more than `window-patt`; it will see
# end-of-input at the end of the substring matched by `window-patt`.

# If `patt` also succeeds, `sub` will advance to the end of what
# `window-patt` matched.

# If any of the `col`, `line`, `position`, or `error` specials appear
# in `patt`, they still yield values relative to the whole input.

(comment

  # matches the same input twice
  (peg/match ~(sub "abcd" "abc")
             "abcdef")
  # =>
  @[]

  # second pattern cannot match more than the first pattern
  (peg/match ~(sub "abcd" "abcde")
             "abcdef")
  # =>
  nil

  # fails if first pattern fails
  (peg/match ~(sub "x" "abc")
             "abcdef")
  # =>
  nil

  # fails if second pattern fails
  (peg/match ~(sub "abc" "x")
             "abcdef")
  # =>
  nil

  # keeps captures from both patterns
  (peg/match ~(sub (capture "abcd") (capture "abc"))
             "abcdef")
  # =>
  @["abcd" "abc"]

  # second pattern can reference captures from first
  (peg/match ~(sequence (constant 5 :tag)
                        (sub (capture "abc" :tag)
                             (backref :tag)))
             "abcdef")
  # =>
  @[5 "abc" "abc"]

  # second pattern can't see past what the first pattern matches
  (peg/match ~(sub "abc" (sequence "abc" -1))
             "abcdef")
  # =>
  @[]

  # positions inside second match are still relative to the entire input
  (peg/match ~(sequence "one\ntw"
                        (sub "o" (sequence (position) (line) (column))))
             "one\ntwo\nthree\n")
  # =>
  @[6 2 3]

  # advances to the end of the first pattern's match
  (peg/match ~(sequence (sub "abc" "ab")
                        "d")
             "abcdef")
  # =>
  @[]

 (peg/match ~(sequence (sub (capture "abcd" :a)
                            (capture "abc"))
                       (capture (backmatch)))
            "abcdabcd")
  # =>
  @["abcd" "abc" "abc"]

  (peg/match ~(sequence (sub (capture "abcd" :a)
                             (capture "abc"))
                        (capture (backmatch :a)))
             "abcdabcd")
  # =>
  @["abcd" "abc" "abcd"]

  (peg/match ~(sequence (capture "abcd" :a)
                        (sub (capture "abc" :a)
                             (capture (backmatch :a)))
                        (capture (backmatch :a)))
             "abcdabcabcd")
  # =>
  @["abcd" "abc" "abc" "abc"]

  (peg/match ~(sequence (capture "abcd" :a)
                        (sub (capture "abc")
                             (capture (backmatch)))
                        (capture (backmatch :a)))
             "abcdabcabcd")
  # =>
  @["abcd" "abc" "abc" "abcd"]

  (peg/match ~(sub (capture "abcd")
                   (look 3 (capture "d")))
             "abcdcba")
  # =>
  @["abcd" "d"]

  (peg/match ~(sub (capture "abcd")
                   (capture (to "c")))
             "abcdef")
  # =>
  @["abcd" "ab"]

  (peg/match ~(sub (capture (to "d"))
                   (capture "abc"))
             "abcdef")
  # =>
  @["abc" "abc"]

  (peg/match ~(sub (capture (to "d"))
                   (capture (to "c")))
             "abcdef")
  # =>
  @["abc" "ab"]

  (peg/match ~(sequence (sub (capture (to "d"))
                             (capture (to "c")))
                        (capture (to "f")))
             "abcdef")
  # =>
  @["abc" "ab" "de"]

  (peg/match ~(sub (capture "abcd")
                   (capture (thru "c")))
             "abcdef")
  # =>
  @["abcd" "abc"]

  (peg/match ~(sub (capture (thru "d"))
                   (capture "abc"))
             "abcdef")
  # =>
  @["abcd" "abc"]

  (peg/match ~(sub (capture (thru "d"))
                   (capture (thru "c")))
             "abcdef")
  # =>
  @["abcd" "abc"]

  (peg/match ~(sequence (sub (capture (thru "d"))
                             (capture (thru "c")))
                        (capture (thru "f")))
             "abcdef")
  # =>
  @["abcd" "abc" "ef"]

  (peg/match ~(sequence (sub (capture 3)
                             (capture 2))
                        (capture 3))
             "abcdef")
  # =>
  @["abc" "ab" "def"]

  (peg/match ~(sub (capture -7)
                   (capture -1))
             "abcdef")
  # =>
  @["" ""]

  (peg/match ~(sequence (sub (capture -7)
                             (capture -1))
                        (capture 1))
             "abcdef")
  # =>
  @["" "" "a"]

  (peg/match ~(sequence (sub (capture (repeat 3 (range "ac")))
                             (capture (repeat 2 (range "ab"))))
                        (capture (repeat 3 (range "df"))))
             "abcdef")
  # =>
  @["abc" "ab" "def"]

  (peg/match ~(sequence (sub (capture (repeat 3 (set "abc")))
                             (capture (repeat 2 (set "ab"))))
                        (capture (repeat 3 (set "def"))))
             "abcdef")
  # =>
  @["abc" "ab" "def"]

  (peg/match ~(sequence (sub (capture "abcd")
                             (int 1))
                        (int 1))
             "abcdef")
  # =>
  @["abcd" 97 101]

  (peg/match ~(sequence (sub (capture "ab")
                             (int 3)))
             "abcdef")
  # =>
  nil

  (peg/match ~(sub (capture "abcd")
                   (sub (capture "abc")
                        (capture "ab")))
             "abcdef")
  # =>
  @["abcd" "abc" "ab"]

  )

(comment

  (try
    (peg/match ~(sequence "a"
                          (sub "bcd" (error "bc")))
               "abcdef")
    ([e] e))
  # =>
  "match error at line 1, column 2"


  )
  `````
)

(def data/thru
  `````
(import ../margaret/meg :as peg)

# `(thru patt)`

# Match up through `patt` (thus including it).

# If the end of the input is reached and `patt` is not matched, the entire
# pattern does not match.

(comment

  (peg/match ~(thru "\n")
             "this is a nice line\n")
  # =>
  @[]

  (peg/match ~(sequence (thru "\n")
                        "\n")
             "this is a nice line\n")
  # =>
  nil

  (peg/match ~(sequence "(" (thru ")"))
             "(12345)")
  # =>
  @[]

  (peg/match ~(sequence "(" (thru ")"))
             " (12345)")
  # =>
  nil

  (peg/match ~(sequence "(" (thru ")"))
             "(12345")
  # =>
  nil

  )

(comment

  # issue #640 in janet
  (peg/match '(thru -1) "aaaa")
  # =>
  @[]

  (peg/match ''(thru -1) "aaaa")
  # =>
  @["aaaa"]

  (peg/match '(thru "b") "aaaa")
  # =>
  nil

  # https://github.com/janet-lang/janet/issues/971
  (peg/match
    '{:dd (sequence :d :d)
      :sep (set "/-")
      :date (sequence :dd :sep :dd)
      :wsep (some (set " \t"))
      :entry (group (sequence (capture :date) :wsep (capture :date)))
      :main (some (thru :entry))}
    "1800-10-818-9-818 16/12\n17/12 19/12\n20/12 11/01")
  # =>
  @[@["17/12" "19/12"]
    @["20/12" "11/01"]]

  )

  `````
)

(def data/til
  `````
(import ../margaret/meg :as peg)

# `(til sep patt)`

# Match `patt` up to (but not including) the first character of what
# `(to sep)` matches.

# If `(to sep)` does not match, the entire pattern does not match.

# If match succeeds, advance one character beyond the last character
# matched by `(to sep)`.

# Any captures made by `(to sep)` are dropped.

# `(til set patt)` might be seen as short for:

# `(sequence (sub (drop (to sep)) patt) (drop sep))`

(comment

  (peg/match ~(sequence (til "bcde" (capture (to -1)))
                        (capture (to -1)))
             "abcdef")
  # =>
  @["a" "f"]

  # basic matching
  (peg/match ~(til "d" "abc")
             "abcdef")
  # =>
  @[]

  # second pattern can't see past the first occurrence of first pattern
  (peg/match ~(til "d" (sequence "abc" -1))
             "abcdef")
  # =>
  @[]

  # fails if first pattern fails
  (peg/match ~(til "x" "abc")
             "abcdef")
  # =>
  nil

  # fails if second pattern fails
  (peg/match ~(til "abc" "x")
             "abcdef")
  # =>
  nil

  # discards captures from initial pattern
  (peg/match ~(til (capture "d") (capture "abc"))
             "abcdef")
  # =>
  @["abc"]

  # positions inside second match are still relative to the entire input
  (peg/match ~(sequence "one\ntw"
                        (til 0 (sequence (position) (line) (column))))
             "one\ntwo\nthree\n")
  # =>
  @[6 2 3]

  # advances to the end of the first pattern's first occurrence
  (peg/match ~(sequence (til "d" "ab") "e")
             "abcdef")
  # =>
  @[]

  )

  `````
)

(def data/to
  `````
(import ../margaret/meg :as peg)

# `(to patt)`

# Match up to `patt` (but not including it).

# If the end of the input is reached and `patt` is not matched, the entire
# pattern does not match.

(comment

  (peg/match ~(to "\n")
             "this is a nice line\n")
  # =>
  @[]

  (peg/match ~(sequence (to "\n")
                        "\n")
             "this is a nice line\n")
  # =>
  @[]

  (peg/match ~(capture (to -1)) "foo")
  # =>
  @["foo"]

  )

(comment
  
  # issue #640 in janet
  (peg/match '(to -1) "aaaa")
  # =>
  @[]

  (peg/match ''(to -1) "aaaa")
  # =>
  @["aaaa"]

  (peg/match '(to "b") "aaaa")
  # =>
  nil

  )

  `````
)

(def data/uint-be
  `````
(import ../margaret/meg :as peg)

# `(uint-be n ?tag)`

# Captures `n` bytes interpreted as a big endian unsigned integer.

(comment

  (peg/match ~(uint-be 1) "a")
  # =>
  @[97]

  (peg/match '(uint-be 1) "\xFF")
  # =>
  @[255]

  (peg/match '(uint-be 2)
             "\x7f\xff")
  # =>
  @[0x7fff]

  (peg/match ~(uint-be 8) "abcdefgh")
  # =>
  @[(int/u64 "7017280452245743464")]

  (peg/match ~(sequence (uint-be 2 :a)
                        (backref :a))
             "ab")
  # =>
  @[24930 24930]

  )

  `````
)

(def data/uint
  `````
(import ../margaret/meg :as peg)

# `(uint n ?tag)`

# Captures `n` bytes interpreted as a little endian unsigned integer.

(comment

  (peg/match ~(uint 1) "a")
  # =>
  @[97]

  (peg/match '(uint 1) "\xFF")
  # =>
  @[255]

  (peg/match '(uint 2)
             "\xff\x7f")
  # =>
  @[0x7fff]

  (peg/match '(uint 8)
             "\xff\x7f\x00\x00\x00\x00\x00\x00")
  # =>
  @[(int/u64 0x7fff)]

  (peg/match '(uint 7)
             "\xff\x7f\x00\x00\x00\x00\x00")
  # =>
  @[(int/u64 0x7fff)]

  (peg/match ~(uint 8) "abcdefgh")
  # =>
  @[(int/u64 "7523094288207667809")]

  (peg/match ~(sequence (uint 2 :a)
                        (backref :a))
             "ab")
  # =>
  @[25185 25185]

  )

  `````
)

(def data/unref
  `````
(import ../margaret/meg :as peg)

# `(unref rule ?tag)`

# The `unref` combinator lets a user "scope" tagged captures.

# After the rule has matched, all captures with `tag` can no longer be
# referred to by their tag. However, such captures from outside the
# rule are kept as is.

# If no tag is given, all tagged captures from rule are
# unreferenced.

# Note that this doesn't `drop` the captures, merely removes their
# association with the tag. This means subsequent calls to `backref`
# and `backmatch` will no longer "see" these tagged captures.

(comment

  # try removing the unref to see what happens
  (peg/match ~{:main (sequence :thing -1)
               :thing (choice (unref (sequence :open :thing :close))
                              (capture (any (if-not "[" 1))))
               :open (capture (sequence "[" (some "_") "]")
                              :delim)
               :close (capture (backmatch :delim))}
             "[__][_]a[_][__]")
  # =>
  @["[__]" "[_]" "a" "[_]" "[__]"]

  )

(comment

  (def grammar
    ~{:main (sequence :tagged -1)
      :tagged (unref (replace (sequence :open-tag :value :close-tag)
                              ,struct))
      :open-tag (sequence (constant :tag)
                          "<"
                          (capture :w+ :tag-name)
                          ">")
      :value (sequence (constant :value)
                       (group (any (choice :tagged :untagged))))
      :close-tag (sequence "</"
                           (backmatch :tag-name)
                           ">")
      :untagged (capture (any (if-not "<" 1)))})

  (peg/match grammar "<p>Hello</p>")
  # =>
  @[{:tag "p"
     :value @["Hello"]}]

  (peg/match grammar "<p><p>Hello</p></p>")
  # =>
  @[{:tag "p"
     :value @[{:tag "p"
               :value @["Hello"]}]}]

  (peg/match grammar "<p><em>Hello</em></p>")
  # =>
  @[{:tag "p"
     :value @[{:tag "em"
               :value @["Hello"]}]}]

  )

  `````
)

