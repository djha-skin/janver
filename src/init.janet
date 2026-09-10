# janver compatibility module.
#
# Implementations are available as janver/debian, janver/semver2,
# janver/maven, janver/ruby, and janver/pep440. The legacy names remain
# exported here.

(import ./debian :export true :prefix "debian-")
(import ./semver2 :export true :prefix "semver2-")
(import ./maven :export true :prefix "maven-")
(import ./ruby :export true :prefix "ruby-")
(import ./pep440 :export true :prefix "pep440-")
