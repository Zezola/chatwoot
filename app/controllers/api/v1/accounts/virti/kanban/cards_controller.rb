class Api::V1::Accounts::Virti::Kanban::CardsController < Api::V1::Accounts::Virti::Kanban::BaseController
  before_action :fetch_model
  before_action :ensure_model_access!

  def index
    render json: {
      model: serialize_model_summary(@model),
      columns: serialized_columns_with_cards
    }
  end

  def move
    conversation = Current.account.conversations.find_by!(display_id: params.require(:conversation_id))
    return render json: { error: 'Permission denied' }, status: :forbidden unless allowed_conversation?(conversation)

    source_column = column_by_id(params[:source_column_id]) if params[:source_column_id].present?
    target_column = column_by_id(params.require(:target_column_id))
    target_label = label_title(target_column['labelToAddId'])
    labels = conversation.cached_label_list_array
    removed_labels = labels & movement_label_titles(target_label)
    labels -= removed_labels
    labels |= [target_label]

    conversation.update_labels(labels.compact)

    render json: {
      conversationId: conversation.display_id,
      sourceColumnId: source_column&.dig('id'),
      targetColumnId: target_column['id'],
      removedLabels: removed_labels,
      addedLabel: target_label,
      labels: conversation.label_list
    }
  end

  private

  def fetch_model
    @model = Current.account.virti_kanban_models.find(params[:model_id])
  end

  def ensure_model_access!
    return if Current.account_user&.administrator?
    return if Virti::Kanban::UserModel.exists?(account: Current.account, user: current_user, model: @model)

    render_unauthorized('You are not authorized to do this action')
  end

  def serialized_columns_with_cards
    serialized_configuration[:columns].map do |column|
      column.merge(cards: cards_for_column(column))
    end
  end

  def cards_for_column(column)
    label_titles = column[:labels].map { |label| label[:title] }.compact
    return [] if label_titles.empty?

    scope = Virti::Acl::ConversationScope.new(scope: Current.account.conversations, user: current_user, account: Current.account).perform
    scope.includes(:contact).tagged_with(label_titles, any: true).sort_on_last_activity_at.limit(cards_limit).map do |conversation|
      serialize_conversation(conversation)
    end
  end

  def serialize_conversation(conversation)
    {
      id: conversation.display_id,
      content: conversation.contact&.name,
      labels: conversation.cached_label_list_array,
      status: conversation.status,
      assigneeId: conversation.assignee_id,
      lastActivityAt: conversation.last_activity_at
    }
  end

  def column_by_id(column_id)
    column = @model.normalized_configuration['columns'].find { |candidate| candidate['id'] == column_id }
    return column if column.present?

    raise ActiveRecord::RecordNotFound, 'Column not found'
  end

  def label_title(label_id)
    labels_by_id[label_id]&.title
  end

  def movement_label_titles(target_label)
    labels_by_id.values.map(&:title).compact - [target_label]
  end

  def labels_by_id
    @labels_by_id ||= Current.account.labels.where(id: label_ids).index_by(&:id)
  end

  def label_ids
    @label_ids ||= @model.normalized_configuration['columns'].pluck('labelToAddId').compact
  end

  def serialized_configuration
    @serialized_configuration ||= serialize_configuration(@model.configuration)
  end

  def cards_limit
    limit = params[:limit].presence || 50
    [[limit.to_i, 1].max, 100].min
  end

  def allowed_conversation?(conversation)
    Virti::Acl::ConversationPolicy.new(user: current_user, account: Current.account, conversation: conversation).show?
  end
end
