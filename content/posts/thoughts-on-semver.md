---
title: "Thoughts on Semantic Versioning"
date: 2024-05-27T14:30:36+02:00
draft: true
---

# Introduction

Semantic Versioning, or [SemVer](https://semver.org/spec/v2.0.0.html), is an attempt at solving the issues brought by dependency managements.



Content:

- Dependency mgmt = depending on code you do not control
- Dependencies can end up forming large network (direct and transitive dependencies)

- Dependency mgmt issues: how to describe versions ? what changes are allowed ? how to decide when upgrading is wise ?

- Diamond dependencies problem
- 

# Limitations

- Over promise (human error, hirum law)
- Over constraints (lack of fine grained API, major bump for Foo() does not affect Bar() clients)



# Reducing human interactions

- Go Semver Release



# Conclusion

