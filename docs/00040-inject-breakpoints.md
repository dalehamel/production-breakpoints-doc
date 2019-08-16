# Injecting breakpoints

There are multiple ways to inject breakpoints into running code, each with
different tradeoffs.

## Unmixer Approach

I set out to prove if I could build a line-targeting debugger with USDT
tracepoints, and did so via modifying the class hierarchy, generating an
override method on-the-fly.

I was able to do this with "eval", and be passing the current binding to a
block that calls eval, I was able to wrap the original code in my own block
handler, but still be able to execute it in the current context!

This was a proof of concept at least. However, I quickly learned from my
colleague Alan Wu, that this type of monkeypatching had dangerous implications
to the ruby method cache which I had not considered.

Ruby "production breakpoints" would originally use its AST parsing to rewrite
the source code of a method with the targeted lines to include a wrapper around
those lines. This is still the most powerful way to do this from outside of
the RubyVM I have been able to determine.

The method is redefined by prepending a module with the new definition to the
parent of the original method, overriding it. To undo this, the module can be
'unprepended' restoring the original behavior.

## Using the Ruby TracePoint API

Ruby now supports tracing only particular methods [@ruby-tracing-feature-15289]
instead of all methods, and looks to be aiming to add a similar sort of
debugging support natively.

The docs are not very thorough in the official rubydoc for this
[@ruby-2-6-tracing-docs], but it is further documented in the
[@ruby-prelude-targetted-tracing] prelude.rb file:


```{.ruby include=src/ruby/prelude.rb startLine=136 endLine=192}
```

Alan Wu [@xrxr] tipped me off to this, and showed by an initial prototype gist
[@xrxr-gist], which succinctly shows a basic usage of this:

```ruby
class Foo
  def hello(arg = nil)
    puts "Hello #{arg}"
  end
end

one = Foo.new
two = Foo.new

one.hello
two.hello

trace = TracePoint.new(:call) do |tp|
  puts "intercepted! arg=#{tp.binding.local_variable_get(:arg)}"
end
trace.enable(target: Foo.instance_method(:hello)) do
  one.hello(:first)
  two.hello(:second)
end
```

From this, we can build handlers that run using the RubyVM TracePoint object.

This object has full access to the execution context of the caller it would
seem.

# Specifying breakpoints

A global config value:

```ruby
ProductionBreakpoints.config_file
```

Can be set to specify the path to a JSON config, indicating the breakpoints
that are to be installed:

```{.json include=src/ruby-production-breakpoints/test/config/test_load.json}
```


These values indicate:

* `type`: the built-in breakpoint handler to run when the specified breakpoint
is hit in production.
* `source_file`: the source repository-root relative path to the source file to
install a breakpoint within. (note, the path of this source folder relative to
the host / mount namespace is to be handled elsewhere by the caller that
initiates tracing via this gem)
* `start_line`: The first line which should be evaluated from the context of
the breakpoint.
* `end_line`: The last line which should be evaluated in the context of the
breakpoint
* `trace_id`: A key to group the output of executing the breakpoint, and filter
results associated with a particular breakpoint invocation

Many breakpoints can be specified. Breakpoints that apply to the same file are
added and removed simultaneously. Breakpoints that are applied but not
specified in the config file will be removed if the config file is reloaded.


