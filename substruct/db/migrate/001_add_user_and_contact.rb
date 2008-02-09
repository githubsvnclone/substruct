class AddUserAndContact < ActiveRecord::Migration
  def self.up
		# EMail address for asking questions
		add_column :questions, :email_address, :string, :limit => 50
		change_column :questions, :answered_on, :datetime, :null => true
		# Transaction ID that needs to be stored by authorize.net
		add_column :orders, :auth_transaction_id, :integer, :limit => 11, :default => nil
  end

  def self.down
		remove_column :questions, :email_address
		change_column :questions, :answered_on, :datetime, :null => false
		remove_column :orders, :auth_transaction_id
  end
end
