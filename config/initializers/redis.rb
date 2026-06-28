require "connection_pool"
require "redis"

REDIS = ConnectionPool.new(size: Integer(ENV.fetch("RAILS_MAX_THREADS", 5)), timeout: 5) do
  Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6380/0"))
end
