# Maven ComparableVersion ordering.

(use judge)

(import ./utils :as utils)

(def version
  `
  Parse a Maven ComparableVersion string into lexical tokens.

  Tokens are tagged as :number, :text, or :separator. The parser keeps ASCII
  digit runs separate from text and preserves dots and hyphens for the nested
  Maven item builder.
  `
  (peg/compile
    ~{:digit (range "09")
      :text-char (choice (range "\x00\x2C")
                         (range "\x2E\x2F")
                         (range "\x3A\xFF"))
      :digits (capture (some :digit))
      :text (capture (some :text-char))
      :separator (capture (choice "." "-"))
      :token (choice
               (replace :separator ,|(do [:separator $]))
               (replace :digits ,|(do [:number $]))
               (replace :text ,|(do [:text $])))
      :main (some :token)}))

(defn- maven-number [digits]
  [:number digits])

(defn- maven-string [value]
  [:string (string/ascii-lower value)])

(defn- maven-combination [text digits]
  (let [text (string/ascii-lower text)
        text (cond (= text "a") "alpha"
                   (= text "b") "beta"
                   (= text "m") "milestone"
                   text)]
    [:combination text digits]))

(defn- maven-list [items]
  [:list items])

(defn- maven-merge-number-text [items]
  (if (and (>= (length items) 2)
           (= (first (get items (- (length items) 2))) :number)
           (= (first (last items)) :string))
    (let [text-node (array/pop items)
          number-node (array/pop items)]
      (array/push items (maven-list @[number-node text-node])))
    items))

(defn- maven-token-tree [tokens]
  (defn parse-list [start stop-at-hyphen]
    (def items @[])
    (var i start)
    (var stopped false)
    (while (and (< i (length tokens)) (not stopped))
      (let [token (get tokens i)]
        (match token
          [:separator "."] nil
          [:separator "-"]
          (if (and (not (empty? items))
                   (= (first (last items)) :string)
                   (< (+ i 1) (length tokens))
                   (= (first (get tokens (+ i 1))) :number))
            (do
              (++ i)
              (let [digits (get (get tokens i) 1)
                    text-node (array/pop items)]
                (array/push items
                            (maven-combination (text-node 1) digits)))
              (++ i))
            (if stop-at-hyphen
              (set stopped true)
              (do
                (++ i)
                (let [[child end] (parse-list i true)]
                  (array/push items (maven-list child))
                  (set i end)))))
          [:number digits]
          (if (and (not (empty? items))
                   (= (first (last items)) :string))
            (let [text-node (array/pop items)]
              (array/push items
                          (maven-combination (text-node 1) digits)))
            (array/push items (maven-number digits)))
          [:text text]
          (array/push items (maven-string text))))
      (unless stopped (++ i)))
    [items i])
  (maven-list (maven-merge-number-text (first (parse-list 0 false)))))

(def- maven-qualifiers
  @["alpha" "beta" "milestone" "rc" "snapshot" "" "sp"])

(def- maven-release-qualifiers
  @{"ga" true "final" true "release" true})

(defn- maven-qualifier [value]
  (let [value (if (= value "cr") "rc" value)]
    (if (in maven-release-qualifiers value)
      ""
      value)))

(defn- maven-qualifier-rank [value]
  (let [value (maven-qualifier value)]
    (var rank (+ (length maven-qualifiers) 1))
    (for i 0 (length maven-qualifiers)
      (when (= value (get maven-qualifiers i))
        (set rank i)))
    rank))

(defn- maven-string-compare [a b]
  (let [a (maven-qualifier a)
        b (maven-qualifier b)
        rank-a (maven-qualifier-rank a)
        rank-b (maven-qualifier-rank b)]
    (if (not= rank-a rank-b)
      (- rank-a rank-b)
      (cond (< a b) -1
            (> a b) 1
            0))))

(defn- maven-item-null-compare [item]
  (match item
    [:number digits]
    (if (= (string/triml digits "0") "") 0 1)
    [:string value]
    (- (maven-qualifier-rank value) 5)
    [:combination text digits]
    (maven-item-null-compare [:string text])
    [:list items]
    (label compare-null-list
      (var result 0)
      (each child items
        (let [child-result (maven-item-null-compare child)]
          (when (not= child-result 0)
            (set result child-result)
            (break))))
      result)))

