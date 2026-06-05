module Virti
  module Acl
    module DefaultPermissions
      VALUES = {
        'pode_ver_menu_de_acoes_da_conversa' => true,
        'pode_ver_opcoes_de_atribuicao_no_menu_de_contexto' => true,
        'pode_filtrar_sem_times' => true,
        'pode_filtrar_por_qualquer_time' => true,
        'pode_filtrar_sem_agente_atribuido' => true,
        'pode_filtrar_por_qualquer_agente' => true,
        'pode_ver_aba_de_nao_atribuidas' => true,
        'pode_ver_aba_de_todas_conversas' => true,
        'nao_redirecionar_para_primeira_pasta' => true,
        'pode_ver_menu_kanban' => true,
        'pode_ver_menu_inbox' => true,
        'pode_ver_menu_conversas' => true,
        'pode_ver_menu_contatos' => true,
        'pode_ver_menu_captain' => true,
        'pode_ver_menu_portais' => true,
        'pode_ver_menu_relatorios' => true,
        'pode_ver_menu_configuracoes' => true,
        'menu_conversas_exibir_todas_conversas' => true,
        'menu_conversas_exibir_mencoes' => true,
        'menu_conversas_exibir_nao_atendidas' => true,
        'menu_conversas_exibir_times' => true,
        'menu_conversas_exibir_canais' => true,
        'menu_conversas_exibir_etiquetas' => true,
        'pode_ver_barra_de_busca' => true
      }.freeze

      def self.to_h
        VALUES.deep_dup
      end
    end
  end
end
