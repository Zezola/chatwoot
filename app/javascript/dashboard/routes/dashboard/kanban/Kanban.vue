<script>
import VirtiKanbanAPI from 'dashboard/virti/kanban/api';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import { conversationUrl, frontendURL } from '../../../helper/URLHelper';
import Spinner from '../../../../shared/components/Spinner.vue'

const kanbanApi = new VirtiKanbanAPI();
const COLUMN_COLOR_CLASSES = {
  blue: 'bg-n-blue-4 border-n-blue-8',
  teal: 'bg-n-teal-4 border-n-teal-8',
  amber: 'bg-n-amber-4 border-n-amber-8',
  violet: 'bg-n-violet-4 border-n-violet-8',
  ruby: 'bg-n-ruby-4 border-n-ruby-8',
  iris: 'bg-n-iris-4 border-n-iris-8',
  gray: 'bg-n-gray-4 border-n-gray-8',
  slate: 'bg-n-slate-6 border-n-slate-9',
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
    await this.loadBoard()
  },

  beforeUnmount() {
    emitter.off(BUS_EVENTS.KANBAN_UPDATED, this.onKanbanUpdated)
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
        })),
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
          await this.refreshColumns();
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

    async refreshColumns() {
      if (!this.currentModel) return
      this.isLoading = true;
      try {
        const { data } = await kanbanApi.getCards(this.currentModel.id);
        this.localColumns = (data.columns || []).map(column => this.normalizeColumn(column));
        this.emitColumns();
      } catch (error) {
        console.error("Erro ao atualizar colunas: ", error)
      } finally {
        this.isLoading = false
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
        @dragover.prevent
        @drop="onDrop($event, columnIndex)"
      >

        <div class="column-header">
          <h2>{{ column.title }}</h2>
        </div>
        
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
      </div>
    </div>
    <div v-else class="spinner-container">
      <Spinner></Spinner>
    </div>
  </div>
</template>

<style scoped>
.kanban-root {
  @apply p-2.5 bg-n-background h-screen w-screen box-border overflow-x-auto;
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
  @apply rounded-lg p-3 w-[300px] min-w-[300px] h-full overflow-y-auto border-2 border-solid;
}

@media (max-width: 768px) {
  .column {
    width: 280px;
    min-width: 280px;
    padding: 8px;
  }
}

.column-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10%;
  padding-bottom: 10px;
  border-bottom: 2px solid #ccc;
}

.column-header h2 {
  margin: 0;
  font-size: 18px;
}


.card {
  color: #464343;
  background-color: #fff;
  border-radius: 6px;
  padding: 10px;
  margin-bottom: 10px;
  cursor: move;
  box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24);
  user-select: none;
}

.card:hover {
  box-shadow: 0 3px 6px rgba(0,0,0,0.16), 0 3px 6px rgba(0,0,0,0.23);
}

.dragging { opacity: 0.5; }

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
