# Debian version ordering.

(use judge)

(import ./utils :as utils)

(def version
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

(deftest version
  (test (peg/match version "33333") @["" @["" "33333"]])
  (test (peg/match version "a3") @["" @["a" "3"]])
  (test (peg/match version "3a") @["" @["" "3" "a" ""]])
  (test (peg/match version ".") @["" @["." ""]])
  (test (peg/match version "1.2.3")
        @["" @["" "1" "." "2" "." "3"]])
  (test (peg/match version "1a2b3c")
        @["" @["" "1" "a" "2" "b" "3" "c" ""]])
  (test (peg/match version "1.2.3~rc1")
        @[""
          @["" "1" "." "2" "." "3" "~rc" "1"]])
  (test (peg/match version "1.2.3~~rc1")
        @[""
          @["" "1" "." "2" "." "3" "~~rc" "1"]])
  (test (peg/match version "1:2.3.4") @["1" @["" "2" "." "3" "." "4"]])
  (test (peg/match version "0:") @["0" @[]])
  (test (peg/match version "") @["" @[]])
  (test (peg/match version "0:1.2") @["0" @["" "1" "." "2"]])
  (test (peg/match version "1.2") @["" @["" "1" "." "2"]])
  (test (peg/match version "1:") @["1" @[]])
  (test (peg/match version "1:1.2.3") @["1" @["" "1" "." "2" "." "3"]])
  (test (peg/match version "2:0.4.5") @["2" @["" "0" "." "4" "." "5"]]))

(defn- debian-compare-transform
  `
  Transforms the numeric value of a byte so that it will conform to the
  comparison rules for characters in a non-digit version part in the
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
  (test (justify (peg/match version "1.2.3~rc1")
                 (peg/match version "1.2.3~~rc1"))
        [@[""
           @["" "1" "." "2" "." "3" "~rc" "1"]]
         @[""
           @["" "1" "." "2" "." "3" "~~rc" "1"]]]))

(defn vercmp
  `
  (vercmp a b)

  Compares two version numbers according to the rules set forth in the Debian
  Policy Manual.
  `
  [a b]
  (if (= a b) 0
    (let [[a-epoch a-parts] (peg/match version a)
          [b-epoch b-parts] (peg/match version b)
          epoch-cmp (utils/numbers-compare a-epoch b-epoch)]
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
              (let [second-cmp (utils/numbers-compare
                                 (get just-a i)
                                 (get just-b i))]
                (when (not= second-cmp 0)
                  (return compare-parts second-cmp)))
              # Due to the nature of the PEG, I can guarantee that there
              # are an even number of matches for both A and B, so I'm
              # allowed to do this.
              (++ i))
            0))))))

(deftest vercmp
  (test (= (vercmp "" "") 0) true)
  (test (< (vercmp "~~" "~~a") 0) true)
  (test (> (vercmp "~" "~~a") 0) true)
  (test (< (vercmp "~" "") 0) true)
  (test (> (vercmp "a" "") 0) true)
  (test (< (vercmp "1.2.3~rc1" "1.2.3") 0) true)
  (test (= (vercmp "1.2" "1.2") 0) true)
  (test (< (vercmp "1.2" "a1.2") 0) true)
  (test (> (vercmp "1.2.3" "1.2-3") 0) true)
  (test (> (vercmp "1.2.3~rc1" "1.2.3~~rc1") 0) true)
  (test (< (vercmp "1.2.3" "2") 0) true)
  (test (> (vercmp "2.0.0" "2.0") 0) true)
  (test (> (vercmp "1.2.a" "1.2.3") 0) true)
  (test (> (vercmp "1.2.a" "1.2a") 0) true)
  (test (< (vercmp "1" "1.2.3.4") 0) true)
  (test (= (vercmp "1:2.3.4" "1:2.3.4") 0) true)
  (test (= (vercmp "0:" "0:") 0) true)
  (test (= (vercmp "0:" "") 0) true)
  (test (= (vercmp "0:1.2" "1.2") 0) true)
  (test (< (vercmp "0:" "1:") 0) true)
  (test (< (vercmp "1:1.2.3" "2:0.4.5") 0) true))

