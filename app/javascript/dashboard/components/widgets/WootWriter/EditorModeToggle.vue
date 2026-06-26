<script setup>
import { computed, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useElementSize } from '@vueuse/core';
import { REPLY_EDITOR_MODES } from './constants';

const props = defineProps({
  mode: {
    type: String,
    default: REPLY_EDITOR_MODES.REPLY,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  isReplyRestricted: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['toggleMode']);

const { t } = useI18n();

const wootEditorReplyMode = useTemplateRef('wootEditorReplyMode');
const wootEditorPrivateMode = useTemplateRef('wootEditorPrivateMode');

const replyModeSize = useElementSize(wootEditorReplyMode);
const privateModeSize = useElementSize(wootEditorPrivateMode);

/**
 * Computed boolean indicating if the editor is in private note mode
 * When isReplyRestricted is true, force switch to private note
 * Otherwise, respect the current mode prop
 * @type {ComputedRef<boolean>}
 */
const isPrivate = computed(() => {
  if (props.isReplyRestricted) {
    // Force switch to private note when replies are restricted
    return true;
  }
  // Otherwise respect the current mode
  return props.mode === REPLY_EDITOR_MODES.NOTE;
});

/**
 * Computes the width of the sliding background chip in pixels
 * Includes 16px of padding in the calculation
 * @type {ComputedRef<string>}
 */
const width = computed(() => {
  const widthToUse = isPrivate.value
    ? privateModeSize.width.value
    : replyModeSize.width.value;

  const widthWithPadding = widthToUse + 16;
  return `${widthWithPadding}px`;
});

/**
 * Computes the X translation value for the sliding background chip
 * Translates by the width of reply mode + padding when in private mode
 * @type {ComputedRef<string>}
 */
const translateValue = computed(() => {
  const xTranslate = isPrivate.value ? replyModeSize.width.value + 16 : 0;

  return `${xTranslate}px`;
});

const toggleClass = computed(() => {
  return isPrivate.value
    ? 'border-[#f6c978] bg-[#fff7e8] text-n-slate-12 dark:text-n-slate-1'
    : 'border-[#d9fdd3] bg-[#d9fdd3] text-n-slate-12 dark:text-n-slate-1';
});

const activeChipClass = computed(() => {
  return isPrivate.value ? 'bg-[#ffe1a6]' : 'bg-white/70';
});

const abbreviateReplyBoxLabel = label => {
  const replyPrefix = 'Responder ';
  const replyToTeamPrefix = 'Responder para o ';
  const prefix = label.startsWith(replyToTeamPrefix)
    ? replyToTeamPrefix
    : replyPrefix;

  if (!label.startsWith(prefix)) return label;

  const remainingText = label.slice(prefix.length);
  return `Resp. ${remainingText.charAt(0).toUpperCase()}${remainingText.slice(1)}`;
};

const replyLabel = computed(() => t('CONVERSATION.REPLYBOX.REPLY'));
const privateNoteLabel = computed(() =>
  t('CONVERSATION.REPLYBOX.PRIVATE_NOTE')
);

const mobileReplyLabel = computed(() =>
  abbreviateReplyBoxLabel(replyLabel.value)
);
const mobilePrivateNoteLabel = computed(() =>
  abbreviateReplyBoxLabel(privateNoteLabel.value)
);
</script>

<template>
  <button
    class="flex items-center w-auto h-8 p-1 transition-all border rounded-full bg-n-alpha-2 group relative duration-300 ease-in-out z-0 active:scale-[0.995] active:duration-75"
    :disabled="disabled || isReplyRestricted"
    :class="[
      toggleClass,
      {
        'cursor-not-allowed': disabled || isReplyRestricted,
      },
    ]"
    @click="$emit('toggleMode')"
  >
    <div ref="wootEditorReplyMode" class="flex items-center gap-1 px-2 z-20">
      <span class="hidden xs:inline">{{ replyLabel }}</span>
      <span class="xs:hidden">{{ mobileReplyLabel }}</span>
    </div>
    <div ref="wootEditorPrivateMode" class="flex items-center gap-1 px-2 z-20">
      <span class="hidden xs:inline">{{ privateNoteLabel }}</span>
      <span class="xs:hidden">{{ mobilePrivateNoteLabel }}</span>
    </div>
    <div
      class="absolute shadow-sm rounded-full h-6 w-[var(--chip-width)] ease-in-out translate-x-[var(--translate-x)] rtl:translate-x-[var(--rtl-translate-x)]"
      :class="{
        [activeChipClass]: true,
        'transition-all duration-300': !disabled && !isReplyRestricted,
      }"
      :style="{
        '--chip-width': width,
        '--translate-x': translateValue,
        '--rtl-translate-x': `calc(-1 * var(--translate-x))`,
      }"
    />
  </button>
</template>
