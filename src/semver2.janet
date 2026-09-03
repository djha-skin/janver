# Semantic Versioning 2.0.0 ordering.

(use judge)

(import ./utils :as utils)

(def version
  `
  Parse a Semantic Versioning 2.0.0 version into its core, pre-release, and
  build metadata parts.
  `
  (peg/compile
    ~{:letter (choice (range "AZ") (range "az"))
      :positive-digit (range "19")
      :digit (range "09")
      :digits (some :digit)
      :non-digit (choice :letter "-")
      :identifier-character (choice :digit :non-digit)
      :numeric (choice "0" (sequence :positive-digit (any :digit)))
      :alphanumeric (sequence (any :digit) :non-digit
                              (any :identifier-character))
      :build-identifier (capture (choice :alphanumeric (any :digit)))
      :pri (choice
             (replace
               (capture :alphanumeric)
               ,|(do [:alphanumeric $]))
             (replace
               (capture :numeric)
               ,|(do [:numeric $])))
      :build (sequence :build-identifier (any (sequence "." :build-identifier)))
      :pre-release (sequence :pri (any (sequence "." :pri)))
      :patch (capture :numeric)
      :minor (capture :numeric)
      :major (capture :numeric)
      :core (group (sequence :major "." :minor "." :patch))
      :semver (sequence
                :core
                (group (at-most 1 (sequence "-" :pre-release)))
                (group (at-most 1 (sequence "+" :build))))
      :main :semver}))

(deftest version
  (test (peg/match version "1.2.3") @[@["1" "2" "3"] @[] @[]])
  (test (peg/match version "1.0.0-alpha")
        @[@["1" "0" "0"]
          @[[:alphanumeric "alpha"]]
          @[]])
  (test (peg/match version "1.0.0-alpha.1")
        @[@["1" "0" "0"]
          @[[:alphanumeric "alpha"]
            [:numeric "1"]]
          @[]])
  (test (peg/match version "1.0.0-0.3.7")
        @[@["1" "0" "0"]
          @[[:numeric "0"]
            [:numeric "3"]
            [:numeric "7"]]
          @[]])
  (test (peg/match version "1.0.0-x.7.z.92")
        @[@["1" "0" "0"]
          @[[:alphanumeric "x"]
            [:numeric "7"]
            [:alphanumeric "z"]
            [:numeric "92"]]
          @[]])
  (test (peg/match version "1.0.0-x-y-z.--.")
        @[@["1" "0" "0"]
          @[[:alphanumeric "x-y-z"]
            [:alphanumeric "--"]]
          @[]])
  (test (peg/match version "1.0.0-alpha+001")
        @[@["1" "0" "0"]
          @[[:alphanumeric "alpha"]]
          @["001"]])
  (test (peg/match version "1.0.0+20130313144700")
        @[@["1" "0" "0"]
          @[]
          @["20130313144700"]])
  (test (peg/match version "1.0.0-beta+exp.sha.5114f85")
        @[@["1" "0" "0"]
          @[[:alphanumeric "beta"]]
          @["exp" "sha" "5114f85"]])
  (test (peg/match version "1.0.0+21AF26D3----117B344092BD")
        @[@["1" "0" "0"]
          @[]
          @["21AF26D3----117B344092BD"]])
  (test (peg/match version "1234567890.98765.0-alpha.1+a-b-c.d-e-f.15")
        @[@["1234567890" "98765" "0"]
          @[[:alphanumeric "alpha"]
            [:numeric "1"]]
          @["a-b-c" "d-e-f" "15"]]))

(defn vercmp
  `
  (vercmp a b)

  Compare two version numbers according to the rules found at
  https://semver.org/#semantic-versioning-200 .
  `
  [a b]
  (let [[[major-a minor-a patch-a] prerelease-a build-a] (peg/match version a)
        [[major-b minor-b patch-b] prerelease-b build-b] (peg/match version b)]
    (label top
      (let [major-cmp (utils/numbers-compare major-a major-b)]
        (when (not= major-cmp 0)
          (return top major-cmp)))
      (let [minor-cmp (utils/numbers-compare minor-a minor-b)]
        (when (not= minor-cmp 0)
          (return top minor-cmp)))
      (let [patch-cmp (utils/numbers-compare patch-a patch-b)]
        (when (not= patch-cmp 0)
          (return top patch-cmp)))
      (let [la (length prerelease-a)
            lb (length prerelease-b)
            minl (min la lb)]
        (cond
          (and (= la 0) (= lb 0)) (return top 0)
          (= la 0) (return top 1)
          (= lb 0) (return top -1))
        (for i 0 minl
          (let [result-of-part
                (label prerelease-part
                  (match [(get prerelease-a i)
                          (get prerelease-b i)]
                    [[:numeric a-part]
                     [:numeric b-part]]
                    (return
                      prerelease-part
                      (utils/numbers-compare a-part b-part))
                    [[:alphanumeric a-part]
                     [:alphanumeric b-part]]
                    (return
                      prerelease-part
                      (cond
                        (< a-part b-part) -1
                        (< b-part a-part) 1
                        0))
                    [[:numeric a-part]
                     [:alphanumeric b-part]] -1
                    [[:alphanumeric a-part]
                     [:numeric b-part]] 1))]
            (when (not= result-of-part 0)
              (return top result-of-part))))
        (cond
          (> la minl) 1
          (> lb minl) -1
          0)))))

(deftest vercmp
  (test (vercmp "1.9.0" "1.10.0") -1)
  (test (vercmp "1.10.0" "1.11.0") -1)
  (test (vercmp "1.0.0" "2.0.0") -1)
  (test (vercmp "2.0.0" "2.1.0") -1)
  (test (vercmp "2.1.0" "2.1.1") -1)
  (test (vercmp "1.0.0-alpha" "1.0.0") -1)
  (test (vercmp "1.0.0-alpha" "1.0.0-alpha.1") -1)
  (test (vercmp "1.0.0-alpha.1" "1.0.0-alpha.beta") -1)
  (test (vercmp "1.0.0-alpha.beta" "1.0.0-alpha.1") 1)
  (test (vercmp "1.0.0-alpha.beta" "1.0.0-alpha.beta") 0)
  (test (vercmp "1.0.0-alpha.beta" "1.0.0-beta") -1)
  (test (vercmp "1.0.0-beta" "1.0.0-alpha.beta") 1)
  (test (vercmp "1.0.0-beta.2" "1.0.0-beta") 1)
  (test (vercmp "1.0.0-beta.2" "1.0.0-beta.11") -1)
  (test (vercmp "1.0.0-beta.11" "1.0.0-rc.1") -1)
  (test (vercmp "1.0.0-rc.1" "1.0.0") -1))

