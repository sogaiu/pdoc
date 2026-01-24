(def compl/bash-completion
  ``
  _pdoc_specials() {
      COMPREPLY=( $(compgen -W "$(pdoc --raw-all)" -- ${COMP_WORDS[COMP_CWORD]}) );
  }
  complete -F _pdoc_specials pdoc
  ``)

(def compl/fish-completion
  ``
  function __pdoc_complete_specials
    if not test "$__pdoc_specials"
      set -g __pdoc_specials (pdoc --raw-all)
    end

    printf "%s\n" $__pdoc_specials
  end

  complete -c pdoc -a "(__pdoc_complete_specials)" -d 'specials'
  ``)

(def compl/zsh-completion
  ``
  #compdef pdoc

  _pdoc() {
      local matches=(`pdoc --raw-all`)
      compadd -a matches
  }
  
  _pdoc "$@"
  ``)

(defn compl/maybe-handle-dump-completion
  [opts]
  # this makes use of the fact that print returns nil
  (not
    (cond
      (opts :bash-completion)
      (print compl/bash-completion)
      #
      (opts :fish-completion)
      (print compl/fish-completion)
      #
      (opts :zsh-completion)
      (print compl/zsh-completion)
      #
      true)))

