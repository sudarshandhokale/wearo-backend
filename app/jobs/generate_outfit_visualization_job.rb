class GenerateOutfitVisualizationJob < ApplicationJob
  queue_as :visualizations

  discard_on ActiveJob::DeserializationError

  def perform(outfit_visualization_id)
    visualization = OutfitVisualization.find(outfit_visualization_id)
    return unless visualization.queued?

    Visualization::Generate.call(visualization)
  rescue ActiveRecord::RecordNotFound
    nil
  rescue StandardError => error
    Rails.logger.error("Outfit visualization failed for #{outfit_visualization_id}: #{error.class}: #{error.message}")
  end
end
