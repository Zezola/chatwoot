import { describe, it, beforeEach, expect, vi } from 'vitest';
import ActionCableConnector from '../actionCable';
import DashboardAudioNotificationHelper from '../AudioAlerts/DashboardAudioNotificationHelper';

vi.mock('shared/helpers/mitt', () => ({
  emitter: {
    emit: vi.fn(),
  },
}));

vi.mock('dashboard/composables/useImpersonation', () => ({
  useImpersonation: () => ({
    isImpersonating: { value: false },
  }),
}));

vi.mock('../AudioAlerts/DashboardAudioNotificationHelper', () => ({
  default: {
    onNotificationCreated: vi.fn(),
  },
}));

global.chatwootConfig = {
  websocketURL: 'wss://test.chatwoot.com',
};

describe('ActionCableConnector - Copilot Tests', () => {
  let store;
  let actionCable;
  let mockDispatch;

  beforeEach(() => {
    vi.clearAllMocks();
    mockDispatch = vi.fn();
    store = {
      $store: {
        dispatch: mockDispatch,
        getters: {
          getCurrentAccountId: 1,
        },
      },
    };

    actionCable = ActionCableConnector.init(store.$store, 'test-token');
  });
  describe('copilot event handlers', () => {
    it('should register the copilot.message.created event handler', () => {
      expect(Object.keys(actionCable.events)).toContain(
        'copilot.message.created'
      );
      expect(actionCable.events['copilot.message.created']).toBe(
        actionCable.onCopilotMessageCreated
      );
    });

    it('should handle the copilot.message.created event through the ActionCable system', () => {
      const copilotData = {
        id: 2,
        content: 'This is a copilot message from ActionCable',
        conversation_id: 456,
        created_at: '2025-05-27T15:58:04-06:00',
        account_id: 1,
      };
      actionCable.onReceived({
        event: 'copilot.message.created',
        data: copilotData,
      });
      expect(mockDispatch).toHaveBeenCalledWith(
        'copilotMessages/upsert',
        copilotData
      );
    });
  });

  describe('notification event handlers', () => {
    it('should store message.created events without playing audio directly', () => {
      const messageData = {
        account_id: 1,
        id: 20,
        conversation_id: 580,
        conversation: { last_activity_at: 1718636000 },
      };

      actionCable.onReceived({
        event: 'message.created',
        data: messageData,
      });

      expect(
        DashboardAudioNotificationHelper.onNotificationCreated
      ).not.toHaveBeenCalled();
      expect(mockDispatch).toHaveBeenCalledWith('addMessage', messageData);
      expect(mockDispatch).toHaveBeenCalledWith(
        'updateConversationLastActivity',
        {
          lastActivityAt: 1718636000,
          conversationId: 580,
        }
      );
    });

    it('should play audio and store notification.created events', () => {
      const notificationData = {
        account_id: 1,
        notification: { id: 10, notification_type: 'conversation_assignment' },
      };

      actionCable.onReceived({
        event: 'notification.created',
        data: notificationData,
      });

      expect(
        DashboardAudioNotificationHelper.onNotificationCreated
      ).toHaveBeenCalled();
      expect(mockDispatch).toHaveBeenCalledWith(
        'notifications/addNotification',
        notificationData
      );
    });
  });
});
