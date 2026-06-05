module Virti
  module Acl
    module PermissionDefinitions
      LABELS = {
        'pode_ver_menu_de_acoes_da_conversa' => 'Ver menu de ações da conversa',
        'pode_ver_opcoes_de_atribuicao_no_menu_de_contexto' => 'Ver opções de atribuição',
        'pode_filtrar_sem_times' => 'Filtrar sem time obrigatório',
        'pode_filtrar_por_qualquer_time' => 'Filtrar por qualquer time',
        'pode_filtrar_sem_agente_atribuido' => 'Filtrar sem agente obrigatório',
        'pode_filtrar_por_qualquer_agente' => 'Filtrar por qualquer agente',
        'pode_ver_aba_de_nao_atribuidas' => 'Ver conversas não atribuídas',
        'pode_ver_aba_de_todas_conversas' => 'Ver todas as conversas',
        'nao_redirecionar_para_primeira_pasta' => 'Não redirecionar para primeira pasta',
        'pode_ver_menu_kanban' => 'Ver menu Kanban',
        'pode_ver_menu_inbox' => 'Ver menu Inbox',
        'pode_ver_menu_conversas' => 'Ver menu Conversas',
        'pode_ver_menu_contatos' => 'Ver menu Contatos',
        'pode_ver_menu_captain' => 'Ver menu Captain',
        'pode_ver_menu_portais' => 'Ver menu Portais',
        'pode_ver_menu_relatorios' => 'Ver menu Relatórios',
        'pode_ver_menu_configuracoes' => 'Ver menu Configurações',
        'menu_conversas_exibir_todas_conversas' => 'Exibir Todas em Conversas',
        'menu_conversas_exibir_mencoes' => 'Exibir Menções em Conversas',
        'menu_conversas_exibir_nao_atendidas' => 'Exibir Não atendidas em Conversas',
        'menu_conversas_exibir_times' => 'Exibir Times em Conversas',
        'menu_conversas_exibir_canais' => 'Exibir Canais em Conversas',
        'menu_conversas_exibir_etiquetas' => 'Exibir Etiquetas em Conversas',
        'pode_ver_barra_de_busca' => 'Ver barra de busca'
      }.freeze

      GROUPS = {
        'pode_ver_menu_de_acoes_da_conversa' => 'Ações de conversa',
        'pode_ver_opcoes_de_atribuicao_no_menu_de_contexto' => 'Ações de conversa',
        'pode_filtrar_sem_times' => 'Filtros',
        'pode_filtrar_por_qualquer_time' => 'Filtros',
        'pode_filtrar_sem_agente_atribuido' => 'Filtros',
        'pode_filtrar_por_qualquer_agente' => 'Filtros',
        'pode_ver_aba_de_nao_atribuidas' => 'Escopo de conversas',
        'pode_ver_aba_de_todas_conversas' => 'Escopo de conversas',
        'nao_redirecionar_para_primeira_pasta' => 'Navegação',
        'pode_ver_menu_kanban' => 'Menu lateral',
        'pode_ver_menu_inbox' => 'Menu lateral',
        'pode_ver_menu_conversas' => 'Menu lateral',
        'pode_ver_menu_contatos' => 'Menu lateral',
        'pode_ver_menu_captain' => 'Menu lateral',
        'pode_ver_menu_portais' => 'Menu lateral',
        'pode_ver_menu_relatorios' => 'Menu lateral',
        'pode_ver_menu_configuracoes' => 'Menu lateral',
        'menu_conversas_exibir_todas_conversas' => 'Menu Conversas',
        'menu_conversas_exibir_mencoes' => 'Menu Conversas',
        'menu_conversas_exibir_nao_atendidas' => 'Menu Conversas',
        'menu_conversas_exibir_times' => 'Menu Conversas',
        'menu_conversas_exibir_canais' => 'Menu Conversas',
        'menu_conversas_exibir_etiquetas' => 'Menu Conversas',
        'pode_ver_barra_de_busca' => 'Navegação'
      }.freeze

      def self.keys
        DefaultPermissions.to_h.keys
      end

      def self.to_a
        defaults = DefaultPermissions.to_h
        keys.map do |key|
          {
            key: key,
            label: LABELS.fetch(key, key.humanize),
            group: GROUPS.fetch(key, 'Outros'),
            default: defaults.fetch(key)
          }
        end
      end
    end
  end
end
