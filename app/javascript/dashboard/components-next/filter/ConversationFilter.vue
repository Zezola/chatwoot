<script setup>
import {
  useTemplateRef,
  onBeforeUnmount,
  computed,
  ref,
  onMounted,
  nextTick,
} from 'vue';
import { useI18n } from 'vue-i18n';
import { useTrack } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { vOnClickOutside } from '@vueuse/components';
import { CONVERSATION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useConversationFilterContext } from './provider.js';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useMapGetter } from 'dashboard/composables/store';

import Button from 'next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ConditionRow from './ConditionRow.vue';

const props = defineProps({
  isFolderView: {
    type: Boolean,
    default: false,
  },
  folderName: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['applyFilter', 'updateFolder', 'close']);
const { filterTypes } = useConversationFilterContext();
const teams = useMapGetter('teams/getMyTeams');
const allTeams = useMapGetter('teams/getTeams');

const filters = defineModel({
  type: Array,
  default: [],
});
const folderNameLocal = ref(props.folderName);

const DEFAULT_FILTER = {
  attributeKey: 'status',
  filterOperator: 'equal_to',
  values: [],
  queryOperator: 'and',
};

const { t } = useI18n();
const store = useStore();
const userACL = useMapGetter('acl/getUserACL');
const currentUser = useMapGetter('getCurrentUser');
const canFilterWithoutTeams = computed(() => {
  return userACL.value.pode_filtrar_sem_times;
});
const canFilterAnyTeam = computed(() => {
  return userACL.value.pode_filtrar_por_qualquer_time;
});
const canFilterAnyAssignee = computed(() => {
  return userACL.value.pode_filtrar_por_qualquer_agente;
});
const canFilterWithoutAssignee = computed(() => {
  return userACL.value.pode_filtrar_sem_agente_atribuido;
});

const resetFilter = () => {
  const filtersToAdd = [];

  // Verificar team_id (independente)
  if (!canFilterWithoutTeams.value) {
    filtersToAdd.push({
      attributeKey: 'team_id',
      filterOperator: 'equal_to',
      values: teamFilterValue(),
      queryOperator: 'and',
    });
  }

  // Verificar assignee_id (independente)
  if (!canFilterWithoutAssignee.value) {
    filtersToAdd.push({
      attributeKey: 'assignee_id',
      filterOperator: 'equal_to',
      values: assigneeFilterValue(),
      queryOperator: 'and',
    });
  }

  // Se não tem filtros obrigatórios, usar o padrão
  if (filtersToAdd.length === 0) {
    filters.value = [{ ...DEFAULT_FILTER }];
  } else {
    filters.value = filtersToAdd;
  }
};

const removeFilter = index => {
  if (
    !canFilterWithoutTeams.value &&
    filters.value[index].attributeKey === 'team_id'
  ) {
    return;
  }
  if (
    !canFilterWithoutAssignee.value &&
    filters.value[index].attributeKey === 'assignee_id'
  ) {
    return;
  }
  if (filters.value.length === 1) {
    resetFilter();
  } else {
    filters.value.splice(index, 1);
  }
};

const addFilter = () => {
  filters.value.push({ ...DEFAULT_FILTER });
};

const teamFilterValue = existingFilter => {
  const availableTeams = canFilterAnyTeam.value ? allTeams.value : teams.value;
  const existingTeamId = existingFilter?.values?.id;
  const existingTeam = availableTeams.find(team => team.id === existingTeamId);
  const team = existingTeam || availableTeams[0];

  return team ? { id: team.id, name: team.name } : {};
};

const assigneeFilterValue = () => ({
  id: currentUser.value.id,
  name: currentUser.value.name,
});

const isAclFilterLocked = filter => {
  if (!filter) return false;

  return (
    (filter.attributeKey === 'team_id' &&
      (!canFilterWithoutTeams.value || !canFilterAnyTeam.value)) ||
    (filter.attributeKey === 'assignee_id' &&
      (!canFilterWithoutAssignee.value || !canFilterAnyAssignee.value))
  );
};

const hasMandatoryAclFilters = () => {
  return !canFilterWithoutTeams.value || !canFilterWithoutAssignee.value;
};

const sanitizeRestrictedAclFilter = filter => {
  if (
    filter.attributeKey === 'team_id' &&
    (!canFilterWithoutTeams.value || !canFilterAnyTeam.value)
  ) {
    return {
      ...filter,
      filterOperator: 'equal_to',
      values: canFilterAnyTeam.value ? filter.values : teamFilterValue(filter),
      queryOperator: 'and',
    };
  }

  if (
    filter.attributeKey === 'assignee_id' &&
    (!canFilterWithoutAssignee.value || !canFilterAnyAssignee.value)
  ) {
    return {
      ...filter,
      filterOperator: 'equal_to',
      values: canFilterAnyAssignee.value ? filter.values : assigneeFilterValue(),
      queryOperator: 'and',
    };
  }

  return filter;
};

const normalizeMandatoryAclFilters = () => {
  const mandatoryFilters = [];
  let nextFilters = filters.value.map(sanitizeRestrictedAclFilter);

  if (!canFilterWithoutTeams.value) {
    const existingTeamFilter = nextFilters.find(
      filter => filter.attributeKey === 'team_id'
    );
    nextFilters = nextFilters.filter(filter => filter.attributeKey !== 'team_id');
    mandatoryFilters.push({
      ...existingTeamFilter,
      attributeKey: 'team_id',
      filterOperator: 'equal_to',
      values: teamFilterValue(existingTeamFilter),
      queryOperator: 'and',
    });
  }

  if (!canFilterWithoutAssignee.value) {
    const existingAssigneeFilter = nextFilters.find(
      filter => filter.attributeKey === 'assignee_id'
    );
    nextFilters = nextFilters.filter(
      filter => filter.attributeKey !== 'assignee_id'
    );
    mandatoryFilters.push({
      ...existingAssigneeFilter,
      attributeKey: 'assignee_id',
      filterOperator: 'equal_to',
      values:
        canFilterAnyAssignee.value && existingAssigneeFilter?.values?.id
          ? existingAssigneeFilter.values
          : assigneeFilterValue(),
      queryOperator: 'and',
    });
  }

  const normalizedFilters = [...mandatoryFilters, ...nextFilters];
  normalizedFilters.forEach((filter, index) => {
    if (index > 0 && (hasMandatoryAclFilters() || isAclFilterLocked(filter))) {
      normalizedFilters[index - 1].queryOperator = 'and';
    }
  });

  filters.value = normalizedFilters;
};

const conditionsRef = useTemplateRef('conditionsRef');

const isConditionsValid = () => {
  return conditionsRef.value.every(condition => condition.validate());
};

const updateSavedCustomViews = async () => {
  normalizeMandatoryAclFilters();
  await nextTick();

  if (isConditionsValid()) {
    emit('updateFolder', filters.value, folderNameLocal.value);
  }
};

async function validateAndSubmit() {
  normalizeMandatoryAclFilters();
  await nextTick();

  if (!isConditionsValid()) {
    return;
  }

  store.dispatch(
    'setConversationFilters',
    useSnakeCase(JSON.parse(JSON.stringify(filters.value)))
  );
  emit('applyFilter', filters.value);
  useTrack(CONVERSATION_EVENTS.APPLY_FILTER, {
    appliedFilters: filters.value.map(filter => ({
      key: filter.attributeKey,
      operator: filter.filterOperator,
      queryOperator: filter.queryOperator,
    })),
  });
}

const filterModalHeaderTitle = computed(() => {
  return !props.isFolderView
    ? t('FILTER.TITLE')
    : t('FILTER.EDIT_CUSTOM_FILTER');
});

const isAclConnectorLocked = index => {
  return (
    hasMandatoryAclFilters() ||
    isAclFilterLocked(filters.value[index - 1]) ||
    isAclFilterLocked(filters.value[index])
  );
};

onBeforeUnmount(() => emit('close'));
onMounted(() => {
  if (filters.value.length === 0) {
    filters.value = [{ ...DEFAULT_FILTER }];
  }

  normalizeMandatoryAclFilters();
});
const outsideClickHandler = [
  () => emit('close'),
  { ignore: ['#toggleConversationFilterButton'] },
];
</script>

<template>
  <div
    v-on-click-outside="outsideClickHandler"
    class="z-40 max-w-3xl lg:w-[750px] overflow-visible w-full border border-n-weak bg-n-alpha-3 backdrop-blur-[100px] shadow-lg rounded-xl p-6 grid gap-6"
  >
    <h3 class="text-base font-medium leading-6 text-n-slate-12">
      {{ filterModalHeaderTitle }}
    </h3>
    <div v-if="props.isFolderView">
      <div class="border-b border-n-weak pb-6">
        <Input
          v-model="folderNameLocal"
          :label="t('FILTER.FOLDER_LABEL')"
          :placeholder="t('FILTER.INPUT_PLACEHOLDER')"
        />
      </div>
    </div>
    <ul class="grid gap-4 list-none">
      <template v-for="(filter, index) in filters" :key="filter.id">
        <ConditionRow
          v-if="index === 0"
          ref="conditionsRef"
          :key="`filter-${filter.attributeKey}-0`"
          v-model:attribute-key="filter.attributeKey"
          v-model:filter-operator="filter.filterOperator"
          v-model:values="filter.values"
          :filter-types="filterTypes"
          :show-query-operator="false"
          @remove="removeFilter(index)"
        />
        <ConditionRow
          v-else
          :key="`filter-${filter.attributeKey}-${index}`"
          ref="conditionsRef"
          v-model:attribute-key="filter.attributeKey"
          v-model:filter-operator="filter.filterOperator"
          v-model:query-operator="filters[index - 1].queryOperator"
          v-model:values="filter.values"
          show-query-operator
          :filter-types="filterTypes"
          :force-and-query-operator="isAclConnectorLocked(index)"
          @remove="removeFilter(index)"
        />
      </template>
    </ul>
    <div class="flex gap-2 justify-between">
      <Button sm ghost blue @click="addFilter">
        {{ $t('FILTER.ADD_NEW_FILTER') }}
      </Button>
      <div class="flex gap-2">
        <Button sm faded slate @click="resetFilter">
          {{ t('FILTER.CLEAR_BUTTON_LABEL') }}
        </Button>
        <Button
          v-if="isFolderView"
          sm
          solid
          blue
          :disabled="!folderNameLocal"
          @click="updateSavedCustomViews"
        >
          {{ t('FILTER.UPDATE_BUTTON_LABEL') }}
        </Button>
        <Button v-else sm solid blue @click="validateAndSubmit">
          {{ t('FILTER.SUBMIT_BUTTON_LABEL') }}
        </Button>
      </div>
    </div>
  </div>
</template>
