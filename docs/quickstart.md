# Quickstart

This walkthrough shows how to compare Debian and SemVer 2.0.0 versions from a
Janet program.

## Compare Debian versions

Import the module and call `debian-vercmp`:

```janet
(import janver)

(def result (janver/debian-vercmp "1.2.3~rc1" "1.2.3"))
(assert (< result 0))
```

Debian puts a tilde before every other character, including the end of a
part. Debian versions may also begin with a numeric epoch:

```janet
(assert (> (janver/debian-vercmp "2:1.0" "1:9.9") 0))
(assert (= (janver/debian-vercmp "0:1.2" "1.2") 0))
```

## Compare SemVer versions

Use `semver2-vercmp` for Semantic Versioning 2.0.0 precedence:

```janet
(assert (< (janver/semver2-vercmp "1.0.0-alpha" "1.0.0") 0))
(assert (< (janver/semver2-vercmp "1.0.0-beta.2" "1.0.0-beta.11") 0))
(assert (> (janver/semver2-vercmp "2.0.0" "1.9.9") 0))
```

Numeric identifiers are compared numerically, and numeric identifiers sort
before alphanumeric identifiers. A version without a pre-release section has
higher precedence than one with a pre-release section. Build metadata is
ignored when precedence is compared.

## Use the result for sorting

The comparators return the same negative, zero, or positive shape expected by
code that needs an ordering function. They do not return a Boolean, so callers
can distinguish equality from either ordering direction.
