# PEP 440 version ordering.
#
# Python packaging version parsing and comparison for janver.

(use judge)

(import ./utils :as utils)

(defn- ascii-digit? [byte]
  (and (number? byte) (>= byte 48) (<= byte 57)))

(deftest ascii-digit?
  (test (ascii-digit? 48) true)
  (test (ascii-digit? 57) true)
  (test (ascii-digit? 47) false)
  (test (ascii-digit? 65) false)
  (test (ascii-digit? nil) false))

(defn- ascii-letter? [byte]
  (and (number? byte)
       (or (and (>= byte 65) (<= byte 90))
           (and (>= byte 97) (<= byte 122)))))

(deftest ascii-letter?
  (test (ascii-letter? 65) true)
  (test (ascii-letter? 90) true)
  (test (ascii-letter? 97) true)
  (test (ascii-letter? 122) true)
  (test (ascii-letter? 64) false)
  (test (ascii-letter? 123) false)
  (test (ascii-letter? nil) false))

(defn- ascii-alnum? [byte]
  (or (ascii-digit? byte) (ascii-letter? byte)))

(deftest ascii-alnum?
  (test (ascii-alnum? 48) true)
  (test (ascii-alnum? 65) true)
  (test (ascii-alnum? 45) false)
  (test (ascii-alnum? nil) false))

(defn- normalize-integer [digits]
  (let [trimmed (string/triml digits "0")]
    (if (= trimmed "") "0" trimmed)))

(deftest normalize-integer
  (test (normalize-integer "000") "0")
  (test (normalize-integer "00120") "120")
  (test (normalize-integer "120") "120"))


(defn- starts-at? [s index prefix]
  (and (<= (+ index (length prefix)) (length s))
       (= (string/slice s index (+ index (length prefix))) prefix)))

(deftest starts-at?
  (test (starts-at? "abcdef" 2 "cd") true)
  (test (starts-at? "abcdef" 5 "f") true)
  (test (starts-at? "abcdef" 5 "fg") false)
  (test (starts-at? "abcdef" 0 "") true))

(defn- take-digits [s index]
  (var pos index)
  (while (and (< pos (length s)) (ascii-digit? (get s pos)))
    (++ pos))
  (if (= pos index)
    nil
    @[pos (normalize-integer (string/slice s index pos))]))

(deftest take-digits
  (test (take-digits "0012x" 0) @[4 "12"])
  (test (take-digits "0012x" 2) @[4 "12"])
  (test (take-digits "abc" 0) nil)
  (test (take-digits "12" 2) nil))

(defn- suffix-separator? [byte]
  (or (= byte 46) (= byte 45) (= byte 95)))

(deftest suffix-separator?
  (test (suffix-separator? 46) true)
  (test (suffix-separator? 45) true)
  (test (suffix-separator? 95) true)
  (test (suffix-separator? 47) false))

(defn- digits-only? [s]
  (if (= (length s) 0)
    false
    (do
      (var result true)
      (each byte s
        (unless (ascii-digit? byte)
          (set result false)))
      result)))

(deftest digits-only?
  (test (digits-only? "0") true)
  (test (digits-only? "0012") true)
  (test (digits-only? "") false)
  (test (digits-only? "12a") false))

(defn- pre-label [s index]
  (var result nil)
  (def labels ["alpha" "beta" "preview" "pre" "rc" "a" "b" "c"])
  (each token labels
    (when (and (nil? result) (starts-at? s index token))
      (set result [token (+ index (length token))])))
  result)

(deftest pre-label
  (test (pre-label "1.0alpha1" 3) @["alpha" 8])
  (test (pre-label "1.0rc1" 3) @["rc" 5])
  (test (pre-label "1.0" 3) nil)
  (test (pre-label "1.0beta" 3) @["beta" 7]))

(defn- normalize-pre-label [label]
  (cond (= label "alpha") "a"
    (= label "a") "a"
    (= label "beta") "b"
    (= label "b") "b"
    (= label "preview") "rc"
    (= label "pre") "rc"
    (= label "c") "rc"
    (= label "rc") "rc"
    nil))

