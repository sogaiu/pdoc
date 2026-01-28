(import ./argv :as av)
(import ./completion :as compl)
(import ./data :as data)
(import ./examples :as ex)
(import ./random :as rnd)
(import ./show :as s)
(import ./view :as view)

(def version "DEVEL")

(def usage
  ``
  Usage: pdoc [option] [peg-special]

  View Janet PEG information.

    -h, --help                   show this output

    -d, --doc [<peg-special>]    show doc
    -q, --quiz [<peg-special>]   show quiz question
    -u, --usage [<peg-special>]  show usage

    --bash-completion            output bash-completion bits
    --fish-completion            output fish-completion bits
    --zsh-completion             output zsh-completion bits
    --raw-all                    show all names for completion

  With a peg-special, but no options, show docs and usages.

  If any of "boolean", "dictionary", "integer", "string",
  "struct", or "table" are specified as the "peg-special",
  show docs and usages about using those as PEG constructs.

  With the `-d` or `--doc` option, show docs for specified
  PEG special, or if none specified, for a randomly chosen one.

  With the `-q` or `--quiz` option, show quiz question for
  specified PEG special, or if none specified, for a randomly
  chosen one.

  With the `-u` or `--usage` option, show usages for
  specified PEG special, or if none specified, for a randomly
  chosen one.

  With no arguments, lists all PEG specials.

  Be careful to quote shortnames (e.g. *, ->, >, <-, etc.)
  appropriately so the shell doesn't process them in an
  undesired fashion.
  ``)

(defn main
  [& argv]
  (setdyn :pdoc-rng
          (math/rng (os/cryptorand 8)))

  (view/configure)

  (def [opts rest errs]
    (av/parse-argv argv))

  (when (not (empty? errs))
    (each err errs
      (eprint "pdoc: " err))
    (eprint "Try 'pdoc -h' for usage text.")
    (os/exit 1))

  # usage
  (when (opts :help)
    (print usage)
    (os/exit 0))

  # possibly handle dumping completion bits
  (when (compl/maybe-handle-dump-completion opts)
    (os/exit 0))

  # help completion by showing a raw list of relevant names
  (when (opts :raw-all)
    (s/all-names data/names)
    (os/exit 0))

  # check if there was a peg special specified
  (def special (ex/get-special (first rest)))

  # if no peg-special found and no options, show info about all specials
  (when (and (nil? special)
             (nil? (opts :doc))
             (nil? (opts :usage))
             (nil? (opts :quiz)))
    (print ex/summary)
    (os/exit 0))

  # ensure a special-name beyond this form by choosing one if needed
  (default special (rnd/choose data/names))

  # show docs, usages, and/or quizzes for a special-fname
  (def content (ex/get-content special))

  (when (or (and (opts :doc) (opts :usage))
            (and (nil? (opts :doc))
                 (nil? (opts :usage))
                 (nil? (opts :quiz))))
    (s/special-doc content)
    ((dyn :pdoc-hl-prin) (string/repeat "#" (dyn :pdoc-width))
                         (dyn :pdoc-separator-color))
    (print)
    (s/special-usages content)
    (os/exit 0))

  (when (opts :doc)
    (s/special-doc content))

  (cond
    (opts :usage)
    (s/special-usages content)
    #
    (opts :quiz)
    (s/special-quiz content)))

