module CountryWhitelist
  REDIS_KEY = "country_whitelist"

  module_function

  def allowed?(country, redis: REDIS)
    return false if country.blank?

    redis.sismember(REDIS_KEY, country.to_s.upcase)
  end

  def add(country, redis: REDIS)
    redis.sadd(REDIS_KEY, country.to_s.upcase)
  end

  def reset!(countries, redis: REDIS)
    redis.del(REDIS_KEY)
    countries.each { |country| add(country, redis: redis) }
  end
end
