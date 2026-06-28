require "rails_helper"

RSpec.describe IntegrityLogger do
  subject(:logger) { described_class.new(sink: sink) }

  let(:sink) { instance_double(DatabaseIntegrityLogSink, write: true) }
  let(:entry) do
    described_class::LogEntry.new(
      idfa: "8264148c-be95-4b2b-b260-6ee98dd53bf6",
      ban_status: User::BANNED,
      ip: "203.0.113.1",
      rooted_device: true,
      country: "US",
      proxy: false,
      vpn: true
    )
  end

  it "routes log entries to the configured sink" do
    logger.log(entry)

    expect(sink).to have_received(:write).with(entry)
  end
end

RSpec.describe DatabaseIntegrityLogSink do
  subject(:sink) { described_class.new }

  let(:entry) do
    IntegrityLogger::LogEntry.new(
      idfa: create(:user).idfa,
      ban_status: User::BANNED,
      ip: "203.0.113.1",
      rooted_device: false,
      country: "US",
      proxy: false,
      vpn: false
    )
  end

  it "persists integrity logs in PostgreSQL" do
    expect { sink.write(entry) }.to change(IntegrityLog, :count).by(1)

    log = IntegrityLog.last
    expect(log.idfa).to eq(entry.idfa)
    expect(log.ban_status).to eq(User::BANNED)
    expect(log.country).to eq("US")
  end
end
