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
func Uppercase(r io.Reader) ([]byte, err) {
    buf := new(bytes.Buffer)
    _, err := r.Read(buf)
    if err != nil {
        return nil, err
    }
    
    return bytes.ToUpper(buf), nil
}

// Here we use "strings.NewReader" to mock any concrete 
// implementation of io.Reader.
func TestUppercase(t *testing.T) {
    r := strings.NewReader("foo")
    want := []byte("FOO")
    
    got, err := Uppercase(r)
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

Sometimes a program might need to access an interface underlying value. Doing so is called a **type assertion**, the "comma ok" idiom and type switches are two methods to achieve that. Type assertion is not limited to concrete types and can also be used to check if an interface underlying value implements other interfaces.

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

Another interesting feature brought by interface in Go is that they allow to restrict the behavior on the underlying type. We will discuss how this is achieved in the next section.



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

<object data="itable.svg" type="image/svg+xml">
  <img src="itable.png" />
</object>

Now that we understand how interfaces are modeled, we can understand the followings:

- Type assertion on an interface is done by checking the asserted type against the one stored in the interface table.

- Interfaces restrict the underlying types behavior because they only have pointers to the methods used to satisfy the interface, the ones stored in the interface table. Type assertion is a way to lift these restrictions by getting a copy of the underlying value which is either not restricted at all, in the case of an assertion to a concrete type, or has different restrictions in the case of an assertion to another interface.
- Interfaces are equal to `nil` only if both value and type are `nil`.



# Common mistakes

## When `nil` is not equal to `nil`

We now know that an interface is equal to `nil` only when both its type and value are `nil`. This can lead to tricky errors when wrapping a `nil` pointers as shown below.

```go
type customError struct {
    Message string
}

// customError implements the Error interface
func (c *customError) Error() string {
    return c.Message
}

func foo() error {
    var err *customError
    // err has its default value, nil
    return err 
}

func main() {
    err := foo()
    // This will always be triggered because "error" is an interface
    // wrapping a nil pointer which is a valid wrappee, hence "error"
    // is not nil.
    if err != nil {
        panic(err)
    }
}

```



## Using a value for pointer-receiver methods

Aka interface value not addressable



## Defining interfaces on the producer side

This one is more a design mistakes than a technical one and is very well explained in [100 Go Mistakes and How to Avoid Them](https://www.manning.com/books/100-go-mistakes-and-how-to-avoid-them). 

When manipulating packages and modules, we distinguish between the producer side, where the imported code lives, and the customer sides, where the imported code is used. Defining interfaces on the producer side is considered a bad practice since you force your abstraction upon customers, abstraction that they might not need which goes against the [interface segregation principle](https://en.wikipedia.org/wiki/Interface_segregation_principle). Let's remember that "*abstraction should be discovered, not created*".

<br>

<br>

# Conclusion

Thank you for reading this post. I hope you learned a few things, if this is the case, please share it with whoever you think might be interested.

This following sources helped in the writing of this post:

- [100 Go Mistakes and How to Avoid Them](https://www.manning.com/books/100-go-mistakes-and-how-to-avoid-them), T. Harsanyi

- [Go Data Structures: Interfaces](https://research.swtch.com/interfaces), R. Cox
- [Understanding nil](https://www.youtube.com/watch?v=ynoY2xz-F8s), F. Campoy

[^1]: [Relevant XCKD](https://xkcd.com/927/)
