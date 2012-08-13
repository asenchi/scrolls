# Scrolls

Scrolls is a logging library that is focused on outputting logs in a
key=value structure. It's in use at Heroku where we use the event data
to drive metrics and monitoring services.

Scrolls is rather opinionated.

## Installation

Add this line to your application's Gemfile:

    gem 'scrolls'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install scrolls

## Usage

At Heroku we are big believers in "logs as data". We log everything so
that we can act upon that event stream of logs. Internally we use logs
to produce metrics and monitoring data that we can alert on.

Here's an example of a log you might specify in your application:

```ruby
Scrolls.log(fn: "trap", signal: s, at: "exit", status: 0)
```

The output of which might be:

    fn=trap signal=TERM at=exit status=0

This provides a rich set of data that we can parse and act upon.

A feature of Scrolls is setting contexts. Scrolls has two types of
context. One is 'global_context' that prepends every log in your
application with that data and a local 'context' which can be used,
for example, to wrap requests with a request id.

In our example above, the log message is rather generic, so in order
to provide more context we might set a global context that links this
log data to our application and deployment:

```ruby
Scrolls.global_context(app: "myapp", deploy: ENV["DEPLOY"])
```

This would change our log output above to:

    app=myapp deploy=production fn=trap signal=TERM at=exit status=0

If we were in a file and wanted to wrap a particular point of context
we might also do something similar to:

```ruby
Scrolls.context(ns: "server") do
  Scrolls.log(fn: "trap", signal: s, at: "exit", status: 0)
end
```

This would be the output (taking into consideration our global context
above):

    app=myapp deploy=production ns=server fn=trap signal=TERM at=exit status=0

This allows us to track this log to `Server#trap` and we received a
'TERM' signal and exited 0.

As you can see we have some standard nomenclature around logging.
Here's a cheat sheet for some of the methods we use:

* `app`: Application
* `lib`: Library
* `ns`: Namespace (Class, Module or files)
* `fn`: Function
* `at`: Execution point
* `deploy`: Our deployment (typically an environment variable i.e. `DEPLOY=staging`)
* `elapsed`: Measurements (Time)
* `count`: Measurements (Counters)

Scrolls makes it easy to measure the run time of a portion of code.
For example:

```ruby
    Scrolls.log(fn: "test") do
      Scrolls.log(status: "exec")
      # Code here
    end
```

This will output the following log:

    fn=test at=start
    status=exec
    fn=test at=finish elapsed=0.300

You can change the time unit that Scrolls uses to "milliseconds" (the
default is "seconds"):

```ruby
    Scrolls.time_unit = "ms"
```

Scrolls has a rich #parse method to handle a number of cases. Here is
a look at some of the ways Scrolls handles certain values.

Time and nil:

```ruby
    Scrolls.log(t: Time.at(1340118167), this: nil)
    t=2012-06-19T11:02:47-0400 this=nil
```

True/False:

```ruby
    Scrolls.log(that: false, this: true)
    that=false this=true
```

## History

This library originated from various logging methods used internally
at Heroku. Starting at version 0.2.0 Scrolls was ripped apart and
restructured to provide a better foundation for the future. Tests and
documentation were add at that point as well.

## Thanks

Most of the ideas used in Scrolls are those of other engineers at
Heroku, I simply ripped them off to create a single library. Huge
thanks to:

* Mark McGranaghan
* Noah Zoschke
* Mark Fine
* Fabio Kung
* Ryan Smith
