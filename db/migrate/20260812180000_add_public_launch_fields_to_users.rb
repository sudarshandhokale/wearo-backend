class AddPublicLaunchFieldsToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :confirmed_at, :datetime
    add_column :users, :terms_accepted_at, :datetime
    add_column :users, :terms_version, :string
    add_column :users, :privacy_accepted_at, :datetime
    add_column :users, :privacy_version, :string
    add_column :users, :ai_processing_consent_at, :datetime
    add_column :users, :adult_confirmed_at, :datetime
    add_column :users, :full_body_image_consent_at, :datetime

    add_index :users, :confirmed_at

    # Existing prototype accounts remain accessible; new registrations must verify email and record consent.
    execute <<~SQL.squish
      UPDATE users
      SET confirmed_at = COALESCE(confirmed_at, created_at)
    SQL
  end

  def down
    remove_index :users, :confirmed_at
    remove_columns :users,
                   :confirmed_at,
                   :terms_accepted_at,
                   :terms_version,
                   :privacy_accepted_at,
                   :privacy_version,
                   :ai_processing_consent_at,
                   :adult_confirmed_at,
                   :full_body_image_consent_at
  end
end
