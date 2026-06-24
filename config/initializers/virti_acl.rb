Rails.application.config.to_prepare do
  permission_filter_patch = Virti::Acl::Patches::PermissionFilterServicePatch
  permission_filter_service = Conversations::PermissionFilterService
  permission_filter_service.prepend(permission_filter_patch) unless permission_filter_patch <= permission_filter_service

  conversations_patch = Virti::Acl::Patches::ConversationsControllerPatch
  conversations_controller = Api::V1::Accounts::ConversationsController
  conversations_controller.prepend(conversations_patch) unless conversations_patch <= conversations_controller

  conversations_base_patch = Virti::Acl::Patches::ConversationsBaseControllerPatch
  conversations_base_controller = Api::V1::Accounts::Conversations::BaseController
  conversations_base_controller.prepend(conversations_base_patch) unless conversations_base_patch <= conversations_base_controller

  assignments_patch = Virti::Acl::Patches::AssignmentsControllerPatch
  assignments_controller = Api::V1::Accounts::Conversations::AssignmentsController
  assignments_controller.prepend(assignments_patch) unless assignments_patch <= assignments_controller

  notification_builder_patch = Virti::Acl::Patches::NotificationBuilderPatch
  NotificationBuilder.prepend(notification_builder_patch) unless notification_builder_patch <= NotificationBuilder

  notification_finder_patch = Virti::Acl::Patches::NotificationFinderPatch
  NotificationFinder.prepend(notification_finder_patch) unless notification_finder_patch <= NotificationFinder

  action_cable_broadcast_job_patch = Virti::Acl::Patches::ActionCableBroadcastJobPatch
  ActionCableBroadcastJob.prepend(action_cable_broadcast_job_patch) unless action_cable_broadcast_job_patch <= ActionCableBroadcastJob

  action_cable_listener_patch = Virti::Acl::Patches::ActionCableListenerPatch
  ActionCableListener.prepend(action_cable_listener_patch) unless action_cable_listener_patch <= ActionCableListener

  room_channel_patch = Virti::Acl::Patches::RoomChannelPatch
  RoomChannel.prepend(room_channel_patch) unless room_channel_patch <= RoomChannel
end
