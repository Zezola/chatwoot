import AudioNotificationStore from '../AudioNotificationStore';
describe('AudioNotificationStore', () => {
  let store;
  let audioNotificationStore;

  beforeEach(() => {
    store = {
      getters: {
        getMineChats: vi.fn(),
        getSelectedChat: null,
        getCurrentAccountId: 1,
        getConversationById: vi.fn(),
      },
    };
    audioNotificationStore = new AudioNotificationStore(store);
  });

  describe('hasUnreadConversation', () => {
    it('should return true when there are unread conversations', () => {
      store.getters.getMineChats.mockReturnValue([
        { id: 1, unread_count: 2 },
        { id: 2, unread_count: 0 },
      ]);

      expect(audioNotificationStore.hasUnreadConversation()).toBe(true);
    });

    it('should return false when there are no unread conversations', () => {
      store.getters.getMineChats.mockReturnValue([
        { id: 1, unread_count: 0 },
        { id: 2, unread_count: 0 },
      ]);

      expect(audioNotificationStore.hasUnreadConversation()).toBe(false);
    });

    it('should return false when there are no conversations', () => {
      store.getters.getMineChats.mockReturnValue([]);

      expect(audioNotificationStore.hasUnreadConversation()).toBe(false);
    });

    it('should call getMineChats with correct parameters', () => {
      store.getters.getMineChats.mockReturnValue([]);
      audioNotificationStore.hasUnreadConversation();

      expect(store.getters.getMineChats).toHaveBeenCalledWith({
        assigneeType: 'me',
        status: 'open',
      });
    });
  });
});
