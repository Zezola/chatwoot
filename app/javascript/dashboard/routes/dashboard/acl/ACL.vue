<script setup>
import { ref, onMounted, computed } from 'vue';
import { useStore } from 'vuex';
import Button from 'dashboard/components-next/button/Button.vue';
import { useAlert } from 'dashboard/composables';
import VirtiAclAPI from 'dashboard/virti/acl/api';
import { DEFAULT_ACL } from 'dashboard/virti/acl/defaults';

const store = useStore();
const aclApi = new VirtiAclAPI();
const showEditModal = ref(false);
const showModelModal = ref(false);
const activeTab = ref('users');
const selectedAgent = ref(null);
const selectedModel = ref(null);
const models = ref([]);
const userModels = ref({});
const modelForm = ref({ name: '', description: '', permissions: { ...DEFAULT_ACL } });
const modelDropdownAgentId = ref(null);
const modelSearch = ref('');
const modelListSearch = ref('');

const agentList = computed(() => store.getters['agents/getAgents']);
const currentUser = computed(() => store.getters['getCurrentUser']);
const filteredAgents = computed(() =>
  agentList.value.filter(a => a.id !== currentUser.value.id)
);
const userACL = computed(() => store.getters['acl/getUserACL']);

// Paginação
const currentPage = ref(1);
const pageSize = 10;
const totalPages = computed(() =>
  Math.ceil(filteredAgents.value.length / pageSize)
);
const paginatedAgents = computed(() => {
  const start = (currentPage.value - 1) * pageSize;
  return filteredAgents.value.slice(start, start + pageSize);
});

const filteredModels = computed(() => {
  const query = modelListSearch.value.trim().toLowerCase();
  if (!query) return models.value;

  return models.value.filter(model =>
    [model.name, model.description].some(value =>
      (value || '').toLowerCase().includes(query)
    )
  );
});

