class Virti::Kanban::ConfigurationNormalizer
  DEFAULT_COLORS = %w[blue teal amber violet ruby iris gray].freeze
  ALLOWED_COLORS = (DEFAULT_COLORS + ['slate']).freeze

  class InvalidConfigurationError < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super(errors.join(', '))
    end
  end

  def self.perform(configuration, account:)
    new(configuration, account: account).perform
  end

  def initialize(configuration, account:)
    @configuration = configuration || {}
    @account = account
    @errors = []
  end

  def perform
    normalized = { 'version' => version, 'columns' => normalized_columns }
    raise InvalidConfigurationError, errors if errors.any?

    normalized
  end

  private

  attr_reader :configuration, :account, :errors

  def version
    raw_configuration['version'].presence || 1
  end

  def normalized_columns
    columns = raw_configuration['columns'] || []
    unless columns.is_a?(Array)
      errors << 'columns must be an array'
      return []
    end

    columns.each_with_index.map { |column, index| normalize_column(column, index) }.compact
  end

  def normalize_column(column, index)
    unless column.respond_to?(:to_h)
      errors << "column #{index + 1} must be an object"
      return
    end

    raw_column = column.to_h.with_indifferent_access
    label_ids = normalize_label_ids(raw_column)
    label_to_add_id = normalize_label_to_add_id(raw_column) || label_ids.first
    validate_column(raw_column, label_ids, label_to_add_id, index)

    {
      'id' => raw_column[:id].presence || SecureRandom.uuid,
      'title' => raw_column[:title].to_s.strip,
      'color' => normalize_color(raw_column, index),
      'labelIds' => label_ids,
      'labelToAddId' => label_to_add_id
    }
  end

  def validate_column(raw_column, label_ids, label_to_add_id, index)
    errors << "column #{index + 1} title is required" if raw_column[:title].to_s.strip.blank?
    errors << "column #{index + 1} must have at least one label" if label_ids.empty?
    if label_to_add_id.present? && !label_ids.include?(label_to_add_id)
      errors << "column #{index + 1} labelToAddId must be one of labelIds"
    end
    if raw_column[:color].present? && !ALLOWED_COLORS.include?(raw_column[:color].to_s)
      errors << "column #{index + 1} has invalid color"
    end

    missing_label_ids = label_ids - labels_by_id.keys
    errors << "column #{index + 1} has invalid label ids: #{missing_label_ids.join(', ')}" if missing_label_ids.any?
  end

  def normalize_color(raw_column, index)
    color = raw_column[:color].presence || DEFAULT_COLORS[index % DEFAULT_COLORS.length]
    ALLOWED_COLORS.include?(color.to_s) ? color.to_s : DEFAULT_COLORS[index % DEFAULT_COLORS.length]
  end

  def normalize_label_ids(raw_column)
    values = raw_column[:labelIds] || raw_column[:label_ids]
    values ||= Array(raw_column[:labels]).filter_map { |label| label_id(label) }
    Array(values).filter_map { |value| integer_value(value) }.uniq
  end

  def normalize_label_to_add_id(raw_column)
    value = raw_column[:labelToAddId] || raw_column[:label_to_add_id]
    value ||= label_id(raw_column[:label_to_add])
    integer_value(value)
  end

  def label_id(label)
    return if label.blank?
    return label[:id] if label.respond_to?(:[]) && label[:id].present?
    return label['id'] if label.respond_to?(:[]) && label['id'].present?

    nil
  end

  def integer_value(value)
    return if value.blank?

    Integer(value)
  rescue ArgumentError, TypeError
    nil
  end

  def labels_by_id
    return {} if account.blank?

    @labels_by_id ||= account.labels.where(id: all_label_ids).index_by(&:id)
  end

  def all_label_ids
    @all_label_ids ||= begin
      columns = raw_configuration['columns'] || []
      Array(columns).flat_map do |column|
        next [] unless column.respond_to?(:to_h)

        raw_column = column.to_h.with_indifferent_access
        normalize_label_ids(raw_column) + [normalize_label_to_add_id(raw_column)]
      end.compact.uniq
    end
  end

  def raw_configuration
    @raw_configuration ||= if configuration.respond_to?(:to_unsafe_h)
                             configuration.to_unsafe_h.with_indifferent_access
                           else
                             configuration.to_h.with_indifferent_access
                           end
  end
end
