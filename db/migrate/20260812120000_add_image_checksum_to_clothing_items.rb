class AddImageChecksumToClothingItems < ActiveRecord::Migration[8.0]
  def up
    add_column :clothing_items, :image_checksum, :string

    execute <<~SQL.squish
      WITH active_item_checksums AS (
        SELECT clothing_items.id,
               active_storage_blobs.checksum,
               ROW_NUMBER() OVER (
                 PARTITION BY clothing_items.user_id, active_storage_blobs.checksum
                 ORDER BY clothing_items.id
               ) AS duplicate_rank
        FROM clothing_items
        INNER JOIN active_storage_attachments
          ON active_storage_attachments.record_type = 'ClothingItem'
          AND active_storage_attachments.record_id = clothing_items.id
          AND active_storage_attachments.name = 'image'
        INNER JOIN active_storage_blobs
          ON active_storage_blobs.id = active_storage_attachments.blob_id
        WHERE clothing_items.discarded_at IS NULL
      )
      UPDATE clothing_items
      SET image_checksum = active_item_checksums.checksum
      FROM active_item_checksums
      WHERE clothing_items.id = active_item_checksums.id
        AND active_item_checksums.duplicate_rank = 1
    SQL

    execute <<~SQL.squish
      UPDATE clothing_items
      SET image_checksum = active_storage_blobs.checksum
      FROM active_storage_attachments
      INNER JOIN active_storage_blobs
        ON active_storage_blobs.id = active_storage_attachments.blob_id
      WHERE active_storage_attachments.record_type = 'ClothingItem'
        AND active_storage_attachments.record_id = clothing_items.id
        AND active_storage_attachments.name = 'image'
        AND clothing_items.discarded_at IS NOT NULL
    SQL

    add_index :clothing_items,
              [ :user_id, :image_checksum ],
              unique: true,
              where: "discarded_at IS NULL AND image_checksum IS NOT NULL",
              name: "index_active_clothing_items_on_user_and_image_checksum"
  end

  def down
    remove_index :clothing_items, name: "index_active_clothing_items_on_user_and_image_checksum"
    remove_column :clothing_items, :image_checksum
  end
end
