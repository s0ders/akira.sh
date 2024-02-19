---
title: "Interfaces in Go"
date: 2024-02-19T00:59:58+01:00
draft: true
tags: ['Go']
---
# Introduction 

<!--start-summary-->
Go treats interfaces very differently from other languages that implement them. Knowledge about them is scattered across various blog posts and books, this article aims to be a single resource[^1] to understand interfaces in the context of Go: when to use them, how are they modeled in memory and what are the most common mistakes when using them.

# Basics

To quote [Effective Go](https://go.dev/doc/effective_go#interfaces_and_types) "interfaces in Go provide a way to specify the behavior of an object: if it can do *this*, then it can be used *here*", meaning that interfaces are satisfied implicitly so structures need not any `implement` keyword to signal that they implement an interface.

Let's better dive into this topic using as examples two ubiquitous interfaces in Go, `io.Reader` and `io.Writer`.

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

You may notice a common idiom in Go with interfaces, they are very often named using an *-er* suffix. Another idiomatic way of manipulating interfaces is to keep them small: "*the bigger the interface, the weaker the abstraction*".

Going back to `io.Reader` and `io.Writer`, whether a program wants to read/write to a file or an HTTP request/response, it will end up using one of these. Hence, it is a good idea to follow the [Liskov's substitution principle](https://en.wikipedia.org/wiki/Liskov_substitution_principle). For instance, instead of accepting a file path as a function parameter to read from said file, the function should accept an `io.Reader` directly.

This small change makes the function more generic so that it may be reused in the future and it also allows for easier testing by simplifying the creation of mocks as demonstrated bellow.

```go
// Uppercase reads from a stream and returns all data in uppercase.
func Uppercase(r io.Reader) ([]byte, err) {
    buf := new(bytes.Buffer)
    _, err := r.Read(buf)
    if err != nil {
        return nil, err
    }
    
    return bytes.ToUpper(buf), nil
}

// Here we use "strings.NewReader" to easily mock any actual implementation
// of io.Reader. To mock an io.Writer, you can use a bytes.Buffer.
func TestUppercase(t *testing.T) {
    foo := strings.NewReader("foo")
    want := []byte("FOO")
    
    got, err := Uppercase([]byte(foo))
    if err != nil {
        t.Fatal(err)
    }
    
    if got != want {
        t.Errorf("got %q, want %q", got, want)
    }
}
```

It's possible to combine multiple interfaces together when it makes sens. Common examples are `io.ReadWritter` or `io.ReadCloser`.

```go
// To combine interfaces, simply create a new one embedding the existing ones.
type ReadCloser interface {
	Reader
	Closer
}
```

Sometimes a program might need to access an interface underlying value. The "comma ok" idiom and type switches are two methods to achieve that.

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
    fmt.Println("type unknown")
}
```

Though the implementation differs from other languages, Go interfaces provide the same benefits: define abstractions for common behavior (e.g. writing to a data stream) which allows for loose coupling between functions and their parameters which then brings several benefits (i.e. reusability, easier testing). There is another feature provided by interfaces that we haven't yet mentioned: they allow to limit the behavior on the underlying type.



# Under the hood

Russ Cox's [post](https://research.swtch.com/interfaces) goes into the details of interfaces implementation in Go. Let's summarize the important bits that will help understand the most common mistakes.

Interfaces are modeled as a two-word data structure:

- The first word points to an interface table, or "itable", which holds the underlying concrete type and pointers to the associated functions for that interface. The second word points to the actual value of that interface.

To illustrate this, let's take the example of a simple interface, `Stringer`. It is defined in the `fmt` package, and is used to print values passed to the various print functions in the package.

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
fmt.Println(foo)
```

Behind the scenes, the `Stringer` interface in `foo` is stored as depicted below where arrows symbolize pointers.

<object data="itable.svg" type="image/svg+xml">
  <img src="itable.png" />
</object>

Now that we understand how interfaces are modeled, we know why:

First, whenever you try to assert the concrete type of an interface using the "comma ok" idiom or a type switch, the runtime checks if the type you are asserting matches the one stored in the itable.

Second, using interfaces allows to restrict the behavior of the underlying concrete type because the interface's itable only has access to the functions defined by the interface. One way to overcome this is to dynamically check if the interface value implements other interfaces as depicted bellow.

```go
// bytes.Buffer implement the Writer interface and Stringer
foo := new(bytes.Buffer)

func bar(f Stringer) {
    w, ok := f.(Writer)
    if ok {
        // "w" now contains a Writer interface and is not limited
        // by the "String" method.s
    }
}
```

Finally, and this is very important, an interface will only be considered `nil` if both its value and type are `nil`.



# Common mistakes

#### 1. `nil` error not equal to `nil`

Since an interface is only considered `nil` when both its type and value are `nil`. Returning 

<br>

#### 2. Using pointer-receiver methods with value

Aka interface value not addressable

<br>

#### 3. Defining interfaces on the producer side

This one is more a design mistakes than a technical one and is very well explained in [100 Go Mistakes and How to Avoid Them](https://www.manning.com/books/100-go-mistakes-and-how-to-avoid-them). 

When manipulating packages and modules, we distinguish between the producer side, where the imported code lives, and the customer sides, where the imported code is used. Defining interfaces on the producer side is considered a bad practice since you force your abstraction upon customers, abstraction that they might not need or not exactly the one you built. Let's remember that "*abstraction should be discovered, not created*".



[^1]: [Relevant XCKD](https://xkcd.com/927/)
