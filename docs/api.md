# janver API

## src/debian

### vercmp

[Source](https://github.com/djha-skin/janver/blob/main/src/debian.janet#L182)

(vercmp a b)

Compares two version numbers according to the rules set forth in the Debian
Policy Manual.


### version

[Source](https://github.com/djha-skin/janver/blob/main/src/debian.janet#L7)

Parse a Debian version into its epoch and alternating non-numeric and
numeric parts.


## src/init

### debian-vercmp

[Source](src/debian.janet#L182)

(vercmp a b)

Compares two version numbers according to the rules set forth in the Debian
Policy Manual.


### debian-version

[Source](src/debian.janet#L7)

Parse a Debian version into its epoch and alternating non-numeric and
numeric parts.


### maven-vercmp

[Source](src/maven.janet#L188)

(vercmp a b)

Compare Maven versions according to Apache Maven ComparableVersion rules.


### maven-version

[Source](src/maven.janet#L7)

Tokens are tagged as :number, :text, or :separator. The parser keeps ASCII
digit runs separate from text and preserves dots and hyphens for the nested
Maven item builder.


### pep440-vercmp

[Source](src/pep440.janet#L498)

(vercmp a b)

Compare two version identifiers according to PEP 440. Invalid version
identifiers raise an error. Local version labels only affect ordering when
the public versions are otherwise equal.


### pep440-version

[Source](src/pep440.janet#L350)

Parse and normalize a Python PEP 440 version identifier. The result contains
epoch, release segments, pre-release, post-release, development-release, and
local-version components; decimal values remain strings for arbitrary length.


### ruby-vercmp

[Source](src/ruby.janet#L96)

(vercmp a b)

Compare RubyGems Gem::Version strings. Numeric segments are compared by
their decimal values, strings sort before numbers, prerelease strings sort
before release numbers, and insignificant trailing zero segments compare
equal. Invalid version strings raise an error.


### ruby-version

[Source](src/ruby.janet#L9)

Leading and trailing whitespace is accepted, as is an empty version (which
becomes zero). Hyphens are represented as the prerelease marker "pre".


### semver2-vercmp

[Source](src/semver2.janet#L93)

(vercmp a b)

Compare two version numbers according to the rules found at
https://semver.org/#semantic-versioning-200 .


### semver2-version

[Source](src/semver2.janet#L7)

Parse a Semantic Versioning 2.0.0 version into its core, pre-release, and
build metadata parts.


## src/maven

### vercmp

[Source](https://github.com/djha-skin/janver/blob/main/src/maven.janet#L188)

(vercmp a b)

Compare Maven versions according to Apache Maven ComparableVersion rules.


### version

[Source](https://github.com/djha-skin/janver/blob/main/src/maven.janet#L7)

Tokens are tagged as :number, :text, or :separator. The parser keeps ASCII
digit runs separate from text and preserves dots and hyphens for the nested
Maven item builder.


## src/pep440

### vercmp

[Source](https://github.com/djha-skin/janver/blob/main/src/pep440.janet#L498)

(vercmp a b)

Compare two version identifiers according to PEP 440. Invalid version
identifiers raise an error. Local version labels only affect ordering when
the public versions are otherwise equal.


### version

[Source](https://github.com/djha-skin/janver/blob/main/src/pep440.janet#L350)

Parse and normalize a Python PEP 440 version identifier. The result contains
epoch, release segments, pre-release, post-release, development-release, and
local-version components; decimal values remain strings for arbitrary length.


## src/ruby

### vercmp

[Source](https://github.com/djha-skin/janver/blob/main/src/ruby.janet#L96)

(vercmp a b)

Compare RubyGems Gem::Version strings. Numeric segments are compared by
their decimal values, strings sort before numbers, prerelease strings sort
before release numbers, and insignificant trailing zero segments compare
equal. Invalid version strings raise an error.


### version

[Source](https://github.com/djha-skin/janver/blob/main/src/ruby.janet#L9)

Leading and trailing whitespace is accepted, as is an empty version (which
becomes zero). Hyphens are represented as the prerelease marker "pre".


## src/semver2

### vercmp

[Source](https://github.com/djha-skin/janver/blob/main/src/semver2.janet#L93)

(vercmp a b)

Compare two version numbers according to the rules found at
https://semver.org/#semantic-versioning-200 .


### version

[Source](https://github.com/djha-skin/janver/blob/main/src/semver2.janet#L7)

Parse a Semantic Versioning 2.0.0 version into its core, pre-release, and
build metadata parts.


## src/utils

### numbers-compare

[Source](https://github.com/djha-skin/janver/blob/main/src/utils.janet#L5)
