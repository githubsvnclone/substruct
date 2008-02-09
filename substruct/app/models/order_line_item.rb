class OrderLineItem < ActiveRecord::Base
  belongs_to :product
  belongs_to :order

  # Creates and returns a line item when a product is passed in
  def self.for_product(product)
    item = self.new
    item.quantity = 1
    item.product = product
    item.unit_price = product.price
    return item
  end

  def total
    self.quantity * self.unit_price
  end

	# Item name.
	# 
	# If the product has been deleted return our own string.
	# It might be smarter to store the product name
	# in the order_line_item in the future.
  def name
    if self.product then
			return self.product.name
		else 
			return "Item has been deleted."
		end
  end

end
