require 'rails_helper'

RSpec.describe Virti::Acl::PermissionsResolver do
  describe '#perform' do
    it 'returns default permissions when user has no ACL record' do
      user = create(:user)

      permissions = described_class.new(user: user).perform

      expect(permissions['pode_ver_menu_kanban']).to be true
      expect(permissions['pode_filtrar_sem_times']).to be true
    end

    it 'merges user permissions over defaults' do
      user = create(:user)
      Virti::Acl::UserPermission.create!(
        IdUsuario: user.id,
        Permissoes: { 'pode_ver_menu_kanban' => false },
        CriadoEm: Time.current,
        AtualizadoEm: Time.current
      )

      permissions = described_class.new(user: user).perform

      expect(permissions['pode_ver_menu_kanban']).to be false
      expect(permissions['pode_filtrar_sem_times']).to be true
    end

    it 'uses model permissions before legacy user permissions when account is present' do
      account = create(:account)
      user = create(:user, account: account)
      model = create(:virti_acl_model, account: account, permissions: { 'pode_ver_menu_kanban' => true })
      create(:virti_acl_user_model, account: account, user: user, model: model)
      Virti::Acl::UserPermission.create!(
        IdUsuario: user.id,
        Permissoes: { 'pode_ver_menu_kanban' => false },
        CriadoEm: Time.current,
        AtualizadoEm: Time.current
      )

      permissions = described_class.new(user: user, account: account).perform

      expect(permissions['pode_ver_menu_kanban']).to be true
    end

    it 'falls back to legacy user permissions when user has no model in the account' do
      account = create(:account)
      user = create(:user, account: account)
      Virti::Acl::UserPermission.create!(
        IdUsuario: user.id,
        Permissoes: { 'pode_ver_menu_kanban' => false },
        CriadoEm: Time.current,
        AtualizadoEm: Time.current
      )

      permissions = described_class.new(user: user, account: account).perform

      expect(permissions['pode_ver_menu_kanban']).to be false
    end

    it 'ignores soft-deleted user permissions' do
      user = create(:user)
      Virti::Acl::UserPermission.create!(
        IdUsuario: user.id,
        Permissoes: { 'pode_ver_menu_kanban' => false },
        CriadoEm: Time.current,
        AtualizadoEm: Time.current,
        DeletadoEm: Time.current
      )

      permissions = described_class.new(user: user).perform

      expect(permissions['pode_ver_menu_kanban']).to be true
    end

    it 'removes legacy keys from stored permissions' do
      user = create(:user)
      Virti::Acl::UserPermission.create!(
        IdUsuario: user.id,
        Permissoes: { 'time_privado' => false, 'pode_ver_menu_kanban' => false },
        CriadoEm: Time.current,
        AtualizadoEm: Time.current
      )

      permissions = described_class.new(user: user).perform

      expect(permissions).not_to have_key('time_privado')
      expect(permissions['pode_ver_menu_kanban']).to be false
    end

    it 'returns permissive defaults when ACL is disabled' do
      user = create(:user)
      Virti::Acl::UserPermission.create!(
        IdUsuario: user.id,
        Permissoes: { 'pode_ver_menu_kanban' => false },
        CriadoEm: Time.current,
        AtualizadoEm: Time.current
      )

      with_modified_env VIRTI_ACL_ENABLED: 'false' do
        permissions = described_class.new(user: user).perform

        expect(permissions['pode_ver_menu_kanban']).to be true
      end
    end

    it 'reports model source only when user has an explicit model assignment' do
      account = create(:account)
      user = create(:user, account: account)
      model = create(:virti_acl_model, account: account, permissions: { 'pode_ver_menu_kanban' => false })
      create(:virti_acl_user_model, account: account, user: user, model: model)

      result = described_class.new(user: user, account: account).resolve

      expect(result.acl_source).to eq('model')
      expect(result.model).to eq(model)
      expect(result.permissions['pode_ver_menu_kanban']).to be false
    end

    it 'reports individual source when ACL matches a model but there is no explicit assignment' do
      account = create(:account)
      user = create(:user, account: account)
      create(:virti_acl_model, account: account, permissions: { 'pode_ver_menu_kanban' => false })
      Virti::Acl::UserPermission.create!(
        IdUsuario: user.id,
        Permissoes: { 'pode_ver_menu_kanban' => false },
        CriadoEm: Time.current,
        AtualizadoEm: Time.current
      )

      result = described_class.new(user: user, account: account).resolve

      expect(result.acl_source).to eq('individual')
      expect(result.model).to be_nil
      expect(result.permissions['pode_ver_menu_kanban']).to be false
    end

    it 'reports default source when user has no model or legacy ACL' do
      user = create(:user)

      result = described_class.new(user: user).resolve

      expect(result.acl_source).to eq('default')
      expect(result.model).to be_nil
      expect(result.permissions['pode_ver_menu_kanban']).to be true
    end

    it 'reports disabled source when ACL is disabled' do
      user = create(:user)

      with_modified_env VIRTI_ACL_ENABLED: 'false' do
        result = described_class.new(user: user).resolve

        expect(result.acl_source).to eq('disabled')
        expect(result.model).to be_nil
        expect(result.permissions['pode_ver_menu_kanban']).to be true
      end
    end
  end
end
