RSpec.configure do |config|
  config.before(:each) do
    REDIS.with(&:flushdb)
  end
end
