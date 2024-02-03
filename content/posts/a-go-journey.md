---
title: "A Go Journey"
date: 2024-02-02T23:00:19+01:00
draft: false
tags: ['Go']
---

## Introduction
<!--start-summary-->

I began programming using Go three years ago with a background of backend web developer. Nowadays I am a software engineer spending most of its time writing Go code for a living — and for fun. This post aims to list the resources that helped me understand Go and write clean, efficient and secure programs.

Back when I discovered Go, several features of the language had piqued my interest: statically linked binaries, easy-to-use primitive for concurrency, composition over inheritance, implicit interfaces, and may be the most interesting: **Go is easy to learn, hard to master**. 

This last property highlights that Go was designed so that developers can quickly be productive using it. But of course, writing clean and efficient code means you need to understand the language primitives, idioms and sometimes, how things work under the hood.

<br>

## The basics

Before learning about style guidelines and optimizations techniques, one must know about a language primitives. I believe the following resources will help you grasp Go primitives and what can be accomplished using them. Coding along the various examples provided by these resources using the [Go playground](https://go.dev/play/) or you own environment is a really valuable learning opportunity.

- [Go by Example](https://gobyexample.com/), a website which offers a tour of from basics (e.g. slices, maps, structures) to more advanced features (e.g. concurrency, templating, testing).
- [Effective Go](https://go.dev/doc/effective_go), written by the Go team, this guide lays down advices to write clear and idiomatic code and highlight severals gotchas. This one is, in my opinion a must read if you are serious about learning Go.
- [Go Landmines](https://gist.github.com/lavalamp/4bd23295a9f32706a48f), a short list of three common mistakes that can trick beginners and hardened developers alike.[^1]
- [Let's Go](https://lets-go.alexedwards.net/), Alex Edward's book is a very good reading to learn how to build clean, efficient and secure web application.

<br>

## Guidelines 

Even-though Go is a language with several idioms, there is still room for interpretation. Guidelines can help you write code in a way that will maximize its readability and maintainability. The following links can enlighten you to achieve this.

- [Standard Go Project Layout](https://github.com/golang-standards/project-layout), though this layout is in no way official, you will find it in almost every sizable Go project, hence, it is highly recommended that you familiarize yourself with it.
- [Google Style Decisions](https://google.github.io/styleguide/go/decisions), by the company that brought Go in the first place, I strongly advise to read and follow these, especially if you intend to contribute to open-source Go projects such as Kubernetes. These guidelines cover lots of ground, from naming and documentation to which receiver type to use.
- [Uber Style Guide](https://github.com/uber-go/guide/blob/master/style.md), this guide covers frequent mistakes, style guidance and gives a few tips to simply enhance performance of your programs.

<br>

## Advanced understanding

You now know about the language's primitives, idioms, features and most common mistakes. Writing reliable code means that you must go the extra-miles and, sometimes, understand the language nuts and bolts. The books and talks bellow were conceived for that very purpose.

- [100 Go Mistakes and How to Avoid Them](https://www.manning.com/books/100-go-mistakes-and-how-to-avoid-them), my favorite resource in this post. Teiva Harsanyi's book is a must read for any serious Go developer. From common data types mistakes to advanced compiler and memory optimizations, this book has it all. Knowing these 100 mistakes will without a doubt make you a better Go developer.
- [research!rsc](https://research.swtch.com/), Russ Cox[^2] blog on programming, it contains several articles that give an insight on how Go is designed, be it the memory model or how are interfaces and structures modeled in memory.
- [Understanding nil](https://www.youtube.com/watch?v=ynoY2xz-F8s), this half an hour talk offers lots of valuable informations on of Go most special value.

<br>

## Staying up-to-date

Go is a rapidly evolving language with new features added to every new version. At the time I'm writing these lines, version 1.22 is in pre-release and, among other things, is fixing one of the most common mistakes[^1]. Being a software engineer also means knowing about what direction the language is taking and what new features are discussed. Bellow are two links to stay updated with how the Go ecosystem is evolving.

- [The Go Blog](https://go.dev/blog/), the official Go blog. This is where news about the language are published but there is more. You can also find articles detailing a specific feature of the language such as type parameters or structured logging.
- [Golang Weekly](https://golangweekly.com/), a weekly newsletter to stay updated about the ecosystem as well as the library and tools built in Go. I highly recommend subscribing to it.

<br>
<br>

Thank you for reading this post. I hope these resources can be as useful for you as they are for me.



[^1]: The first mistake regarding loop variables scoped outside the loop is [now fixed](https://go.dev/blog/loopvar-preview) in Go 1.22
[^2]: Russ Cox is a member of the Go development team.
