Rails.application.config.to_prepare do
  patch = Virti::PhoneNumberNormalizer::ContactPatch

  Contact.include(patch) unless Contact.included_modules.include?(patch)
end
