require "curl/spawn/version"
require "curl/spawn/args_builder"
require 'erb'
require 'uri'

module Curl
  module Spawn
    def self.build_argv(explicit_argv, &block)
      builder = ArgsBuilder.new(explicit_argv)
      builder.instance_eval(&block) if block
      builder.build!
    end
  end

  # Synopsis: Curses.spawn([spawn_env_hash,] *positional_args [, spawn_options_hash])
  # Note: If only one hash is supplied, it is assumed to be an options hash, not
  #       an environment hash (see Kernel.spawn).
  #
  # Return the pid of the curl process.
  def self.spawn(*explicit_argv, &block)
    argv = Curl::Spawn.build_argv(explicit_argv, &block)
    Kernel.spawn(*argv)
  end

  # Just like `Curl.spawn`, but creates a pipe for reading from curl,
  # and returns the read end (with a pid attribute).
  def self.popen(*explicit_argv, &block)
    argv = Curl::Spawn.build_argv(explicit_argv, &block)

    r, w = IO.pipe
    argv.last[:out] = w
    pid = Kernel.spawn(*argv)
    r.instance_variable_set(:@pid, pid)
    def r.pid
      @pid
    end
    w.close
    r
  end

  def self.build_argv(*explicit_argv, &block)
    Curl::Spawn.build_argv(explicit_argv, &block)
  end

  def self.encode_url(str)
    ERB::Util.url_encode(str)
  end
  class << self
    alias url_encode encode_url
  end

  def self.encode_form(form)
    URI.encode_www_form(form)
  end
  class << self
    alias form_encode encode_form
    alias encode_www_form encode_form
  end

  def self.encode_form_component(str, enc=nil)
    URL.encode_www_form_component(str, enc)
  end
  class << self
    alias encode_www_form_component encode_form_component
  end
end
