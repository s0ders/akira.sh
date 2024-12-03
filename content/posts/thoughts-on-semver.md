---
title: "Thoughts on Semantic Versioning"
date: 2024-09-29T12:01:36+02:00
draft: true
---

# Introduction

Semantic Versioning, often abbreviated SemVer, is a system to version public APIs (e.g., packages, libraries) that tries to avoid the [dependency hell](https://en.wikipedia.org/wiki/Dependency_hell) problem that arise when dealing with software project's multiple dependencies.

This specification brings a set of rule that, when followed by the project and its dependencies, reduce the risks of falling into the dependency hell problem and allows for human to quickly know what changed between two versions by taking a look at the two version numbers. It is assumed here that the reader is aware of the SemVer specification basic set of rules, otherwise they can be found on [their website](https://semver.org/spec/v2.0.0.html), it is a quick read.



> Under this scheme, version numbers and the way they change convey meaning about the underlying code and what has been modified from one version to the next. ― https://semver.org



My main issue with this scheme is that I wanted to automate the versioning process. Because humans are not machines, they make mistake and automation can help with reducing these. Before going on with the software I came up with to automate Semantic Versioning, let's discuss the limitations of that scheme.



Content:

- Dependency mgmt = depending on code you do not control
- Dependencies can end up forming large network (direct and transitive dependencies)

- Dependency mgmt issues: how to describe versions ? what changes are allowed ? how to decide when upgrading is wise ?

- Diamond dependencies problem
- 

# Limitations

In the book [Software Engineering at Google](https://www.oreilly.com/library/view/software-engineering-at/9781492082781/), Titus Winter points the limitations of Semantic Versioning.

First, it might overpromise: 





- Over promise (human error, Hirum law)
- Over constraints (lack of fine-grained API, major bump for Foo() does not affect Bar() clients)

- Major version are not sacred: https://tom.preston-werner.com/2022/05/23/major-version-numbers-are-not-sacred

# Proposed enhancement

- Go Semver Release
- Compare features VS Semantic Release
- Benchmark Go Semver Release VS Semantic Release





## Sources

- https://semver.org/spec/v2.0.0.html
- https://en.wikipedia.org/wiki/Dependency_hell
- https://tom.preston-werner.com/2022/05/23/major-version-numbers-are-not-sacred
- 
