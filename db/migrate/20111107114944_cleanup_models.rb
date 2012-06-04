class CleanupModels < ActiveRecord::Migration
  def self.up
    drop_table :statistics

    remove_column :items, :wip_total
    remove_column :items, :current_lane_entry
    remove_column :items, :last_editor_id

    remove_column :lanes, :max_items
    remove_column :lanes, :type
    remove_column :lanes, :counts_wip
    remove_column :lanes, :warn_limit
    remove_column :lanes, :urgent_limit
    remove_column :lanes, :dashboard

    remove_index :items, :name => :index_items_on_last_editor_id rescue ActiveRecord::StatementInvalid
  end

  def self.down
    add_column :items, :wip_total, :integer
    add_column :items, :current_lane_entry, :timestamp
    add_column :items, :last_editor_id, :integer

    add_column :lanes, :max_items, :integer, :default => 25
    add_column :lanes, :type, :string
    add_column :lanes, :counts_wip, :boolean
    add_column :lanes, :warn_limit, :integer, :default => 10
    add_column :lanes, :urgent_limit, :integer, :default => 10
    add_column :lanes, :dashboard, :boolean, :default => false

    create_table "statistics", :force => true do |t|
      t.timestamp "entry_time"
      t.timestamp "leave_time"
      t.integer   "duration"
      t.timestamp "created_at"
      t.timestamp "updated_at"
      t.integer   "lane_id"
      t.integer   "item_id"
      t.integer   "user_id"
    end

    add_index "statistics", ["item_id"], :name => "index_statistics_on_item_id"
    add_index "statistics", ["lane_id"], :name => "index_statistics_on_lane_id"
    add_index "statistics", ["user_id"], :name => "index_statistics_on_user_id"

    add_index :items, [:last_editor_id]
  end
end