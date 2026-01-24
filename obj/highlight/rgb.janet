# color names (except "none") from M-x list-colors-display

(def rgb/red
  [0xff 0x00 0x00])

(def rgb/dark-orange
  [0xff 0x8c 0x00])

(def rgb/yellow
  [0xff 0xff 0x00])

(def rgb/chartreuse
  [0x7f 0xff 0x00])

(def rgb/cyan
  [0x00 0xff 0xff])

(def rgb/blue
  [0x00 0x00 0xff])

(def rgb/purple
  [0xa0 0x20 0xf0])

(def rgb/magenta
  [0xff 0x00 0xff])

(def rgb/white
  [0xff 0xff 0xff])

(def rgb/none
  [nil nil nil])

(defn rgb/rgb-str
  [text [r g b]]
  (if (nil? r)
    text
    # https://en.wikipedia.org/wiki/ANSI_escape_code#24-bit
    # ESC[38;2;⟨r⟩;⟨g⟩;⟨b⟩ m Select RGB foreground color     # ] <- hack
    (string "\e[38;2;" r ";" g ";" b "m"
            text
            "\e[0m")))

(defn rgb/rgb-prin
  [msg [r g b]]
  (prin (rgb/rgb-str msg [r g b])))

(def rgb/rgb-separator-color
  rgb/blue)

