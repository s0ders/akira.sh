---
title: "Constants in Go"
date: 2024-11-07T12:28:34+02:00
draft: false
tags: ['Go']
---
# Introduction
<!--start-summary-->

Go is a statically typed language, and because of that, different numeric types cannot be mixed and matched. Yet, the following snippet is valid code  `math.Pow(2, 16)` even though the parameters should be of type `float64`.

Another strange feature is that operations with numeric scalar values are much more precise than operations with variables. 

For instance, the floating point number approximation due to [IEEE 754](https://en.wikipedia.org/wiki/IEEE_754)[^1] might not appear. Here, `x := 0.1 + 0.2` is equal to `0.3` and not something along the lines of `0.30000000000000004`. 

These two features are a consequence of how Go treats constants, so let's dive in and understand how they are implemented.

# Terminology

In Go, a constant can be defined using the `const` keyword and can only hold scalar values — understand "primitive types" — such as `1`, `3.14`, `true` or `"Hello world"`. 

These values are called *constants* in the context of Go and they can be assigned to variables. 

They will remain constants but the variable value itself can be changed. Let's take the variable `pi := 3.14`, updating it will change its value not `3.14`. That is why it is said that `3.14` is a constant: it cannot be changed to something else.

# Type conversion

The introduction stated that, since Go is statically typed, numeric types cannot be mixed and matched. That does not mean operations can't be performed with the values they hold, an `int32` can't be added to an `int64` yet we may still add their values using *conversion*. 

Type conversion, which is not to be confused with **[type assertion](https://go.dev/ref/spec#Type_assertions)**, is the process of changing an expression to a type specified by the conversion:

```go
var foo int64 = 2
var bar int32 = 3

// "bar" value is converted to an int64 value, yet the "bar" variable
// is still of type int32.
result := foo * int64(bar)
```

For a conversion to work, the [Go specification](https://go.dev/ref/spec#Conversions) states that “value `x` can be converted to type `T` if `x` is **representable** by a value of `T`”. 

What is representability then ?  

Let's refer to the [specification](https://go.dev/ref/spec#Representability) once more: 

> A constant `x` is representable by a value of type `T` [...] if one of the following conditions applies: `x` is in the set of values determined by `T`, `T` is a floating-point type and `x` can be rounded to `T`'s precision without overflow, `T` is a complex type, and `x`'s components `real(x)` and `imag(x)` are representable by values of `T`'s component type (`float32` or `float64`).

In Layman's terms, the first constraint states that for a value to be converted to a certain type, it must belong to the type value set. For instance `-1` cannot be converted to an `uint64` since unsigned integers' value set does not contain negative integers. 

The second constraints states that a constant value can be converted to a `float32` or `float64` if the value fits within the type range. 

For example, `float64` type has a value range of roughly `[-1.8e308, 1.8e308]`. Hence, anything that doesn't fit into that range can't be converted to a `float64` or it would overflow. 

The third constraint regarding complex types is self explanatory if you ever worked with complex numbers so I won't dwell on it.

# Constant types

When a constant is assigned to a variable such as `i := 0`, you may wonder how does the compiler decide which type `i` is. We may be very explicit about it and use conversion such as `i := int64(0)` but decorating your code with conversions everywhere would feel a bit clumsy.

It turns out that constant have a **default type**.

For string and boolean constant the default type is pretty obvious but what about numeric constants ? 

Since there is more variety, their default type is determined by their syntax: integer constant default type is `int`, floating point is `float64`, imaginary is `complex128` and rune is `rune`.

So why is the code below valid ? 
```go
type CustomInt int

var i CustomInt = 1
```
Since `1` is a numeric constant with its default type being `int` it should not be able to be assigned to `CustomInt`, right ?

Well `1` is actually an **untyped** numeric constant whose default type is `int` unless another one, in which it can be represented, is specified.

Constants can nonetheless be typed as shown below. In which case they can no longer be assigned to an other type without conversion:

```go
const i int = 1

// Not allowed
var foo CustomInt = i
// Allowed
var bar CustomInt = CustomInt(i)
// Allowed
var baz CustomInt = 1
```

To recap, until they are typed, constants live a more flexible type space and can be assigned more freely to a type in which they can be represented.

# Range of values

Let's now understand why computation with numeric constants is more precise than with typed variables. If we read the [Go specification](https://go.dev/ref/spec#Constants) section on constants we understand that "numeric constants represent exact values of arbitrary precision and do not overflow". 

What does **arbitrary precision** means ? 

It means that the Go specification does not dictate precisely how many bits a compiler must use to store numeric constants though there are some lower bounds. Every implementation must:

- Represent integer constants with *at least* 256 bits
- Represent floating-point constants, including the parts of a complex constant, with a mantissa of at least 256 bits and a signed binary exponent of at least 16 bits.

If we consider integer constants, they have a minimum precision of 256 bits whereas `int` variable have a maximum precision of 64 bits. 

There is a huge gap in terms of precision and the same goes for floating point numbers as shown below. Constants can hold much larger numbers and are less prone to approximations.

```go
// Allowed
bigNumber := 1e999 / 1e998 // bigNumber == 10

// Not allowed, overflow
var x = 1e999
var y = 1e998
var z = x / y
```

This explains why computation with numeric constants is more precise until the value is assigned to a typed variable.

# Conclusion

Let's finish by answering the two questions raised in the introduction now that we understand how constants work in Go.

If `math.Pow(2, 16)` is valid, it is because `2` and `16` are **untyped numeric constants** and can be converted to `float64` since they are representable as such a type.

The value of `x := 0.1 + 0.2` is precisely `0.3` because `0.1` and `0.2` are numeric constants that live in an *arbitrary precision space* of a minimum of 256 bits until they are assigned to a variable. That's why computation is more precise and less prone to approximation.

That's it. I hope you learned a few things with this post. If you did, please share it to whoever you think might also be interested. 

For more details I invite you to read the Go specification.


[^1]: Long story short, IEEE 754 is a standard that defines how to store numbers whose values can be infinitely precise in finite memory which is done using approximation, hence why 0.1 + 0.2 is not equal to 0.3 when using this standard.
