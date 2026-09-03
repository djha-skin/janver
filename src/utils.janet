# Shared utilities for version implementations.

(use judge)

(defn numbers-compare [a b]
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

