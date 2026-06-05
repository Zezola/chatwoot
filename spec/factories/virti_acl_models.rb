FactoryBot.define do
  factory :virti_acl_model, class: 'Virti::Acl::Model' do
    account
    sequence(:name) { |n| "ACL Model #{n}" }
    description { 'ACL model for tests' }
    permissions { { 'pode_ver_menu_kanban' => false } }
  end
end
