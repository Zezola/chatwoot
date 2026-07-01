json.array! @agents do |agent|
  json.partial! 'api/v1/models/agent', formats: [:json], resource: agent
  json.last_presence_at OnlineStatusTracker.get_last_presence(Current.account.id, 'User', agent.id)
end
