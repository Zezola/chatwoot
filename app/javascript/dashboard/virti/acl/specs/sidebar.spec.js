import {
  shouldShowAllConversationShortcut,
  shouldShowMineConversationShortcut,
} from '../sidebar';

describe('#conversation sidebar shortcuts', () => {
  it('shows All and hides Mine when user can view all conversations', () => {
    const acl = { pode_ver_aba_de_todas_conversas: true };

    expect(shouldShowAllConversationShortcut(acl)).toBe(true);
    expect(shouldShowMineConversationShortcut(acl)).toBe(false);
  });

  it('shows Mine and hides All when user cannot view all conversations', () => {
    const acl = { pode_ver_aba_de_todas_conversas: false };

    expect(shouldShowAllConversationShortcut(acl)).toBe(false);
    expect(shouldShowMineConversationShortcut(acl)).toBe(true);
  });
});
