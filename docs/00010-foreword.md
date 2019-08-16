---
title: Production Breakpoints
author: Dale Hamel
header-includes: |
    \usepackage{fvextra}
    \DefineVerbatimEnvironment{Highlighting}{Verbatim}{breaklines,commandchars=\\\{\}}
---

This document is also available in [epub](./output/doc.epub) and [pdf](./output/doc.pdf) format if you prefer.

# Status

- Still very much under heavy development and experimentation
- Shifted direction to be tied to Ruby TracePoints
- Original implementation tied to eval to re-interpret method code is still
more functional, but less practical for production use.
