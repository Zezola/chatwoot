<script>
import Modal from '../../Modal.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    Modal,
    NextButton,
  },
  props: {
    title: {
      type: String,
      default: '',
    },
    description: {
      type: String,
      default: '',
    },
    confirmLabel: {
      type: String,
      default: 'Sim',
    },
    cancelLabel: {
      type: String,
      default: 'Não',
    },
  },
  data() {
    return {
      show: false,
      resolvePromise: null,
    };
  },
  methods: {
    showConfirmation() {
      this.show = true;
      return new Promise(resolve => {
        this.resolvePromise = resolve;
      });
    },
    confirm() {
      this.resolvePromise?.(true);
      this.show = false;
    },
    cancel() {
      this.resolvePromise?.(false);
      this.show = false;
    },
  },
};
</script>

<template>
  <Modal v-model:show="show" :on-close="cancel">
    <div class="h-auto overflow-auto flex flex-col">
      <woot-modal-header :header-title="title" :header-content="description" />
      <div class="flex flex-row justify-end gap-2 py-4 px-6 w-full">
        <NextButton type="submit" :label="confirmLabel" @click="confirm" />
        <NextButton faded type="reset" :label="cancelLabel" @click="cancel" />
      </div>
    </div>
  </Modal>
</template>
