(def m/none
  [nil])

(defn m/mono-str
  [text _ignored]
  text)

(defn m/mono-prin
  [msg _color]
  (prin msg))

(def m/mono-separator-color
  m/none)

