# janver API

## janver/debian

### vercmp

[Source](https://github.com/djha-skin/janver/blob/main/src/debian.janet#L182)

(vercmp a b)

Compares two version numbers according to the rules set forth in the Debian
Policy Manual.


### version

[Source](https://github.com/djha-skin/janver/blob/main/src/debian.janet#L7)

Parse a Debian version into its epoch and alternating non-numeric and
numeric parts.


## janver/maven

### vercmp

[Source](https://github.com/djha-skin/janver/blob/main/src/maven.janet#L188)

(vercmp a b)

Compare Maven versions according to Apache Maven ComparableVersion rules.


### version

[Source](https://github.com/djha-skin/janver/blob/main/src/maven.janet#L7)

Tokens are tagged as :number, :text, or :separator. The parser keeps ASCII
digit runs separate from text and preserves dots and hyphens for the nested
Maven item builder.


## janver/ruby

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


## janver/semver2

### vercmp

[Source](https://github.com/djha-skin/janver/blob/main/src/semver2.janet#L93)

(vercmp a b)

Compare two version numbers according to the rules found at
https://semver.org/#semantic-versioning-200 .


### version

[Source](https://github.com/djha-skin/janver/blob/main/src/semver2.janet#L7)

Parse a Semantic Versioning 2.0.0 version into its core, pre-release, and
build metadata parts.


## janver/utils

### numbers-compare

[Source](https://github.com/djha-skin/janver/blob/main/src/utils.janet#L5)

Compares two strings as if they are numbers. The strings must only contain
characters ranging from 0-9 or none at all. The empty string is considered as
the zero value.
