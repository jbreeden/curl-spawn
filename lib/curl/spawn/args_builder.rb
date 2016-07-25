require 'erb'
require 'curl/spawn/args'

module Curl
module Spawn

  class ArgsBuilder
    def initialize(explicit_argv)
      @explicit_argv = explicit_argv

      @user = nil
      @password = nil
      @scheme = 'http'
      @ssl_no_verify = false
      @host = 'localhost'
      @port = 80
      @path = '/'
      @verb = 'GET'
      @queries = {}
      @headers = {}
      @data = nil

      @show_headers = false
      @verbose = false
    end

    def url_encode(str)
      Curl.url_encode(str)
    end

    def user(user)
      @user = user
    end
    alias user= user
    alias username user
    alias username= user

    def password(p)
      @password = p
    end
    alias password= password

    def scheme(h)
      @scheme = h
    end
    alias scheme= scheme

    def http
      @scheme = 'http'
    end

    def https
      @scheme = 'https'
    end

    def ssl_no_verify(val = true)
      @ssl_no_verify = val
    end
    alias ssl_no_verify= ssl_no_verify

    def host(h)
      @host = h
    end
    alias host= host

    def port(p)
      @port = p
    end
    alias port= port

    def path(p)
      p = "/#{p}" unless p.start_with?('/')
      @path = p
    end
    alias path= path

    def verb(v)
      @verb = v
    end
    alias verb= verb

    def query(q)
      @queries.merge!(q)
    end
    alias queries query

    def header(h)
      @headers.merge!(h)
    end
    alias headers header

    def data(d)
      @data =d
    end
    alias data= data
    alias content data
    alias content= data

    def dump_headers(v=true)
      @show_headers = v
    end
    alias dump_headers= dump_headers
    alias show_headers dump_headers
    alias show_headers= dump_headers

    def verbose
      @verbose = true
    end

    def build!
      @derived_args = ::Curl::Spawn::Args.new

      @derived_args.argv.push('curl')
      @derived_args.argv.push('-k') if @ssl_no_verify
      @derived_args.argv.push('--user') unless @user.nil?
      @derived_args.argv.push("#{@user}#{":#{@password}" unless @password.nil?}")

      query_str = ''
      @queries.each do |k, v|
        if query_str == ''
          query_str << '?'
        else
          query_str << '&'
        end
        query_str << "#{ERB::Util.url_encode(k)}=#{ERB::Util.url_encode(v)}"
      end

      @derived_args.argv.push('-X')
      @derived_args.argv.push(@verb.upcase)

      @derived_args.argv.push("#{@scheme}://#{@host}:#{@port}#{@path}#{query_str}")

      @headers.each do |k, v|
        @derived_args.argv.push("-H")
        @derived_args.argv.push("'#{k}: #{v}'")
      end

      if @data
        @derived_args.argv.push('--data-binary')
        @derived_args.argv.push('@-')
        @derived_args.opt[:in] = @data
      end

      if @show_headers
        @derived_args.argv.push('-i')
      end

      if @verbose
        @derived_args.argv.push('-v')
      end

      @derived_args.argv = @derived_args.argv.reject { |arg| arg.nil? || arg.empty? }.map { |arg| arg.to_s }

      merge_args!
    end

    # Merges the derived arguments from the DSL block with the explicit argv
    # into a single argv array suitable for invoking `Kernel.spawn`
    def merge_args!
      normalized_argv = []

      supplied_opt = @explicit_argv.last.kind_of?(Hash) ? @explicit_argv.pop : {}
      supplied_env = @explicit_argv.first.kind_of?(Hash) ? @explicit_argv.shift : {}

      # Merge the argv contents
      @derived_args.argv.each do |arg|
        normalized_argv.push(arg.to_s)
      end

      @explicit_argv.each do |arg|
        normalized_argv.push(arg.to_s)
      end

      # Merge the spawn options hash argument
      normalized_argv.push(supplied_opt.merge(@derived_args.opt))

      # Merge the env options hash argument
      normalized_argv.unshift(supplied_env.merge(@derived_args.env))

      normalized_argv
    end
  end

end
end
