class Api::V1::Accounts::Virti::Kanban::BaseController < Api::V1::Accounts::BaseController
  KANBAN_UPDATED_EVENT = 'virti.kanban.updated'.freeze

  private

  def ensure_administrator!
    render_unauthorized('You are not authorized to do this action') unless Current.account_user&.administrator?
  end

  def serialize_model(model)
    {
      id: model.id,
      accountId: model.account_id,
      name: model.name,
      description: model.description,
      configuration: serialize_configuration(model.configuration),
      usersCount: model.user_models.where(account: Current.account).count,
      createdAt: model.created_at,
      updatedAt: model.updated_at
    }
  end

  def serialize_configuration(configuration)
    Virti::Kanban::ConfigurationSerializer.perform(configuration, account: Current.account)
  end

  def serialize_effective_kanban(user, user_model)
    model = user_model&.model

    {
      userId: user.id,
      kanbanSource: model.present? ? 'model' : 'default',
      editable: model.present? && Current.account_user&.administrator?,
      model: model.present? ? serialize_model_summary(model) : nil,
      configuration: model.present? ? serialize_configuration(model.configuration) : { version: 1, columns: [] }
    }
  end

  def serialize_model_summary(model)
    {
      id: model.id,
      name: model.name,
      description: model.description
    }
  end

  def render_invalid_configuration(error)
    render json: { error: 'Invalid Kanban configuration', details: error.errors }, status: :unprocessable_entity
  end

  def broadcast_kanban_model_updated(model, action)
    users = User.where(id: model.user_models.select(:user_id))
    broadcast_kanban_updated(users, model_id: model.id, action: action)
  end

  def broadcast_kanban_user_updated(user, model_id:, action:)
    broadcast_kanban_updated([user], model_id: model_id, action: action)
  end

  def broadcast_kanban_updated(users, model_id:, action:)
    tokens = Array(users).filter_map(&:pubsub_token).uniq
    return if tokens.blank?

    ActionCableBroadcastJob.perform_later(
      tokens,
      KANBAN_UPDATED_EVENT,
      account_id: Current.account.id,
      model_id: model_id,
      action: action
    )
  end
end
