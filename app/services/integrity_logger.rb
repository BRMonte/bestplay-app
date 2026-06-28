class IntegrityLogger
  LogEntry = Data.define(:idfa, :ban_status, :ip, :rooted_device, :country, :proxy, :vpn)

  def initialize(sink: DatabaseIntegrityLogSink.new)
    @sink = sink
  end

  def log(entry)
    sink.write(entry)
  end

  private

  attr_reader :sink
end