const editingACL = ref({});
const aclLabels = {
  pode_ver_menu_kanban: 'menu kanban',
  pode_ver_menu_inbox: 'menu inbox',
  pode_ver_menu_contatos: 'menu contatos',
  pode_ver_menu_captain: 'menu captain',
  pode_ver_menu_portais: 'menu portais',
  pode_ver_menu_relatorios: 'menu relatorios',
  pode_ver_menu_configuracoes: 'menu configuracoes',
  pode_ver_barra_de_busca: 'menu barra de busca',
  menu_conversas_exibir_canais: 'conversas exibir canais',
  menu_conversas_exibir_etiquetas: 'conversas exibir etiquetas',
  menu_conversas_exibir_mencoes: 'conversas exibir mencoes',
  menu_conversas_exibir_nao_atendidas: 'conversas exibir nao atendidas',
  menu_conversas_exibir_times: 'conversas exibir times',
  menu_conversas_exibir_todas_conversas: 'conversas exibir todas conversas',
  pode_ver_menu_de_acoes_da_conversa: 'menu de acoes da conversa',
  pode_ver_opcoes_de_atribuicao_no_menu_de_contexto:
    'opcoes de atribuicao no menu de contexto',
  pode_filtrar_sem_times: 'filtrar sem times',
  pode_filtrar_por_qualquer_time: 'filtrar por qualquer time',
  pode_filtrar_sem_agente_atribuido: 'filtrar sem agente atribuido',
  pode_filtrar_por_qualquer_agente: 'filtrar por qualquer agente',
  pode_ver_aba_de_todas_conversas: 'ver aba de todas conversas',
  pode_ver_aba_de_nao_atribuidas: 'ver aba de nao atribuidas',
  nao_redirecionar_para_primeira_pasta: 'nao redirecionar para primeira pasta',
};
const aclDescriptions = {
  pode_ver_menu_kanban: 'Habilita a visualização do menu Kanban na sidebar.',
  pode_ver_menu_inbox: 'Habilita a visualização do menu Inbox na sidebar.',
  pode_ver_menu_contatos:
    'Habilita a visualização do menu Contatos na sidebar.',
  pode_ver_menu_captain: 'Habilita a visualização do menu Captain na sidebar.',
  pode_ver_menu_portais: 'Habilita a visualização do menu Portais na sidebar.',
  pode_ver_menu_relatorios:
    'Habilita a visualização do menu Relatórios na sidebar.',
  pode_ver_menu_configuracoes:
    'Habilita a visualização do menu Configurações na sidebar.',
  pode_ver_barra_de_busca:
    'Habilita a visualização da barra de busca na sidebar.',
  menu_conversas_exibir_canais:
    'Habilita a visualização de Canais dentro de Conversas.',
  menu_conversas_exibir_etiquetas:
    'Habilita a visualização de Etiquetas dentro de Conversas.',
  menu_conversas_exibir_mencoes:
    'Habilita a visualização de Menções dentro de Conversas.',
  menu_conversas_exibir_nao_atendidas:
    'Habilita a visualização de Não Atendidas dentro de Conversas.',
  menu_conversas_exibir_times:
    'Habilita a visualização de Times dentro de Conversas.',
  menu_conversas_exibir_todas_conversas:
    'Habilita a visualização de Todas Conversas dentro de Conversas.',
  pode_ver_menu_de_acoes_da_conversa:
    'Habilita a visualização do menu de ações da conversa quando está marcado.',
  pode_ver_opcoes_de_atribuicao_no_menu_de_contexto:
    'Habilita as opções de atribuição no menu de contexto quando está marcado.',
  pode_filtrar_sem_times:
    'Quando desmarcado, o filtro de time se torna obrigatório.',
  pode_filtrar_por_qualquer_time:
    'Quando desmarcado, o usuário só pode filtrar pelos próprios times.',
  pode_filtrar_sem_agente_atribuido:
    'Quando desmarcado, o filtro de agente atribuído se torna obrigatório.',
  pode_filtrar_por_qualquer_agente:
    'Quando desmarcado, o usuário só pode filtrar pelo próprio agente.',
  pode_ver_aba_de_todas_conversas:
    'Quando desmarcado, o usuário não pode acessar a aba de todas conversas.',
  pode_ver_aba_de_nao_atribuidas:
    'Quando desmarcado, o usuário não pode acessar a aba de não atribuidas.',
  nao_redirecionar_para_primeira_pasta:
    'Quando marcado, o usuário não é redirecionado para a primeira pasta ao entrar.',
};

const aclGroups = [
  {
    title: 'Menu lateral',
    keys: [
      'pode_ver_menu_inbox',
      'pode_ver_menu_kanban',
      'pode_ver_menu_contatos',
      'pode_ver_menu_captain',
      'pode_ver_menu_portais',
      'pode_ver_menu_relatorios',
      'pode_ver_menu_configuracoes',
      'pode_ver_barra_de_busca',
    ],
    subGroups: [
      {
        title: 'Conversas',
        keys: [
          'menu_conversas_exibir_todas_conversas',
          'menu_conversas_exibir_mencoes',
          'menu_conversas_exibir_nao_atendidas',
          'menu_conversas_exibir_times',
          'menu_conversas_exibir_canais',
          'menu_conversas_exibir_etiquetas',
        ],
      },
    ],
  },
  {
    title: 'Acoes de conversa',
    keys: [
      'pode_ver_menu_de_acoes_da_conversa',
      'pode_ver_opcoes_de_atribuicao_no_menu_de_contexto',
    ],
  },
  {
    title: 'Filtros e escopo',
    keys: [
      'pode_filtrar_sem_times',
      'pode_filtrar_por_qualquer_time',
      'pode_filtrar_sem_agente_atribuido',
      'pode_filtrar_por_qualquer_agente',
    ],
  },
  {
    title: 'Abas de conversa',
    keys: ['pode_ver_aba_de_todas_conversas', 'pode_ver_aba_de_nao_atribuidas'],
  },
  {
    title: 'Redirecionamento',
    keys: ['nao_redirecionar_para_primeira_pasta'],
  },
];

const openGroup = ref(aclGroups[0]?.title ?? null);
const openSubGroup = ref(null);

