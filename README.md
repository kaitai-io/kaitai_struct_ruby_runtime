# Kaitai Struct: runtime library for Ruby

This library implements Kaitai Struct API for Ruby.

Kaitai Struct is a declarative language used for describe various binary
data structures, laid out in files or in memory: i.e. binary file
formats, network stream packet formats, etc.

Further reading:

* [About Kaitai Struct](http://kaitai.io/)
* [About API implemented in this library](http://doc.kaitai.io/stream_api.html)

## Installing

### Using `Gemfile`

If your project uses Bundler, just include the line

```
gem 'kaitai-struct'
```

in your project's `Gemfile`.

### Using `gem install`

If you have a RubyGems package manager installed, you can use command

```
gem install kaitai-struct
```

to install this runtime library.

### Manually

This library is intentionally kept as very simple, one-file `.rb`
file. One can just copy it to your project from this
repository. Usually you won't `require` it directly, it will be loaded
by Ruby source code generate by Kaitai Struct compiler.
