<script>
import VirtiKanbanAPI from 'dashboard/virti/kanban/api';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import { conversationUrl, frontendURL } from '../../../helper/URLHelper';
import Spinner from '../../../../shared/components/Spinner.vue'

const kanbanApi = new VirtiKanbanAPI();
const CARDS_PER_PAGE = 30;
const SCROLL_THRESHOLD = 80;
const ACTIVITY_REFRESH_DELAY = 1000;
const COLUMN_COLOR_CLASSES = {
  blue: 'bg-gradient-to-br from-n-blue-3 via-n-blue-4 to-n-blue-5 border-n-blue-8',
  teal: 'bg-gradient-to-br from-n-teal-3 via-n-teal-4 to-n-teal-5 border-n-teal-8',
  amber: 'bg-gradient-to-br from-n-amber-3 via-n-amber-4 to-n-amber-5 border-n-amber-8',
  violet: 'bg-gradient-to-br from-n-violet-3 via-n-violet-4 to-n-violet-5 border-n-violet-8',
  ruby: 'bg-gradient-to-br from-n-ruby-3 via-n-ruby-4 to-n-ruby-5 border-n-ruby-8',
  iris: 'bg-gradient-to-br from-n-iris-3 via-n-iris-4 to-n-iris-5 border-n-iris-8',
  gray: 'bg-gradient-to-br from-n-gray-3 via-n-gray-4 to-n-gray-5 border-n-gray-8',
  slate: 'bg-gradient-to-br from-n-slate-5 via-n-slate-6 to-n-slate-7 border-n-slate-9',
};

