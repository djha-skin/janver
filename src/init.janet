# src/init.janet
#
# Compare Debian and Semantic Versioning versions.

(use judge)

(def debian-version
  `
  Parse a Debian version into its epoch and alternating non-numeric and
  numeric parts.
  `
  (peg/compile
    ~{:number (range "09")
      :non-number (choice (range "\x00\x2F")
                          (range "\x3A\xFF"))
      :epochless (group (any
                          (sequence
                            (capture
                              (any
                                :non-number))
                            (capture
                              (any
                                :number)))))
      :epoched (accumulate
                 (at-most
                   1
                   (sequence
                     (capture (any
                                (range "09")))
                     ":")))
      :root (sequence :epoched :epochless)
      :main :root}))

# A consequence of the above construction of PEG is that match vectors lengths
# will ALWAYS be even within the epochless subvector.

(deftest debian-version
  (test (peg/match debian-version "33333") @["" @["" "33333"]])
  (test (peg/match debian-version "a3") @["" @["a" "3"]])
  (test (peg/match debian-version "3a") @["" @["" "3" "a" ""]])
  (test (peg/match debian-version ".") @["" @["." ""]])
  (test (peg/match debian-version "1.2.3")
        @["" @["" "1" "." "2" "." "3"]])
  (test (peg/match debian-version "1a2b3c")
        @["" @["" "1" "a" "2" "b" "3" "c" ""]])
  (test (peg/match debian-version "1.2.3~rc1")
        @[""
          @["" "1" "." "2" "." "3" "~rc" "1"]])
  (test (peg/match debian-version "1.2.3~~rc1")
        @[""
          @["" "1" "." "2" "." "3" "~~rc" "1"]])
  (test (peg/match debian-version "1:2.3.4") @["1" @["" "2" "." "3" "." "4"]])
  (test (peg/match debian-version "0:") @["0" @[]])
  (test (peg/match debian-version "") @["" @[]])
  (test (peg/match debian-version "0:1.2") @["0" @["" "1" "." "2"]])
  (test (peg/match debian-version "1.2") @["" @["" "1" "." "2"]])
  (test (peg/match debian-version "1:") @["1" @[]])
  (test (peg/match debian-version "1:1.2.3") @["1" @["" "1" "." "2" "." "3"]])
  (test (peg/match debian-version "2:0.4.5") @["2" @["" "0" "." "4" "." "5"]]))

(defn- numbers-compare [a b]
  `
  Compares two strings as if they are numbers.
  The strings must only contain characters ranging from 0-9 or none at all.
  The empty string is considered as the zero value.
  `
  (let [trimmed-a (string/triml a "0")
        trimmed-b (string/triml b "0")
        la (length trimmed-a)
        lb (length trimmed-b)]
    (if (not= la lb)
      (- la lb)
      (label compare-parts
        (for i 0 la
          (let [diff (- (get trimmed-a i) (get trimmed-b i))]
            (when (not= diff 0)
              (return compare-parts diff))))
        0))))

(deftest numbers-compare
  (test (numbers-compare "" "0") 0)
  (test (numbers-compare "" "") 0)
  (test (numbers-compare "" "7") -1)
  (test (numbers-compare "7" "007") 0)
  (test (numbers-compare "007" "7") 0)
  (test (numbers-compare "0" "1") -1)
  (test (numbers-compare "736" "54") 1))

(defn- debian-compare-transform
  `
  Transforms the numeric value of a byte so that it will conform to the
  comparison rules for characters in a non-digit debian-version part in the
  Deiban
  Policy Manual, section 5.6.12, about the "Version" field.

  Takes a character's numeric value and transforms it so that:

  1. If the number corresponds to a tilde, its negative will be returned
     (-0x7E).
  2. If the number corresponds to an English upper-case value, a new number
     between -0x7A and -0x61 will be returned such that two such transform
     returns a' from a and b' from b will satisfy (< a b) iff (< a b).
  3. If the number corresponds to an English lower-case value, a new number
     between -0x5A and -0x41 will be returned such that two such transform
     returns a' from a and b' from b will satisfy (< a' b') iff (< a b).
  `
  [char]
  (cond (= 0x7E char) (- char)
    (and (>= char 0x41) (<= char 0x5A)) (- char 0x41 0x7A)
    (and (>= char 0x61) (<= char 0x7A)) (- char 0x61 0x5A)
    char))

(deftest debian-compare-transform
  (test (debian-compare-transform (get "~~a" 0)) -126)
  (test (map debian-compare-transform "AaBbCcZz&^%$#@!@")
        @[-122
          -90
          -121
          -89
          -120
          -88
          -97
          -65
          38
          94
          37
          36
          35
          64
          33
          64])
  (test (map debian-compare-transform "~~rc") @[-126 -126 -73 -88])
  (test (map debian-compare-transform "~rc") @[-126 -73 -88]))

