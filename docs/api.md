# janver API

## src/init

### debian-vercmp

[Source](https://github.com/djha-skin/janver/blob/main/src/init.janet#L210)

(debian-vercmp a b)

Compares two version numbers according to the rules set forth in the Debian
Policy Manual.


### debian-version

[Source](https://github.com/djha-skin/janver/blob/main/src/init.janet#L7)

Parse a Debian version into its epoch and alternating non-numeric and
numeric parts.


### semver2

[Source](https://github.com/djha-skin/janver/blob/main/src/init.janet#L269)

Parse a Semantic Versioning 2.0.0 version into its core, pre-release, and
build metadata parts.


### semver2-vercmp

[Source](https://github.com/djha-skin/janver/blob/main/src/init.janet#L355)

(semver2-vercmp a b)

Compare two version numbers according to the rules found at
https://semver.org/#semantic-versioning-200 .

