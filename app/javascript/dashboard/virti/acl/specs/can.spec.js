import { can } from '../can';

describe('#can', () => {
  it('returns true for unknown permissions by default', () => {
    expect(can({}, 'unknown.permission')).toBe(true);
  });

  it('maps semantic permissions to legacy keys', () => {
    expect(can({ pode_ver_menu_kanban: false }, 'sidebar.kanban')).toBe(false);
    expect(can({ pode_ver_menu_kanban: true }, 'sidebar.kanban')).toBe(true);
  });
});
