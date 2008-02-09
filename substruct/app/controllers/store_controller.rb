class StoreController < ApplicationController
  layout 'main'
  include OrderHelper

  # Our simple store index
  def index
    @title = "Store"
    @cart = find_cart
		@tags = Tag.find_alpha
		@tag_names = nil
		@viewing_tags = nil
    #@products = Product.find(:all)
    @product_pages, 
			@products = paginate :products, 
			:per_page => 10, 
			:order_by => "name ASC"
  end

	# Shows products by tag or tags.
	# Tags are passed in as id #'s separated by commas.
	#
	def show_by_tags
		@cart = find_cart
		# Tags are passed in as an array.
		# Passed into this controller like this:
		# /store/show_by_tags/tag_one/tag_two/tag_three/...
		@tag_names = params[:tags]
		# Generate tag ID list from names
		tag_ids_array = Array.new
		for name in @tag_names
			temp_tag = Tag.find_by_name(name)
			if temp_tag then
				tag_ids_array << temp_tag.id
			end
		end
		@viewing_tags = Tag.find(tag_ids_array)
		viewing_tag_names = @viewing_tags.collect { |t| "#{t} > "}
		@title = "Store > #{viewing_tag_names}"
		@tags = Tag.find_related_tags(tag_ids_array)
		@products = Product.find_by_tags(tag_ids_array)
		render :action => 'index'
	end

  # This is a component...
  # Displays a fragment of HTML that shows a product, desc, and "buy now" link
  def display_product
		@cart = find_cart
    @product = Product.find(:first, :conditions => ["id = ?", @params[:id]])
    if (@product.images[0]) then
			@image = @product.images[0]
		else
			@image = nil
		end
    render :layout => false
  end

  # Adds an item to the cart, then redirects to checkout
  #
  # This is the old way of doing things before the AJAX cart.
  #
  # Left in if someone would like to use it instead.
  def add_to_cart
    product = Product.find(params[:id])
    @cart = find_cart
    @cart.add_product(product)
		# In substruct.rb
		redirect_to get_link_to_checkout
  rescue
    logger.error("[ERROR] - Can't find product for id: #{params[:id]}")
    redirect_to_index("Sorry, you tried to buy a product that we don't carry any longer.")
  end

	# Adds an item to our cart via AJAX
	#
	# Returns the cart HTML as a partial to update the view in JS
	def add_to_cart_ajax
		product = Product.find(params[:id])
		@cart = find_cart
		@cart.add_product(product)
		render :partial => 'cart'
	rescue
		render :text => "There was a problem adding that item. Please refresh this page."
	end


	# Removes one item via AJAX
	#
	# Returns the cart HTML as a partial to update the view in JS
	def remove_from_cart_ajax
		product = Product.find(params[:id])
		@cart = find_cart
		@cart.remove_product(product)
		render :partial => 'cart'
	rescue
		render :text => "There was a problem removing that item. Please refresh this page."
	end

	# Empties the entire cart via ajax...
	#
	# Again, returns cart HTML via partial
	def empty_cart_ajax
		clear_cart_and_order
		render :partial => 'cart'
	end

  # Empties the cart out and redirects to index.
  # Removes any order saved to the DB if there is such a thing.
  #
  # The old (non-ajax) way of doing things
  def empty_cart
    clear_cart_and_order
    redirect_to_index("All items have been removed from your order.")
  end

  # Gathers customer information.
  # Displays form fields for grabbing name/addy/credit info
  #
  # Also displays items in the current order
  def checkout
    @title = "Please enter your information to continue this purchase."
    @cart = find_cart
    @items = @cart.items
    @order = find_order
    if @order == nil then
      # Save standard form info
      initialize_new_order
    else
      initialize_existing_order
    end
    if @items.empty?
      redirect_to_index("You've not chosen to buy any items yet. Please select an item from this page.")
    end
  end

  # Execution action of checkout (above)
  #
  # Tries to create an order. If it cant, returns to the page and shows errors.
  def do_checkout
    @title = "Ooops, did you forget to fill something in?"
    @cart = find_cart
    @items = @cart.items
    @order = find_order
    # We might be re-doing an existing order.
    # Don't want to create a new order for failed transactions, sooo
    if @order == nil then
      logger.info("\n\n\nCREATING NEW ORDER FROM POST\n\n\n")
      logger.info(params[:use_separate_shipping_address])
      logger.info("\n\n\n")
      create_order_from_post
    else
      logger.info("\n\n\nUPDATING EXISTING ORDER FROM POST\n\n\n")
      update_order_from_post
    end
    # Add cart items to order
    @order.order_line_items = @items
    @order.save
    # Save the order id to the session so we can find it later
    session[:order_id] = @order.id
    # All went well?
    logger.info("\n\nTRYING TO REDIRECT...")
    if (Substruct.config(:use_live_rate_calculation) == true) then
      logger.info("\n\nRedirecting to select_shipping_method\n")
      redirect_to :action => 'select_shipping_method'
    else
      logger.info("\n\nRedirecting to view_shipping_method\n")
      redirect_to :action => 'view_shipping_method'
    end
    #
  rescue
    logger.error("\n\nSomething went bad when trying to checkout...\n#{$!}\n\n")
    flash.now[:notice] = 'There were some problems with the information you entered.<br/><br/>Please look at the fields below.'
    render :action => 'checkout'
  end

  # Checks shipping price of items
  # Used with live rate calculation
  # Lets customer choose what method to use
  def select_shipping_method
    @title = "Select Your Shipping Method - Step 2 of 2"
    @order = find_order
    if @order == nil then
      redirect_to_checkout("Have you entered all of this information yet?") and return
    end
    @items = @order.order_line_items
    session[:order_shipping_types] = @order.get_shipping_prices
    # Set default price to pick what radio button should be entered
    @default_price = session[:order_shipping_types][0].id
  end

  # For flat rate calculation.
  # The customer just looks at how much it's going to cost to ship
  # We also set shipping cost here as well.
  def view_shipping_method
    @title = "Shipping Costs - Step 2 of 2"
    @order = find_order
    if @order == nil then
      redirect_to_checkout("Have you entered all of this information yet?") and return
    end
		# Setting this to a non-existent shipping type id
		# Not sure if this is the smartest thing to do - or if we should load
		# one into the authority data...
    ship_id = 0
    ship_price = @order.get_flat_shipping_price
    @order.order_shipping_type_id = ship_id
    @order.shipping_cost = ship_price
    @order.save
    @items = @order.order_line_items
    @shipping_price = @order.get_flat_shipping_price
  end

  # Execution action of select_shipping_method (above)
  # OR called when setting shipping method using a flat calculation...
  #
  # Saves shipping method, redirects to finish order
  def set_shipping_method
    @order = find_order
    ship_id = params[:ship_type_id]
    # Convert to integers for comparison purposes!
    ship_type = session[:order_shipping_types].find { |type| type.id.to_i == ship_id.to_i }
    ship_price = ship_type.price
    @order.order_shipping_type_id = ship_id
    @order.shipping_cost = ship_price
    @order.save
    redirect_to :action => 'finish_order'
  end

  # Finishes the order
  #
  # Submits order info to Authorize.net
  def finish_order
    @title = "Thanks for your order!"
    @order = find_order
    # If there's no order redirect to index
    if @order == nil
      redirect_to_index and return
    end
    transaction = @order.get_auth_transaction
    begin
      transaction.submit
      @payment_message = "Card processed successfully: #{transaction.authorization}"
			# Save transaction id for later
			@order.auth_transaction_id = transaction.transaction_id
			logger.info("\n\nORDER TRANSACTION ID - #{transaction.transaction_id}\n\n")
      # Set completed
      @order.cleanup_successful
      # Send success message
      @order.deliver_receipt
      clear_cart_and_order(false)
    rescue
      # Order failed - store transaction id
			@order.auth_transaction_id = transaction.transaction_id
      @order.cleanup_failed(transaction.error_message)
      # Send failed message
      @order.deliver_failed
      # Log errors
      logger.error("\n\n[ERROR] FAILED ORDER \n")
      logger.error(transaction.inspect)
      logger.error("\n\n")
      # Redirect to checkout and allow them to enter info again.
      error_message = "Sorry, but your transaction didn't go through.<br/>"
      error_message << "#{transaction.error_message}<br/>"
      error_message << "Please try again or contact us."
      redirect_to_checkout(error_message)
    end
  end

  # Finds or creates a cart
  private
  def find_cart
    session[:cart] ||= Cart.new
  end
  # Finds an order
  def find_order
    Order.find(session[:order_id])
  rescue
    return nil
  end

  # Clears the cart and possibly destroys the order
  # Called when the user wants to start over, or when the order is completed.
  def clear_cart_and_order(destroy_order = true)
    @cart = find_cart.empty!
    if session[:order_id] then
      @order = Order.find(session[:order_id])
      if destroy_order then
        @order.destroy
      end
      session[:order_id] = nil
    end
  end

  # Redirects to index with a message
  def redirect_to_index(msg = nil)
    flash[:notice] = msg
    redirect_to :action => 'index'
  end
  # Redirects to checkout with a message
  def redirect_to_checkout(msg = nil)
    flash[:notice] = msg
    redirect_to :action => 'checkout'
  end

end
