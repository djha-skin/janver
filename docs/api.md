# janver API

## src/init

[debian-vercmp](#debian-vercmp), [justify](#justify), [numbers-compare](#numbers-compare), [semver2](#semver2), [semver2-vercmp](#semver2-vercmp)

## debian-vercmp

**function**  | [source][1]

```janet
(debian-vercmp a b)
```



[1]: https://github.com/djha-skin/janver/blob/main/src/init.janet#L206


## justify

**function**  | [source][2]

```janet
(justify a b)
```

Ensures both arrays of strings have the same number of elements

[2]: https://github.com/djha-skin/janver/blob/main/src/init.janet#L179


## numbers-compare

**function**  | [source][3]

```janet
(numbers-compare a b)
```



[3]: https://github.com/djha-skin/janver/blob/main/src/init.janet#L57


## semver2

**core/peg**  | [source][4]

```janet
<core/peg 0x00000AC29330>
```


[4]: https://github.com/djha-skin/janver/blob/main/src/init.janet#L262


## semver2-vercmp

**function**  | [source][5]

```janet
(semver2-vercmp a b)
```

Compare two version numbers according to the rules found at
https://semver.org/#semantic-versioning-200 .

[5]: https://github.com/djha-skin/janver/blob/main/src/init.janet#L344

