require "curl/spawn/version"
require "curl/spawn/args_builder"
require 'erb'
require 'uri'

module Curl
  module Spawn
    def self.build_args(&block)
      builder = ArgsBuilder.new
      builder.instance_eval(&block) if block
      builder.build!
    end

    def self.merge_args(supplied_argv, built_args)
      normalized_argv = []

      supplied_opt = supplied_argv.last.kind_of?(Hash) ? supplied_argv.pop : {}
      supplied_env = supplied_argv.first.kind_of?(Hash) ? supplied_argv.shift : {}

      # Merge the argv contents
      built_args.argv.each do |arg|
        normalized_argv.push(arg.to_s)
      end

      supplied_argv.each do |arg|
        normalized_argv.push(arg.to_s)
      end

      # Merge the spawn options hash argument
      normalized_argv.push(supplied_opt.merge(built_args.opt))

      # Merge the env options hash argument
      normalized_argv.unshift(supplied_env.merge(built_args.env))

      normalized_argv
    end
  end

  # Synopsis: Curses.spawn([spawn_env_hash,] *positional_args [, spawn_options_hash])
  # Note: If only one hash is supplied, it is assumed to be an options hash, not
  #       an environment hash (see Kernel.spawn).
  #
  # Return the pid of the curl process.
  def self.spawn(*supplied_argv, &block)
    built_args = Curl::Spawn.build_args(&block)
    normalized_argv = Curl::Spawn.merge_args(supplied_argv, built_args)
    Kernel.spawn(*normalized_argv)
  end

  # Just like `Curl.spawn`, but creates a pipe for reading from curl,
  # and returns the read end (with a pid attribute).
  def self.popen(*supplied_argv, &block)
    built_args = Curl::Spawn.build_args(&block)
    normalized_argv = Curl::Spawn.merge_args(supplied_argv, built_args)

    r, w = IO.pipe
    normalized_argv.last[:out] = w
    pid = Kernel.spawn(*normalized_argv)
    r.instance_variable_set(:@pid, pid)
    def r.pid
      @pid
    end
    w.close
    r
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
