import VirtiAclAPI from '../api';

describe('#VirtiAclAPI', () => {
  const originalAxios = window.axios;
  const originalPathname = window.location.pathname;
  const axiosMock = {
    get: vi.fn(() => Promise.resolve()),
    patch: vi.fn(() => Promise.resolve()),
  };

  beforeEach(() => {
    window.axios = axiosMock;
  });

  afterEach(() => {
    window.axios = originalAxios;
    window.history.pushState({}, '', originalPathname);
    vi.clearAllMocks();
  });

  it('uses account-scoped Rails endpoint inside account routes', () => {
    window.history.pushState({}, '', '/app/accounts/2/dashboard');

    new VirtiAclAPI().getCurrent();

    expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/accounts/2/virti/acl');
  });

  it('falls back to legacy ACL endpoint outside account routes', () => {
    window.history.pushState({}, '', '/app/login');

    new VirtiAclAPI().getCurrent();

    expect(axiosMock.get).toHaveBeenCalledWith('/acl');
  });

  it('wraps permissions when updating through the Rails endpoint', () => {
    window.history.pushState({}, '', '/app/accounts/2/dashboard');

    new VirtiAclAPI().updateUser(10, { pode_ver_menu_kanban: false });

    expect(axiosMock.patch).toHaveBeenCalledWith('/api/v1/accounts/2/virti/acl/10', {
      permissions: { pode_ver_menu_kanban: false },
    });
  });

  it('removes response metadata when updating through the Rails endpoint', () => {
    window.history.pushState({}, '', '/app/accounts/2/dashboard');

    new VirtiAclAPI().updateUser(10, {
      pode_ver_menu_kanban: false,
      aclSource: 'individual',
      model: null,
      userId: 10,
    });

    expect(axiosMock.patch).toHaveBeenCalledWith('/api/v1/accounts/2/virti/acl/10', {
      permissions: { pode_ver_menu_kanban: false },
    });
  });
});
