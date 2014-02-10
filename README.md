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

## Need to know!

The way Scrolls handles "global_context" is changing after v0.3.8. Please see the [release notes](https://github.com/asenchi/scrolls/releases/tag/v0.3.8) and [this documentation](https://github.com/asenchi/scrolls/tree/master/docs/global-context.md) for more information. I apologize for any trouble this may cause.

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
now="2014-01-17T16:11:39Z" app=scrolls deploy=nil at=test
now="2014-01-17T16:11:39Z" app=scrolls deploy=nil context=block at=exec
now="2014-01-17T16:11:39Z" app=scrolls deploy=nil at=exception class=RuntimeError message= exception_id=70312608019740
now="2014-01-17T16:11:39Z" app=scrolls deploy=nil at=exception class= exception_id=70312608019740 site="./test.rb:16:in <main>"
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
