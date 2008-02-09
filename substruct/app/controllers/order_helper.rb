require_dependency 'order'
require_dependency 'order_address'
require_dependency 'order_account'
require_dependency 'order_user'

# OrderHelper helps controllers in the application CrUD orders.
#
# It's used as a mixin for various controllers.
module OrderHelper

  # Create all of these instance variables that are associated with an order
  # If a customer is already logged in, use that info.
  #
  def initialize_new_order
    if @customer
      @order_user = @customer
      @billing_address = @customer.billing_address || OrderAddress.new
      @shipping_address = @customer.shipping_address || OrderAddress.new
      @use_separate_shipping_address = @billing_address != @shipping_address
    else
      @order_user = OrderUser.new
      @billing_address = OrderAddress.new
      @shipping_address = OrderAddress.new      
      @use_separate_shipping_address = false
    end
    @order = Order.new

    @order_account = OrderAccount.new
    @order_account.order_account_type_id = 1
  end

  def initialize_existing_order
    if @customer
      logger.info('Order user is @customer')
      @order_user = @customer
      @billing_address = @customer.billing_address
      @shipping_address = @customer.shipping_address
      @use_separate_shipping_address = @billing_address != @shipping_address
    else
      logger.info('Order user coming from @order')
      @order_user = @order.order_user
      @billing_address = @order.billing_address
      @shipping_address = @order.shipping_address
      @use_separate_shipping_address = false
    end
    @order_account= @order.account
  end

  # Does a creation of all required objects from a form post
  #
  # Each model is created and validated at the beginning.
  # This assures all errors show up if even if the begin...rescue...end
  # block skips save! of a model.
  #
  # Does transaction to create a new order.
  #
  # Will throw an exception if there is a problem, so be sure to handle that
  def create_order_from_post
    @use_separate_shipping_address = params[:use_separate_shipping_address]

    @order_user = OrderUser.find_or_create_by_email_address(
      params[:order_user][:email_address]
    )
    @order_user.valid?

    @order = Order.new(params[:order])
    @order.valid?

    # Look up billing address and update if customer is logged in.
    if @customer
      @billing_address = @customer.billing_address || OrderAddress.new
      @billing_address.attributes = params[:billing_address]
      @shipping_address = @customer.billing_address || OrderAddress.new
      @shipping_address.attributes = params[:shipping_address]
    else
      @billing_address = OrderAddress.new(params[:billing_address])
      @shipping_address = OrderAddress.new(params[:shipping_address])
    end
    @billing_address.valid?
    
    if @use_separate_shipping_address
      @shipping_address.valid?
    end

    @order_account = OrderAccount.new(params[:order_account])
    @order_account.valid?

    OrderUser.transaction do
      @order_user.save!
      Order.transaction do
        @order = @order_user.orders.build(params[:order])
        @order.order_number = Order.generate_order_number
        @order.save!
      end
      OrderAddress.transaction do
        # Addresses
        @billing_address = @order_user.order_addresses.create(params[:billing_address])
        @billing_address.order_id = @order.id
        @billing_address.is_shipping = true
        @billing_address.save!
        if @use_separate_shipping_address then
          @shipping_address = @order_user.order_addresses.create(params[:shipping_address])
          @shipping_address.is_shipping = true
          @billing_address.is_shipping = false
          @billing_address.save!
          @shipping_address.order_id = @order.id
          @shipping_address.save!
        end
      end
      OrderAccount.transaction do
        @order_account = OrderAccount.new(params[:order_account])
        @order_account.order_id = @order.id
        @order_account.order_user_id = @order_user.id
        @order_account.order_address_id = @billing_address.id
        @order_account.save!
      end
    end
  end

  # Updates an order from a post.
  # Used for editing orders on the admin side & the customer side.
  #
  # On the admin side we trust the ID fields from the post
  # On the customer side, we use the order id in session to identify order.
  # (@order should be set before calling this method)
  def update_order_from_post
    # Find the objects in the db to update
		@order_user = @order.order_user
		@order_account = @order.account
		@billing_address = @order.billing_address
		# Comes in as a string, so we force it into a boolean.
		@use_separate_shipping_address = (params[:use_separate_shipping_address] == 'true')
		# Update all objects
		# Store the results in variables that we use from our controller.
		@up_ordr = @order.update_attributes(params[:order])
		@up_user = @order_user.update_attributes(params[:order_user])
		@up_acct = @order_account.update_attributes(params[:order_account])
		@up_bill = @billing_address.update_attributes(params[:billing_address])
		if (@use_separate_shipping_address)
		  # Create a new record for shipping address if it's the same
		  # as the billing address...or if it doesn't exist.
			@shipping_address = @order.shipping_address
		  if @billing_address == @shipping_address || @shipping_address.nil?
		    @shipping_address = @order_user.order_addresses.create(params[:shipping_address])
		    @shipping_address.order_id = @order.id
	    	@shipping_address.is_shipping = true
		    @up_ship = @shipping_address.save
		    @billing_address.is_shipping = false
        @billing_address.save
		  else
		    @up_ship = @shipping_address.update_attributes(params[:shipping_address])
      end
		else
			@up_ship = true
      @billing_address.is_shipping = true
      @billing_address.save
			@shipping_address = OrderAddress.new
		end
  end

end
