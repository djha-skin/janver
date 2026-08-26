# janver

![janver logo](assets/janver.png)

`janver` is a Janet library for comparing version numbers. It provides
comparators for Debian versions and Semantic Versioning 2.0.0 versions.

## How it fits

Use `janver` when a Janet program needs to sort, validate, or compare version
strings according to an established ecosystem's rules. The library is small
and dependency-light: the comparison functions operate on strings and return
an ordinary numeric ordering result.

## Scope

`janver` does not provide a command-line program, package manager integration,
or version constraint solver. It compares complete version strings; callers
remain responsible for selecting a format and handling invalid input.

## Next steps

- [Install janver](install.html)
- [Try the quickstart](quickstart.html)
- [Read the API reference](api.html)
- [Review the changelog](changelog.html)

## The name

The name is a convenient coincidence: it sounds like “JANet VERsioning,” but
`janver` is actually named for Johannes Vermeer, the painter. The logo is
inspired by a painting by Vermeer.
