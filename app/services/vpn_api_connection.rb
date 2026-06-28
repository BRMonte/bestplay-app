module VpnApiConnection
  module_function

  def connection
    @connection ||= Faraday.new do |faraday|
      faraday.options.open_timeout = 1
      faraday.options.timeout = 2
      faraday.adapter Faraday.default_adapter
    end
  end
end