export default {
  components: {
    Spinner
  },
  name: 'Kanban',
  
  props: {
    /**
     * Columns data. Use v-model:columns to get updates when items move.
     */
    columns: {
      type: Array,
      required: false
    }
  },

  emits: ['update:columns', 'moved'],

  async mounted() {
    await this.$store.dispatch('labels/get')
    const labelsFromStore = this.$store.getters['labels/getLabels']
    this.allLabels = [...labelsFromStore]
    emitter.on(BUS_EVENTS.KANBAN_UPDATED, this.onKanbanUpdated)
    emitter.on(BUS_EVENTS.KANBAN_CONVERSATION_ACTIVITY, this.onConversationActivity)
    await this.loadBoard()
  },

  beforeUnmount() {
    emitter.off(BUS_EVENTS.KANBAN_UPDATED, this.onKanbanUpdated)
    emitter.off(BUS_EVENTS.KANBAN_CONVERSATION_ACTIVITY, this.onConversationActivity)
    clearTimeout(this.activityRefreshTimer)
  },

  data() {
    return {
      localColumns: [],
      currentModel: null,
      draggedItem: null,
      sourceColumnIndex: null,
      sourceItemIndex: null,
      allLabels: [],
      isLoading: false,
      activityRefreshTimer: null,
    }
  },

  watch: {
    columns: {
      handler(next) {
        if (!next) return
        this.localColumns = next.map(c => ({ ...c, items: [...c.items] }))
      },
      deep: true
    },

  },

  computed: {
    emptyStateDescription() {
      if (!this.currentModel) return this.$t('KANBAN.EMPTY_STATE.NO_MODEL');

      return this.$t('KANBAN.EMPTY_STATE.EMPTY_MODEL');
    },
  },

  methods: {
    async onKanbanUpdated() {
      await this.loadBoard();
    },

    onConversationActivity() {
      if (!this.currentModel) return;

      clearTimeout(this.activityRefreshTimer);
      this.activityRefreshTimer = setTimeout(() => {
        this.refreshColumns({ showLoader: false });
      }, ACTIVITY_REFRESH_DELAY);
    },

    columnColorClass(color) {
      return COLUMN_COLOR_CLASSES[color] || COLUMN_COLOR_CLASSES.blue;
    },

    labelById(labelId) {
      return this.allLabels.find(label => Number(label.id) === Number(labelId));
    },

    normalizeColumn(column) {
      const labels = Array.isArray(column.labels)
        ? column.labels
        : (column.labelIds || []).map(labelId => this.labelById(labelId)).filter(Boolean);
      const labelToAdd = column.label_to_add || this.labelById(column.labelToAddId) || labels[0] || null;
      const cards = column.cards || column.items || [];

      return {
        id: column.id,
        title: column.title,
        color: column.color || 'blue',
        labels,
        label_to_add: labelToAdd,
        items: cards.map(card => ({
          id: card.id,
          content: card.content,
          labels: card.labels || [],
          lastActivityAt: card.lastActivityAt,
        })),
        hasMore: Boolean(column.hasMore),
        nextCursor: column.nextCursor || null,
        totalCards: column.totalCards ?? cards.length,
        isLoadingMore: Boolean(column.isLoadingMore),
      };
    },

    emitColumns() {
      this.$emit('update:columns', JSON.parse(JSON.stringify(this.localColumns)));
    },

    async loadBoard() {
      this.isLoading = true;
      try {
        const { data } = await kanbanApi.getCurrent();
        this.currentModel = data.model;
        this.localColumns = (data.configuration?.columns || []).map(column => this.normalizeColumn(column));
        if (this.currentModel) {
          await this.refreshColumns({ showLoader: false });
        } else {
          this.emitColumns();
        }
      } catch (error) {
        console.error('Erro ao carregar Kanban: ', error);
      } finally {
        this.isLoading = false;
      }
    },

    onDragStart(event, columnIndex, itemIndex) {
      this.draggedItem = this.localColumns[columnIndex].items[itemIndex]
      this.sourceColumnIndex = columnIndex
      this.sourceItemIndex = itemIndex
      const target = event.target
      target?.classList.add('dragging')
      // for Firefox compatibility
      event.dataTransfer?.setData('text/plain', '')
    },

    onDragEnd(event) {
      const target = event.target
      target?.classList.remove('dragging')
    },

    async onDrop(_event, targetColumnIndex) {
      if (!this.currentModel) return
      if (this.draggedItem && this.sourceColumnIndex !== null && this.sourceItemIndex !== null) {
        const movedItem = this.draggedItem
        const targetColumnItems = [...this.localColumns[targetColumnIndex].items]
        if (targetColumnItems.some(item => item.id === movedItem.id)) {
          this.draggedItem = null
          this.sourceColumnIndex = null
          this.sourceItemIndex = null
          return
        }

        try {
          await kanbanApi.moveCard(this.currentModel.id, {
            conversation_id: movedItem.id,
            source_column_id: this.localColumns[this.sourceColumnIndex].id,
            target_column_id: this.localColumns[targetColumnIndex].id,
          });
          await this.refreshColumns();
          this.$emit('moved', {
            item: movedItem,
            fromColumn: this.sourceColumnIndex,
            toColumn: targetColumnIndex,
          })
        } catch (error) {
          console.error('Erro ao mover card: ', error);
        } finally {
          this.draggedItem = null
          this.sourceColumnIndex = null
          this.sourceItemIndex = null
        }
      }
    },

    handleCardClick(item) {
      const conversationPath = conversationUrl({
        accountId: this.$route.params.accountId,
        id: item.id
      })
      const fullPath = frontendURL(conversationPath)
      this.$router.push(fullPath)
    },

    onColumnScroll(event, columnIndex) {
      const target = event.target;
      const shouldLoadMore = target.scrollTop + target.clientHeight >= target.scrollHeight - SCROLL_THRESHOLD;

      if (shouldLoadMore) {
        this.loadMoreColumn(columnIndex);
      }
    },

    async loadMoreColumn(columnIndex) {
      const column = this.localColumns[columnIndex];
      if (!this.currentModel || !column?.hasMore || column.isLoadingMore) return;

      const loadingColumn = { ...column, isLoadingMore: true };
      this.localColumns.splice(columnIndex, 1, loadingColumn);

      try {
        const { data } = await kanbanApi.getColumnCards(this.currentModel.id, column.id, {
          cursor: column.nextCursor,
          per_page: CARDS_PER_PAGE,
        });
        const nextColumn = this.normalizeColumn({ ...column, ...data });
        const existingIds = new Set(column.items.map(item => item.id));
        const newItems = nextColumn.items.filter(item => !existingIds.has(item.id));
        this.localColumns.splice(columnIndex, 1, {
          ...column,
          items: [...column.items, ...newItems],
          hasMore: nextColumn.hasMore,
          nextCursor: nextColumn.nextCursor,
          totalCards: nextColumn.totalCards,
          isLoadingMore: false,
        });
        this.emitColumns();
      } catch (error) {
        console.error('Erro ao carregar mais cards: ', error);
        this.localColumns.splice(columnIndex, 1, { ...column, isLoadingMore: false });
      }
    },

    async refreshColumns({ showLoader = true } = {}) {
      if (!this.currentModel) return
      if (showLoader) this.isLoading = true;
      try {
        const { data } = await kanbanApi.getCards(this.currentModel.id, { per_page: CARDS_PER_PAGE });
        this.localColumns = (data.columns || []).map(column => this.normalizeColumn(column));
        this.emitColumns();
      } catch (error) {
        console.error("Erro ao atualizar colunas: ", error)
      } finally {
        if (showLoader) this.isLoading = false
      }
    },

  }
}
</script>

