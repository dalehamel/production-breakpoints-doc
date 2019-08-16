# Internals

## Installing breakpoints
 
This gem leverages the ruby-static-tracing [@ruby-static-tracing] gem
[@ruby-static-tracing-gem] which provides the **secret sauce** that allows for
plucking this data out of a ruby process, using the kernel’s handling of the
Intel x86 “Breakpoint” int3 instruction, you can learn more about that in the
USDT Report [@usdt-report-doc]

For each source file, a 'shadow' ELF stub is associated with it, and can be
easily found by inspecting the processes open file handles.

After all breakpoints have been specified for a file, the ELF stub can be
generated and loaded. To update or remove breakpoints, this ELF stub needs to
be re-loaded, which requires the breakpoints to be disabled first. To avoid
this, the scope could be changed to be something other than file, but file
is believed to be nice and easily discoverable for now.

The tracing code will noop, until a tracer is actually attached to it, and
should have minimal performance implications.

## Ruby Override technique via Unmixer

The Unmixer gem hooks into the ruby internal header API, and provides a
back-door into the RubyVM source code to `unprepend` classes or modules from
the global hierarchy.

An anonymous module is created, with the modified source code containing our
breakpoint handler.

To enable the breakpoint code, this module is prepended to the original
method's parent. To undo this, the module is simply 'unprepended', a feature
unmixer uses to tap into Ruby's ancestry hierarchy via a native extension.

```{.ruby include=src/ruby-production-breakpoints/lib/ruby-production-breakpoints/breakpoints/base.rb startLine=26 endLine=35}
```


## Dynamically redefined methods

We define a 'handler' and a 'finisher' block for each breakpoint we attach.

Presently, we don't support attaching multiple breakpoints within the same
function, but we could do so if we applied this as a chain of handers followed
by a finalizer, but that will be a feature for later. Some locking should exist
to ensure the same method is not overriden multiple times until this is done.

These hooks into our breakpoint API are injected into the method source from
the locations we used the ruby AST libraries to parse:

```{.ruby include=src/ruby-production-breakpoints/lib/ruby-production-breakpoints/breakpoints/base.rb startLine=60 endLine=74}
```

And the outcome looks something like this:


```{.ruby include=src/ruby-production-breakpoints/lib/ruby-production-breakpoints/parser.rb startLine=124 endLine=136}
```

This is called when the breakpoint is handled, in order to evaluate the whole
method within the original, intended context:


```{.ruby include=src/ruby-production-breakpoints/lib/ruby-production-breakpoints/breakpoints/base.rb startLine=45 endLine=53}
```

This caller binding is taken at the point our handler starts, so it's
propagated from the untraced code within the method. We use it to evaluate the
original source within the handler and finalizer, to ensure that the whole
method is evaluated within the original context / binding that it was intended
to. This should make the fact that there is a breakpoint installed transparent
to the application.

The breakpoint handler code (see above) is only executed when the handler is
attached, as they all contain an early return if the shadow "ELF" source
doesn't have a breakpoint installed, via the `enabled?` check.
