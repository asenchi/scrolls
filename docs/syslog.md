## Scrolls: Sending data to syslog

By default Scrolls writes log messages to `STDOUT`. With the release of [v0.2.8](https://github.com/asenchi/scrolls/releases/tag/v0.2.8) it is now possible to write to the local system logger. To do so, set `#stream` to "syslog":

```ruby
Scrolls.stream = "syslog"
```

Or using `Scrolls#init` in versions 0.9.0 and after:

```ruby
Scrolls.init(
    stream: "syslog"
)
```

This defaults to syslog facility USER and log level ERROR. You can adjust the log facility like so:

```ruby
Scrolls.facility = "local7"
```

Scrolls generally doesn't care about log levels. The library defaults to ERROR (or 3), but ultimately is of the opinion that levels are useless. The reasoning behind this is that applications should log useful data, all of the time. Debugging data is great for development, but should never be deployed. The richness of structured logging allows exceptions and error messages to sit along side the context of the data in which the error was thrown, there is no need to send to an "emergency" level.

With that said, if one wanted to adjust the log level, you can set an environment variable `LOG_LEVEL` or use one of the level methods. This allows this particular feature to be rather fluid throughout your application.

```ruby
Scrolls.info(d: "data")
Scrolls.warn(d: "data")
```