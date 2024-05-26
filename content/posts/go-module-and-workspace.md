---
title: "Go Modules and Workspace"
date: 2024-05-23T23:03:00+01:00
draft: false
tags: ['Go']
---
# Introduction
<!--start-summary-->

Go 1.11 introduced the concept of modules which are now the standard way for Go developers to manage dependencies. Later on, Go 1.18 introduced the concept of workspaces to work locally with multiple modules simultaneously. This post tries to introduces both of these concepts while explaining the tips and tricks to maximize the benefits they offer.



# Modules

Though the Go standard is known to be pretty thorough and robust, a Go project might need to use external dependencies at some point. To do so, the project needs to be a module. A module is created by running `go mod init <module_path>` at the root of the module's directory. 

First, let's explain what is a module path. It's the canonical name for a module





The `go` command offers a subset of commands to work with modules:






# Workspace





# References

- [Go Modules Reference](https://go.dev/ref/mod#module-path)