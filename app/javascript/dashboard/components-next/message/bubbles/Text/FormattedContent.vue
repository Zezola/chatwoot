<script setup>
import { computed } from 'vue';
import { useMessageContext } from '../../provider.js';

import MessageFormatter from 'shared/helpers/MessageFormatter.js';
import { MESSAGE_VARIANTS } from '../../constants';

const props = defineProps({
  content: {
    type: String,
    required: true,
  },
});

const { variant } = useMessageContext();

const contentClass = computed(() => {
  const baseClass = 'prose prose-bubble';

  if (
    [MESSAGE_VARIANTS.AGENT, MESSAGE_VARIANTS.BOT, MESSAGE_VARIANTS.TEMPLATE].includes(
      variant.value
    )
  ) {
    return `${baseClass} dark:!text-n-slate-1 dark:[&_a]:!text-n-slate-1 dark:[&_b]:!text-n-slate-1 dark:[&_h1]:!text-n-slate-1 dark:[&_h2]:!text-n-slate-1 dark:[&_h3]:!text-n-slate-1 dark:[&_h4]:!text-n-slate-1 dark:[&_h5]:!text-n-slate-1 dark:[&_h6]:!text-n-slate-1 dark:[&_li]:!text-n-slate-1 dark:[&_ol]:!text-n-slate-1 dark:[&_p]:!text-n-slate-1 dark:[&_span]:!text-n-slate-1 dark:[&_strong]:!text-n-slate-1`;
  }

  return baseClass;
});

const formattedContent = computed(() => {
  if (variant.value === MESSAGE_VARIANTS.ACTIVITY) {
    return props.content;
  }

  return new MessageFormatter(props.content).formattedMessage;
});
</script>

<template>
  <span v-dompurify-html="formattedContent" :class="contentClass" />
</template>
