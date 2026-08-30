# Changelog

All notable changes to `janver` are documented here.

## [0.4.0] - 2026-08-29

### Added

- RubyGems `Gem::Version` parsing and precedence comparison with `ruby-version`
  and `ruby-vercmp`.
- RubyGems-compatible whitespace and blank-version handling, hyphen-to-`pre`
  prerelease normalization, ASCII segment parsing, canonical trailing-zero
  equality, and arbitrary-length numeric comparison.
- API and quickstart documentation for RubyGems version comparison.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and versions follow [Semantic Versioning](https://semver.org/).

## [0.3.0] - 2026-08-26

### Added

- Maven `ComparableVersion` parsing and precedence comparison with
  `maven-version` and `maven-vercmp`.
- Maven qualifier aliases, case-insensitive comparison, nested dot/hyphen
  handling, and arbitrary-length numeric comparison.
- Design notes documenting the behavior referenced from Apache Maven's
  `ComparableVersion` implementation in the [GitHub wiki][maven-design].

## [0.2.0] - 2026-08-25

### Added

- Semantic Versioning 2.0.0 parsing and precedence comparison with
  `semver2` and `semver2-vercmp`.
- API documentation generated from Janet docstrings with Documentarian.
- Installation, quickstart, contribution, and published documentation pages.

## [0.1.0]

### Added

- Debian version parsing and comparison with `debian-version` and
  `debian-vercmp`.

[0.4.0]: https://github.com/djha-skin/janver/releases/tag/v0.4.0
[0.3.0]: https://github.com/djha-skin/janver/releases/tag/v0.3.0
[0.2.0]: https://github.com/djha-skin/janver/releases/tag/v0.2.0
[maven-design]: https://github.com/djha-skin/janver/wiki/Maven-ComparableVersion-Design
[0.1.0]: https://github.com/djha-skin/janver/releases/tag/v0.1.0
