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


### maven-vercmp

[Source](https://github.com/djha-skin/janver/blob/main/src/init.janet#L610)

(maven-vercmp a b)

Compare Maven versions according to Apache Maven ComparableVersion rules.


### maven-version

[Source](https://github.com/djha-skin/janver/blob/main/src/init.janet#L429)

Tokens are tagged as :number, :text, or :separator. The parser keeps ASCII
digit runs separate from text and preserves dots and hyphens for the nested
Maven item builder.


### ruby-vercmp

[Source](https://github.com/djha-skin/janver/blob/main/src/init.janet#L710)

(ruby-vercmp a b)

Compare RubyGems Gem::Version strings. Numeric segments are compared by
their decimal values, strings sort before numbers, prerelease strings sort
before release numbers, and insignificant trailing zero segments compare
equal. Invalid version strings raise an error.


### ruby-version

[Source](https://github.com/djha-skin/janver/blob/main/src/init.janet#L623)

Leading and trailing whitespace is accepted, as is an empty version (which
becomes zero). Hyphens are represented as the prerelease marker "pre".


### semver2

[Source](https://github.com/djha-skin/janver/blob/main/src/init.janet#L269)

Parse a Semantic Versioning 2.0.0 version into its core, pre-release, and
build metadata parts.


### semver2-vercmp

[Source](https://github.com/djha-skin/janver/blob/main/src/init.janet#L355)

(semver2-vercmp a b)

Compare two version numbers according to the rules found at
https://semver.org/#semantic-versioning-200 .

