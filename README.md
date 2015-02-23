# Loki - a logging utility for Swift

> I have brought you a gift! I only ask for one thing in return;
> a good seat from which to watch Asgard burn. - *[Loki](http://www.imdb.com/character/ch0039559/quotes)*

## Rationale

TODO

Loki is a simple to use, but powerful logging tool for Swift

- logging levels: Error, Warning, Info, Debug, Trace
- multiple output handlers (console, files...)
- tracing functionality to show file and function names
- indented logging to visualize the structure of callstack
- enable or disable the logging by module
- logging code can be left to the production code and has minimal effect on the performance when turned off


## Indended logging 

Assume you have the following code in `main.swift` file

```
    func bar() {
        let scope = Loki.function()
        if true {
           Loki.debug("Hello from bar")
           return
        }
        Loki.debug("It was not true")
    }
        
    func foo() {
        let scope = Loki.function()
        bar()
    }

    foo()
```

When tracing with Loki, it produces the following log output:

```
->main.swift:XX foo
  ->main.swift:YY bar
    Hello from bar
  <-main.swift:YY bar
<-main.swift:XX foo
```
    
## Configuration

```
    Loki.include({"MainViewController.swift": .DEBUG})
```

```
    Loki.exclude("MainViewController.swift")
```

