---
title: "Constants in Go"
date: 2024-11-07T12:28:34+02:00
draft: false
tags: ['Go']
---
# Introduction
<!--start-summary-->

Go is a statically typed language, meaning that you cannot mix and match different numeric types for instance.  Yet, the following snippet is valid code  `math.Pow(2, 16)` even though `math.Pow` expects `float64` parameters.

Another feature of the language is that operations with numeric scalar values are more precise than operations with variables. For instance, the issue due to floating point number approximation due to [IEEE 754](https://en.wikipedia.org/wiki/IEEE_754)[^1] might not appear, for instance `x := 0.1 + 0.2` is equal to `0.3` and not something along the lines of `0.30000000000000004`. 

These two features are a consequence of how Go treats constants, so let's dive in and understand how constants are implemented in Go.



# Terminology

In Go a constant can be defined using the `const` keyword. Constants can only hold scalar values - understand "primitive types" - such as `1`, `3.14`, `true` or `Hello world`. These values are called "constants" in the context of Go.

These constants, such as `3.14`, can be assigned to variables. They will remain constants but the variable value itself can be changed. Let's take the following variable for instance, `pi := 3.14`, if you update `pi` you will update its value not `3.14` which is why it is said that `3.14` is a constant, it cannot be changed to something else.



# Type conversion

You may be wondering what does type conversion has to do with constants but it's an important piece of the puzzle to understand why constant types are designed the way they are so bear with me for the next few lines.

The introduction stated that, since Go is statically typed, numeric types cannot be mixed and match. That does not mean operations cannot be performed with the value they hold, an `int32` can't be added to an `int64` yet we can still add their values using *conversion*. 

Type conversion, which is not to be confused with *[type assertion](https://go.dev/ref/spec#Type_assertions)*, is the process of changing an expression to a type specified by the conversion:

```go
var foo int64 = 2
var bar int32 = 3

// "bar" value is converted to an int64 value, yet the "bar" variable
// is still of type int32.
result := foo * int64(bar)
```

For a conversion to work, the [Go specification](https://go.dev/ref/spec#Conversions) states that “value `x` can be converted to type `T` if `x` is *representable* by a value of `T`”. What is representability then ?  

Let's refer to the [specification](https://go.dev/ref/spec#Representability) once more: "a constant `x` is representable by a value of type `T` [...] if one of the following conditions applies: `x` is in the set of values determined by `T`, `T` is a floating-point type and `x` can be rounded to `T`'s precision without overflow, `T` is a complex type, and `x`'s components `real(x)` and `imag(x)` are representable by values of `T`'s component type (`float32` or `float64`)."

In Layman's terms, the first constraint states that for a value to be converted to a certain type, it must belong to the type value set, for instance `-1` cannot be converted to an `uint` since unsigned integers' value set does not contain negative integers. 

The second constraints states a constant value can be converted to a `float32` or `float64` if it the value fits within the type range. For instance, IEEE 754 double precision, or `float64`, has a value range of around `[-1.8e308, 1.8e308]`, hence, anything that does not fit in that range can't be converted to a `float64` or else it will cause an overflow. 

The third constraints regarding complex types is self explanatory if you ever worked with complex numbers so I won't dwell on it.



# Constant types

When you assign a constant to a variable such as `i := 0`, you may wonder how the compiler decides which type `i` is. We may be very explicit about it and use conversion such as `i := int64(0)` but decorating your code with conversions everywhere would feel a bit clumsy.

It turns out that constant have a *default type*, for string and boolean constant it is pretty obvious but what about numeric constants ? Since there is more variety, their default type is determined by the syntax: `1` default type is `int`, `3.14` is `float64` and `0i` is `complex128`.

So how come the following code is valid ? Since `1` is a numeric constant with its default type being `int` it should not be able to be assigned to `CustomInt`.

```go
type CustomInt int

var i CustomInt = 1
```

That's because `1` is actually an *untyped* numeric constant whose default type is `int` unless another one in which it can be represented is specified.

Constants can nonetheless be typed as shown below in which case they can no longer be assigned to an other type without conversion:

```go
const i int = 1

// Not allowed
var foo CustomInt = i
// Allowed
var bar CustomInt = CustomInt(i)
```

To recap, until they are typed, constants live a more flexible type space and can be assigned more freely to a type in which they can be represented.



# Range of values

Let's now understand why computation with numeric constants is more precise than with typed variables. If we read the [Go specification](https://go.dev/ref/spec#Constants) section on constants we understand that "numeric constants represent exact values of arbitrary precision and do not overflow". What does *arbitrary precision* means ? It means that the Go specification does not dictate precisely how many bits a compiler must use to store numeric constants though there are some lower bounds. Every implementation must:

- Represent integer constants with *at least* 256 bits
- Represent floating-point constants, including the parts of a complex constant, with a mantissa of at least 256 bits and a signed binary exponent of at least 16 bits.

So if we consider integer constants, they have a minimum precision of 256 bits where `int` variable have a maximum precision of 64 bits.  The code below illustrate how floating point numbers computation is more precision using constants and can help avoid overflows:

```go
// Allowed
bigNumber := 1e999 / 1e998 // bigNumber == 10

// Not allowed, overflow
var x = 1e999
var y = 1e998
var z = x / y
```

This explains why computation of numeric constants is more precise until the value is assigned to a typed variable and how we can work with bigger numbers.



# Conclusion

Let's finish this post by answering the two questions raised in the introduction now that we understand how constants work in Go.

If `math.Pow(2, 16)` is valid, it's because `2` and `16` are *untyped numeric constants* and can be converted to `float64` since they can be represented as such a type.

The value of `x := 0.1 + 0.2` is precisely `0.3` because `0.1` and `0.2` are numeric constants that live in an *arbitrary precision space* of a minimum of 256 bits until they are assigned to a variable which is why computation is more precise and less prone to approximation.

That's it ! I hope you learned a few things with this small post, if you did, please share it to whoever you think might also be interested and if you want more details I invite you to read the Go specification.


[^1]: Long story short, IEEE 754 is a standard that define how to store number whose values can be infinitely precise in finite memory which is done using approximation, hence why 0.1 + 0.2 is not equal to 0.3 when using this standard.