(defn- non-numbers-compare [a b]
  `
  Compare non-numerical parts of a debian version number according to the rules
  in the Debian Policy Manual:

  > These two parts (one of which may be empty) are compared lexically. If a
  > difference is found it is returned. The lexical comparison is a comparison
  > of ASCII values modified so that all the letters sort earlier than all the
  > non-letters and so that a tilde sorts before anything, even the end of a
  > part. For example, the following parts are in sorted order from earliest to
  > latest: ~~, ~~a, ~, the empty part, a.
  `
  (let [la (length a)
        lb (length b)
        minl (min la lb)
        parts-check
        (label compare-parts
          (for i 0 minl
            (let [effective-a (debian-compare-transform (get a i))
                  effective-b (debian-compare-transform (get b i))
                  difference (- effective-a effective-b)]
              (if (not= difference 0)
                (return compare-parts difference))))
          0)]
    (if (not= parts-check 0)
      parts-check
      (if (not= la lb)
        (cond (> la lb)
          (if (= (get a minl) 0x7E)
            -1
            1)
          (> lb la)
          (if (= (get b minl) 0x7E)
            1
            -1)
          0)
        0))))

(deftest non-numbers-compare
  (test (non-numbers-compare "" "") 0)
  (test (non-numbers-compare "~~" "~~a") -1)
  (test (non-numbers-compare "~~a" "~") -1)
  (test (non-numbers-compare "~" "") -1)
  (test (non-numbers-compare "" "a") -1)
  (test (non-numbers-compare "-fifty" "fifty") 130)
  (test (non-numbers-compare "fifty" "fifty-") -1)
  (test (non-numbers-compare "~rc" "~~rc") 53))

(defn- justify
  "Ensures both arrays of strings have the same number of elements"
  [a b]
  (let [la (length a)
        lb (length b)]
    (cond (> la lb)
      [a
       (array/concat b (array/new-filled (- la lb) ""))]
      (> lb la)
      [(array/concat a (array/new-filled (- lb la) ""))
       b]
      [a b])))

(deftest justify
  (test (justify @["a" "" "b" "" "c"] @[])
        [@["a" "" "b" "" "c"] @["" "" "" "" ""]])
  (test (justify @[] @[]) [@[] @[]])
  (test (justify @["a" "" "b" "" "c"] @["" "1" "" "2" "" "3"])
        [@["a" "" "b" "" "c" ""]
         @["" "1" "" "2" "" "3"]])
  (test (justify (peg/match debian-version "1.2.3~rc1")
                 (peg/match debian-version "1.2.3~~rc1"))
        [@[""
           @["" "1" "." "2" "." "3" "~rc" "1"]]
         @[""
           @["" "1" "." "2" "." "3" "~~rc" "1"]]]))

(defn debian-vercmp
  `
  (debian-vercmp a b)

  Compares two version numbers according to the rules set forth in the Debian
  Policy Manual.
  `
  [a b]
  (if (= a b) 0
    (let [[a-epoch a-parts] (peg/match debian-version a)
          [b-epoch b-parts] (peg/match debian-version b)
          epoch-cmp (numbers-compare a-epoch b-epoch)]
      (if (not= epoch-cmp 0)
        epoch-cmp
        (let [[just-a just-b] (justify a-parts b-parts)
              la (length just-a)]
          (label compare-parts
            (var i 0)
            (while (< i la)
              (let [first-cmp (non-numbers-compare
                                (get just-a i)
                                (get just-b i))]
                (when (not= first-cmp 0)
                  (return compare-parts first-cmp)))
              (++ i)
              (let [second-cmp (numbers-compare
                                 (get just-a i)
                                 (get just-b i))]
                (when (not= second-cmp 0)
                  (return compare-parts second-cmp)))
              # Due to the nature of the PEG, I can guarantee that there
              # are an even number of matches for both A and B, so I'm
              # allowed to do this.
              (++ i))
            0))))))

(deftest debian-vercmp
  (test (= (debian-vercmp "" "") 0) true)
  (test (< (debian-vercmp "~~" "~~a") 0) true)
  (test (> (debian-vercmp "~" "~~a") 0) true)
  (test (< (debian-vercmp "~" "") 0) true)
  (test (> (debian-vercmp "a" "") 0) true)
  (test (< (debian-vercmp "1.2.3~rc1" "1.2.3") 0) true)
  (test (= (debian-vercmp "1.2" "1.2") 0) true)
  (test (< (debian-vercmp "1.2" "a1.2") 0) true)
  (test (> (debian-vercmp "1.2.3" "1.2-3") 0) true)
  (test (> (debian-vercmp "1.2.3~rc1" "1.2.3~~rc1") 0) true)
  (test (< (debian-vercmp "1.2.3" "2") 0) true)
  (test (> (debian-vercmp "2.0.0" "2.0") 0) true)
  (test (> (debian-vercmp "1.2.a" "1.2.3") 0) true)
  (test (> (debian-vercmp "1.2.a" "1.2a") 0) true)
  (test (< (debian-vercmp "1" "1.2.3.4") 0) true)
  (test (= (debian-vercmp "1:2.3.4" "1:2.3.4") 0) true)
  (test (= (debian-vercmp "0:" "0:") 0) true)
  (test (= (debian-vercmp "0:" "") 0) true)
  (test (= (debian-vercmp "0:1.2" "1.2") 0) true)
  (test (< (debian-vercmp "0:" "1:") 0) true)
  (test (< (debian-vercmp "1:1.2.3" "2:0.4.5") 0) true))

