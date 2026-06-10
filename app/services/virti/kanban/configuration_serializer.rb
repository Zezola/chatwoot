class Virti::Kanban::ConfigurationSerializer
  DEFAULT_COLORS = Virti::Kanban::ConfigurationNormalizer::DEFAULT_COLORS

  def self.perform(configuration, account:)
    new(configuration, account: account).perform
  end

  def initialize(configuration, account:)
    @configuration = configuration || {}
    @account = account
  end

  def perform
    {
      version: raw_configuration['version'].presence || 1,
      columns: columns.map.with_index { |column, index| serialize_column(column, index) }
    }
  end

  private

  attr_reader :configuration, :account

  def columns
    raw_configuration['columns'].is_a?(Array) ? raw_configuration['columns'] : []
  end

  def serialize_column(column, index)
    raw_column = column.to_h.with_indifferent_access
    label_ids = Array(raw_column[:labelIds] || raw_column[:label_ids]).filter_map { |id| integer_value(id) }
    label_to_add_id = integer_value(raw_column[:labelToAddId] || raw_column[:label_to_add_id]) || label_ids.first

    {
      id: raw_column[:id],
      title: raw_column[:title],
      color: raw_column[:color].presence || DEFAULT_COLORS[index % DEFAULT_COLORS.length],
      labelIds: label_ids,
      labelToAddId: label_to_add_id,
      labels: label_ids.filter_map { |id| serialize_label(labels_by_id[id]) },
      label_to_add: serialize_label(labels_by_id[label_to_add_id])
    }
  end

  def labels_by_id
    @labels_by_id ||= account.labels.where(id: label_ids).index_by(&:id)
  end

  def label_ids
    @label_ids ||= columns.flat_map do |column|
      raw_column = column.to_h.with_indifferent_access
      Array(raw_column[:labelIds] || raw_column[:label_ids]) + [raw_column[:labelToAddId] || raw_column[:label_to_add_id]]
    end.filter_map { |id| integer_value(id) }.uniq
  end

  def serialize_label(label)
    return if label.blank?

    {
      id: label.id,
      title: label.title,
      description: label.description,
      color: label.color,
      show_on_sidebar: label.show_on_sidebar
    }
  end

  def integer_value(value)
    return if value.blank?

    Integer(value)
  rescue ArgumentError, TypeError
    nil
  end

  def raw_configuration
    @raw_configuration ||= if configuration.respond_to?(:to_unsafe_h)
                             configuration.to_unsafe_h.with_indifferent_access
                           else
                             configuration.to_h.with_indifferent_access
                           end
  end
end
