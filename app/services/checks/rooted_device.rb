module Checks
  class RootedDevice
    def initialize(rooted_device:)
      @rooted_device = rooted_device
    end

    def call
      return banned if rooted_device

      pass
    end

    private

    attr_reader :rooted_device

    def pass
      { banned: false }
    end

    def banned
      { banned: true, reason: "rooted_device" }
    end
  end
end
