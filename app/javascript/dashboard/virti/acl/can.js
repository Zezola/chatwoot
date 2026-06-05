export const PERMISSION_MAP = {
  'sidebar.kanban': 'pode_ver_menu_kanban',
  'sidebar.inbox': 'pode_ver_menu_inbox',
  'sidebar.contacts': 'pode_ver_menu_contatos',
  'sidebar.captain': 'pode_ver_menu_captain',
  'sidebar.portals': 'pode_ver_menu_portais',
  'sidebar.reports': 'pode_ver_menu_relatorios',
  'sidebar.settings': 'pode_ver_menu_configuracoes',
  'sidebar.search': 'pode_ver_barra_de_busca',
  'conversation.menu.all': 'menu_conversas_exibir_todas_conversas',
  'conversation.menu.mentions': 'menu_conversas_exibir_mencoes',
  'conversation.menu.unattended': 'menu_conversas_exibir_nao_atendidas',
  'conversation.menu.teams': 'menu_conversas_exibir_times',
  'conversation.menu.channels': 'menu_conversas_exibir_canais',
  'conversation.menu.labels': 'menu_conversas_exibir_etiquetas',
  'conversation.actions': 'pode_ver_menu_de_acoes_da_conversa',
  'conversation.assign': 'pode_ver_opcoes_de_atribuicao_no_menu_de_contexto',
  'conversation.view_all': 'pode_ver_aba_de_todas_conversas',
  'conversation.view_unassigned': 'pode_ver_aba_de_nao_atribuidas',
  'filters.without_team': 'pode_filtrar_sem_times',
  'filters.any_team': 'pode_filtrar_por_qualquer_time',
  'filters.without_assignee': 'pode_filtrar_sem_agente_atribuido',
  'filters.any_assignee': 'pode_filtrar_por_qualquer_agente',
};

export const can = (acl, permission) => {
  const key = PERMISSION_MAP[permission] || permission;
  return acl?.[key] !== false;
};
