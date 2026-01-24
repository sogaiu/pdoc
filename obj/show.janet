(import ./doc :prefix "")

# XXX: not sure if this quoting will work on windows...
(defn s/escape
  [a-str]
  (string "\""
          a-str
          "\""))

(defn s/all-names
  [names]
  # print all names
  (each name (sort names)
    # XXX: anything missing?
    # XXX: anything platform-specific?
    (if (get {"*" true
              "->" true
              ">" true
              "<-" true}
             name)
      (print (s/escape name))
      (print name))))

(defn s/normal-doc
  [content]
  '(each line (doc/normal-doc content)
    (print line))
  (print (doc/normal-doc content)))

(defn s/special-doc
  [content &opt width indent]
  (print (doc/special-doc content width indent)))

########################################################################

(import ./highlight :prefix "")
(import ./indent :prefix "")
(import ./parse :prefix "")
(import ./random :prefix "")

(defn s/print-nicely
  [expr-str]
  (let [buf (hl/colorize (indent/format expr-str))]
    (each line (string/split "\n" buf)
      (print line))))

(defn s/print-separator
  []
  ((dyn :pdoc-hl-prin) (string/repeat "#" (dyn :pdoc-width))
                       (dyn :pdoc-separator-color)))

(defn s/handle-eval-failure
  [resp e]
  (print "Sorry, failed to evaluate your answer.")
  (print)
  (print "The error I got was:")
  (print)
  (printf "%p" e)
  (print)
  (print "I tried to evaluate the following:")
  (print)
  (print resp))

(defn s/handle-plain-response
  [ans resp]
  (print)
  (print "My answer is:")
  (print)
  (s/print-nicely ans)
  (print)
  (print "Your answer is:")
  (print)
  (s/print-nicely resp)
  (print)
  (when (deep= ans resp)
    (print "Yay, our answers agree :)")
    (break true))
  (print "Our answers differ, but perhaps yours works too.")
  (print)
  (try
    (let [result (eval-string resp)
          evaled-ans (eval-string ans)]
      (if (deep= result evaled-ans)
        (do
          (printf "Nice, our answers both evaluate to: %M"
                  evaled-ans)
          true)
        (do
          (printf "Sorry, your answer evaluates to: %M" result)
          false)))
    ([e]
      (s/handle-eval-failure resp e)
      false)))

(defn s/handle-want-to-quit
  [buf]
  (when (empty? (string/trim buf))
    (print "Had enough?  Perhaps on another occasion then.")
    #
    true))

(defn s/validate-response
  [buf]
  (try
    (do
      (parse buf)
      (string/trim buf))
    ([e]
      (print)
      (printf "Sorry, I didn't understand your response: %s"
              (string/trim buf))
      (print)
      (print "I got the following error:")
      (print)
      (printf "%p" e)
      nil)))

(defn s/special-plain-quiz
  [content]
  # extract first set of tests from content
  (def tests
    (p/extract-first-test-set content))
  (when (empty? tests)
    (print "Sorry, didn't find any material to make a quiz from.")
    (break nil))
  # choose a question and answer pair
  (let [[ques ans] (rnd/choose tests)
        trimmed-ans (string/trim ans)]
    # show the question
    (s/print-nicely ques)
    (print "# =>")
    # ask for an answer
    (def buf
      (getline ""))
    (when (s/handle-want-to-quit buf)
      (break nil))
    # does the response make some sense?
    (def resp
      (s/validate-response buf))
    (unless resp
      (break nil))
    # improve perceptibility
    (print)
    (s/print-separator)
    (print)
    #
    (s/handle-plain-response trimmed-ans resp)))

