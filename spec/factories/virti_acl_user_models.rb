FactoryBot.define do
  factory :virti_acl_user_model, class: 'Virti::Acl::UserModel' do
    account
    user
    association :model, factory: :virti_acl_model
  end
end
