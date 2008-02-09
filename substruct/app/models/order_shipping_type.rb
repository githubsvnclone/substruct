class OrderShippingType < ActiveRecord::Base
  has_many :orders
  attr_accessor :price

  def self.get_domestic
    find(:all, :conditions => "is_domestic = 1",
         :order => "flat_fee ASC")
  end

  def self.get_foreign
    find(:all, :conditions => "is_domestic = 0",
         :order => "flat_fee ASC")
  end

  # Calculates shipping price for a shipping type if we can't get it
  # using the shipping gem.
  def calculate_price(weight)
    self.price = ((weight * self.shipping_multiplier) + self.flat_fee)
    return self.price
  end
end
