module Virti
  module PhoneNumberNormalizer
    BRAZIL_COUNTRY_CODE = '55'.freeze
    BRAZIL_MOBILE_CANDIDATE_DIGITS = %w[8 9].freeze

    def self.normalize(value, force_plus: false)
      return value if value.blank?

      raw_value = value.to_s
      digits = raw_value.gsub(/\D/, '')
      return raw_value if digits.blank?

      plus = force_plus || raw_value.start_with?('+') ? '+' : ''
      digits = normalize_brazilian_mobile_number(digits)

      "#{plus}#{digits}"
    end

    def self.normalize_e164(value)
      return value if value.blank?

      raw_value = value.to_s
      digits = raw_value.gsub(/\D/, '')
      return value if digits.blank?

      return normalize(raw_value, force_plus: true) if raw_value.start_with?('+') || brazilian_number?(digits)

      value
    end

    def self.normalize_brazilian_mobile_number(digits)
      return digits unless missing_brazilian_ninth_digit?(digits)

      digits.dup.insert(4, '9')
    end
    private_class_method :normalize_brazilian_mobile_number

    def self.brazilian_number?(digits)
      digits.start_with?(BRAZIL_COUNTRY_CODE)
    end
    private_class_method :brazilian_number?

    def self.missing_brazilian_ninth_digit?(digits)
      digits.match?(/\A55\d{10}\z/) && BRAZIL_MOBILE_CANDIDATE_DIGITS.include?(digits[4])
    end
    private_class_method :missing_brazilian_ninth_digit?
  end
end
