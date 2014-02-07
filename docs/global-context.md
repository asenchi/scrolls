## Scrolls: Global Context

Early on Scrolls established a method for adding a "global_context" to log messages. This was perfect for data that should be appended to every log message in a project. Items like environment, request_id, app name all fit perfectly within the global logging context of a project. Later on @slemiere added in a way to dynamically update this global context.

However, due to [changes in Ruby 2.0](https://github.com/asenchi/scrolls/issues/53) it has become necessary to make the global context immutable and thus remove the locking necessary in our atomic operation. The effects of which Scrolls API changes slightly.

Previously, the global context was set using the following:

```ruby
require 'scrolls'

Scrolls.global_context(:app => example)
Scrolls.log(:at => test)
```

However, this will no longer be the method used. All releases after 0.3.8 will use the following method:

```ruby
require 'scrolls'

Scrolls.init(
  :global_context => { :app => example }
)
Scrolls.log(:at => test)
```

`Scrolls#init` is a new method for initializing the internal Logger in Scrolls and will allow other configuration details to be set. Once the work is finalized more documentation on this method will be available and linked here. Until then you can follow along with development [here](https://github.com/asenchi/scrolls/pulls/54). However, `0.3.8` introduced a `#init` that allows developers to start moving toward that pattern.

Here is an example:

```ruby
Scrolls.init(
  :global_context => {:g => "g"},
  :timestamp      => true,
)

Scrolls.log(:t => "t")
```

Is the same as this currently:

```ruby
Scrolls.global_context(:g => "g")
Scrolls.add_timestamp = true

Scrolls.log(:t => "t")
```

All of this also means that the "global_context" is no longer mutable and `Scrolls#add_global_context` will be deprecated.

I apologize for the incompatability of these changes, I work very hard not to break existing behavior. However, with the changes in Ruby core, I think we have a better path forward. I'm looking forward to "cementing" the API and releasing a 1.0 soon after this major refactor.
