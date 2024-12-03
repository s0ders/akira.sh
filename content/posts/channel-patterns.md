---
title: "Channel Patterns in Go"
date: 2024-12-01T23:00:19+01:00
draft: true
tags: ['Go']
---

# Introduction

Go concurrency model is a different than most C based language. Instead of directly letting us manipulate kernel-level thread, it provides us with user-level thread called **goroutine**. The Go runtime manages the placement of these goroutine onto kernel-level thread. Most importantly, Go provides us with an interesting way to communicate and coordinate between goroutines: channels.

Regular inter-thread communication mechanisms such as memory sharing and mutexes are available yet channels are a very interesting option. First introduced by C.A.R. Hoare in "[Communicating Sequential Processes](https://en.wikipedia.org/wiki/Communicating_sequential_processes)", channels are "pipes" in which concurrent processes can send or receive data. They provide a higher level tool than classic memory sharing tools and can make concurrent programming simpler to understand for us programmers. 

Most of the time, using channels reduces the cognitive load of having to understand concurrent interactions and greatly diminishes the risk of race condition since it promotes an approach of **sharing memory by communication and not communication by sharing memory**.

Let's dive in the common patterns you might encounter when dealing with channels in Go programs.



## Quick recap

- A Go program finishes when its main goroutine finishes, it does not wait for other goroutines to finish.
- Channels are unbuffered by default, meaning a sender while block until there is a receiver and a receiver will block until there is a sender.
- Channels can be buffered. A sender can send values without a receiver on the other end until the buffer is full and a receiver can read from the buffer without a sender on the other end until the buffer is emptied.
- Channels are bidirectional by default but can be assigned a direction restricting the operation that can be done with them. Channels with direction are either read only or send only.
- Channels can be closed using the `close()` built-in.
- A closed channels can still be read from and will return the default value of the type it conveys. However, sending a message to a close channel will raise an error.
- When receiving from a channel, a second value can be received indicating whether the channel is closed or not such as `v, ok := <-ch`.
- A channel can be `nil`, writing to or reading from a `nil` channel will block.



## Building blocks

### For and select loop

The `select` statement allows to deal with multiple channels operations and execute the one that unblocks first. In the code below, if `sendChannel` is ready first, we will send `0` but if `readChannel` is ready first, we will read and print its value. The point is: only one case of the `select` statement is executed and it is the one that's unblocks first. 

```go
select {
case sendChannel <- 0
	fmt.Println("Send: 0")
case v <- readChannel:
	fmt.Println("Read:", v)
}
```

If more than one case are ready, one is chosen is a pseudo-random way[^1]. So unlike `switch` statements, you should not rely on the cases order.

The code above is fine but usually we want to read or send data more than once. To do so, a common pattern is to execute a `select` statement inside a `for` loop as below.

```go
for {
    select {
    case v, ok := <- ch1:
        // ...
    case v, ok := <-ch2:
        // ...
    }
}
```

The code above does what we asked: it receives forever from `ch1` or `ch2` but it has two major flaws. First, it loops forever and we most likely want the loop to stop at some points, if both channels are closed for example. Second, if one channel closes, the select will chose its case first every time since a closing channels is always ready to return the default value it conveys. 

Both of these issues can be fixed using the next pattern.



### Using `nil` channels

Reading from or writing to a `nil` channel — understand a channel whose value is actually `nil` — is a **blocking** operation. We previously saw that a `select` statement choses whichever operations unblocks first. We also know that a closed channels is always unblocked and returns the default value of the type it conveys, do you see where I am going with that ?

If we assign `nil` to a closed channel, we effectively disable that case in a `select` statement since reading from or sending to a channel is a blocking operation. This is a very important piece of knowledge that every Go developer working with channels should be aware of.

Let's fix our previous example with the code below.

