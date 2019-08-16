# Built-in breakpoints

## Latency

Output: Integer, nanoseconds elapsed

The latency breakpoint provides the elapsed time from a monotonic source, for
the duration of the breakpoint handler.

This shows the time required to execute the code between the start and end
lines, within a given method.

Handler definition:

```{.ruby include=src/ruby-production-breakpoints/lib/ruby-production-breakpoints/breakpoints/latency.rb startLine=7 endLine=14}
```

## Locals

Output: String, key,value via ruby inspect

The 'locals' breakpoint shows the value of all locals.

NOTE: due to limitations in eBPF, there is a maximum serializable string size.
Very complex objects cannot be efficiently serialized and inspected.


```{.ruby include=src/ruby-production-breakpoints/lib/ruby-production-breakpoints/breakpoints/locals.rb startLine=7 endLine=15}
```

## Inspect

Output: String, value via ruby inspect

The `inspect` command shows the inspected value of whatever the last expression
evaluated to within the breakpoint handler block.

```{.ruby include=src/ruby-production-breakpoints/lib/ruby-production-breakpoints/breakpoints/inspect.rb startLine=7 endLine=12}
```

## Ustack

Output: String, simplified stack caller output
