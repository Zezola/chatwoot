import { can } from './can';

export const shouldShowAllConversationShortcut = acl =>
  can(acl, 'conversation.view_all');

export const shouldShowMineConversationShortcut = acl =>
  !shouldShowAllConversationShortcut(acl);