(def semver2
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

(deftest semver2
  (test (peg/match semver2 "1.2.3") @[@["1" "2" "3"] @[] @[]])
  (test (peg/match semver2 "1.0.0-alpha")
        @[@["1" "0" "0"]
          @[[:alphanumeric "alpha"]]
          @[]])
  (test (peg/match semver2 "1.0.0-alpha.1")
        @[@["1" "0" "0"]
          @[[:alphanumeric "alpha"]
            [:numeric "1"]]
          @[]])
  (test (peg/match semver2 "1.0.0-0.3.7")
        @[@["1" "0" "0"]
          @[[:numeric "0"]
            [:numeric "3"]
            [:numeric "7"]]
          @[]])
  (test (peg/match semver2 "1.0.0-x.7.z.92")
        @[@["1" "0" "0"]
          @[[:alphanumeric "x"]
            [:numeric "7"]
            [:alphanumeric "z"]
            [:numeric "92"]]
          @[]])
  (test (peg/match semver2 "1.0.0-x-y-z.--.")
        @[@["1" "0" "0"]
          @[[:alphanumeric "x-y-z"]
            [:alphanumeric "--"]]
          @[]])
  (test (peg/match semver2 "1.0.0-alpha+001")
        @[@["1" "0" "0"]
          @[[:alphanumeric "alpha"]]
          @["001"]])
  (test (peg/match semver2 "1.0.0+20130313144700")
        @[@["1" "0" "0"]
          @[]
          @["20130313144700"]])
  (test (peg/match semver2 "1.0.0-beta+exp.sha.5114f85")
        @[@["1" "0" "0"]
          @[[:alphanumeric "beta"]]
          @["exp" "sha" "5114f85"]])
  (test (peg/match semver2 "1.0.0+21AF26D3----117B344092BD")
        @[@["1" "0" "0"]
          @[]
          @["21AF26D3----117B344092BD"]])
  (test (peg/match semver2 "1234567890.98765.0-alpha.1+a-b-c.d-e-f.15")
        @[@["1234567890" "98765" "0"]
          @[[:alphanumeric "alpha"]
            [:numeric "1"]]
          @["a-b-c" "d-e-f" "15"]]))

(defn semver2-vercmp
  `
  (semver2-vercmp a b)

  Compare two version numbers according to the rules found at
  https://semver.org/#semantic-versioning-200 .
  `
  [a b]
  (let [[[major-a minor-a patch-a] prerelease-a build-a] (peg/match semver2 a)
        [[major-b minor-b patch-b] prerelease-b build-b] (peg/match semver2 b)]
    (label top
      (let [major-cmp (numbers-compare major-a major-b)]
        (when (not= major-cmp 0)
          (return top major-cmp)))
      (let [minor-cmp (numbers-compare minor-a minor-b)]
        (when (not= minor-cmp 0)
          (return top minor-cmp)))
      (let [patch-cmp (numbers-compare patch-a patch-b)]
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
                      (numbers-compare a-part b-part))
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

(deftest semver2-vercmp
  (test (semver2-vercmp "1.9.0" "1.10.0") -1)
  (test (semver2-vercmp "1.10.0" "1.11.0") -1)
  (test (semver2-vercmp "1.0.0" "2.0.0") -1)
  (test (semver2-vercmp "2.0.0" "2.1.0") -1)
  (test (semver2-vercmp "2.1.0" "2.1.1") -1)
  (test (semver2-vercmp "1.0.0-alpha" "1.0.0") -1)
  (test (semver2-vercmp "1.0.0-alpha" "1.0.0-alpha.1") -1)
  (test (semver2-vercmp "1.0.0-alpha.1" "1.0.0-alpha.beta") -1)
  (test (semver2-vercmp "1.0.0-alpha.beta" "1.0.0-alpha.1") 1)
  (test (semver2-vercmp "1.0.0-alpha.beta" "1.0.0-alpha.beta") 0)
  (test (semver2-vercmp "1.0.0-alpha.beta" "1.0.0-beta") -1)
  (test (semver2-vercmp "1.0.0-beta" "1.0.0-alpha.beta") 1)
  (test (semver2-vercmp "1.0.0-beta.2" "1.0.0-beta") 1)
  (test (semver2-vercmp "1.0.0-beta.2" "1.0.0-beta.11") -1)
  (test (semver2-vercmp "1.0.0-beta.11" "1.0.0-rc.1") -1)
  (test (semver2-vercmp "1.0.0-rc.1" "1.0.0") -1))
