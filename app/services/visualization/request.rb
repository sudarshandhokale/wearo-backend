module Visualization
  class Request
    DEFAULT_DAILY_LIMIT = 10
    DEFAULT_AUTO_DAILY_LIMIT = 30
    DEFAULT_TRY_ON_DAILY_LIMIT = 1

    Result = Data.define(:visualization, :reused, :queued, :limited)

    class << self
      def call(user:, outfit:, mode: "flat_lay", reference_image: nil, metadata: {}, enforce_limit: true, auto: false, allow_create: true)
        return Result.new(visualization: nil, reused: false, queued: false, limited: false) unless user.ai_processing_consented?

        visualization = user.outfit_visualizations.new(
          outfit: outfit,
          mode: resolved_mode(user, mode, reference_image),
          metadata: metadata.to_h.stringify_keys
        )
        visualization.reference_image.attach(reference_image) if reference_image.present?
        visualization.metadata["requested_mode"] = mode if mode == "try_on" && visualization.flat_lay?
        visualization.metadata["fallback_reason"] = "person_reference_missing" if mode == "try_on" && visualization.flat_lay?
        visualization.metadata["reference_source"] = reference_source(visualization) if visualization.try_on?
        visualization.metadata["source_fingerprint"] = Visualization::SourceFingerprint.call(visualization)

        if (existing = reusable_visualization(outfit, visualization))
          purge_transient_reference(visualization)
          return Result.new(visualization: existing, reused: true, queued: false, limited: false)
        end

        return Result.new(visualization: nil, reused: false, queued: false, limited: false) unless allow_create
        return Result.new(visualization: nil, reused: false, queued: false, limited: true) if enforce_limit && daily_limit_reached?(user, mode: visualization.mode, auto: auto)

        visualization.save!
        GenerateOutfitVisualizationJob.perform_later(visualization.id)
        Result.new(visualization: visualization, reused: false, queued: true, limited: false)
      rescue ActiveRecord::RecordInvalid
        purge_transient_reference(visualization)
        Result.new(visualization: nil, reused: false, queued: false, limited: false)
      end

      private

      def resolved_mode(user, mode, reference_image)
        return mode unless mode == "try_on"

        reference_image.present? || user.full_body_image.attached? ? "try_on" : "flat_lay"
      end

      def reusable_visualization(outfit, visualization)
        outfit.outfit_visualizations
              .joins(:image_attachment)
              .where(mode: visualization.mode, status: :ready)
              .where("outfit_visualizations.metadata ->> 'source_fingerprint' = ?", visualization.metadata["source_fingerprint"])
              .recent_first
              .first || reusable_in_progress_visualization(outfit, visualization)
      end

      def reusable_in_progress_visualization(outfit, visualization)
        outfit.outfit_visualizations
              .where(mode: visualization.mode, status: %i[queued processing])
              .where("outfit_visualizations.metadata ->> 'source_fingerprint' = ?", visualization.metadata["source_fingerprint"])
              .recent_first
              .first
      end

      def daily_limit_reached?(user, mode:, auto:)
        limit_key, default = limit_config(mode: mode, auto: auto)
        limit = Integer(AppConfig.fetch(limit_key, default: default), exception: false).to_i.clamp(1, 100)
        local_day = Time.current.in_time_zone(user.timezone).all_day
        scope = user.outfit_visualizations.where(created_at: local_day)
        scope = scope.where(mode: "try_on") if limit_key == :try_on_visualization_daily_limit
        scope.count >= limit
      end

      def limit_config(mode:, auto:)
        return [ :try_on_visualization_daily_limit, DEFAULT_TRY_ON_DAILY_LIMIT ] if !auto && mode == "try_on"
        return [ :auto_flat_lay_visualization_daily_limit, DEFAULT_AUTO_DAILY_LIMIT ] if auto

        [ :visualization_daily_limit, DEFAULT_DAILY_LIMIT ]
      end

      def reference_source(visualization)
        visualization.reference_image.attached? ? "request" : "profile"
      end

      def purge_transient_reference(visualization)
        visualization.reference_image.purge if visualization&.reference_image&.attached? && !visualization.persisted?
      end
    end
  end
end
