module Curl
module Spawn

  class Args
    attr_accessor :argv, :env, :opt

    def initialize()
      @argv = []
      @env = {}
      @opt = {}
    end
  end

end
end