const toggleGroup = title => {
  openGroup.value = openGroup.value === title ? null : title;
};

const toggleSubGroup = title => {
  openSubGroup.value = openSubGroup.value === title ? null : title;
};

function openEditPopup(agent) {
  selectedAgent.value = agent;
  showEditModal.value = true;
  store.dispatch('acl/fetchEditingAcl', agent.id).then(() => {
    // Faz uma copia local pro editingACL
    editingACL.value = { ...store.getters['acl/getEditingACL'] };
  });
}

function saveACL() {
  const userId = selectedAgent.value.id;
  store
    .dispatch('acl/updateAcl', { userId, newAcl: editingACL.value })
    .then(() => {
      closeEditModal();
    });
}

function closeEditModal() {
  showEditModal.value = false;
  selectedAgent.value = null;
}

async function fetchModels() {
  const { data } = await aclApi.getModels();
  models.value = data;
}

async function fetchUserModels() {
  const entries = await Promise.all(
    filteredAgents.value.map(async agent => {
      const { data } = await aclApi.getUserModel(agent.id);
      return [agent.id, data.model];
    })
  );
  userModels.value = Object.fromEntries(entries);
}

function openCreateModelModal() {
  selectedModel.value = null;
  modelForm.value = { name: '', description: '', permissions: { ...DEFAULT_ACL } };
  showModelModal.value = true;
}

function openEditModelModal(model) {
  selectedModel.value = model;
  modelForm.value = {
    name: model.name,
    description: model.description || '',
    permissions: { ...DEFAULT_ACL, ...model.permissions },
  };
  showModelModal.value = true;
}

function closeModelModal() {
  showModelModal.value = false;
  selectedModel.value = null;
}

async function saveModel() {
  try {
    if (selectedModel.value) {
      await aclApi.updateModel(selectedModel.value.id, modelForm.value);
      useAlert('Modelo de ACL atualizado.');
    } else {
      await aclApi.createModel(modelForm.value);
      useAlert('Modelo de ACL criado.');
    }
    await fetchModels();
    closeModelModal();
  } catch (error) {
    useAlert('Não foi possível salvar o modelo de ACL.');
  }
}

async function deleteModel(model) {
  try {
    await aclApi.deleteModel(model.id);
    await fetchModels();
    await fetchUserModels();
    useAlert('Modelo de ACL removido.');
  } catch (error) {
    useAlert('Não foi possível remover o modelo. Verifique se ele está em uso.');
  }
}

async function changeUserModel(agentId, modelId) {
  if (modelId) {
    const { data } = await aclApi.updateUserModel(agentId, Number(modelId));
    userModels.value = { ...userModels.value, [agentId]: data.model };
    await fetchModels();
    useAlert('Modelo atribuído ao usuário.');
    return;
  }

  await aclApi.deleteUserModel(agentId);
  userModels.value = { ...userModels.value, [agentId]: null };
  await fetchModels();
  useAlert('Modelo removido do usuário.');
}

function openModelDropdown(agentId) {
  modelDropdownAgentId.value = agentId;
  modelSearch.value = '';
}

function closeModelDropdown() {
  modelDropdownAgentId.value = null;
  modelSearch.value = '';
}

function filteredModelsForDropdown() {
  const query = modelSearch.value.trim().toLowerCase();
  if (!query) return models.value;

  return models.value.filter(model =>
    [model.name, model.description].some(value =>
      (value || '').toLowerCase().includes(query)
    )
  );
}

async function selectUserModel(agentId, modelId) {
  await changeUserModel(agentId, modelId);
  closeModelDropdown();
}

onMounted(async () => {
  await store.dispatch('agents/get');
  await fetchModels();
  await fetchUserModels();
  //store.dispatch('acl/fetchAcl', currentUser.value.id);
});
</script>

