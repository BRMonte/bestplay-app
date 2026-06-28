RSpec.configure do |config|
  config.before(:each) do
    REDIS.flushdb
  end
end
