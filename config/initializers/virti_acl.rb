Rails.application.config.to_prepare do
  prepend_once = lambda do |target, patch|
    target.prepend(patch) unless target.ancestors.include?(patch)
  end

  permission_filter_patch = Virti::Acl::Patches::PermissionFilterServicePatch
  permission_filter_service = Conversations::PermissionFilterService
  prepend_once.call(permission_filter_service, permission_filter_patch)

  conversations_patch = Virti::Acl::Patches::ConversationsControllerPatch
  conversations_controller = Api::V1::Accounts::ConversationsController
  prepend_once.call(conversations_controller, conversations_patch)

  conversations_base_patch = Virti::Acl::Patches::ConversationsBaseControllerPatch
  conversations_base_controller = Api::V1::Accounts::Conversations::BaseController
  prepend_once.call(conversations_base_controller, conversations_base_patch)

  assignments_patch = Virti::Acl::Patches::AssignmentsControllerPatch
  assignments_controller = Api::V1::Accounts::Conversations::AssignmentsController
  prepend_once.call(assignments_controller, assignments_patch)

  notification_builder_patch = Virti::Acl::Patches::NotificationBuilderPatch
  prepend_once.call(NotificationBuilder, notification_builder_patch)

  notification_finder_patch = Virti::Acl::Patches::NotificationFinderPatch
  prepend_once.call(NotificationFinder, notification_finder_patch)

  action_cable_broadcast_job_patch = Virti::Acl::Patches::ActionCableBroadcastJobPatch
  prepend_once.call(ActionCableBroadcastJob, action_cable_broadcast_job_patch)

  action_cable_listener_patch = Virti::Acl::Patches::ActionCableListenerPatch
  prepend_once.call(ActionCableListener, action_cable_listener_patch)

  search_service_patch = Virti::Acl::Patches::SearchServicePatch
  prepend_once.call(SearchService, search_service_patch)
end
