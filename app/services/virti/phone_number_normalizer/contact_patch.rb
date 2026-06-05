module Virti
  module PhoneNumberNormalizer
    module ContactPatch
      extend ActiveSupport::Concern

      included do
        before_validation :normalize_virti_phone_number
      end

      private

      def normalize_virti_phone_number
        self.phone_number = Virti::PhoneNumberNormalizer.normalize_e164(phone_number)
      end
    end
  end
end
