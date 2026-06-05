require 'rails_helper'

RSpec.describe Virti::Acl::UserPermission do
  describe 'table mapping' do
    it 'uses the legacy ACL table and primary key' do
      expect(described_class.table_name).to eq('Virti_UsuarioACL')
      expect(described_class.primary_key).to eq('Id')
    end
  end

  describe '#permissions' do
    it 'returns stored permissions as a hash' do
      user = create(:user)
      permission = described_class.create!(
        IdUsuario: user.id,
        Permissoes: { 'pode_ver_menu_kanban' => false },
        CriadoEm: Time.current,
        AtualizadoEm: Time.current
      )

      expect(permission.permissions).to eq('pode_ver_menu_kanban' => false)
    end
  end

  describe '.active' do
    it 'excludes soft-deleted records' do
      user = create(:user)
      described_class.create!(IdUsuario: user.id, Permissoes: {}, CriadoEm: Time.current, AtualizadoEm: Time.current, DeletadoEm: Time.current)

      expect(described_class.active).to be_empty
    end
  end
end
