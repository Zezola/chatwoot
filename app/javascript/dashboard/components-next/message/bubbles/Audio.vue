<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import AudioChip from 'next/message/chips/Audio.vue';
import { useMessageContext } from '../provider.js';

const { attachments, isPrivate } = useMessageContext();

const attachment = computed(() => {
  return attachments.value[0];
});
</script>

<template>
  <BaseBubble
    :class="isPrivate ? 'p-2' : 'bg-transparent'"
    data-bubble-name="audio"
  >
    <AudioChip
      :attachment="attachment"
      :is-private="isPrivate"
      :class="isPrivate ? 'text-n-amber-12' : 'p-2 text-n-slate-12'"
      class="skip-context-menu"
    />
  </BaseBubble>
</template>
