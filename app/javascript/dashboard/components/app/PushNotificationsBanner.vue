<script>
import Banner from 'dashboard/components/ui/Banner.vue';
import Modal from '../Modal.vue';
import {
  requestPushPermissions,
  verifyServiceWorkerExistence,
} from 'dashboard/helper/pushHelper';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { LocalStorage } from 'shared/helpers/localStorage';

export default {
  components: {
    Banner,
    Modal,
  },
  props: {
    accountId: {
      type: [Number, String],
      default: null,
    },
    currentUser: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      hasPushSubscription: false,
      isInstructionModalOpen: false,
      isDismissed: false,
      permissionState: 'default',
    };
  },
  computed: {
    storageKey() {
      return `${this.accountId}:${this.currentUser?.id || 'anonymous'}`;
    },
    isIOSDevice() {
      const { userAgent, maxTouchPoints } = window.navigator;
      return (
        /iPad|iPhone|iPod/.test(userAgent) ||
        (userAgent.includes('Macintosh') && maxTouchPoints > 1)
      );
    },
    isStandaloneMode() {
      return (
        window.matchMedia('(display-mode: standalone)').matches ||
        window.navigator.standalone === true
      );
    },
    supportsPushNotifications() {
      return (
        'Notification' in window &&
        'serviceWorker' in navigator &&
        'PushManager' in window
      );
    },
    shouldShowIOSInstructions() {
      return this.isIOSDevice && !this.isStandaloneMode;
    },
    shouldShowBanner() {
      if (this.isDismissed) {
        return false;
      }

      if (this.shouldShowIOSInstructions) {
        return true;
      }

      if (!this.supportsPushNotifications) {
        return false;
      }

      if (this.permissionState === 'denied') {
        return true;
      }

      return !(this.permissionState === 'granted' && this.hasPushSubscription);
    },
    bannerMessage() {
      if (this.shouldShowIOSInstructions) {
        return this.$t('APP_GLOBAL.PUSH_NOTIFICATION_BANNER.IOS_MESSAGE');
      }

      if (this.permissionState === 'denied') {
        return this.$t('APP_GLOBAL.PUSH_NOTIFICATION_BANNER.DENIED_MESSAGE');
      }

      return this.$t('APP_GLOBAL.PUSH_NOTIFICATION_BANNER.DEFAULT_MESSAGE');
    },
    actionButtonLabel() {
      if (this.shouldShowIOSInstructions) {
        return this.$t('APP_GLOBAL.PUSH_NOTIFICATION_BANNER.IOS_ACTION');
      }

      if (this.permissionState === 'denied') {
        return '';
      }

      return this.$t('APP_GLOBAL.PUSH_NOTIFICATION_BANNER.DEFAULT_ACTION');
    },
    shouldShowActionButton() {
      return !!this.actionButtonLabel;
    },
    closeButtonLabel() {
      return this.$t('APP_GLOBAL.PUSH_NOTIFICATION_BANNER.DISMISS_ACTION');
    },
  },
  watch: {
    storageKey() {
      this.isDismissed = this.getDismissedState();
      this.syncPushState();
    },
  },
  mounted() {
    this.isDismissed = this.getDismissedState();
    this.syncPushState();
    window.addEventListener('focus', this.syncPushState);
  },
  beforeUnmount() {
    window.removeEventListener('focus', this.syncPushState);
  },
  methods: {
    closeInstructionsModal() {
      this.isInstructionModalOpen = false;
    },
    getDismissedState() {
      return !!LocalStorage.getFromJsonStore(
        LOCAL_STORAGE_KEYS.PUSH_NOTIFICATION_BANNER_DISMISSED,
        this.storageKey
      );
    },
    dismissBanner() {
      LocalStorage.updateJsonStore(
        LOCAL_STORAGE_KEYS.PUSH_NOTIFICATION_BANNER_DISMISSED,
        this.storageKey,
        true
      );
      this.isDismissed = true;
    },
    syncPushState() {
      this.permissionState =
        'Notification' in window ? Notification.permission : 'unsupported';

      if (this.shouldShowIOSInstructions || !this.supportsPushNotifications) {
        this.hasPushSubscription = false;
        return;
      }

      verifyServiceWorkerExistence(registration =>
        registration.pushManager
          .getSubscription()
          .then(subscription => {
            this.hasPushSubscription = !!subscription;
          })
          .catch(() => {
            this.hasPushSubscription = false;
          })
      );
    },
    triggerPrimaryAction() {
      if (this.shouldShowIOSInstructions) {
        this.isInstructionModalOpen = true;
        return;
      }

      requestPushPermissions({
        onSuccess: this.syncPushState,
      });
    },
  },
};
</script>

<template>
  <Banner
    v-if="shouldShowBanner"
    color-scheme="secondary"
    :banner-message="bannerMessage"
    :action-button-label="actionButtonLabel"
    :close-button-label="closeButtonLabel"
    action-button-icon="i-lucide-bell"
    :has-action-button="shouldShowActionButton"
    has-close-button
    @primary-action="triggerPrimaryAction"
    @close="dismissBanner"
  />

  <Modal
    v-model:show="isInstructionModalOpen"
    :on-close="closeInstructionsModal"
  >
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header
        :header-title="
          $t('APP_GLOBAL.PUSH_NOTIFICATION_BANNER.IOS_MODAL.TITLE')
        "
        :header-content="
          $t('APP_GLOBAL.PUSH_NOTIFICATION_BANNER.IOS_MODAL.DESCRIPTION')
        "
      />
      <ol class="push-banner__steps">
        <li>
          {{ $t('APP_GLOBAL.PUSH_NOTIFICATION_BANNER.IOS_MODAL.STEP_1') }}
        </li>
        <li>
          {{ $t('APP_GLOBAL.PUSH_NOTIFICATION_BANNER.IOS_MODAL.STEP_2') }}
        </li>
        <li>
          {{ $t('APP_GLOBAL.PUSH_NOTIFICATION_BANNER.IOS_MODAL.STEP_3') }}
        </li>
        <li>
          {{ $t('APP_GLOBAL.PUSH_NOTIFICATION_BANNER.IOS_MODAL.STEP_4') }}
        </li>
      </ol>
    </div>
  </Modal>
</template>

<style scoped lang="scss">
.push-banner__steps {
  @apply list-decimal px-10 pb-6 m-0 text-sm text-n-slate-12 space-y-3;
}
</style>
