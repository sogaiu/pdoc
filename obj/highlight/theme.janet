(import ./color :prefix "")
(import ./mono :prefix "")
(import ./rgb :prefix "")

(defn th/rgb-theme
  [node-type]
  (cond
    (= :constant node-type)
    rgb/magenta
    #
    (= :symbol node-type)
    rgb/chartreuse
    #
    (= :keyword node-type)
    rgb/magenta
    #
    (= :string node-type)
    rgb/yellow
    #
    (= :number node-type)
    rgb/cyan
    #
    rgb/none))

(defn th/color-theme
  [node-type]
  (cond
    (= :constant node-type)
    color/magenta
    #
    (= :symbol node-type)
    color/green
    #
    (= :keyword node-type)
    color/magenta
    #
    (= :string node-type)
    color/yellow
    #
    (= :number node-type)
    color/cyan
    #
    color/none))

(defn th/mono-theme
  [_]
  m/none)

