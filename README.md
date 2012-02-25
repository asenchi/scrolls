# Scrolls

Logging gem, compiled from many different internal projects in order to make
it easier to add logging to projects. Basically I grew tired of moving this
file around.

## Installation

Add this line to your application's Gemfile:

    gem 'scrolls'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install scrolls

## Usage

It's pretty easy to use:

    require 'scrolls'

Put this somewhere early on in your application:

    Scrolls::Log.start

Use it:

    Scrolls.log(:testing => true, :at => "readme")

## Thanks

I only compiled this library, many others made it work. Here are some of the
authors of projects that I've used to get an idea of a consistent log gem:

* Mark McGranaghan
* Noah Zoschke
* Mark Fine

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
