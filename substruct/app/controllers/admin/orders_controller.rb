class Admin::OrdersController < Admin::BaseController
  layout 'admin'
  include OrderHelper

  @@list_options = [ "Ready To Ship",
                    "On Hold",
                    "Completed",
                    "All" ]

  def index
    list
    render_action 'list'
  end

  def list
    # Clone so we can modify the list options if we want
    @list_options = @@list_options.clone

    if params[:key] then
      @viewing_by = params[:key]
    elsif session[:last_order_list_view] then
      @viewing_by = session[:last_order_list_view]
    else
      @viewing_by = @list_options[0]
    end

    @title = "Order List"

    conditions = nil

    case @viewing_by
      when @list_options[0]
        conditions = 'order_status_code_id = 5'
      when @list_options[1]
        conditions = 'order_status_code_id = 3
                      OR order_status_code_id = 4'
      when @list_options[2]
        conditions = 'order_status_code_id = 5
                      OR order_status_code_id = 6
                      OR order_status_code_id = 7'
      when @list_options[3]
        conditions = nil
    end

    session[:last_order_list_view] = @viewing_by

    @order_pages,
    @orders = paginate :order,
              :per_page => 30,
              :conditions => conditions,
              :order_by => "created_on DESC"
  end

  # Search uses the list view as well.
  # We create a custom paginator to show search results since there might be a ton
  def search
    @search_term = params[:term]

    if !@search_term then
      @search_term = session[:last_search_term]
    end
    # Save this for after editing
    session[:last_view] = 'search'
    session[:last_search_term] = @search_term

    # Need this so that links show up
    @list_options = @@list_options
    @title = "Search Results For '#{@search_term}'"

    @search_count = Order.search(@search_term, true, nil)
    @order_pages = Paginator.new(self, @search_count, 30, params[:page])
    # to_sql is an array
    # it seems to return the limits in reverse order for mysql's liking
    the_sql = @order_pages.current.to_sql.reverse.join(',')
    @orders = Order.search(@search_term, false, the_sql)

    render :action => 'list'
  end

  # Shows sales totals for all years.
  def totals
    @title = 'Sales Totals'
    sql = "SELECT DISTINCT YEAR(created_on) as year "
    sql << "FROM orders "
    sql << "ORDER BY year ASC"
    @year_rows = Order.find_by_sql(sql)
    @years = Hash.new
    # Build a hash containing all orders hashed by year.
    for row in @year_rows
      @years[row.year] = Order.get_totals_for_year(row.year)
    end
  end

  # Shows the new order screen
  def new
    @title = 'Creating a new order'
    initialize_new_order
  end

  # Creates an order from new using a transaction.
  #
  # Redisplays new page if any errors happen.
  def create
    @title = 'Creating a new order'
    create_order_from_post
    # All went well?
    flash[:notice] = 'Order was successfully created.'
    redirect_to :action => 'show', :id => @order.id
  rescue
    render :action => 'new'
  end

  # Edits or shows an existing order
  def show
    @order = Order.find(params[:id])
    order_time = @order.created_on.strftime("%m/%d/%y %I:%M %p")
    @title = "Order #{@order.order_number} - #{order_time}"
    @order_user = @order.order_user
    @order_account = @order_user.order_account
    @billing_address = @order_account.order_address
    @shipping_address = OrderAddress.find_shipping_address_for_user(@order_user)
    if @shipping_address then
      @use_separate_shipping_address = true
    else
      @use_separate_shipping_address = false
      @shipping_address = OrderAddress.new if !@shipping_address
    end
    @products = Product.find(:all)
    # If this order is "finished" send them to the view page instead of the edit one...
		# Orders on the show page can still do things like add notes.
    if (@order.order_status_code.is_editable?) then
      render :action => 'edit' and return
    else
      render :action => 'show' and return
    end
  end

  # Updates an order from edit
  def update
		@order = Order.find(params[:id])
		update_order_from_post
		@products = Product.find(:all)
		if (!@use_separate_shipping_address)
		  @shipping_address = OrderAddress.new
	  end
    if (@up_ordr && @up_user && @up_acct && @up_bill && @up_ship) then
      flash[:notice] = 'Order was successfully updated.'
      redirect_to :action => 'show', :id => @order.id
    else
			flash[:notice] = 'There were problems modifying the order.'
      render :action => 'show'
    end
  end

	# Voids an order
	#
	# Voiding sends the order back to Authorize.net and reverses
	# any charges.
	#
	# Redirects back to the order show page after a success or failure
	def void
		@order = Order.find(params[:id])
		# Don't try to void an order that's missing a transaction id
		if @order.auth_transaction_id.blank? then
			flash[:notice] = "The system doesn't have a record of the payment processor's transaction id for this order.<br/>This transaction can't be voided."
			redirect_to :action => 'show', :id => @order.id
		end
		# Get a transaction ready to be voided
		transaction = @order.get_void_transaction
		begin
      transaction.submit
      message = "Order voided successfully:<br/>#{transaction.authorization}"
			# Save transaction id for later
			#@order.auth_transaction_id = transaction.transaction_id
			# Set the order status to cancelled / voided
			@order.order_status_code_id = 8
	    @order.new_notes = message
	    @order.save
			# Flash the success or error message and redirect to show.
			flash[:notice] = message
			redirect_to :action => 'show', :id => @order.id
    rescue
      # Order failed - store transaction id
			#@order.auth_transaction_id = transaction.transaction_id
      # Log errors
      logger.error("\n\n[ERROR] FAILED ORDER VOID \n")
      logger.error(transaction.inspect)
      logger.error("\n\n")
      # Redirect to checkout and allow them to enter info again.
      message = "Order void failed:<br/>"
      message << "#{transaction.error_message}<br/>"
			@order.new_notes = message
			@order.save
			# Flash the success or error message and redirect to show.
			flash[:notice] = message
			redirect_to :action => 'show', :id => @order.id
    end
	end

	# Marks an order as returned.
	# Useful for closed orders.
	def return_order
		@order = Order.find(params[:id])
		@order.order_status_code_id = 9
		@order.save
		flash[:notice] = "Order has been marked as returned."
		redirect_to :action => 'show', :id => @order.id
	end

  # Resends the order receipt to the customer
  def resend_receipt
    @order = Order.find(params[:id])
   	#@order.cleanup_successful
    # Send success message
    @order.deliver_receipt
    redirect_to :action => 'show', :id => @order.id
  end

  # Deletes an order
  def destroy
    Order.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
  # Processes orders passed in, packages as XML or CSV and downloads
  #
  def download
    @orders = Order.find(params[:ids])
    
    case params[:format]
      when 'xml'
        content = Order.get_xml_for_orders(@orders)
      when 'csv'
        content = Order.get_csv_for_orders(@orders)
    end
    
    directory = File.join(RAILS_ROOT, "public/system/order_files")
    file_name = Time.now.strftime("%m_%d_%Y_%H-%M")
    file = "#{file_name}.#{params[:format]}"
    save_to = "#{directory}/#{file}"
    
    # make sure we have the directory to write these files to
    if Dir[directory].empty?
      FileUtils.mkdir_p(directory)
    end    
    
    # write the file
    File.open(save_to, "w") { |f| f.write(content)  }
    
    send_file(save_to, :type => "text/#{params[:format]}")
  end

end
