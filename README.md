# janver

![janver logo](docs/assets/janver.png)

`janver` compares version numbers in Janet. It implements Debian version
ordering and Semantic Versioning 2.0.0 ordering as library functions, so it
can be used from Janet programs without imposing a command-line interface.

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

Import the module and call the comparator for the version format you need.
Comparators return a negative number when the first version sorts earlier, a
positive number when it sorts later, and zero when the versions are equal.

```janet
(import janver)

(janver/debian-vercmp "1.2.3~rc1" "1.2.3")
# => a negative number

(janver/semver2-vercmp "1.0.0-alpha" "1.0.0")
# => a negative number
```

`debian-vercmp` follows the [Debian Policy Manual section
5.6.12](https://www.debian.org/doc/debian-policy/ch-controlfields.html#version).
It supports an optional numeric epoch and Debian's special tilde ordering.
`semver2-vercmp` follows the [Semantic Versioning
2.0.0](https://semver.org/#semantic-versioning-200) precedence rules,
including numeric and alphanumeric pre-release identifiers. Build metadata
does not affect precedence.

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

The project is released as Git tags. The current release is `v0.2.0`.

## License

`janver` is released under the MIT License. See [LICENSE](LICENSE) for the
full text.

## The name

The name is a little coincidence: it sounds like “JANet VERsioning,” which
fits the library, but `janver` is really named for Johannes Vermeer, the
painter. The logo is inspired by a painting by Vermeer.
