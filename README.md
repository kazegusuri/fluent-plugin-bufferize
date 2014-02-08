# fluent-plugin-bufferize, a plugin for [Fluentd](http://fluentd.org)

An adapter plugin which enables existing non-buffered plugins to resend messages easily in case of unexpected exceptions without creating duplicate messages.

## Why

Buffered plugin accumulates many messages in buffer and sends all the messages at a same time. There are many APIs that does not support such reqeusts like bulk-insert. In that case, you have to use non-buffered output and implement resend meschanism yourself because non-buffered output lacks exception handling functionality. 

To use this plugin, you just have to create non-buffered plugin without caring exception handling. If an exception happens in your plugin, the request is issued again automatically. With file buffer, none of messages are lost even on sudden fluentd process down.

## Configuration

Just embrace existing configuration by <config> directive.

If you use following configuration:

```
<match *>
  type http
  endpoint_url    http://foo.bar.com/
  http_method     put
</match>
```

Modify it like this:

```
<match *>
  type bufferize
  buffer_type file
  buffer_path /var/log/fluent/myapp.*.buffer
  <config>
    type http
    endpoint_url    http://foo.bar.com/
    http_method     put
  </config>
</match>
```

This is a buffered output plugin. For more information about parameters, please refer [official document](http://docs.fluentd.org/articles/buffer-plugin-overview).

## Example of application

These plugins are good compatibility to fluent-plugin-bufferize.

- [fluent-plugin-out-http](https://github.com/ento/fluent-plugin-out-http)
- [fluent-plugin-jubatus](https://github.com/katsyoshi/fluent-plugin-jubatus)
- [fluent-plugin-irc](https://github.com/choplin/fluent-plugin-irc)

## Installation

Add this line to your application's Gemfile:

    gem 'fluent-plugin-bufferize'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-bufferize

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

<table>
  <tr>
    <td>Author</td><td>Masahiro Sano <sabottenda@gmail.com></td>
  </tr>
  <tr>
    <td>Copyright</td><td>Copyright (c) 2013- Masahiro Sano</td>
  </tr>
  <tr>
    <td>License</td><td>MIT License</td>
  </tr>
</table>
