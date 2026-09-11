# Changelog

The canonical changelog is maintained in the repository root:

Read [CHANGELOG.md on GitHub][changelog].

[changelog]: https://github.com/djha-skin/janver/blob/main/CHANGELOG.md

## 0.5.1 - 2026-09-11

- Corrected PEP 440 local-version ordering for numeric and text labels.
- Accepted documented normalized separator forms for implicit pre/dev/post
  release numbers.
- Added comprehensive adjacent tests for PEP 440 helpers and comparator edge
  cases, including the legacy `c` release-candidate alias.

## 0.5.0

- Added Python PEP 440 parsing and precedence comparison.
- Added PEP 440 API and quickstart documentation.

## 0.4.0

- Added RubyGems `Gem::Version` parsing and precedence comparison with
  `ruby-version` and `ruby-vercmp`.
- Added documentation for RubyGems grammar, whitespace, blank versions,
  hyphen prerelease normalization, and canonical trailing-zero comparison.

## 0.2.0 - 2026-08-25

- Added Semantic Versioning 2.0.0 parsing and precedence comparison.
- Added generated API documentation and the published documentation site.

See the [full changelog][changelog] for earlier releases and future
changes.
