# How this works

Ruby "production breakpoints" rewrite the source code of a method with the targeted lines to include a wrapper around those lines.

The method is redefined by prepending a module with the new definition to the parent of the original method, overriding it. To undo this,
the module can be 'unprepended' restoring the original behavior.

When a breakpoint line is executed, we can use the Linux Kernel to interrupt our application and retrieve some data we've prepared for it.

Unless a breakpoint is both enabled and attached to by a debugger, it shouldn't change execution

# Injecting breakpoints

To do this, we will need to actually rewrite Ruby functions to inject our tracing code around the selected line or lines. Ruby 2.6 + has built-in AST parsing, so we can use this to determine what needs to be redefined, in order to add our tracer.

The AST parsing will show us the scope of the lines that the user would like to trace, and will load the method scope of the lines, in order to inject the tracing support. This modified ruby code string can then be evaluated in the scope of an anonymous module, which is prepended to the parent of the method that has been redefined.

This will put it at the tip of the chain, and override the original copy of this method. Upon unprepending the module, the original definition should be what is evaluated by Ruby's runtime Polymorphic method message mapping.

# Specifying breakpoints

A global config value:

```ruby
ProductionBreakpoints.config_file
```

Can be set to specify the path to a JSON config, indicating the breakpoints that are to be installed:

```json
{
  "breakpoints": [
    {
      "type": "inspect",
      "source_file": "test/ruby_sources/config_target.rb",
      "start_line": 7,
      "end_line": 9,
      "trace_id": "config_file_test"
    }
  ]
}
```

These values indicate:

* `type`: the built-in breakpoint handler to run when the specified breakpoint is hit in production.
* `source_file`: the source repository-root relative path to the source file to install a breakpoint within. (note, the path of this source folder relative to the host / mount namespace is to be handled elsewhere by the caller that initiates tracing via this gem)
* `start_line`: The first line which should be evaluated from the context of the breakpoint.
* `end_line`: The last line which should be evaluated in the context of the breakpoint
* `trace_id`: A key to group the output of executing the breakpoint, and filter results associated with a particular breakpoint invocation

Many breakpoints can be specified. Breakpoints that apply to the same file are added and removed simultaneously. Breakpoints that are applied but not specified in the config file will be removed if the config file is reloaded.

# Built-in breakpoints

## Latency

Output: Integer, nanoseconds elapsed

The latency breakpoint provides the elapsed time from a monotonic source, for the duration of the breakpoint handler.

This shows the time required to execute the code between the start and end lines, within a given method.

## Locals

Output: String, key,value via ruby inspect

The 'locals' breakpoint shows the value of all locals.

NOTE: due to limitations in eBPF, there is a maximum serializable string size. Very complex objects cannot be efficiently serialized and inspected.

## Inspect

Output: String, value via ruby inspect

The 'inspect' command shows the inspected value of whatever the last expression evaluated to within the breakpoint handler block.

# Internals

## Loading breakpoints
 
This gem leverages the ruby-static-tracing gem which provides the 'secret sauce' that allows for plucking this data out of a ruby process, using the kernel’s handling of the intel x86 “Breakpoint” int3 instruction.

For each source file, a 'shadow' ELF stub is associated with it, and can be easily found by inspecting the processes open file handles.

After all breakpoints have been specified for a file, the ELF stub can be generated and loaded. To update or remove breakpoints, this ELF stub needs to be re-loaded, which requires the breakpoints to be disabled first. To avoid this, the scope could be changed to be something other than file, but file is believed to be nice and easily discoverable for now.

The tracing code will noop, until a tracer is actually attached to it, and should have minimal performance implications.

## Ruby Override technique

The 'unmixer' gem hooks into the ruby internal header API, and provides a back-door into the RubyVM source code to 'unappend' classes or modules from the global hierarchy.

An anonymous module is created, with the modified source code containing our breakpoint handler.

To enable the breakpoint code, this module is prepended to the original method's parent. To undo this, the module is simply 'unprepended', a feature unmixer uses to tap into Ruby's ancestry hierarchy via a native extension.
