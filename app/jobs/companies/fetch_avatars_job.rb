class Companies::FetchAvatarsJob < ApplicationJob
  queue_as :low

  def perform(account_id)
    Rails.logger.info "Skipping Companies::FetchAvatarsJob for account #{account_id}: companies are not enabled in this fork"
  end
end
