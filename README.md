# janver

![janver logo](docs/assets/janver.png)

`janver` compares version numbers in Janet. It implements Debian version ordering, Semantic Versioning 2.0.0 ordering,
Maven `ComparableVersion` ordering, and RubyGems `Gem::Version` ordering as
library functions, so it can be used from Janet programs without imposing a
command-line interface.

## Install

Install directly from GitHub with jpm:

```sh
jpm install https://github.com/djha-skin/janver
```

Or clone the repository and build its dependencies locally:

```sh
git clone https://github.com/djha-skin/janver.git
cd janver
jpm -l deps
jpm -l build
```

## Usage

Import the module for the version format you need. Each implementation
provides `version` (its parser) and `vercmp` (its comparator). Comparators
return a negative number when the first version sorts earlier, a positive
number when it sorts later, and zero when the versions are equal.

```janet
(import janver/debian)
(import janver/semver2)
(import janver/maven)
(import janver/ruby)

(debian/vercmp "1.2.3~rc1" "1.2.3")
# => a negative number

(semver2/vercmp "1.0.0-alpha" "1.0.0")
# => a negative number

(maven/vercmp "1.0-SNAPSHOT" "1.0")
# => a negative number

(ruby/vercmp "1.0.a1" "1.0")
# => a negative number
```

The parsers are available from the same modules, for example
`(peg/match semver2/version "1.2.3")`. For backwards compatibility,
`(import janver)` still provides the original names such as
`janver/semver2-vercmp`.

`debian-vercmp` follows the [Debian Policy Manual section
5.6.12](https://www.debian.org/doc/debian-policy/ch-controlfields.html#version).
It supports an optional numeric epoch and Debian's special tilde ordering.
`semver2-vercmp` follows the [Semantic Versioning
2.0.0](https://semver.org/#semantic-versioning-200) precedence rules,
including numeric and alphanumeric pre-release identifiers. Build metadata
does not affect precedence. `maven-vercmp` follows Apache Maven's
`ComparableVersion` behavior, including qualifier aliases, nested separators,
case-insensitive comparison, and arbitrary-length numeric components. The
implementation is based on [Apache Maven's ComparableVersion
source](https://github.com/apache/maven/blob/master/compat/maven-artifact/src/main/java/org/apache/maven/artifact/versioning/ComparableVersion.java).
`ruby-vercmp` follows RubyGems [`Gem::Version`](https://docs.ruby-lang.org/en/master/Gem/Version.html)
comparison: it accepts an initial decimal component, dot-separated
alphanumeric components, and an optional hyphenated prerelease suffix. Leading
and trailing whitespace is ignored, blank input is version zero, and hyphens
are normalized to `pre` segments. Numeric and alphabetic runs are compared
separately, with trailing zero components ignored. The `ruby-version` PEG
returns tagged `[:number digits]` and `[:string text]` segments; invalid input
returns `nil` from the PEG and causes `ruby-vercmp` to raise an error.

## Documentation

The full documentation is published at
[GitHub Pages documentation](https://djha-skin.github.io/janver/):

- [Quickstart](https://djha-skin.github.io/janver/quickstart.html)
- [Installation](https://djha-skin.github.io/janver/install.html)
- [API reference](https://djha-skin.github.io/janver/api.html)
- [Contributing](https://djha-skin.github.io/janver/contributing.html)
- [Changelog](https://djha-skin.github.io/janver/changelog.html)

## Development

Install the local dependencies, regenerate the API reference, and run the
suite with:

```sh
jpm -l deps
jpm -l run doc
jpm -l test
```

The project is released as Git tags. The current release is `v0.4.0`.

## License

`janver` is released under the MIT License. See [LICENSE](LICENSE) for the
full text.

## The Name

The name is a little coincidence: it sounds like “JANet VERsioning,” which
fits the library, but `janver` is really named for Johannes Vermeer, the
painter. The logo is inspired by a painting by Vermeer.
