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

## Documentation:

I apologize, some of these are a WIP.

* [Sending logs to syslog using Scrolls](https://github.com/asenchi/scrolls/tree/master/docs/syslog.md)
* Logging contexts
* Adding timestamps by default
* Misc Features

## Usage

```ruby
require 'scrolls'

Scrolls.add_timestamp = true
Scrolls.global_context(:app => "scrolls", :deploy => ENV["DEPLOY"])

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
now="2014-01-17T06:39:59Z" app=scrolls deploy=nil at=test
now="2014-01-17T06:39:59Z" app=scrolls deploy=nil at=exec
now="2014-01-17T06:39:59Z" app=scrolls deploy=nil at=exception class=RuntimeError message= exception_id=70213731497400
now="2014-01-17T06:39:59Z" app=scrolls deploy=nil at=exception class= exception_id=70213731497400 site="../testscrolls/test.rb:16:in <main>"
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