<template>
  <div class="flex flex-col p-4 h-full w-full">
    <h1 class="text-xl font-medium mb-4">ACL</h1>
    <p class="text-sm text-n-slate-11 mb-6">Gerenciamento de permissões</p>

    <div class="mb-4 flex gap-2 border-b border-n-weak">
      <button
        type="button"
        class="px-4 py-2 text-sm font-medium border-b-2 transition-colors"
        :class="
          activeTab === 'users'
            ? 'border-n-brand text-n-brand'
            : 'border-transparent text-n-slate-11 hover:text-n-slate-12'
        "
        @click="activeTab = 'users'"
      >
        Usuários
      </button>
      <button
        type="button"
        class="px-4 py-2 text-sm font-medium border-b-2 transition-colors"
        :class="
          activeTab === 'models'
            ? 'border-n-brand text-n-brand'
            : 'border-transparent text-n-slate-11 hover:text-n-slate-12'
        "
        @click="activeTab = 'models'"
      >
        Modelos
      </button>
    </div>

    <section
      v-if="activeTab === 'models'"
      class="min-h-0 flex-1 rounded-lg border border-n-weak bg-n-solid-2 p-4 flex flex-col"
    >
      <div class="flex items-start justify-between gap-4 mb-4">
        <div class="min-w-0">
          <h2 class="text-base font-medium text-n-slate-12">Modelos de ACL</h2>
          <p class="text-sm text-n-slate-11">
            Crie modelos por conta e atribua um modelo para cada usuário.
          </p>
        </div>
        <Button primary @click="openCreateModelModal">Novo modelo</Button>
      </div>
      <input
        v-model="modelListSearch"
        class="mb-4 w-full max-w-md rounded border border-n-weak bg-n-solid-1 px-3 py-2 text-sm text-n-slate-12 outline-none"
        type="search"
        placeholder="Buscar modelo..."
      />
      <div v-if="filteredModels.length" class="min-h-0 flex-1 overflow-y-auto pr-1">
        <div class="grid gap-2">
          <div
            v-for="model in filteredModels"
            :key="model.id"
            class="flex items-center justify-between gap-4 rounded border border-n-weak p-3"
          >
            <div class="min-w-0">
              <p class="font-medium text-n-slate-12 truncate">{{ model.name }}</p>
              <p class="text-sm text-n-slate-11 truncate">{{ model.description || 'Sem descrição' }}</p>
              <p class="text-xs text-n-slate-10">{{ model.usersCount }} usuário(s)</p>
            </div>
            <div class="flex shrink-0 gap-2">
              <Button xs faded slate @click="openEditModelModal(model)">Editar</Button>
              <Button xs faded ruby @click="deleteModel(model)">Excluir</Button>
            </div>
          </div>
        </div>
      </div>
      <p v-else class="text-sm text-n-slate-11">
        {{ models.length ? 'Nenhum modelo encontrado.' : 'Nenhum modelo criado ainda.' }}
      </p>
    </section>
    <div
      v-if="activeTab === 'users'"
      class="overflow-auto border border-n-weak rounded-lg shadow-sm flex-grow w-full h-[80vh]"
    >
      <table class="w-full divide-y divide-n-weak">
        <thead class="bg-n-solid-3">
          <tr>
            <th
              scope="col"
              class="py-3 px-4 text-left text-xs font-medium text-n-slate-11 uppercase tracking-wider"
            >
              Usuário
            </th>
            <th
              scope="col"
              class="py-3 px-4 text-left text-xs font-medium text-n-slate-11 uppercase tracking-wider"
            >
              Modelo
            </th>
            <th
              scope="col"
              class="py-3 px-4 text-left text-xs font-medium text-n-slate-11 uppercase tracking-wider"
            >
              Editar ACL
            </th>
          </tr>
        </thead>
        <tbody class="bg-n-solid-2 divide-y divide-n-weak text-n-slate-11">
          <tr
            v-for="agent in paginatedAgents"
            :key="agent.email"
            class="hover:bg-n-solid-3 transition-colors"
          >
            <td class="py-4 px-4">
              <div class="flex flex-row items-center gap-4">
                <!-- <Avatar
                                    :src="agent.thumbnail"
                                    :name="agent.name"
                                    :status="agent.availability_status"
                                    :size="40"
                                    hide-offline-status
                                    rounded-full
                                /> -->
                <div class="min-w-0">
                  <span class="block font-medium capitalize truncate">
                    {{ agent.name }}
                  </span>
                  <span class="text-sm text-n-slate-10 truncate">{{
                    agent.email
                  }}</span>
                </div>
              </div>
            </td>
            <td class="py-4 px-4">
              <div class="relative min-w-[14rem]">
                <button
                  type="button"
                  class="flex w-full items-center justify-between gap-2 rounded border border-n-weak bg-n-solid-1 px-3 py-2 text-left text-sm text-n-slate-12 hover:bg-n-solid-2"
                  @click="
                    modelDropdownAgentId === agent.id
                      ? closeModelDropdown()
                      : openModelDropdown(agent.id)
                  "
                >
                  <span class="truncate">
                    {{ userModels[agent.id]?.name || 'Sem modelo' }}
                  </span>
                  <span class="i-lucide-chevron-down size-4 shrink-0 text-n-slate-10" />
                </button>
                <div
                  v-if="modelDropdownAgentId === agent.id"
                  class="absolute left-0 right-0 top-full z-50 mt-1 rounded-lg border border-n-weak bg-n-solid-1 p-2 shadow-lg"
                >
                  <input
                    v-model="modelSearch"
                    class="mb-2 w-full rounded border border-n-weak bg-n-solid-2 px-3 py-2 text-sm text-n-slate-12 outline-none"
                    type="search"
                    placeholder="Buscar modelo..."
                    @keydown.esc="closeModelDropdown"
                  />
                  <div class="max-h-64 overflow-y-auto">
                    <button
                      type="button"
                      class="flex w-full items-center justify-between rounded px-3 py-2 text-left text-sm hover:bg-n-solid-2"
                      :class="!userModels[agent.id] ? 'text-n-brand' : 'text-n-slate-12'"
                      @click="selectUserModel(agent.id, '')"
                    >
                      <span>Sem modelo</span>
                      <span v-if="!userModels[agent.id]" class="i-lucide-check size-4" />
                    </button>
                    <button
                      v-for="model in filteredModelsForDropdown()"
                      :key="model.id"
                      type="button"
                      class="flex w-full items-center justify-between gap-3 rounded px-3 py-2 text-left text-sm hover:bg-n-solid-2"
                      :class="userModels[agent.id]?.id === model.id ? 'text-n-brand' : 'text-n-slate-12'"
                      @click="selectUserModel(agent.id, model.id)"
                    >
                      <span class="min-w-0">
                        <span class="block truncate">{{ model.name }}</span>
                        <span class="block truncate text-xs text-n-slate-10">
                          {{ model.description || 'Sem descrição' }}
                        </span>
                      </span>
                      <span
                        v-if="userModels[agent.id]?.id === model.id"
                        class="i-lucide-check size-4 shrink-0"
                      />
                    </button>
                    <p
                      v-if="filteredModelsForDropdown().length === 0"
                      class="px-3 py-2 text-sm text-n-slate-11"
                    >
                      Nenhum modelo encontrado.
                    </p>
                  </div>
                </div>
              </div>
            </td>
            <td class="py-4 px-4">
              <div class="flex justify-end gap-1">
                <Button
                  v-tooltip.top="$t('AGENT_MGMT.EDIT.BUTTON_TEXT')"
                  icon="i-lucide-pen"
                  slate
                  xs
                  faded
                  @click="openEditPopup(agent)"
                />
                <!-- <Button
                                    v-if="showDeleteAction(agent)"
                                    v-tooltip.top="$t('AGENT_MGMT.DELETE.BUTTON_TEXT')"
                                    icon="i-lucide-trash-2"
                                    xs
                                    ruby
                                    faded
                                    :is-loading="loading[agent.id]"
                                    @click="openDeletePopup(agent, index)"
                                /> -->
              </div>
            </td>
          </tr>
        </tbody>
      </table>
      <!-- Paginação -->
      <div class="flex justify-center mt-4 gap-2">
        <button
          class="px-3 py-1 rounded border text-sm"
          :disabled="currentPage === 1"
          @click="currentPage--"
        >
          Anterior
        </button>
        <span class="px-2 py-1 text-sm">
          Página {{ currentPage }} de {{ totalPages }}
        </span>
        <button
          class="px-3 py-1 rounded border text-sm"
          :disabled="currentPage >= totalPages"
          @click="currentPage++"
        >
          Próxima
        </button>
      </div>
    </div>
  </div>

  <!-- Modal para criar/editar modelo -->
  <div
    v-if="showModelModal"
    class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
  >
    <div
      class="bg-n-solid-1 rounded-lg p-6 w-[560px] shadow-lg max-h-[80vh] flex flex-col"
    >
      <div class="flex justify-between items-center mb-4">
        <h2 class="text-lg font-medium">
          {{ selectedModel ? 'Editar modelo' : 'Novo modelo' }}
        </h2>
        <button
          class="text-n-slate-11 hover:text-n-slate-12"
          @click="closeModelModal"
        >
          <span class="i-lucide-x text-lg"></span>
        </button>
      </div>
      <div class="grid gap-3 mb-4">
        <label class="grid gap-1 text-sm text-n-slate-11">
          Nome
          <input
            v-model="modelForm.name"
            class="rounded border border-n-weak bg-n-solid-1 px-3 py-2 text-n-slate-12"
            type="text"
          />
        </label>
        <label class="grid gap-1 text-sm text-n-slate-11">
          Descrição
          <textarea
            v-model="modelForm.description"
            class="rounded border border-n-weak bg-n-solid-1 px-3 py-2 text-n-slate-12"
            rows="2"
          />
        </label>
      </div>
      <div class="mb-4 flex-1 overflow-y-auto">
        <div
          v-for="group in aclGroups"
          :key="group.title"
          class="rounded border border-n-weak mb-3"
        >
          <button
            type="button"
            class="w-full flex items-center justify-between p-3 text-sm font-medium text-n-slate-11"
            @click="toggleGroup(group.title)"
          >
            <span>{{ group.title }}</span>
            <span
              class="i-lucide-chevron-down text-sm transition-transform"
              :class="openGroup === group.title ? 'rotate-180' : ''"
            ></span>
          </button>
          <div v-if="openGroup === group.title" class="border-t border-n-weak px-3 pb-3">
            <div v-for="key in group.keys" :key="key" class="flex items-center space-x-3 py-1">
              <input v-model="modelForm.permissions[key]" type="checkbox" class="rounded" />
              <label>{{ aclLabels[key] || key.replace('_', ' ') }}</label>
            </div>
            <template v-if="group.subGroups?.length">
              <div v-for="subGroup in group.subGroups" :key="subGroup.title" class="mt-2 rounded border border-n-weak">
                <button
                  type="button"
                  class="w-full flex items-center justify-between px-3 py-2 text-sm font-medium text-n-slate-11"
                  @click="toggleSubGroup(subGroup.title)"
                >
                  <span>{{ subGroup.title }}</span>
                  <span
                    class="i-lucide-chevron-down text-sm transition-transform"
                    :class="openSubGroup === subGroup.title ? 'rotate-180' : ''"
                  ></span>
                </button>
                <div v-if="openSubGroup === subGroup.title" class="border-t border-n-weak px-3 pb-2">
                  <div v-for="key in subGroup.keys" :key="key" class="flex items-center space-x-3 py-1">
                    <input v-model="modelForm.permissions[key]" type="checkbox" class="rounded" />
                    <label>{{ aclLabels[key] || key.replace('_', ' ') }}</label>
                  </div>
                </div>
              </div>
            </template>
          </div>
        </div>
      </div>
      <div class="flex justify-end gap-2 sticky bottom-0 bg-n-solid-1 pt-3">
        <Button slate @click="closeModelModal">Cancelar</Button>
        <Button primary :disabled="!modelForm.name" @click="saveModel">Salvar</Button>
      </div>
    </div>
  </div>

  <!-- Modal para editar permissões -->
  <div
    v-if="showEditModal"
    class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
  >
    <div
      class="bg-n-solid-1 rounded-lg p-6 w-96 shadow-lg max-h-[80vh] flex flex-col"
    >
      <div class="flex justify-between items-center mb-4">
        <h2 class="text-lg font-medium">Editar ACL</h2>
        <button
          @click="closeEditModal"
          class="text-n-slate-11 hover:text-n-slate-12"
        >
          <span class="i-lucide-x text-lg"></span>
        </button>
      </div>
      <p class="text-xs text-n-slate-10 mb-2">
        Quando uma opção está marcada, o usuário tem a permissão correspondente.
        Para remover a permissão, basta desmarcar a caixa.
      </p>
      <div class="mb-4 flex-1 overflow-y-auto">
        <p v-if="selectedAgent" class="text-sm text-n-slate-11">
          Editando permissões para: {{ selectedAgent.name }}
        </p>
        <form class="grid gap-3">
          <div
            v-for="group in aclGroups"
            :key="group.title"
            class="rounded border border-n-weak"
          >
            <button
              type="button"
              class="w-full flex items-center justify-between p-3 text-sm font-medium text-n-slate-11"
              @click="toggleGroup(group.title)"
            >
              <span>{{ group.title }}</span>
              <span
                class="i-lucide-chevron-down text-sm transition-transform"
                :class="openGroup === group.title ? 'rotate-180' : ''"
              ></span>
            </button>
            <div
              v-if="openGroup === group.title"
              class="border-t border-n-weak px-3 pb-3"
            >
              <div
                v-for="key in group.keys"
                :key="key"
                class="flex items-center space-x-3 py-1"
              >
                <input
                  type="checkbox"
                  :id="key"
                  v-model="editingACL[key]"
                  class="rounded text-indigo-600 focus:ring-indigo-500"
                />
                <label :for="key">{{
                  aclLabels[key] || key.replace('_', ' ')
                }}</label>
                <span
                  v-tooltip="aclDescriptions[key] || 'Sem descrição'"
                  class="i-lucide-info text-xs text-n-slate-10 cursor-pointer"
                >
                </span>
              </div>
              <template v-if="group.subGroups?.length">
                <div
                  v-for="subGroup in group.subGroups"
                  :key="subGroup.title"
                  class="mt-2 rounded border border-n-weak"
                >
                  <button
                    type="button"
                    class="w-full flex items-center justify-between px-3 py-2 text-sm font-medium text-n-slate-11"
                    @click="toggleSubGroup(subGroup.title)"
                  >
                    <span>{{ subGroup.title }}</span>
                    <span
                      class="i-lucide-chevron-down text-sm transition-transform"
                      :class="
                        openSubGroup === subGroup.title ? 'rotate-180' : ''
                      "
                    ></span>
                  </button>
                  <div
                    v-if="openSubGroup === subGroup.title"
                    class="border-t border-n-weak px-3 pb-2"
                  >
                    <div
                      v-for="key in subGroup.keys"
                      :key="key"
                      class="flex items-center space-x-3 py-1"
                    >
                      <input
                        type="checkbox"
                        :id="key"
                        v-model="editingACL[key]"
                        class="rounded text-indigo-600 focus:ring-indigo-500"
                      />
                      <label :for="key">{{
                        aclLabels[key] || key.replace('_', ' ')
                      }}</label>
                      <span
                        v-tooltip="aclDescriptions[key] || 'Sem descrição'"
                        class="i-lucide-info text-xs text-n-slate-10 cursor-pointer"
                      >
                      </span>
                    </div>
                  </div>
                </div>
              </template>
            </div>
          </div>
        </form>
      </div>
      <div class="flex justify-end gap-2 sticky bottom-0 bg-n-solid-1 pt-3">
        <Button @click="closeEditModal" slate>Cancelar</Button>
        <Button primary @click="saveACL">Salvar</Button>
      </div>
    </div>
  </div>
</template>
