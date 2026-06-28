module ClientIp
  module_function

  def from(headers:, remote_ip:)
    headers["CF-Connecting-IP"].presence || remote_ip
  end
end
