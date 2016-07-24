# curl-spawn

Simple DSL for invoking curl commands. Includes a script generator - `curl-spawn-generate` -
and an interactive shell - `curl-spawn-irb`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'curl-spawn'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install curl-spawn

## Usage

### Ruby API

`curl-spawn-irb` will show a short API example at startup.
At the time of this writing, it looks like this:

```Sh
[jared:~/projects/curl-spawn] curl-spawn-irb
--------------------
Welcome to curl-spawn-irb!

This is an interactive ruby shell with curl-spawn loaded.
Here, you can spawn curl processes with a convenient ruby DSL.

Example:

  # - The block is executed in the context of a Curl::Spawn::ArgsBuilder, which
  #   provides a DSL for describing curl commands.
  #
  # - Any parameters to `Curl.spawn` are merged with the arguments derived
  #   from the DSL block, then passed through to `Kernel.spawn` when invoking curl.
  #   (Arguments derived from the block are preferred in case of conflicts.)
  #
  #   + You can use this to set positional arguments, redirect stdin/stdout/stderr,
  #     and a few other things. (Note: the env hash argument to `Kernel.spawn` is
  #     not supported through this api.)

  pid = Curl.spawn('--progress-bar', out: $stdout, err: $stderr) {
    https                   # Use https. Same as `scheme 'https'`. (default: http)
    ssl_no_verify           # Don't verify ssl certs. (Primarily for development)

    user $opt[:user] if $opt[:user]         # Set the username to use in basic auth
    password 'abcd1234'     # Set the password to use for basic auth

    verb :post              # Set the http method/verb (default: 'GET')
    host 'localhost'        # Specify host (default: 'localhost')
    port 8000               # On port 8000 (default: 80)
    path '/'                # The path segment of the url (default: '/')

    query :param => Curl.url_encode('value') # Set query params (alias: queries)
    header :Accept => 'application/json'     # Set headers (alias: headers)

    content $stdin          # IO object or string to use as the request content.
                            # Note that this option overwrite the `:in` option
                            # from the positional arguments to this method.

    # For debugging, you can print out the generated Curl::Spawn::Args object
    $stderr.puts build!.inspect
  }
--------------------
[1] pry(main)>
```

### Shell Scripts

The main reason for writing this gem was to ease the task of writing small
shell scripts whose main function is using curl to hit a REST endpoint.
So the `curl-spawn-generate` command is provided, which generates just
such a script. By default it accepts arguments for authentication and
setting the target host/port for the request, but you can easily add your own.
Just pipe `curl-spawn-generate` to a file, change the default settings,
and you're done! (Well, you might want to `chmod u+x` the file as well).

## Development

After checking out the repo, run `bin/setup` to install dependencies.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jbreeden/curl-spawn.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
