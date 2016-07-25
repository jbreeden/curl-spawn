module Curl
module Spawn

  EXAMPLE = <<-eos
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

  user $opt[:user] if $opt[:user]  # Set the username to use for authentication
  password 'abcd1234'              # Set the password to use for authentication

  verb :post              # Set the http method/verb (default: 'GET')
  host 'localhost'        # Specify host (default: 'localhost')
  port 8000               # On port 8000 (default: 80)
  path '/'                # The path segment of the url (default: '/')

  query :param => Curl.url_encode('value') # Set query params (alias: queries)
  header :Accept => 'application/json'     # Set headers (alias: headers)

  content $stdin          # IO object or string to use as the request content.
                          # Note that this option overwrite the `:in` option
                          # from the positional arguments to this method.

  # DEBUG: print the argument list that will be used to `spawn` curl.
  $stderr.puts build!.inspect
}
eos

  EXAMPLE_SCRIPT = <<-eos
#! /usr/bin/env ruby

require 'curl/spawn'

# User Manual
# -----------

def help(status = 0)
  puts <<-EOS
Usage:
  \#{File.basename(__FILE__)} [[--]help] [OPTION...] -- [CURL_ARG...]

OPTION:
  -u,--user=USER[:PASSWORD]
    Username & optional password to authenticate with.

  -h,--host=HOST
    The host to send the request to (default: localhost).

  -p,--port=PORT
    The port to send the request to (default: 80).

  -c,--content=FILENAME
    The file to send as the request body. If FILENAME is a hyphen (-), then
    stdin is used.

CURL_ARG:
  Any additional arguments after a -- are passed straight through to curl.
EOS
  exit status
end

# Argument Parsing
# ----------------

$opt = {
  user: nil,
  password: nil,
  host: 'localhost',
  port: 80,
  content: nil
}

in_curl_args = false
curl_args = []
ARGV.dup.each do |arg|
  if !in_curl_args
    case arg
    when '--help', 'help'
      help(0)
    when /^(?:-u|--user)=?(.*)$/
      $opt[:user], $opt[:password] = $1.match(/([^:]*):?(.*)/).captures
      ARGV.delete(arg)
    when /^(?:-h|--host)=?(.*)$/
      $opt[:host] = $1
      ARGV.delete(arg)
    when /^(?:-p|--port)=?(.*)$/
      $opt[:port] = $1
      ARGV.delete(arg)
    when /^(?:-c|--content)=?(.*)$/
      prev = $opt[:content]
      prev.close if prev && prev != $stdin
      if $1 == '-'
        $opt[:content] = $stdin
      else
        $opt[:content] = File.open($1, 'r')
      end
      ARGV.delete(arg)
    when '--'
      in_curl_args = true
      ARGV.delete(arg)
    end
  else
    curl_args.push(arg)
    ARGV.delete(arg)
  end
end

if !ARGV.empty?
  $stderr.puts "Unexpected arguments: \#{ARGV.inspect}"
  help(1)
end

# Curl Invocation
# ---------------

pid = Curl.spawn(*curl_args, out: $stdout, err: $stderr) {
  https
  ssl_no_verify

  user $opt[:user] unless $opt[:user].nil? || $opt[:user].empty?
  password $opt[:password] unless $opt[:password].nil? || $opt[:password].empty?

  verb 'POST'
  host $opt[:host]
  port $opt[:port]
  path '/'

  header 'Content-Type' => 'application/json'
  header 'Accept' => 'application/json'

  content $opt[:content] if $opt[:content]

  # # Debug:
  # $stderr.puts build!.inspect
}

Process.wait(pid)
exit $?.exitstatus
eos

end
end
