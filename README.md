# Kaitai Struct: runtime library for Ruby

This library implements Kaitai Struct API for Ruby.

Kaitai Struct is a declarative language used for describe various binary
data structures, laid out in files or in memory: i.e. binary file
formats, network stream packet formats, etc.

Further reading:

* [About Kaitai Struct](https://github.com/kaitai-io/kaitai_struct/)
* [About API implemented in this library](https://github.com/kaitai-io/kaitai_struct/wiki/Kaitai-Struct-stream-API)
* [Ruby-specific notes](https://github.com/kaitai-io/kaitai_struct/wiki/Ruby)

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

## Licensing

Copyright 2015-2016 Kaitai Project: MIT license

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
