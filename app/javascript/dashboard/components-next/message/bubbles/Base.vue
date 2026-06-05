<script setup>
import { computed } from 'vue';

import MessageMeta from '../MessageMeta.vue';

import { emitter } from 'shared/helpers/mitt';
import { useMessageContext } from '../provider.js';
import { useI18n } from 'vue-i18n';

import MessageFormatter from 'shared/helpers/MessageFormatter.js';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { MESSAGE_VARIANTS, ORIENTATION, SENDER_TYPES } from '../constants';

const props = defineProps({
  hideMeta: { type: Boolean, default: false },
});

const { variant, orientation, inReplyTo, shouldGroupWithNext, sender } =
  useMessageContext();
const { t } = useI18n();

const varaintBaseMap = {
  [MESSAGE_VARIANTS.AGENT]: 'bg-[#D9FDD3] text-n-slate-12 dark:text-n-slate-1',
  [MESSAGE_VARIANTS.PRIVATE]:
    'bg-n-solid-amber text-n-amber-12 [&_.prosemirror-mention-node]:font-semibold',
  [MESSAGE_VARIANTS.USER]: 'bg-n-slate-4 text-n-slate-12',
  [MESSAGE_VARIANTS.ACTIVITY]: 'bg-n-alpha-1 text-n-slate-11 text-sm',
  [MESSAGE_VARIANTS.BOT]: 'bg-[#EEE8FF] text-n-slate-12 dark:text-n-slate-1',
  [MESSAGE_VARIANTS.TEMPLATE]: 'bg-[#EEE8FF] text-n-slate-12 dark:text-n-slate-1',
  [MESSAGE_VARIANTS.ERROR]: 'bg-n-ruby-4 text-n-ruby-12',
  [MESSAGE_VARIANTS.EMAIL]: 'w-full',
  [MESSAGE_VARIANTS.UNSUPPORTED]:
    'bg-n-solid-amber/70 border border-dashed border-n-amber-12 text-n-amber-12',
};

const orientationMap = {
  [ORIENTATION.LEFT]:
    'left-bubble rounded-xl ltr:rounded-bl-sm rtl:rounded-br-sm',
  [ORIENTATION.RIGHT]:
    'right-bubble rounded-xl ltr:rounded-br-sm rtl:rounded-bl-sm',
  [ORIENTATION.CENTER]: 'rounded-md',
};

const flexOrientationClass = computed(() => {
  const map = {
    [ORIENTATION.LEFT]: 'justify-start',
    [ORIENTATION.RIGHT]: 'justify-end',
    [ORIENTATION.CENTER]: 'justify-center',
  };

  return map[orientation.value];
});

const messageClass = computed(() => {
  const classToApply = [varaintBaseMap[variant.value]];

  if (variant.value !== MESSAGE_VARIANTS.ACTIVITY) {
    classToApply.push(orientationMap[orientation.value]);
  } else {
    classToApply.push('rounded-lg');
  }

  return classToApply;
});

const scrollToMessage = () => {
  emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE, {
    messageId: inReplyTo.value.id,
  });
};

const shouldShowMeta = computed(
  () =>
    !props.hideMeta &&
    !shouldGroupWithNext.value &&
    variant.value !== MESSAGE_VARIANTS.ACTIVITY
);

const shouldShowSenderLabel = computed(() => {
  return [
    MESSAGE_VARIANTS.AGENT,
    MESSAGE_VARIANTS.BOT,
    MESSAGE_VARIANTS.TEMPLATE,
    MESSAGE_VARIANTS.PRIVATE,
  ].includes(variant.value);
});

const isAutomatedSender = computed(() => {
  return [SENDER_TYPES.AGENT_BOT, SENDER_TYPES.CAPTAIN_ASSISTANT].includes(
    sender.value?.type
  );
});

const senderLabel = computed(() => {
  const senderName = sender.value?.name || t('CONVERSATION.BOT');

  if (isAutomatedSender.value || variant.value === MESSAGE_VARIANTS.BOT) {
    return t('CONVERSATION.SENT_BY_AI', { name: senderName });
  }

  return t('CONVERSATION.SENT_BY_FULL', { name: senderName });
});

const senderLabelClass = computed(() => {
  if (variant.value === MESSAGE_VARIANTS.PRIVATE) {
    return 'text-n-amber-12/80';
  }

  if (
    [MESSAGE_VARIANTS.AGENT, MESSAGE_VARIANTS.BOT, MESSAGE_VARIANTS.TEMPLATE].includes(
      variant.value
    )
  ) {
    return 'text-n-slate-11 dark:text-n-slate-9';
  }

  return 'text-n-slate-11';
});

const replyToPreview = computed(() => {
  if (!inReplyTo) return '';

  const { content, attachments } = inReplyTo.value;

  if (content) return new MessageFormatter(content).formattedMessage;
  if (attachments?.length) {
    const firstAttachment = attachments[0];
    const fileType = firstAttachment.fileType ?? firstAttachment.file_type;

    return t(`CHAT_LIST.ATTACHMENTS.${fileType}.CONTENT`);
  }

  return t('CONVERSATION.REPLY_MESSAGE_NOT_FOUND');
});
</script>

<template>
  <div
    class="text-sm"
    :class="[
      messageClass,
      {
        'max-w-lg': variant !== MESSAGE_VARIANTS.EMAIL,
      },
    ]"
  >
    <div
      v-if="inReplyTo"
      class="p-2 -mx-1 mb-2 rounded-lg cursor-pointer bg-n-alpha-black1"
      @click="scrollToMessage"
    >
      <div
        v-dompurify-html="replyToPreview"
        class="prose prose-bubble line-clamp-2"
      />
    </div>
    <div
      v-if="shouldShowSenderLabel"
      class="mb-2 text-xxs font-medium tracking-[0.02em]"
      :class="senderLabelClass"
    >
      {{ senderLabel }}
    </div>
    <slot />
    <MessageMeta
      v-if="shouldShowMeta"
      :class="[
        flexOrientationClass,
        variant === MESSAGE_VARIANTS.EMAIL ? 'px-3 pb-3' : '',
        variant === MESSAGE_VARIANTS.PRIVATE
          ? 'text-n-amber-12/50'
          : [
                MESSAGE_VARIANTS.AGENT,
                MESSAGE_VARIANTS.BOT,
                MESSAGE_VARIANTS.TEMPLATE,
              ].includes(variant)
            ? 'text-n-slate-11 dark:text-n-slate-9'
          : 'text-n-slate-11',
      ]"
      class="mt-2"
    />
  </div>
</template>
