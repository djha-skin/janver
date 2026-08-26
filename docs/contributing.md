# Contributing

Open a GitHub issue before starting a substantial change so the approach can
be discussed with the maintainers. Small typo fixes can go directly to a pull
request.

For a normal pull request:

- Base the branch on `main`.
- Add or update tests for behavior changes.
- Run `jpm -l deps` and `jpm -l test`.
- Regenerate the API reference with `jpm -l run doc`.
- Update relevant docstrings and Markdown pages.
- Add a changelog entry when the change is user-visible.
- Keep text files at 80 characters or fewer and check Janet parentheses.

The generated file `docs/api.md` comes from source docstrings. Edit the
source docstrings, then run the documentation task; do not edit the generated
API page by hand.

## Release process

The project version is declared in `project.janet`. A release updates that
version and `CHANGELOG.md`, regenerates the documentation, commits the
result, and creates a matching `v<version>` Git tag. Janet libraries are
consumed from Git repositories, so the tag is the release artifact.
