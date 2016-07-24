#! /usr/bin/env ruby

require 'curl/spawn'

def help(status = 0)
  puts <<-EOS
Usage:
  #{File.basename(__FILE__)} [[--]help] [OPTION...] -- [CURL_ARG...]

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
  $stderr.puts "Unexpected arguments: #{ARGV.inspect}"
  help(1)
end

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
