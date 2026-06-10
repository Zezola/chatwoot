class Api::V1::Accounts::Virti::Kanban::ModelsController < Api::V1::Accounts::Virti::Kanban::BaseController
  rescue_from Virti::Kanban::ConfigurationNormalizer::InvalidConfigurationError, with: :render_invalid_configuration

  before_action :ensure_administrator!
  before_action :fetch_model, only: [:show, :update, :destroy]

  def index
    render json: Current.account.virti_kanban_models.order(:name).map { |model| serialize_model(model) }
  end

  def show
    render json: serialize_model(@model)
  end

  def create
    model = Current.account.virti_kanban_models.create!(model_params.merge(created_by: current_user, updated_by: current_user))

    render json: serialize_model(model), status: :created
  end

  def update
    @model.update!(model_params.merge(updated_by: current_user))
    broadcast_kanban_model_updated(@model, 'model_updated')

    render json: serialize_model(@model)
  end

  def destroy
    if @model.user_models.exists?
      return render json: { error: 'Kanban model is in use' }, status: :conflict
    end

    @model.destroy!
    head :ok
  end

  private

  def fetch_model
    @model = Current.account.virti_kanban_models.find(params[:id])
  end

  def model_params
    permitted_params = params.require(:model).permit(
      :name,
      :description,
      configuration: {
        columns: [
          :id, :title, :color, :labelToAddId, :label_to_add_id,
          { labelIds: [], label_ids: [], labels: [:id] }
        ]
      }
    )
    attributes = permitted_params.to_h

    if permitted_params.key?(:configuration)
      attributes['configuration'] = Virti::Kanban::ConfigurationNormalizer.perform(permitted_params[:configuration], account: Current.account)
    elsif action_name == 'create'
      attributes['configuration'] = { 'version' => 1, 'columns' => [] }
    end

    attributes
  end
end
