class DatabaseIntegrityLogSink
  def write(entry)
    IntegrityLog.create!(
      idfa: entry.idfa,
      ban_status: entry.ban_status,
      ip: entry.ip,
      rooted_device: entry.rooted_device,
      country: entry.country,
      proxy: entry.proxy,
      vpn: entry.vpn
    )
  end
end
