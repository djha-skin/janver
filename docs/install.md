# Installation

## Install from GitHub

Install the current repository with jpm:

```sh
jpm install https://github.com/djha-skin/janver
```

Then import `janver` from a Janet program:

```janet
(import janver)
(assert (= 0 (janver/debian-vercmp "1.2.3" "1.2.3")))
```

## Build from source

Clone the repository and install its project-local dependencies:

```sh
git clone https://github.com/djha-skin/janver.git
cd janver
jpm -l deps
jpm -l build
```

The source module is `src/init.janet`; `declare-source` installs it under the
`janver` prefix. Use `jpm -l test` to run the project's test suite from a
working checkout.

## Requirements

You need Janet and jpm. The project dependencies are installed into
`jpm_tree/`, which is ignored by Git and does not need to be managed manually.