```go
for ch1 != nil || ch2 != nil {
    select {
    case v, ok := <- ch1:
        if !ok {
            ch1 = nil
        }
        // ...
    case v, ok := <-ch2:
        if !ok {
            ch2 = nil
        }
        // ...
    }
}
```

We now have a stop condition for the loop and remove cases from the `select` statement once the channel on that case is closed.



### Notification channels

When sending information on a channel to notify that something happened, the type of the notification is of little importance. We could use a channel of `int` or `bool` but then we would be wasting memory and other developers reading that code might struggle understanding if the value sent has a specific meaning.

The *de facto* type for notification channels is `chan struct{}`, indeed `struct{}` is the only value that uses zero bytes of memory and explicitly signals that this channel is meant for notification only and than we don't care about the value it conveys, we only care about the fact that a notification was sent or received.

```go
func worker(ch chan<- struct) {
    fmt.Println("Performing CPU heavy computation...")

    // Once computation is over
    ch <- struct{}{}
}

func main() {
    ch := make(chan struct{})
    
    go worker(ch)
    
    <-ch
    fmt.Println("Computation done")
}
```

Note that the example above only illustrate what notification channels are. For synchronization, a `sync.WaitGroup` is usually more robust and appropriate.



### Using the default case

Sometimes you want to try to send or receive from a channel and move on if the goroutine on the other end of the channel is not ready. The `default` case of the `select` statement provides this exact feature:

```go
select {
case ch1 <- "foo":
    // ...
case v <- ch2:
    // ...
default:
    fmt.Println("Neither channel 1 or 2 were ready, moving on.")
}
```



### Timing out operations

Let's expend upon the previous pattern: this time we want to move on from the `select` cases if neither of them proceeded after a given amount of time, meaning: we want to implement a time out. The `time` package from standard library has a `time.After` function that returns a read-only channels which sends a single value (the time it executed at) after a given amount of time, which is exactly what we need.

```go
select {
case v <- ch1:
    fmt.Println("Channel 1:", v)
case v <- ch2:
    fmt.Println("Channel 2:", v)
case t <-time.After(3 * time.Second):
    fmt.Println("Timed out after 3 seconds at:", t)
}
```

Note that if you want to timeout in a for/select loop, you need to assign the channel returned by `time.After` outside the loop.



### Using context to signal cancellation and timeout

The `context` package from the standard library offers a `context.Context` type that can be used to transmit signals and values across goroutines. Let's focus on the cancellation and timeout aspect of a context.

Specifically, the method that interest us are:

- `Background`, returns the current goroutine context. Each `With[..]` method builds upon an existing context which can be retrieved using this function.

- `WithCancel`, returns a cancel function that can be used to cancel the goroutines using that context.
- `WithTimeout`, can cancel goroutine using it after the given duration has passed.
- `WithDeadline`, can cancel goroutine using it after the given time is past.

Now, how to know whether a context has been canceled or has "expired" ? Using the `Done` function and the associated `Err` function that returns an error explaining why the context is "done".

```go
// It is idiomatic for the context to be the first parameter
func worker(ctx context.Context, ch <-chan int) {
    go func() {
    	for { 
        	select {
        	case <-ctx.Done():
            	fmt.Println("context is done:", ctx.Err())
            	return
        	case v, ok := <-ch:
            	// Do regular work
        	}
    	}
    }()

}

func main() {
    ctx := context.WithTimeout(context.Background(), 30 * time.Second)
    
    go worker(ctx)
}
```

This pattern is more of a "goroutine" and concurrency pattern but you will find yourself working with context very often when dealing with channels.

**Tip**: if you are unsure what type of context to use, use `context.TODO()` which conveys the meaning of an unknown context at current time instead of `context.Background()`.



## Advanced patterns

### Pipelining



### Fanning in and out

- Order not guaranteed !!

- Fan out good to fan work to a worker pool of gourinte
- Fan in good to aggregate the results of a worker pool



### Broadcasting



[^1]: https://go.dev/ref/spec#Select_statements

