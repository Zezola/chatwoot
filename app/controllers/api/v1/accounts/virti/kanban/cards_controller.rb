class Api::V1::Accounts::Virti::Kanban::CardsController < Api::V1::Accounts::Virti::Kanban::BaseController
  before_action :fetch_model
  before_action :ensure_model_access!

  def index
    render json: {
      model: serialize_model_summary(@model),
      columns: serialized_columns_with_cards
    }
  end

  def column
    render json: column_with_cards(serialized_column_by_id(params.require(:column_id)))
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
      column_with_cards(column)
    end
  end

  def column_with_cards(column)
    column.merge(cards_payload_for_column(column))
  end

  def cards_payload_for_column(column)
    relation = cards_relation_for_column(column)
    total_cards = total_cards_count(relation)
    conversations = relation_with_cursor(relation).limit(cards_per_page + 1).to_a
    has_more = conversations.length > cards_per_page
    cards = conversations.first(cards_per_page)

    {
      cards: cards.map { |conversation| serialize_conversation(conversation) },
      hasMore: has_more,
      nextCursor: has_more ? encode_cursor(cards.last) : nil,
      totalCards: total_cards
    }
  end

  def cards_relation_for_column(column)
    label_titles = column[:labels].map { |label| label[:title] }.compact
    return Current.account.conversations.none if label_titles.empty?

    acl_conversation_scope.includes(:contact)
                          .tagged_with(label_titles, any: true)
                          .reorder(last_activity_at: :desc, id: :desc)
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

  def serialized_column_by_id(column_id)
    column = serialized_configuration[:columns].find { |candidate| candidate[:id] == column_id }
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

  def cards_per_page
    per_page = params[:per_page].presence || params[:limit].presence || 30
    [[per_page.to_i, 1].max, 100].min
  end

  def relation_with_cursor(relation)
    cursor = decoded_cursor
    return relation if cursor.blank?

    relation.where(
      'conversations.last_activity_at < :last_activity_at OR (conversations.last_activity_at = :last_activity_at AND conversations.id < :id)',
      last_activity_at: cursor[:last_activity_at],
      id: cursor[:id]
    )
  end

  def decoded_cursor
    return if params[:cursor].blank?

    timestamp, id = params[:cursor].to_s.split(':', 2)
    return if timestamp.blank? || id.blank?

    { last_activity_at: Time.zone.at(Float(timestamp)), id: Integer(id) }
  rescue ArgumentError, TypeError
    nil
  end

  def encode_cursor(conversation)
    return if conversation.blank?

    "#{conversation.last_activity_at.to_f}:#{conversation.id}"
  end

  def total_cards_count(relation)
    relation.except(:order, :limit, :offset).distinct.count(:id)
  end

  def acl_conversation_scope
    @acl_conversation_scope ||= Virti::Acl::ConversationScope.new(
      scope: Current.account.conversations,
      user: current_user,
      account: Current.account
    ).perform
  end

  def allowed_conversation?(conversation)
    Virti::Acl::ConversationPolicy.new(user: current_user, account: Current.account, conversation: conversation).show?
  end
end
