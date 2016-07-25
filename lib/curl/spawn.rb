require "curl/spawn/version"
require "curl/spawn/args_builder"
require 'erb'

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
  def self.spawn(*supplied_argv, &block)
    built_args = Curl::Spawn.build_args(&block)
    normalized_argv = Curl::Spawn.merge_args(supplied_argv, built_args)
    Kernel.spawn(*normalized_argv)
  end

  def self.url_encode(str)
    ERB::Util.url_encode(str)
  end
end
