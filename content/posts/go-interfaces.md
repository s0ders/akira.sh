---
title: "Interfaces in Go"
date: 2024-02-19T00:59:58+01:00
draft: false
tags: ['Go']
---
# Introduction 

<!--start-summary-->
Go treats interfaces differently from other languages that implement them. Knowledge about them is scattered across various posts and books, this post tries to group in a single place[^1] what developers need to know to be comfortable using interfaces in Go: when to use them, how are they modeled in memory and what are the most common mistakes when using them.

<br>

# Basics

To quote [Effective Go](https://go.dev/doc/effective_go#interfaces_and_types) "interfaces in Go provide a way to specify the behavior of an object: if it can do *this*, then it can be used *here*", meaning that interfaces are satisfied implicitly so structures need not any `implement` keyword to signal that they implement an interface.

Let's dive into this topic using two common interfaces in Go as examples, `io.Reader` and `io.Writer`.

```go
// Writer takes a slice of bytes p and write it to the underlying data stream.
type Writer interface {
	Write(p []byte) (n int, err error)
}

// Reader populate a slice of bytes p using the underlying data stream.
type Reader interface {
	Read(p []byte) (n int, err error)
}
```

You may notice an idiom in Go with interfaces, they are very often named using an *-er* suffix. Another idiomatic way of manipulating interfaces is to keep them small: "*the bigger the interface, the weaker the abstraction*".

Going back to `io.Reader` and `io.Writer`, whether a program wants to read/write to a file or an HTTP request/response, it will end up using one of these. Hence, it is a good idea to follow the [Liskov's substitution principle](https://en.wikipedia.org/wiki/Liskov_substitution_principle). For instance, instead of accepting a file path as a function parameter to read from said file, the function should accept an `io.Reader` directly.

This small change makes the function more generic so that it may be reused in the future and also allows for easier testing by simplifying the creation of mocks as demonstrated bellow.

```go
// Uppercase reads from a stream and returns all data in uppercase.
func Uppercase(r io.Reader) ([]byte, error) {
    b, err := io.ReadAll(r)
    if err != nil {
        return nil, err
    }
    
    return bytes.ToUpper(b), nil
}

// Here we use "strings.NewReader" to mock any concrete 
// implementation of io.Reader.
func TestUppercase(t *testing.T) {
    r := strings.NewReader("foo")
    want := "FOO"
    
    got, err := Uppercase(r)
    if err != nil {
        t.Fatal(err)
    }
    
    // Convert []byte to string since equality is not directly
    // defined for slice
    if string(got) != want {
        t.Errorf("got %q, want %q", got, want)
    }
}
```

It is possible to combine multiple interfaces together when it makes sens by embedding them. Common examples are `io.ReadWritter` or `io.ReadCloser`.

```go
type ReadCloser interface {
	Reader
	Closer
}
```

Sometimes a program might need to access an interface underlying value. Doing so is called a *type assertion*, the "comma ok" idiom and type switches are two methods to achieve that. Type assertion is not limited to concrete types and can also be used to check if an interface underlying value implements other interfaces.

```go
// "any" is an alias for "interface{}" which matches 
// everything  since it defines no function at all.
var foo any = 1

// "comma ok" idiom
intFoo, ok := foo.(int)
if ok {
    fmt.Println("foo is an int")
}

// type switch
switch foo.(type) {
case int:
    fmt.Println("foo is an int")
case float64:
    fmt.Println("foo is float64")
default:
    fmt.Printf("unknown type %T", foo)
}
```

Another interesting feature brought by interface in Go is that they allow to restrict the behavior of the underlying type. We will discuss how this is achieved in the next section.

<br>

# Under the hood

Russ Cox's [post](https://research.swtch.com/interfaces) goes into the details of interfaces implementation in Go. Let's summarize the important bits that will help understand the most common mistakes.

Interfaces are modeled as a two-word data structure:

- The first word points to an interface table, or "itable", which holds the underlying concrete type and pointers to the associated functions for that interface. 
- The second word points to the actual value of that interface.

To illustrate this, let's take the example of a simple interface, `Stringer`. It is defined in the `fmt` package, and is used to print values passed to the various print functions defined in the package.

```go
type Stringer interface {
	String() string
}

type CustomInt int

// CustomInt implements the Stringer interface
func (c CustomInt) String() string {
    return strconv.Itoa(c)
}

var foo Stringer = CustomInt(1)
```

Behind the scenes, the `Stringer` interface in `foo` is stored as depicted below, where arrows symbolize pointers.

![Interface memory model](itable_v2.webp)

Now that we understand how interfaces are modeled, we can understand the followings:

- Type assertion on an interface is done by checking the asserted type against the one stored in the interface table.

- Interfaces restrict the underlying types behavior because they only have pointers to the methods used to satisfy the interface, the ones stored in the interface table. Type assertion is a way to lift these restrictions by getting a copy of the underlying value which is either not restricted at all, in the case of an assertion to a concrete type, or has different restrictions in the case of an assertion to another interface.

- Interfaces are equal to `nil` only if both value and type are `nil`.

<br>

# Common mistakes

## When `nil` is not equal to `nil`

The fact that an interface is only equal to `nil` only when both its type and value are `nil` can lead to tricky errors when wrapping `nil` pointers. Indeed, the type contained by the interface will be a pointer and, even though the value of the interface is `nil`, the interface itself won't be and this can lead to the following problem.

```go
type customError struct {
    Message string
}

// customError implements the Error interface
func (c *customError) Error() string {
    return c.Message
}

// "error" interface wraps the nil pointer *customError
func foo() error {
    var err *customError
    // err has its default value, nil
    return err 
}

// Here we avoid the mistake of wrapping a nil pointer
// by directly returning nil if there the pointer is nil
func betterFoo() error {
    var err *customError

    if err != nil {
        return err
    }

    return nil
}

func main() {
    err := foo()
    // This will always be triggered because "error" is an interface
    // wrapping pointer and even though the pointer is nil, the interface
    // type is not so the interface is not nil.
    if err != nil {
        panic(err)
    }

    err = betterFoo()
    // betterFoo returned nil, so this will not be triggered.
    if err != nil {
        panic(err)
    }
}

```

The solution to this issue is to directly return `nil` and not an interface wrapping a `nil` pointer as done in the `betterFoo` function.



## Using values with pointer-receiver methods

To understand this mistake, we must first understand two things: what methods a type has access to and *addressability*.

A type *T has access to both pointer-receiver methods and value methods, this is because for value methods, a pointer can always be dereferenced to access the value it points to. On the other hand, a type T only has access to value-receiver methods. The catch is that the language allows for values which are *addressable* to use pointer-receiver methods transparently, in which case the runtime simply get the address of that value. 

But not all values are addressable, meaning the runtime cannot get the address of every values. Some notably *unaddressable* values are: interface values and map values. The reason behind this inability to get the values' addresses depend for every type. For maps, it is because the values might get rearranged during the program lifetime so their addresses might change. For interfaces, it is because passing the underlying value's address to a pointer-receiver method might lead to the value being changed which would cause inconsistency if the value no longer matches the type stored in the interface.

```go
type Incrementer interface {
    Increment()
}

type A struct {
    i int
}

func (a *A) Increment() {
    a.i++
}

func Foo(i Incrementer) {
    i.Increment()
}

func main() {
    a := A{i: 0}
    // This will fail with the following error:
    // "A does not implement Incrementer (method Increment has a pointer receiver)"
    Foo(a)
    // A possible workaround is to pass a pointer
    Foo(&a)
    // Another one is to directly store a pointer to the structure
    pA := &A{i: 0}
    Foo(pA)
}
```



## Not checking interface compliance

Most interface checks are done at compile time, the compiler knows what value is passed to a function expecting an interface, and if the value does not satisfies the interface, the program will not compile. However, there are certain situations in which the compiler does not know the value ahead of time and the check will have to happen at run-time and, if the check fail, the program will panic.

To avoid these run-time checks and, when it is necessary to guarantee within a package implementing a type that this type satisfies an interface, you can do the following:

```go
// Replace `io.Writer` with the interface you need to ensure compliance
// with, and `customType` with the type to be checked.
var _ io.Writer = (*customType)(nil)
```

Here the blank identifier is used to create an unallocated variable with an interface type. Then, a `nil` pointer of the type that needs checking is created and affected to that interface type. This method allows for interface static check and has no impact on memory since the variable is never allocated thanks to the blank identifier, and neither is the pointer since it is `nil`.



## Defining interfaces on the producer side

This one is more a design mistakes than a technical one and is very well explained in [100 Go Mistakes and How to Avoid Them](https://www.manning.com/books/100-go-mistakes-and-how-to-avoid-them). 

When manipulating packages and modules, we distinguish between the producer side, where the imported code lives, and the customer sides, where the imported code is used. Defining interfaces on the producer side is considered a bad practice since you force your abstraction upon customers, abstraction that they might not need which goes against the [interface segregation principle](https://en.wikipedia.org/wiki/Interface_segregation_principle). Below is a simple example of defining an interface of the producer side which create a useless abstraction for any customer of that package.

```go
package producer

type Vehicle interface {
    Start()
    Stop()
    Refill()
}

type ThermalCar struct {}

func (t ThermalCar) Start() {}
func (t ThermalCar) Stop() {}
func (t ThermalCar) Refill() {}
```

```go
package customer

// ElectricCar does not implement the producer `Vehicle` interface
// since it uses `Charge` instead of `Refill`, making the producer
// interface useless.

type ElectricCar struct {}

func (e ElectricCar) Start() {}
func (e ElectricCar) Stop() {}
func (e ElectricCar) Charge() {}
```

Rare exceptions to this rules are when the language team foresee interfaces are very generic and useful for most programs such as `io.Writer` or `io.Reader`. Let's remember that *"abstraction should be discovered, not created"*.

<br>

# Conclusion

Thank you for reading this post. I hope you learned a few things, if this is the case, please share it with whoever you think might be interested.

This following sources helped in the writing of this post:

- [100 Go Mistakes and How to Avoid Them](https://www.manning.com/books/100-go-mistakes-and-how-to-avoid-them), T. Harsanyi

- [Go Data Structures: Interfaces](https://research.swtch.com/interfaces), R. Cox

- [Understanding nil](https://www.youtube.com/watch?v=ynoY2xz-F8s), F. Campoy

[^1]: [Relevant XKCD](https://xkcd.com/927/)
