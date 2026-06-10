Rails.application.config.to_prepare do
  permission_filter_patch = Virti::Acl::Patches::PermissionFilterServicePatch
  permission_filter_service = Conversations::PermissionFilterService
  permission_filter_service.prepend(permission_filter_patch) unless permission_filter_service.ancestors.include?(permission_filter_patch)

  conversations_patch = Virti::Acl::Patches::ConversationsControllerPatch
  conversations_controller = Api::V1::Accounts::ConversationsController
  conversations_controller.prepend(conversations_patch) unless conversations_controller.ancestors.include?(conversations_patch)

  conversations_base_patch = Virti::Acl::Patches::ConversationsBaseControllerPatch
  conversations_base_controller = Api::V1::Accounts::Conversations::BaseController
  conversations_base_controller.prepend(conversations_base_patch) unless conversations_base_controller.ancestors.include?(conversations_base_patch)

  assignments_patch = Virti::Acl::Patches::AssignmentsControllerPatch
  assignments_controller = Api::V1::Accounts::Conversations::AssignmentsController
  assignments_controller.prepend(assignments_patch) unless assignments_controller.ancestors.include?(assignments_patch)

  notification_builder_patch = Virti::Acl::Patches::NotificationBuilderPatch
  NotificationBuilder.prepend(notification_builder_patch) unless NotificationBuilder.ancestors.include?(notification_builder_patch)

  notification_finder_patch = Virti::Acl::Patches::NotificationFinderPatch
  NotificationFinder.prepend(notification_finder_patch) unless NotificationFinder.ancestors.include?(notification_finder_patch)

  action_cable_broadcast_job_patch = Virti::Acl::Patches::ActionCableBroadcastJobPatch
  ActionCableBroadcastJob.prepend(action_cable_broadcast_job_patch) unless ActionCableBroadcastJob.ancestors.include?(action_cable_broadcast_job_patch)

  action_cable_listener_patch = Virti::Acl::Patches::ActionCableListenerPatch
  ActionCableListener.prepend(action_cable_listener_patch) unless ActionCableListener.ancestors.include?(action_cable_listener_patch)
end
