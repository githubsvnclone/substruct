class Cart
  attr_reader :items

  # Initializes the shopping cart
  def initialize
    empty!
  end

  # Empties or initializes the cart
  def empty!
    @items = []
    @total = 0.0
  end

	def empty?
		@items.length == 0
	end

  # Returns the total price of our cart
  def total
    @total = 0.0
    for item in items
      @total += (item.quantity * item.unit_price)
    end
    return @total
  end
  # Defined here because in order we have a line_items_total
  # That number is the total of items - shipping costs.
  def line_items_total
    total
  end

  # Adds a product to our shopping cart
  def add_product(product, quantity=1)
    item = @items.find { |i| i.product_id == product.id }
    if item
      item.quantity += quantity
    else
			item = OrderLineItem.for_product(product)
			item.quantity = quantity
      @items << item
    end
  end

	# Removes all quantities of product from our cart
	def remove_product(product, quantity=1)
		item = @items.find { |i| i.product_id == product.id }
		if item
      if item.quantity > quantity then
        item.quantity -= quantity
      else
        @items.delete(item)
			end
		end
	end

end
