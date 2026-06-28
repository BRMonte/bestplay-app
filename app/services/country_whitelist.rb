module CountryWhitelist
  REDIS_KEY = "country_whitelist"

  module_function

  def allowed?(country, redis: REDIS)
    return false if country.blank?

    redis.with { |client| client.sismember(REDIS_KEY, country.to_s.upcase) }
  end

  def add(country, redis: REDIS)
    redis.with { |client| client.sadd(REDIS_KEY, country.to_s.upcase) }
  end

  def reset!(countries, redis: REDIS)
    redis.with do |client|
      client.del(REDIS_KEY)
      countries.each { |country| client.sadd(REDIS_KEY, country.to_s.upcase) }
    end
  end
end
