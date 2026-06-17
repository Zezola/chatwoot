import { describe, it, expect, beforeEach, vi } from 'vitest';
import { DashboardAudioNotificationHelper } from '../DashboardAudioNotificationHelper';
import WindowVisibilityHelper from '../WindowVisibilityHelper';
import { showBadgeOnFavicon } from '../faviconHelper';

vi.mock('dashboard/store', () => ({
  default: {
    getters: {},
  },
}));

vi.mock('../WindowVisibilityHelper', () => ({
  default: {
    isWindowVisible: vi.fn(),
  },
}));

vi.mock('../faviconHelper', () => ({
  showBadgeOnFavicon: vi.fn(),
  initFaviconSwitcher: vi.fn(),
}));

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

describe('DashboardAudioNotificationHelper', () => {
  let helper;
  let store;

  beforeEach(() => {
    vi.clearAllMocks();

    store = {
      getters: {
        getMineChats: vi.fn(() => []),
        getSelectedChat: null,
        getCurrentAccountId: 1,
        getConversationById: vi.fn(),
      },
    };
    helper = new DashboardAudioNotificationHelper(store);
    helper.currentUser = { id: 1 };
    helper.notificationConfig = {
      audioAlertType: ['assigned'],
      playAlertOnlyWhenHidden: false,
      alertIfUnreadConversationExist: false,
    };
    vi.spyOn(helper, 'playAudioAlert').mockResolvedValue();
    vi.spyOn(helper, 'playAudioEvery30Seconds').mockImplementation(() => {});
    WindowVisibilityHelper.isWindowVisible.mockReturnValue(false);
  });

  describe('onNotificationCreated', () => {
    it('plays audio for notification.created events when audio alerts are enabled', () => {
      helper.onNotificationCreated();

      expect(helper.playAudioAlert).toHaveBeenCalled();
      expect(showBadgeOnFavicon).toHaveBeenCalled();
      expect(helper.playAudioEvery30Seconds).toHaveBeenCalled();
    });

    it('does not play audio when audio alerts are disabled', () => {
      helper.notificationConfig.audioAlertType = ['none'];

      helper.onNotificationCreated();

      expect(helper.playAudioAlert).not.toHaveBeenCalled();
      expect(showBadgeOnFavicon).not.toHaveBeenCalled();
    });

    it('does not play audio on active tabs when alerts are limited to hidden tabs', () => {
      helper.notificationConfig.playAlertOnlyWhenHidden = true;
      WindowVisibilityHelper.isWindowVisible.mockReturnValue(true);

      helper.onNotificationCreated();

      expect(helper.playAudioAlert).not.toHaveBeenCalled();
      expect(showBadgeOnFavicon).not.toHaveBeenCalled();
    });
  });
});
