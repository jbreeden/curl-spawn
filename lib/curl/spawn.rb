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
  end

  def self.spawn(*supplied_argv, &block)
    built_args = Curl::Spawn.build_args(&block)

    normalized_argv = []

    supplied_opt = supplied_argv.last.kind_of?(Hash) ? supplied_argv.pop : {}

    # Merge the argv contents
    built_args.argv.each do |arg|
      normalized_argv.push(arg.to_s)
    end

    supplied_argv.each do |arg|
      normalized_argv.push(arg.to_s)
    end

    # Merge the spawn options hash argument
    normalized_argv.push(supplied_opt.merge(built_args.opt))

    Kernel.spawn(*normalized_argv)
  end

  def self.url_encode(str)
    ERB::Util.url_encode(str)
  end
end
