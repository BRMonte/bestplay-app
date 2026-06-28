class CheckStatusService
  def initialize(idfa:, rooted_device:, ip:, country:, logger: IntegrityLogger.new)
    @idfa = idfa
    @rooted_device = rooted_device
    @ip = ip
    @country = country
    @logger = logger
  end

  def call
    user = User.find_by(idfa: idfa)

    if user&.banned?
      return { ban_status: User::BANNED }
    end

    check_result = run_checks
    new_status = check_result[:banned] ? User::BANNED : User::NOT_BANNED
    previous_status = user&.ban_status
    newly_created = user.nil?

    user = persist_user(user, new_status)

    log_status_change(
      newly_created: newly_created,
      previous_status: previous_status,
      new_status: new_status,
      check_result: check_result
    )

    { ban_status: user.ban_status }
  end

  private

  attr_reader :idfa, :rooted_device, :ip, :country, :logger

  def run_checks
    country_result = Checks::CountryWhitelist.new(country: country).call
    return merge_network_details(country_result) if country_result[:banned]

    rooted_result = Checks::RootedDevice.new(rooted_device: rooted_device).call
    return merge_network_details(rooted_result) if rooted_result[:banned]

    Checks::VpnTor.new(ip: ip).call
  end

  def merge_network_details(result)
    result.merge(vpn: false, tor: false, proxy: false)
  end

  def persist_user(user, new_status)
    return User.create!(idfa: idfa, ban_status: new_status) if user.nil?

    user.update!(ban_status: new_status)
    user
  end

  def log_status_change(newly_created:, previous_status:, new_status:, check_result:)
    return unless newly_created || previous_status != new_status

    logger.log(
      IntegrityLogger::LogEntry.new(
        idfa: idfa,
        ban_status: new_status,
        ip: ip,
        rooted_device: rooted_device,
        country: country,
        proxy: check_result.fetch(:proxy, false),
        vpn: check_result.fetch(:vpn, false)
      )
    )
  end
end
