class CreateRecommendationRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :recommendation_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.text :prompt, null: false
      t.jsonb :context, null: false, default: {}
      t.jsonb :wardrobe_suggestions, null: false, default: []
      t.string :status, null: false, default: "processing"
      t.string :ranking_source
      t.string :provider
      t.string :model
      t.string :response_id
      t.integer :input_tokens, null: false, default: 0
      t.integer :output_tokens, null: false, default: 0
      t.integer :total_tokens, null: false, default: 0
      t.integer :attempt_count, null: false, default: 0
      t.string :failure_code
      t.datetime :recommended_for
      t.datetime :completed_at

      t.timestamps
    end

    add_index :recommendation_requests, [ :user_id, :created_at ]
    add_index :recommendation_requests, [ :user_id, :status ]

    add_reference :outfits, :recommendation_request, foreign_key: true
    add_column :outfits, :score_breakdown, :jsonb, null: false, default: {}
    add_column :outfits, :rating, :integer
    add_column :outfits, :feedback_note, :string
    add_column :outfits, :status_updated_at, :datetime
  end
end
