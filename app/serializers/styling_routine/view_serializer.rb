class StylingRoutine::ViewSerializer < ApplicationSerializer
  attributes :id, :name, :routine_type, :routine_type_label, :days_of_week, :day_labels,
             :local_time, :usage, :usage_label, :occasion, :occasion_label, :activity, :activity_label,
             :city_mode, :city_mode_label, :city, :outfit_strategy, :outfit_strategy_label,
             :recommendation_lead_minutes, :reminder_enabled, :active, :created_at, :updated_at

  labeled_attributes :routine_type
  labeled_attributes :usage, scope: :clothing_usage
  labeled_attributes :occasion
  labeled_attributes :activity
  labeled_attributes :city_mode
  labeled_attributes :outfit_strategy

  def day_labels
    object.days_of_week.map { |day| I18n.t("date.day_names")[day % 7] }
  end

  def local_time
    object.local_time.strftime("%H:%M")
  end

  def created_at = format_datetime_value(object.created_at)
  def updated_at = format_datetime_value(object.updated_at)
end