(deftest normalize-pre-label
  (test (normalize-pre-label "alpha") "a")
  (test (normalize-pre-label "a") "a")
  (test (normalize-pre-label "beta") "b")
  (test (normalize-pre-label "b") "b")
  (test (normalize-pre-label "preview") "rc")
  (test (normalize-pre-label "pre") "rc")
  (test (normalize-pre-label "c") "rc")
  (test (normalize-pre-label "rc") "rc")
  (test (normalize-pre-label "post") nil))

(defn- post-label [s index]
  (var result nil)
  (def labels ["post" "rev" "r"])
  (each token labels
    (when (and (nil? result) (starts-at? s index token))
      (set result [token (+ index (length token))])))
  result)

(deftest post-label
  (test (post-label "1.0post1" 3) @["post" 7])
  (test (post-label "1.0rev1" 3) @["rev" 6])
  (test (post-label "1.0r1" 3) @["r" 4])
  (test (post-label "1.0" 3) nil))

(defn- dev-label [s index]
  (when (starts-at? s index "dev")
    ["dev" (+ index 3)]))

(deftest dev-label
  (test (dev-label "1.0dev1" 3) @["dev" 6])
  (test (dev-label "1.0" 3) nil)
  (test (dev-label "dev" 0) @["dev" 3]))

(defn- local-segments [s index]
  (def result @[])
  (var i index)
  (while true
    (var start i)
    (while (and (< i (length s)) (ascii-alnum? (get s i)))
      (++ i))
    (when (= start i)
      (return nil))
    (def raw (string/slice s start i))
    (if (digits-only? raw)
      (array/push result [:number (normalize-integer raw)])
      (array/push result [:string (string/ascii-lower raw)]))
    (if (and (< i (length s)) (suffix-separator? (get s i)))
      (++ i)
      (break)))
  (if (or (= i index)
          (not= i (length s))
          (and (> i index) (suffix-separator? (get s (dec i)))))
    nil
    result))

(deftest local-segments
  (test (local-segments "abc.001" 0)
        @[[:string "abc"] [:number "1"]])
  (test (local-segments "abc-DEF_2" 0)
        @[[:string "abc"] [:string "def"] [:number "2"]])
  (test (local-segments "1" 0) @[[:number "1"]])
  (test (local-segments "" 0) nil)
  (test (local-segments "abc." 0) nil)
  (test (local-segments "abc..def" 0) nil)
  (test (local-segments "abc!" 0) nil))

(defn- pep440-normalize [raw]
  (let [raw (if (string? raw) raw (apply string/from-bytes raw))
        s (string/ascii-lower (string/trim raw))]
    (var i 0)
    (var valid true)
    (var epoch "0")
    (var release @[])
    (var pre nil)
    (var post nil)
    (var dev nil)
    (var local nil)
    (when (and (< i (length s)) (= (get s i) 118))
      (++ i))
    (def epoch-part (take-digits s i))
    (def first-release
      (if (nil? epoch-part)
        nil
        (let [end (get epoch-part 0)
              digits (get epoch-part 1)]
          (if (and (< end (length s)) (= (get s end) 33))
            (do
              (set epoch digits)
              (set i (inc end))
              (take-digits s i))
            (do
              (set i end)
              @[end digits])))))
    (if (nil? first-release)
      (set valid false)
      (let [end (get first-release 0)
            digits (get first-release 1)]
        (array/push release digits)
        (set i end)))
    (while (and valid (< i (length s))
                (= (get s i) 46)
                (< (inc i) (length s))
                (ascii-digit? (get s (inc i))))
      (let [part (take-digits s (inc i))]
        (array/push release (get part 1))
        (set i (get part 0))))
    (when (and valid (< i (length s)))
      (var label-index i)
      (when (suffix-separator? (get s label-index))
        (++ label-index))
      (def found-pre (pre-label s label-index))
      (when found-pre
        (let [label (get found-pre 0)
              end (get found-pre 1)]
          (set i end)
          (set pre @[(normalize-pre-label label) "0"])
          (when (and (< i (length s)) (suffix-separator? (get s i)))
            (++ i))
          (def pre-number (take-digits s i))
          (when pre-number
            (set pre @[(normalize-pre-label label) (get pre-number 1)])
            (set i (get pre-number 0))))))
    (when (and valid (< i (length s)) (= (get s i) 45)
               (< (inc i) (length s))
               (ascii-digit? (get s (inc i))))
      (let [part (take-digits s (inc i))]
        (set post @[:post (get part 1)])
        (set i (get part 0))))
    (when (and valid (nil? post) (< i (length s)))
      (var label-index i)
      (when (suffix-separator? (get s label-index))
        (++ label-index))
      (def found-post (post-label s label-index))
      (when found-post
        (set i (get found-post 1))
        (set post @[:post "0"])
        (when (and (< i (length s)) (suffix-separator? (get s i)))
          (++ i))
        (def post-number (take-digits s i))
        (when post-number
          (set post @[:post (get post-number 1)])
          (set i (get post-number 0)))))
    (when (and valid (< i (length s)))
      (var label-index i)
      (when (suffix-separator? (get s label-index))
        (++ label-index))
      (def found-dev (dev-label s label-index))
      (when found-dev
        (set i (get found-dev 1))
        (set dev @[:dev "0"])
        (when (and (< i (length s)) (suffix-separator? (get s i)))
          (++ i))
        (def dev-number (take-digits s i))
        (when dev-number
          (set dev @[:dev (get dev-number 1)])
          (set i (get dev-number 0)))))
    (when (and valid (< i (length s)) (= (get s i) 43))
      (++ i)
      (set local (local-segments s i))
      (if (nil? local)
        (set valid false)
        (set i (length s))))
    (when (and valid (not= i (length s)))
      (set valid false))
    (if valid
      [epoch release pre post dev local]
      nil)))

