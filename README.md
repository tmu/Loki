# Loki.swift - a debug logging library for Swift

> I have brought you a gift! I only ask for one thing in return; a good seat from which to watch Asgard burn.
>
> - Loki

## Rationale

TODO 

## Usage

Assume you have the following code in `main.swift` file

```
    func bar() {
        let scope = Loki.function()
        Loki.debug("Hello from bar")
    }
        
    func foo() {
        let scope = Loki.function()
        bar()
    }

    foo()
```

It produces the following log output:

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

