class User::ProfileSerializer < ApplicationSerializer
  attributes :id,
             :first_name,
             :last_name,
             :full_name,
             :email,
             :timezone,
             :country_code,
             :preferred_city,
             :created_at,
             :updated_at

  def created_at
    format_datetime_value(object.created_at)
  end

  def updated_at
    format_datetime_value(object.updated_at)
  end
end