(deftest pep440-normalize
  (test (pep440-normalize "1.0c1")
        ["0" @["1" "0"] @["rc" "1"] nil nil nil])
  (test (pep440-normalize "  V01.002-PRE.0001+Foo_001\n")
        ["0" @["1" "2"] @["rc" "1"] nil nil
         @[[:string "foo"] [:number "1"]]])
  (test (pep440-normalize "1.0a1.post2.dev3")
        ["0" @["1" "0"] @["a" "1"] [:post "2"]
         [:dev "3"] nil])
  (test (pep440-normalize "1.0a--1")
        ["0" @["1" "0"] @["a" "0"] [:post "1"] nil nil])
  (test (pep440-normalize "1.0post-")
        ["0" @["1" "0"] nil [:post "0"] nil nil])
  (test (pep440-normalize "1.0dev_")
        ["0" @["1" "0"] nil nil [:dev "0"] nil])
  (test (pep440-normalize "1.0.a1")
        ["0" @["1" "0"] @["a" "1"] nil nil nil])
  (test (pep440-normalize "1.0-a-1")
        ["0" @["1" "0"] @["a" "1"] nil nil nil])
  (test (pep440-normalize "1.0_a_1")
        ["0" @["1" "0"] @["a" "1"] nil nil nil])
  (test (pep440-normalize "1.0post1")
        ["0" @["1" "0"] nil [:post "1"] nil nil])
  (test (pep440-normalize "1.0_post_1")
        ["0" @["1" "0"] nil [:post "1"] nil nil])
  (test (pep440-normalize "1.0-r-1")
        ["0" @["1" "0"] nil [:post "1"] nil nil])
  (test (pep440-normalize "1.0-dev1")
        ["0" @["1" "0"] nil nil [:dev "1"] nil])
  (test (pep440-normalize "1.0_dev_1")
        ["0" @["1" "0"] nil nil [:dev "1"] nil])
  (test (pep440-normalize "1.0+foo-bar_baz")
        ["0" @["1" "0"] nil nil nil
         @[[:string "foo"] [:string "bar"] [:string "baz"]]])
  (test (pep440-normalize "\t\n\v\f\r1.0\r\n")
        ["0" @["1" "0"] nil nil nil nil])
  (test (pep440-normalize "1!0002.0003")
        ["1" @["2" "3"] nil nil nil nil])
  (test (pep440-normalize "1.0!") nil)
  (test (pep440-normalize "1.0..a1") nil)
  (test (pep440-normalize "1.0+foo--bar") nil)
  (test (pep440-normalize "1.0+foo.bar+") nil)
  (test (pep440-normalize "1.0.dev1.dev2") nil)
  (test (pep440-normalize "1.0.post1.post2") nil)
  (test (pep440-normalize "1.0a1a2") nil)
  (test (pep440-normalize "1.0!a1") nil)
  (test (pep440-normalize "1.0")
        ["0" @["1" "0"] nil nil nil nil])
  (test (pep440-normalize "1!2.0")
        ["1" @["2" "0"] nil nil nil nil])
  (test (pep440-normalize "1.0-") nil)
  (test (pep440-normalize "1.0.dev1.post1") nil)
  (test (pep440-normalize @[49 46 48])
        ["0" @["1" "0"] nil nil nil nil]))

