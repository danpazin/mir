# Rules for working on Mir

Mir is a Swift package that draws a globe with Metal. These rules apply to everyone who changes the code, people and coding agents alike.

## 1. Names and comments

Follow these guides. Where they disagree, the earlier one in the list wins.

1. Apple's [API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/), for names and for which declarations get a `///` comment: all of them.
2. Apple's [Writing Symbol Documentation in Your Source Files](https://www.swift.org/documentation/docc/writing-symbol-documentation-in-your-source-files), for how to write a `///` comment.
3. Google's [code review guide](https://google.github.io/eng-practices/review/reviewer/looking-for.html#comments), for `//` comments inside code: explain why, not what.

Names that are standard in the field may stay short, such as `fov`, `sin`, or `i` for a loop counter. Spell out everything else.
