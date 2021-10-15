# Scrolls

Scrolls is a library for generating logs of the structure `key=value`.

## Installation

Add this line to your application's Gemfile:

    gem 'scrolls'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install scrolls

## Philosophy

Scrolls follows the belief that logs should be treated as data. One way to think of them is the blood of your infrastructure. Logs are a realtime view of what is happening on your systems.

## Usage

### 0.9.0 and later

```ruby
require 'scrolls'

Scrolls.init(
  timestamp: true,
  global_context: {app: "scrolls", deploy: "production"},
  exceptions: "multi"
)

Scrolls.log(at: "test")

Scrolls.context(context: "block") do
  Scrolls.log(at: "exec")
end

begin
  raise
rescue Exception => e
  Scrolls.log_exception(e, at: "raise")
end
```

You can also use `Scrolls#log` and `Scrolls#log_exception` without initalizing:

```ruby
require 'scrolls'

Scrolls.log(test: "test")
```

### Defaults

Here are the defaults `Scrolls#init`:

```
stream: STDOUT
facility: Syslog::LOG_USER
time_unit: "seconds"
timestamp: false
exceptions: "single"
global_context: {}
syslog_options: Syslog::LOG_PID|Syslog::LOG_CONS
escape_keys: false
strict_logfmt: false
```

## Older Versions

### Pre 0.9.0

```ruby
require 'scrolls'

Scrolls.add_timestamp = true
Scrolls.global_context(:app => "scrolls", :deploy => "production")

Scrolls.log(:at => "test")

Scrolls.context(:context => "block") do
  Scrolls.log(:at => "exec")
end

begin
  raise
rescue Exception => e
  Scrolls.log_exception(:at => "raise", e)
end
```

Produces:

```
now="2017-09-01T00:37:13Z" app=scrolls deploy=production at=test
now="2017-09-01T00:37:13Z" app=scrolls deploy=production context=block at=exec
now="2017-09-01T00:37:13Z" app=scrolls deploy=production at=exception class=RuntimeError exception_id=70149797587080
now="2017-09-01T00:37:13Z" app=scrolls deploy=production at=exception class=RuntimeError exception_id=70149797587080 site="./test-scrolls.rb:16:in <main>"
```

## History

This library originated from various logging methods used internally
at Heroku. Starting at version 0.2.0 Scrolls was ripped apart and
restructured to provide a better foundation for the future. Tests and
documentation were add at that point as well.

Thanks to the following people for influencing this library.

* Mark McGranaghan
* Noah Zoschke
* Mark Fine
* Fabio Kung
* Ryan Smith

## LICENSE

MIT License
