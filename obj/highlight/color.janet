(def color/red
  :red)

(def color/yellow
  :yellow)

(def color/green
  :green)

(def color/blue
  :blue)

(def color/cyan
  :cyan)

(def color/magenta
  :magenta)

(def color/white
  :white)

(def color/black
  :black)

(def color/none
  nil)

(defn color/color-str
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

(defn color/color-prin
  [msg color]
  (prin (color/color-str msg color)))

(def color/color-separator-color
  color/blue)

