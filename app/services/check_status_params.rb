class CheckStatusParams
  class Invalid < StandardError; end

  attr_reader :idfa, :rooted_device, :ip, :country

  def initialize(params, headers:, remote_ip:)
    permitted = params.permit(:idfa, :rooted_device)

    @idfa = permitted[:idfa]
    @rooted_device = parse_rooted_device!(permitted)
    @ip = ClientIp.from(headers: headers, remote_ip: remote_ip)
    @country = headers["CF-IPCountry"]

    validate!
  end

  private

  def validate!
    raise Invalid, "idfa is required" if idfa.blank?
  end

  def parse_rooted_device!(permitted)
    unless permitted.key?(:rooted_device)
      raise Invalid, "rooted_device is required"
    end

    value = permitted[:rooted_device]
    return value if value == true || value == false

    raise Invalid, "rooted_device must be a boolean" if value.nil?

    cast = ActiveModel::Type::Boolean.new.cast(value)
    raise Invalid, "rooted_device must be a boolean" if cast.nil?

    cast
  end
end