(defn s/handle-fill-in-response
  [ques blank-ques blanked-item ans resp]
  (print)
  (print "One complete picture is: ")
  (print)
  (s/print-nicely ques)
  (print "# =>")
  (s/print-nicely ans)
  (print)
  (print "So one value that works is:")
  (print)
  (s/print-nicely blanked-item)
  (print)
  (print "Your answer is:")
  (print)
  (s/print-nicely resp)
  (print)
  (when (deep= blanked-item resp)
    (print "Yay, the answers agree :)")
    (break true))
  (print "Our answers differ, but perhaps yours works too.")
  (print)
  (let [indeces (string/find-all "_" blank-ques)
        head-idx (first indeces)
        tail-idx (last indeces)]
    # XXX: cheap method -- more accurate would be to use zippers
    (def resp-code
      (string (string/slice blank-ques 0 head-idx)
              resp
              (string/slice blank-ques (inc tail-idx))))
    (try
      (let [result (eval-string resp-code)
            evaled-ans (eval-string ans)]
        (if (deep= result evaled-ans)
          (do
            (printf "Nice, our answers both evaluate to: %M"
                    evaled-ans)
            true)
          (do
            (printf "Sorry, our answers evaluate differently.")
            (print)
            (printf "My answer evaluates to: %M" result)
            (print)
            (printf "Your answer evaluates to: %M" evaled-ans)
            false)))
      ([e]
        (s/handle-eval-failure resp-code e)
        false))))

(defn s/special-fill-in-quiz
  [content]
  # extract first set of tests from content
  (def test-zloc-pairs
    (p/extract-first-test-set-zlocs content))
  (when (empty? test-zloc-pairs)
    (print "Sorry, didn't find any material to make a quiz from.")
    (break nil))
  # choose a question and answer, then make a blanked question
  (let [[ques-zloc ans-zloc] (rnd/choose test-zloc-pairs)
        [blank-ques-zloc blanked-item] (p/rewrite-test-zloc ques-zloc)]
    # XXX: a cheap work-around...evidence of a deeper issue?
    (unless blank-ques-zloc
      (print "Sorry, drew a blank...take a deep breath and try again?")
      (break nil))
    (let [ques (p/indent-node-gen ques-zloc)
          blank-ques (p/indent-node-gen blank-ques-zloc)
          trimmed-ans (string/trim (p/indent-node-gen ans-zloc))]
      # show the question
      (s/print-nicely blank-ques)
      (print "# =>")
      (s/print-nicely trimmed-ans)
      (print)
      # ask for an answer
      (def buf
        (getline "What value could work in the blank? "))
      (when (s/handle-want-to-quit buf)
        (break nil))
      # does the response make some sense?
      (def resp
        (s/validate-response buf))
      (unless resp
        (break nil))
      # improve perceptibility
      (print)
      (s/print-separator)
      (print)
      #
      (s/handle-fill-in-response ques blank-ques blanked-item
                               trimmed-ans resp))))

(defn s/special-quiz
  [content]
  (def quiz-fn
    (rnd/choose [s/special-plain-quiz
                 s/special-fill-in-quiz]))
  (quiz-fn content))

########################################################################

# assumes example file has certain structure
(defn s/massage-lines-for-examples
  [lines]
  (def n-lines (length lines))
  (def m-lines @[])
  (var i 0)
  # skip first line if import
  (when (peg/match ~(sequence "(import")
                   (first lines))
    (++ i))
  # get "inside" comment form
  (while (< i n-lines)
    (def cur-line (get lines i))
    # whether loop ends or not, index increases
    (++ i)
    # stop at first (comment ...) form
    (when (peg/match ~(sequence "(comment")
                     cur-line)
      (break)))
  # save lines until (comment ...) ends
  (while (< i n-lines)
    (def cur-line (get lines i))
    # supposedly where the "(comment ...)" form ends -- hacky
    (if (peg/match ~(sequence (any (set " \t\f\v"))
                              ")")
                   cur-line)
      (break)
      (if (string/has-prefix? "  " cur-line)
        (array/push m-lines (string/slice cur-line 2))
        (array/push m-lines cur-line)))
    (++ i))
  #
  m-lines)

(defn s/special-usages
  [content]
  (def lines
    (string/split "\n" content))
  (def examples-lines
    (s/massage-lines-for-examples lines))
  (-> (string/join examples-lines "\n")
      hl/colorize
      print))

