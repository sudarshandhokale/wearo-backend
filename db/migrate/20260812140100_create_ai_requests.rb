class CreateAiRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :trackable, polymorphic: true
      t.string :operation, null: false
      t.string :status, null: false, default: "pending"
      t.string :provider
      t.string :model
      t.string :response_id
      t.integer :reserved_tokens, null: false, default: 0
      t.integer :input_tokens, null: false, default: 0
      t.integer :output_tokens, null: false, default: 0
      t.integer :total_tokens, null: false, default: 0
      t.integer :attempt_count, null: false, default: 0
      t.string :failure_code
      t.datetime :completed_at

      t.timestamps
    end

    add_index :ai_requests, [ :user_id, :created_at ]
    add_index :ai_requests, [ :user_id, :status, :created_at ]
    add_index :ai_requests, :response_id, unique: true, where: "response_id IS NOT NULL"
  end
end
