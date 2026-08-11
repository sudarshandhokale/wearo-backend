class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :first_name, null: false
      t.string :last_name
      t.string :email, null: false
      t.string :encrypted_password, null: false, default: ""
      t.string :timezone, null: false, default: "UTC"
      t.string :country_code, null: false, default: "US"
      t.string :preferred_city
      t.integer :sign_in_count, null: false, default: 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip

      t.timestamps
    end

    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"
  end
end
