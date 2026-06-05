module Virti
  module Acl
    class PermissionNormalizer
      class InvalidPermissionsError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super('Invalid ACL permissions')
        end
      end

      LEGACY_KEYS = %w[
        direcionar_conversa
        pode_ver_menu_config_macros
        pode_ver_menu_config_respostas_prontas
        pode_ver_menu_empresas
        pode_ver_menu_lateral_completo
        side_panel
        time_privado
        ver_conversas_nao_vinculadas_a_mim
      ].freeze

      def self.perform(permissions, strict: false, allow_empty: true)
        normalized = permissions.to_h.deep_stringify_keys

        if normalized['pode_ver_menu_lateral_completo'].nil? && normalized.key?('side_panel')
          normalized['pode_ver_menu_lateral_completo'] = normalized['side_panel']
        end

        LEGACY_KEYS.each { |key| normalized.delete(key) }
        invalid_keys = normalized.keys - PermissionDefinitions.keys
        invalid_values = normalized.filter_map { |key, value| key unless [true, false].include?(value) }

        if strict && (invalid_keys.any? || invalid_values.any? || (!allow_empty && normalized.blank?))
          raise InvalidPermissionsError.new(
            invalidKeys: invalid_keys,
            invalidValues: invalid_values,
            empty: !allow_empty && normalized.blank?
          )
        end

        normalized.slice(*PermissionDefinitions.keys).select { |_key, value| [true, false].include?(value) }
      end
    end
  end
end