(def version
  `
  Parse and normalize a Python PEP 440 version identifier. The result contains
  epoch, release segments, pre-release, post-release, development-release, and
  local-version components; decimal values remain strings for arbitrary length.
  `
  (peg/compile
    ~{:digit (range "09")
      :letter (choice (range "AZ") (range "az"))
      :version-character (choice :digit :letter "." "-" "_" "+" "!")
      :main (replace
              (sequence
                (any (choice " " "\t" "\n" "\v" "\f" "\r"))
                (capture (some :version-character))
                (any (choice " " "\t" "\n" "\v" "\f" "\r"))
                -1)
              ,|(do (pep440-normalize $)))}))

# Parse and normalize a PEP 440 version identifier. The result is
# `[epoch release pre post dev local]`; numeric values remain strings.

(defn- suffix-key [parsed]
  (let [pre (get parsed 2)
        post (get parsed 3)
        dev (get parsed 4)]
    (cond
      (and (nil? pre) (nil? post) dev)
      ["0" "0" "0" "0" "0" (get dev 1)]
      pre
      [(if (= (get pre 0) "a") "1"
         (if (= (get pre 0) "b") "2" "3"))
       (get pre 1)
       (if post "1" "0")
       (if post (get post 1) "0")
       (if dev "0" "1")
       (if dev (get dev 1) "0")]
      post
      ["4" "0" "1" (get post 1)
       (if dev "0" "1")
       (if dev (get dev 1) "0")]
      ["4" "0" "0" "0" "1" "0"])))

(deftest suffix-key
  (test (suffix-key ["0" @[] nil nil [:dev "2"] nil])
        @["0" "0" "0" "0" "0" "2"])
  (test (suffix-key ["0" @[] [:a "1"] nil nil nil])
        @["1" "1" "0" "0" "1" "0"])
  (test (suffix-key ["0" @[] [:b "2"] [:post "3"] [:dev "4"] nil])
        @["2" "2" "1" "3" "0" "4"])
  (test (suffix-key ["0" @[] [:rc "1"] nil nil nil])
        @["3" "1" "0" "0" "1" "0"])
  (test (suffix-key ["0" @[] nil [:post "5"] nil nil])
        @["4" "0" "1" "5" "1" "0"])
  (test (suffix-key ["0" @[] nil nil nil nil])
        @["4" "0" "0" "0" "1" "0"]))

(defn- numeric-array-compare [a b]
  (var i 0)
  (var result 0)
  (var part-a "0")
  (var part-b "0")
  (while (and (= result 0)
              (or (< i (length a)) (< i (length b))))
    (set part-a "0")
    (set part-b "0")
    (when (< i (length a))
      (let [value (get a i)]
        (if (nil? value)
          (set part-a "0")
          (set part-a (if (string? value) value "0")))))
    (when (< i (length b))
      (let [value (get b i)]
        (if (nil? value)
          (set part-b "0")
          (set part-b (if (string? value) value "0")))))
    (set result
         (utils/numbers-compare part-a part-b))
    (++ i))
  result)

(deftest numeric-array-compare
  (test (numeric-array-compare @["1" "2"] @["1" "2"]) 0)
  (test (numeric-array-compare @["1"] @["1" "1"]) -1)
  (test (numeric-array-compare @["1" "2"] @["1"]) 1)
  (test (numeric-array-compare @["9"] @["10"]) -1)
  (test (numeric-array-compare @["10"] @["9"]) 1))

(defn- suffix-key-compare [a b]
  (var i 0)
  (var result 0)
  (while (and (= result 0) (< i (length a)))
    (set result (utils/numbers-compare (get a i) (get b i)))
    (++ i))
  result)

