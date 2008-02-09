class Country < ActiveRecord::Base
  has_many :order_address
end
