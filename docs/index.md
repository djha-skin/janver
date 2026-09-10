# janver

![janver logo](assets/janver.png)

`janver` is a Janet library for comparing version numbers. It provides
separate modules for Debian versions, Semantic Versioning 2.0.0 versions,
Maven `ComparableVersion` versions, RubyGems `Gem::Version` versions, and
Python PEP 440 versions.
Each module exposes a `version` parser and a `vercmp` comparator.

## How it fits

Use `janver` when a Janet program needs to sort, validate, or compare version
strings according to an established ecosystem's rules. Maven comparison follows
[Apache Maven's `ComparableVersion` implementation](https://github.com/apache/maven/blob/master/compat/maven-artifact/src/main/java/org/apache/maven/artifact/versioning/ComparableVersion.java),
including its qualifier aliases and nested separator behavior. RubyGems
comparison follows [`Gem::Version`](https://docs.ruby-lang.org/en/master/Gem/Version.html),
including its prerelease normalization and trailing-zero equivalence. PEP 440
comparison follows [Python's packaging version specification](https://peps.python.org/pep-0440/),
including epochs, normalized pre/dev/post releases, and local versions. The library
is small and dependency-light: the comparison functions operate on strings and
return an ordinary numeric ordering result.

## Scope

`janver` does not provide a command-line program, package manager integration,
or version constraint solver. Import `janver/debian`, `janver/semver2`,
`janver/maven`, `janver/ruby`, or `janver/pep440` and call its `version` or `vercmp` functions.
It compares complete version strings; callers remain responsible for selecting
a format and handling invalid input.

## Next steps

- [Install janver](install.html)
- [Try the quickstart](quickstart.html)
- [Read the API reference](api.html)
- [Review the changelog](changelog.html)

## The name

The name is a convenient coincidence: it sounds like “JANet VERsioning,” but
`janver` is actually named for Johannes Vermeer, the painter. The logo is
inspired by a painting by Vermeer.
