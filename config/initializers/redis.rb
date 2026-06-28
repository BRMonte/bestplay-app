require "redis"

REDIS = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6380/0"))
