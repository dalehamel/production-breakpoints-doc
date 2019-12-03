[![Build Status](https://travis-ci.org/dalehamel/ruby-production-breakpoints.svg?branch=master)](https://travis-ci.org/dalehamel/ruby-production-breakpoints)

# Ruby Production Breakpoints

This is the start of a gem to enable "production breakpoints" in Ruby.

This Gem is a hack days project idea meant to power a prototype, and not actually suitable for production use (yet).

# What this does

This gem lets you dynamically add "production breakpoints" to a live, running application to see what it is doing.

Once you're done debugging, the breakpoints can be unloaded and removed.

# How to use this

This is in early phases of development, but the [architecture doc](https://bpf.sh/production-breakpoints-doc/index.html) is a good place to get started.

To start with, you will need to include `ruby-production-breakpoints` in your app's gemfile, or `gem install ruby-production-breakpoints`.

Within your app, you need to configure it to enable ruby-production-breakpoints:

```ruby
require 'ruby-production-breakpoints'
```

You can specify the file that breakpoints should be sync'd against like so:

```
ProductionBreakpoints.config_file = "/path/to/you/config.json"
```

And can either manually load the breakpoints from this file with:

```
ProductionBreakpoints.sync!
```

Or, you can simply send the `SIGURG` (this is configurable) UNIX signal to the process, like so:

```
kill -SIGURG ${RUBY_PID}
```

Which will add / remove breakpoints to converge to what has been specified in the file.