(defn- maven-item-compare [a b]
  (match [a b]
    [nil nil] 0
    [nil item] (- (maven-item-null-compare item))
    [item nil] (maven-item-null-compare item)
    [[:number a] [:number b]] (utils/numbers-compare a b)
    [[:number _] [:string _]] 1
    [[:number _] [:combination _ _]] 1
    [[:number _] [:list _]] 1
    [[:string a] [:number _]] -1
    [[:string a] [:string b]] (maven-string-compare a b)
    [[:string a] [:combination b digits]]
    (let [result (maven-string-compare a b)]
      (if (= result 0) -1 result))
    [[:string _] [:list _]] -1
    [[:combination a digits-a] [:number _]] -1
    [[:combination a digits-a] [:string b]]
    (let [result (maven-string-compare a b)]
      (if (= result 0) 1 result))
    [[:combination a digits-a] [:combination b digits-b]]
    (let [result (maven-string-compare a b)]
      (if (= result 0)
        (utils/numbers-compare digits-a digits-b)
        result))
    [[:combination _ _] [:list _]] -1
    [[:list _] [:number _]] -1
    [[:list _] [:string _]] 1
    [[:list _] [:combination _ _]] 1
    [[:list a] [:list b]]
    (label compare-lists
      (var i 0)
      (while (or (< i (length a)) (< i (length b)))
        (let [result (if (< i (length a))
                       (maven-item-compare (get a i)
                                           (if (< i (length b))
                                             (get b i)
                                             nil))
                       (- (maven-item-compare (get b i) nil)))]
          (when (not= result 0)
            (return compare-lists result)))
        (++ i))
      0)))

(defn vercmp
  `
  (vercmp a b)

  Compare Maven versions according to Apache Maven ComparableVersion rules.
  `
  [a b]
  (maven-item-compare
    (maven-token-tree (peg/match version a))
    (maven-token-tree (peg/match version b))))

(deftest vercmp
  (test (< (vercmp "1-alpha2snapshot" "1-alpha2") 0) true)
  (test (< (vercmp "1-alpha2" "1-alpha-123") 0) true)
  (test (< (vercmp "1-alpha-123" "1-beta-2") 0) true)
  (test (< (vercmp "1-beta-2" "1-beta123") 0) true)
  (test (< (vercmp "1-beta123" "1-m2") 0) true)
  (test (< (vercmp "1-m2" "1-m11") 0) true)
  (test (< (vercmp "1-m11" "1-rc") 0) true)
  (test (= (vercmp "1-cr2" "1-rc2") 0) true)
  (test (< (vercmp "1-rc" "1-rc123") 0) true)
  (test (< (vercmp "1-rc123" "1-SNAPSHOT") 0) true)
  (test (< (vercmp "1-SNAPSHOT" "1") 0) true)
  (test (< (vercmp "1" "1-sp") 0) true)
  (test (< (vercmp "1-sp" "1-sp2") 0) true)
  (test (< (vercmp "1-sp2" "1-sp123") 0) true)
  (test (< (vercmp "1-sp123" "1-abc") 0) true)
  (test (< (vercmp "1-abc" "1-def") 0) true)
  (test (< (vercmp "1-def" "1-pom-1") 0) true)
  (test (< (vercmp "1-pom-1" "1-1-snapshot") 0) true)
  (test (< (vercmp "1-1-snapshot" "1-1") 0) true)
  (test (< (vercmp "1-1" "1-2") 0) true)
  (test (< (vercmp "1-2" "1-123") 0) true)
  (test (= (vercmp "1" "1.0") 0) true)
  (test (= (vercmp "1" "1-0") 0) true)
  (test (= (vercmp "1a" "1-a") 0) true)
  (test (= (vercmp "1cr" "1rc") 0) true)
  (test (= (vercmp "1a1" "1-alpha-1") 0) true)
  (test (= (vercmp "1b2" "1-beta-2") 0) true)
  (test (= (vercmp "1m3" "1-milestone3") 0) true)
  (test (= (vercmp "1X" "1x") 0) true)
  (test (= (vercmp "1ga" "1") 0) true)
  (test (< (vercmp "1.0-alpha-1" "1.0") 0) true)
  (test (< (vercmp "1.0-SNAPSHOT" "1.0") 0) true)
  (test (< (vercmp "1.0" "1.0-1") 0) true)
  (test (< (vercmp "1.0-1" "1.0-2") 0) true)
  (test (< (vercmp "1.0.0" "1.0-1") 0) true)
  (test (< (vercmp "2.0-1" "2.0.1") 0) true)
  (test (< (vercmp "2.0.1-klm" "2.0.1-lmn") 0) true)
  (test (< (vercmp "2.0.1" "2.0.1-xyz") 0) true)
  (test (< (vercmp "2.0.1-xyz" "2.0.1-123") 0) true)
  (test (< (vercmp "1" "é") 0) true)
  (test (= (vercmp "1-abcdefghijklmnopqrstuvwxyz"
                         "1-ABCDEFGHIJKLMNOPQRSTUVWXYZ") 0) true))

