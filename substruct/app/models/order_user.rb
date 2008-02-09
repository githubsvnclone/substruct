class OrderUser < ActiveRecord::Base
  has_many :orders,
	          :dependent => false,
	          :order => "created_on DESC"
	has_many :order_addresses,
	          :dependent => :destroy,
	          :order => "id ASC"
	has_one :order_account,
	          :dependent => :destroy
  validates_presence_of :email_address, :message => ERROR_EMPTY
	validates_length_of :email_address, :maximum => 255
	validates_format_of :email_address,
	                    :with => /^([^@\s]+)@((?:[-a-zA-Z0-9]+\.)+[a-zA-Z]{2,})$/,
	                    :message => "Please enter a valid email address."
	
end