(deftest suffix-key-compare
  (test (suffix-key-compare @["1" "2"] @["1" "2"]) 0)
  (test (suffix-key-compare @["1" "2"] @["1" "3"]) -1)
  (test (suffix-key-compare @["1" "3"] @["1" "2"]) 1))

(defn- local-segment-compare [a b]
  (match [a b]
    [[:number x] [:number y]] (utils/numbers-compare x y)
    [[:number _] [:string _]] 1
    [[:string _] [:number _]] -1
    [[:string x] [:string y]]
    (cond (< x y) -1 (> x y) 1 0)))

(deftest local-segment-compare
  (test (local-segment-compare [:number "1"] [:number "2"]) -1)
  (test (local-segment-compare [:number "2"] [:number "1"]) 1)
  (test (local-segment-compare [:number "1"] [:number "1"]) 0)
  (test (local-segment-compare [:number "1"] [:string "abc"]) 1)
  (test (local-segment-compare [:string "abc"] [:number "1"]) -1)
  (test (local-segment-compare [:string "abc"] [:string "abd"]) -1)
  (test (local-segment-compare [:string "abd"] [:string "abc"]) 1)
  (test (local-segment-compare [:string "abc"] [:string "abc"]) 0))

(defn- local-compare [a b]
  (cond
    (and (nil? a) (nil? b)) 0
    (nil? a) -1
    (nil? b) 1
    :else
    (do
      (var i 0)
      (var result 0)
      (while (and (= result 0)
                  (< i (length a))
                  (< i (length b)))
        (set result (local-segment-compare (get a i) (get b i)))
        (++ i))
      (if (not= result 0)
        result
        (cond (> (length a) (length b)) 1
          (< (length a) (length b)) -1
          0)))))

(deftest local-compare
  (test (local-compare nil nil) 0)
  (test (local-compare nil @[]) -1)
  (test (local-compare @[] nil) 1)
  (test (local-compare @[[:string "a"]] @[[:string "b"]]) -1)
  (test (local-compare @[[:string "a"]] @[[:string "a"] [:number "1"]]) -1)
  (test (local-compare @[[:string "a"] [:number "1"]]
                       @[[:string "a"]]) 1)
  (test (local-compare @[[:number "1"]] @[[:number "1"]]) 0))

(defn vercmp
  `
  (vercmp a b)

  Compare two version identifiers according to PEP 440. Invalid version
  identifiers raise an error. Local version labels only affect ordering when
  the public versions are otherwise equal.
  `
  [a b]
  (let [parsed-a (peg/match version a)
        parsed-b (peg/match version b)]
    (when (or (nil? parsed-a) (nil? parsed-b))
      (error "Malformed PEP 440 version"))
    (let [canon-a (get parsed-a 0)
          canon-b (get parsed-b 0)
          epoch-a (get canon-a 0)
          release-a (get canon-a 1)
          local-a (get canon-a 5)
          epoch-b (get canon-b 0)
          release-b (get canon-b 1)
          local-b (get canon-b 5)
          epoch-result (utils/numbers-compare (or epoch-a "0")
                                              (or epoch-b "0"))]
      (if (not= epoch-result 0)
        epoch-result
        (let [release-result (numeric-array-compare release-a release-b)]
          (if (not= release-result 0)
            release-result
            (let [suffix-result
                  (suffix-key-compare (suffix-key canon-a)
                                      (suffix-key canon-b))]
              (if (not= suffix-result 0)
                suffix-result
                (local-compare local-a local-b)))))))))

