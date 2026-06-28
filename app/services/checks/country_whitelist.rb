module Checks
  class CountryWhitelist
    def initialize(country:)
      @country = country
    end

    def call
      return banned if country.blank?
      return banned unless ::CountryWhitelist.allowed?(country)

      pass
    end

    private

    attr_reader :country

    def pass
      { banned: false }
    end

    def banned
      { banned: true, reason: "country_not_whitelisted" }
    end
  end
end
