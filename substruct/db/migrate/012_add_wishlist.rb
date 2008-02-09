# Adds wishlist support
#
class AddWishlist < ActiveRecord::Migration
  def self.up
		# Adds a table for promotions
    create_table(:wishlist_items, :options => 'DEFAULT CHARSET=UTF8 ENGINE=InnoDB') do |t|
      t.column :order_user_id, :integer, :null => false
      t.column :item_id, :integer, :null => false
      t.column :created_on, :date
		end
		add_index :wishlist_items, ["order_user_id"], :name => "user"
    add_index :wishlist_items, ["item_id"], :name => "item"
  end

  def self.down
		drop_table :wishlist_items
	end
end