class VpnApiClient
  CACHE_PREFIX = "vpnapi:"
  CACHE_TTL = 24.hours.to_i
  BASE_URL = "https://vpnapi.io/api"

  Response = Struct.new(:vpn, :tor, :proxy, keyword_init: true)

  def initialize(api_key: ENV.fetch("VPNAPI_KEY"), redis: REDIS, connection: nil)
    @api_key = api_key
    @redis = redis
    @connection = connection || default_connection
  end

  def lookup(ip)
    cached = read_cache(ip)
    return cached if cached

    response = fetch_from_api(ip)
    return unless response

    write_cache(ip, response)
    response
  rescue Faraday::Error, JSON::ParserError, TypeError
    nil
  end

  private

  attr_reader :api_key, :redis, :connection

  def read_cache(ip)
    payload = redis.get(cache_key(ip))
    return unless payload

    data = JSON.parse(payload, symbolize_names: true)
    Response.new(**data)
  end

  def write_cache(ip, response)
    redis.setex(cache_key(ip), CACHE_TTL, response.to_h.to_json)
  end

  def cache_key(ip)
    "#{CACHE_PREFIX}#{ip}"
  end

  def fetch_from_api(ip)
    response = connection.get("#{BASE_URL}/#{ip}") do |request|
      request.params["key"] = api_key
    end

    return unless response.success?

    body = JSON.parse(response.body, symbolize_names: true)
    security = body.fetch(:security, {})

    Response.new(
      vpn: security.fetch(:vpn, false),
      tor: security.fetch(:tor, false),
      proxy: security.fetch(:proxy, false)
    )
  end

  def default_connection
    Faraday.new do |faraday|
      faraday.adapter Faraday.default_adapter
    end
  end
end