(deftest version
  (test (peg/match version "1.2rc3")
        ["0" @["1" "2"] ["rc" "3"] nil nil nil])
  (test (peg/match version " v01.002-Alpha.0001+Ubuntu-001 ")
        ["0" @["1" "2"] ["a" "1"] nil nil
         @[[:string "ubuntu"] [:number "1"]]])
  (test (peg/match version "1!2.0.post-3.dev+linux.x86")
        ["1" @["2" "0"] nil [:post "3"] [:dev "0"]
         @[[:string "linux"] [:string "x86"]]])
  (test (peg/match version "1.0-1")
        ["0" @["1" "0"] nil [:post "1"] nil nil])
  (test (peg/match version "1.2")
        ["0" @["1" "2"] nil nil nil nil])
  (test (peg/match version "1.0+ABC.001")
        ["0" @["1" "0"] nil nil nil
         @[[:string "abc"] [:number "1"]]])
  (test (peg/match version "1.0-") nil)
  (test (peg/match version "1.0+foo-") nil)
  (test (peg/match version "1.0+foo..bar") nil)
  (test (peg/match version "1..0") nil)
  (test (peg/match version "1.0+foo..bar") nil)
  (test (peg/match version "1.0+é") nil))

(deftest vercmp
  (test (< (vercmp "1.0.dev1" "1.0a1") 0) true)
  (test (< (vercmp "1.0a1" "1.0b1") 0) true)
  (test (< (vercmp "1.0b1" "1.0rc1") 0) true)
  (test (= (vercmp "1.0c1" "1.0rc1") 0) true)
  (test (< (vercmp "1.0rc1" "1.0") 0) true)
  (test (< (vercmp "1.0" "1.0.post1") 0) true)
  (test (< (vercmp "1.0.post1.dev1" "1.0.post1") 0) true)
  (test (= (vercmp "1.0a" "1.0alpha0") 0) true)
  (test (= (vercmp "v1.0" "1.0.0") 0) true)
  (test (= (vercmp "1.0-1" "1.0.post1") 0) true)
  (test (< (vercmp "1.0+abc.1" "1.0+abc.2") 0) true)
  (test (> (vercmp "1.0+abc" "1.0+1") 0) true)
  (test (< (vercmp "1.0" "1.0+abc") 0) true)
  (test (= (vercmp "1.0+ABC.001" "1.0+abc.1") 0) true)
  (test (> (vercmp "2!1.0" "1!9.9") 0) true)
  (test (< (vercmp "1!1.0" "2!0.0") 0) true)
  (test (= (vercmp "1.0alpha1" "1.0a1") 0) true)
  (test (= (vercmp "1.0preview1" "1.0rc1") 0) true)
  (test (= (vercmp "1.0pre1" "1.0rc1") 0) true)
  (test (= (vercmp "1.0rev1" "1.0.post1") 0) true)
  (test (= (vercmp "1.0r1" "1.0.post1") 0) true)
  (test (= (vercmp "1.0" "1.0.0.0") 0) true)
  (test (= (vercmp "1.0a" "1.0a0") 0) true)
  (test (= (vercmp "1.0-post" "1.0.post0") 0) true)
  (test (= (vercmp "1.0dev" "1.0.dev0") 0) true)
  (test (< (vercmp "1.0a1.dev1" "1.0a1") 0) true)
  (test (< (vercmp "1.0a1" "1.0a1.post1") 0) true)
  (test (< (vercmp "1.0.post1.dev1" "1.0.post1") 0) true)
  (test (> (vercmp "1.0+1" "1.0+abc") 0) true)
  (test (< (vercmp "1.0+abc.1" "1.0+abc.1.1") 0) true)
  (test (< (vercmp "1.dev0" "1.0.dev456") 0) true)
  (test (< (vercmp "1.0.dev456" "1.0a1") 0) true)
  (test (< (vercmp "1.0a2" "1.0b1") 0) true)
  (test (< (vercmp "1.0a12.dev456" "1.0a12") 0) true)
  (test (< (vercmp "1.0b2" "1.0rc1") 0) true)
  (test (< (vercmp "1.0rc1.dev456" "1.0rc1") 0) true)
  (test (< (vercmp "1.0" "1.0.post456.dev34") 0) true)
  (test (< (vercmp "1.0.post456.dev34" "1.0.post456") 0) true)
  (test (< (vercmp "1.0.post456" "1.0.15") 0) true)
  (test (< (vercmp "1.0.15" "1.1.dev1") 0) true)
  (test (error? (try (vercmp "1.0-" "1.0") true)) true)
  (test (error? (try (vercmp "1.0.dev1.post1" "1.0") true)) true)
  (test (error? (try (vercmp "1.0" "1.0-") true)) true)
  (test (= (vercmp "1.0+foo-1" "1.0+foo.1") 0) true))