<template>
  <div class="kanban-root">
    <div class="kanban-board" v-if="!isLoading">
      <div v-if="localColumns.length === 0" class="empty-state">
        <h2>{{ $t('KANBAN.EMPTY_STATE.TITLE') }}</h2>
        <p>{{ emptyStateDescription }}</p>
      </div>
      <div
        v-else
        v-for="(column, columnIndex) in localColumns"
        :key="column.id ?? columnIndex"
        :class="['column', columnColorClass(column.color)]"
      >

        <div class="column-header">
          <h2>{{ column.title }}</h2>
        </div>

        <div
          class="column-cards"
          @dragover.prevent
          @drop="onDrop($event, columnIndex)"
          @scroll.passive="onColumnScroll($event, columnIndex)"
        >
          <div
            v-for="(item, itemIndex) in column.items"
            :key="item.id ?? itemIndex"
            class="card"
            :draggable="Boolean(currentModel)"
            @dragstart="currentModel && onDragStart($event, columnIndex, itemIndex)"
            @dragend="onDragEnd"
            @click="handleCardClick(item)"
          >
            <slot name="card" :item="item" :column="column">{{ item.content }}</slot>
          </div>
          <div v-if="column.isLoadingMore" class="column-loader">
            <Spinner />
          </div>
        </div>
      </div>
    </div>
    <div v-else class="spinner-container">
      <Spinner></Spinner>
    </div>
  </div>
</template>

<style scoped>
.kanban-root {
  @apply p-2.5 h-screen w-screen box-border overflow-x-auto bg-gradient-to-br from-n-slate-2 via-n-background to-n-blue-2;
}

@media (max-width: 768px) {
  .kanban-root {
    padding: 5px;
  }
}

.kanban-board {
  @apply flex gap-5 h-[calc(100vh-20px)] mx-auto overflow-x-auto pb-5;
}

@media (max-width: 768px) {
  .kanban-board {
    padding-bottom: 10px;
    gap: 10px;
  }
}

.column {
  @apply rounded-2xl p-3 w-[300px] min-w-[300px] h-full overflow-hidden border-2 border-solid flex flex-col shadow-lg shadow-n-slate-12/10 backdrop-blur-sm;
}

@media (max-width: 768px) {
  .column {
    width: 280px;
    min-width: 280px;
    padding: 8px;
  }
}

.column-header {
  @apply shrink-0;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10%;
  padding-bottom: 10px;
  @apply border-b-2 border-n-slate-8;
}

.column-header h2 {
  margin: 0;
  font-size: 18px;
}

.column-cards {
  @apply flex-1 min-h-0 overflow-y-auto;
}

.card {
  @apply text-n-slate-12 bg-n-solid-1 rounded-xl p-3 mb-2.5 cursor-move select-none shadow-sm border border-n-slate-5 transition-all duration-200;
}

.card:hover {
  @apply shadow-md -translate-y-0.5 border-n-slate-7;
}

.dragging { opacity: 0.5; }

.column-loader {
  @apply flex justify-center py-4;
}

.empty-state {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  color: #fff;
  text-align: center;
}

.empty-state h2 {
  font-size: 24px;
  margin-bottom: 16px;
}

.empty-state p {
  font-size: 16px;
  color: #ccc;
}

.spinner-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: calc(100vh - 20px);
  width: 100%;
}

</style>
