# Quickstart

This walkthrough shows how to compare Debian, SemVer 2.0.0, Maven, and RubyGems
versions from a Janet program.

## Compare Debian versions

Import the Debian module and call `debian/vercmp`:

```janet
(import janver/debian)

(def result (debian/vercmp "1.2.3~rc1" "1.2.3"))
(assert (< result 0))
```

Debian puts a tilde before every other character, including the end of a
part. Debian versions may also begin with a numeric epoch:

```janet
(assert (> (debian/vercmp "2:1.0" "1:9.9") 0))
(assert (= (debian/vercmp "0:1.2" "1.2") 0))
```

## Compare SemVer versions

Import `janver/semver2` and use `semver2/vercmp` for Semantic Versioning
2.0.0 precedence:

```janet
(import janver/semver2)

(assert (< (semver2/vercmp "1.0.0-alpha" "1.0.0") 0))
(assert (< (semver2/vercmp "1.0.0-beta.2" "1.0.0-beta.11") 0))
(assert (> (semver2/vercmp "2.0.0" "1.9.9") 0))
```

Numeric identifiers are compared numerically, and numeric identifiers sort
before alphanumeric identifiers. A version without a pre-release section has
higher precedence than one with a pre-release section. Build metadata is
ignored when precedence is compared.

## Compare Maven versions

Import `janver/maven` and use `maven/vercmp` for Apache Maven
`ComparableVersion` precedence:

```janet
(import janver/maven)

(assert (< (maven/vercmp "1.0-SNAPSHOT" "1.0") 0))
(assert (= (maven/vercmp "1a1" "1-alpha-1") 0))
(assert (< (maven/vercmp "1.0.0" "1.0-1") 0))
```

Maven comparison is case-insensitive, recognizes `alpha`/`a`, `beta`/`b`,
`milestone`/`m`, and `cr`/`rc` aliases, and compares numeric components as
strings so it does not depend on machine integer size. The behavior is based
on [Apache Maven's `ComparableVersion` source](https://github.com/apache/maven/blob/master/compat/maven-artifact/src/main/java/org/apache/maven/artifact/versioning/ComparableVersion.java).

## Use the result for sorting

## Compare RubyGems versions

Import `janver/ruby` and use `ruby/vercmp` for RubyGems `Gem::Version`
precedence:

```janet
(import janver/ruby)

(assert (< (ruby/vercmp "1.0.a1" "1.0") 0))
(assert (= (ruby/vercmp "1.0" "1.0.0") 0))
(assert (= (ruby/vercmp "1.0-rc1" "1.0.pre.rc1") 0))
```

`ruby/version` is the parser PEG. It returns tagged numeric and alphabetic
runs, for example `1.0.a10` becomes `[[:number "1"] [:number "0"]
[:string "a"] [:number "10"]]`. RubyGems accepts surrounding whitespace and
blank input (blank input means zero), requires the version to start with a
digit, and rejects malformed separators and non-ASCII letters. A hyphen is
normalized as the prerelease marker `pre`, so `1.0-rc1` is compared like
`1.0.pre.rc1`. Numeric runs are compared without converting them to machine
integers; `1.0.a10` therefore sorts after `1.0.a9`.

The comparators return the same negative, zero, or positive shape expected by
code that needs an ordering function. They do not return a Boolean, so callers
can distinguish equality from either ordering direction.
