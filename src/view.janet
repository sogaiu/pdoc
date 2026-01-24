(import ./highlight :as hl)
(import ./termsize :as t)

(defn configure
  []
  # width
  (def cols
    (if-let [cols (t/cols)]
      cols
      80))
  (setdyn :pdoc-width cols)
  # color
  (let [color-level (os/getenv "PDOC_COLOR")
        # XXX: tput colors more portable?
        color-term (os/getenv "COLORTERM")]
    # XXX: not ready for prime time, so insist PDOC_COLOR is
    #      set for anything to happen
    (if color-level
      (cond
        (or (= "rgb" color-level)
            #(= "truecolor" color-term)
            false)
        (do
          (setdyn :pdoc-hl-prin hl/rgb/rgb-prin)
          (setdyn :pdoc-hl-str hl/rgb/rgb-str)
          (setdyn :pdoc-separator-color hl/rgb/rgb-separator-color)
          (setdyn :pdoc-theme hl/rgb-theme))
        #
        (or (= "color" color-level)
            (= "16" color-term))
        (do
          (setdyn :pdoc-hl-prin hl/color/color-prin)
          (setdyn :pdoc-hl-str hl/color/color-str)
          (setdyn :pdoc-separator-color hl/color/color-separator-color)
          (setdyn :pdoc-theme hl/color-theme))
        #
        (do
          (setdyn :pdoc-hl-prin hl/m/mono-prin)
          (setdyn :pdoc-hl-str hl/m/mono-str)
          (setdyn :pdoc-separator-color hl/m/mono-separator-color)
          (setdyn :pdoc-theme hl/mono-theme)))
      # no color
      (do
        (setdyn :pdoc-hl-prin hl/m/mono-prin)
        (setdyn :pdoc-hl-str hl/m/mono-str)
        (setdyn :pdoc-separator-color hl/m/mono-separator-color)
        (setdyn :pdoc-theme hl/mono-theme)))))

