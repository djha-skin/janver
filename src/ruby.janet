# RubyGems Gem::Version ordering.

(use judge)

(import ./utils :as utils)

# RubyGems-compatible versions

(def version
  `
  Parse a RubyGems Gem::Version string into tagged numeric and text segments.

  Leading and trailing whitespace is accepted, as is an empty version (which
  becomes zero). Hyphens are represented as the prerelease marker "pre".
  `
  (peg/compile
    ~{:digit (range "09")
      :letter (choice (range "AZ") (range "az"))
      :number (replace (capture (some :digit)) ,|(do [:number $]))
      :text (replace (capture (some :letter)) ,|(do [:string $]))
      :pre (replace "-" ,|(do [:string "pre"]))
      :part (some (choice :number :text))
      :suffix-part (some (choice :number :text :pre))
      :space (choice " " "\t" "\n" "\v" "\f" "\r")
      :version (sequence
                 :number
                 (any (sequence "." :part))
                 (at-most 1
                   (sequence
                     :pre
                     :suffix-part
                     (any (sequence "." :suffix-part)))))
      :blank (replace "" ,|(do [:number "0"]))
      :main (sequence
              (any :space)
              (choice :version :blank)
              (any :space)
              -1)}))

(deftest version
  (test (peg/match version "1.2.3")
        @[[:number "1"] [:number "2"] [:number "3"]])
  (test (peg/match version " 1.2-rc1 ")
        @[[:number "1"] [:number "2"] [:string "pre"]
          [:string "rc"] [:number "1"]])
  (test (peg/match version "") @[[:number "0"]])
  (test (peg/match version "   \t\n") @[[:number "0"]])
  (test (peg/match version "1.0a10")
        @[[:number "1"] [:number "0"] [:string "a"] [:number "10"]])
  (test (peg/match version "1.0-rc-1")
        @[[:number "1"] [:number "0"] [:string "pre"] [:string "rc"]
          [:string "pre"] [:number "1"]])
  (test (peg/match version "1.0.0.a")
        @[[:number "1"] [:number "0"] [:number "0"] [:string "a"]])
  (test (peg/match version "1..2") nil)
  (test (peg/match version ".1") nil)
  (test (peg/match version "1.") nil)
  (test (peg/match version "1-") nil)
  (test (peg/match version "1a") nil)
  (test (peg/match version "1.é") nil))

(defn- ruby-canonical [segments]
  (var end (length segments))
  (while (and (> end 1)
              (= (get (get segments (- end 1)) 0) :number)
              (= (string/triml (get (get segments (- end 1)) 1) "0") ""))
    (-- end))
  (var result (slice segments 0 end))
  (var first-string nil)
  (for i 0 (length result)
    (when (= (get (get result i) 0) :string)
      (set first-string i)
      (break)))
  (when first-string
    (var remove-at first-string)
    (while (and (> remove-at 0)
                (= (get (get result (- remove-at 1)) 0) :number)
                (= (string/triml (get (get result (- remove-at 1)) 1) "0") ""))
      (-- remove-at))
    (when (< remove-at first-string)
      (set result (array/concat (array/slice result 0 remove-at)
                                (array/slice result first-string)))))
  result)

(defn- ruby-zero? [segment]
  (and (= (get segment 0) :number)
       (= (string/triml (get segment 1) "0") "")))

(defn- ruby-segment-compare [a b]
  (match [a b]
    [[:string _] [:number _]] -1
    [[:number _] [:string _]] 1
    [[:number a] [:number b]] (utils/numbers-compare a b)
    [[:string a] [:string b]] (cond (< a b) -1 (> a b) 1 0)))

(defn vercmp
  `
  (vercmp a b)

  Compare RubyGems Gem::Version strings. Numeric segments are compared by
  their decimal values, strings sort before numbers, prerelease strings sort
  before release numbers, and insignificant trailing zero segments compare
  equal. Invalid version strings raise an error.
  `
  [a b]
  (let [parsed-a (peg/match version a)
        parsed-b (peg/match version b)]
    (unless (and parsed-a parsed-b)
      (error "Malformed RubyGems version"))
    (let [a (ruby-canonical parsed-a)
          b (ruby-canonical parsed-b)
          limit (min (length a) (length b))]
      (label compare
        (for i 0 limit
          (let [result (ruby-segment-compare (get a i) (get b i))]
            (when (not= result 0)
              (return compare result))))
        (if (= (length a) (length b))
          0
          (if (< (length a) (length b))
            (label tail
              (for i limit (length b)
                (let [segment (get b i)]
                  (when (= (get segment 0) :string)
                    (return tail 1))
                  (when (not (ruby-zero? segment))
                    (return tail -1))))
              0)
            (label tail
              (for i limit (length a)
                (let [segment (get a i)]
                  (when (= (get segment 0) :string)
                    (return tail -1))
                  (when (not (ruby-zero? segment))
                    (return tail 1))))
              0)))))))

(deftest vercmp
  (test (vercmp "" "0") 0)
  (test (vercmp " 1.0 " "1") 0)
  (test (vercmp "1.0" "1.0.0") 0)
  (test (vercmp "1.0.0.a" "1.0.a") 0)
  (test (< (vercmp "1.0.a9" "1.0.a10") 0) true)
  (test (< (vercmp "1.0.a1" "1.0") 0) true)
  (test (< (vercmp "1.0.a2" "1.0.b1") 0) true)
  (test (= (vercmp "1.0-rc1" "1.0.pre.rc1") 0) true)
  (test (> (vercmp "1.0" "1.0-rc1") 0) true)
  (test (< (vercmp "1.0.0.1" "1.0") 0) true)
  (test (= (vercmp "1" "1.0.0.0") 0) true)
  (test (> (vercmp "1.0.0.0" "1") 0) true)
  (test (vercmp "1.0000000000000000000000000000001"
                     "1.1") -1)
  (test (vercmp "1.0.a" "1.0.0.a") 0))
