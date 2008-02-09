class Order < ActiveRecord::Base
  # Associations
  has_many :order_line_items
  belongs_to :order_user
  belongs_to :order_account
  belongs_to :order_shipping_type
  belongs_to :order_status_code
	# Validation
	validates_presence_of :order_number
	validates_uniqueness_of :order_number
  @@handling_fee = 15.00

  # Searches an order
  # Uses order number, first name, last name
  def self.search(search_term, count=false, limit_sql=nil)
    if (count == true) then
      sql = "SELECT COUNT(*) "
    else
      sql = "SELECT DISTINCT orders.* "
		end
		sql << "FROM orders "
		sql << "JOIN order_addresses ON orders.order_user_id = order_addresses.order_user_id "
		sql << "WHERE orders.order_number = ? "
		sql << "OR order_addresses.first_name LIKE ? "
		sql << "OR order_addresses.last_name LIKE ? "
		sql << "ORDER BY orders.created_on DESC "
		sql << "LIMIT #{limit_sql}" if limit_sql
		arg_arr = [sql, search_term, "%#{search_term}%", "%#{search_term}%"]
		if (count == true) then
		  count_by_sql(arg_arr)
	  else
		  find_by_sql(arg_arr)
	  end
  end

  # Generates a unique order number.
  # This number isn't ID because we want to mask that from the customers.
  def self.generate_order_number
    record = Object.new
    while record
      random = rand(999999999)
      record = find(:first, :conditions => ["order_number = ?", random])
    end
    return random
  end

  # Returns array of sales totals (hash) for a given year.
  # Hash contains
  #   * :number_of_sales
  #   * :sales_total
  #   * :tax
  #   * :shipping
  def self.get_totals_for_year(year)
    months = Array.new
    0.upto(12) { |i|
      sql = "SELECT COUNT(*) AS number_of_sales, SUM(product_cost) AS sales_total, "
      sql << "SUM(tax) AS tax, SUM(shipping_cost) AS shipping "
      sql << "FROM orders "
      sql << "WHERE YEAR(created_on) = ? "
      if i != 0 then
        sql << "AND MONTH(created_on) = ? "
      end
      sql << "AND (order_status_code_id = 5 OR order_status_code_id = 6 OR order_status_code_id = 7) "
      sql << "LIMIT 0,1"
      if i != 0 then
        months[i] = self.find_by_sql([sql, year, i])[0]
      else
        months[i] = self.find_by_sql([sql, year])[0]
      end
    }
    return months
  end

	# Gets a CSV string that represents an order list.
	def self.get_csv_for_orders(order_list)
    csv_string = FasterCSV.generate do |csv|
      # Do header generation 1st
      csv << [
        "OrderNumber", "Company", "ShippingType", "Date", 
        "BillLastName", "BillFirstName", "BillAddress", "BillCity", 
        "BillState", "BillZip", "BillCountry", "BillTelephone", 
        "ShipLastName", "ShipFirstName", "ShipAddress", "ShipCity", 
        "ShipState", "ShipZip", "ShipCountry", "ShipTelephone",
        "Item1",
        "Quantity1", "Item2", "Quantity2", "Item3", "Quantity3", "Item4",
        "Quantity4", "Item5", "Quantity5", "Item6", "Quantity6", "Item7",
        "Quantity7", "Item8", "Quantity8", "Item9", "Quantity9", "Item10",
        "Quantity10", "Item11", "Quantity11", "Item12", "Quantity12", "Item13",
        "Quantity13", "Item14", "Quantity14", "Item15", "Quantity15", "Item16",
        "Quantity16"
      ]
      for order in order_list
        bill = order.billing_address
        ship = order.shipping_address
        pretty_date = order.created_on.strftime("%m/%d/%y")
        if !order.order_shipping_type.nil?
          ship_code = order.order_shipping_type.code
        else
          ship_code = ''
        end
        order_arr = [
          order.order_number, '', ship_code, pretty_date,
          bill.last_name, bill.first_name, bill.address, bill.city,
          bill.state, bill.zip, bill.country.name, bill.telephone,
          ship.last_name, ship.first_name, ship.address, ship.city,
          ship.state, ship.zip, ship.country.name, ship.telephone 
        ]
        item_arr = []
        # Generate spaces for items up to 16 deep
        0.upto(15) do |i|
          item = order.order_line_items[i]
          if !item.nil? && !item.product.nil?  then
            item_arr << item.product.code
            item_arr << item.quantity
          else
            item_arr << ''
            item_arr << ''
          end
        end
        # Add csv string by joining arrays
        csv << order_arr.concat(item_arr)
      end
    end
    return csv_string
  end

	# Returns an XML string for each order in the order list.
	# This format is for sending orders to Tony's Fine Foods
	def self.get_xml_for_orders(order_list)
		xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
		xml << "<orders>\n"
		for order in order_list
		  if order.order_shipping_type
		    shipping_type = order.order_shipping_type.code
		  else
		    shipping_type = ''
	    end
		  pretty_date = order.created_on.strftime("%m/%d/%y")
		  xml << "	<order>\n"
  		xml << "		<date>#{pretty_date}</date>\n"
  		xml << "		<shippingCode>#{shipping_type}</shippingCode>\n"
  		xml << "		<invoiceNumber>#{order.order_number}</invoiceNumber>\n"
  		xml << "		<emailAddress>#{order.order_user.email_address}</emailAddress>\n"
      # Shipping address
      address = OrderAddress.find_shipping_address_for_user(order.order_user)
      xml << "		<shippingAddress>\n"
  		xml << "			<firstName>#{address.first_name}</firstName>\n"
  		xml << "			<lastName>#{address.last_name}</lastName>\n"
  		xml << "			<address1>#{address.address}</address1>\n"
  		xml << "			<address2></address2>\n"
  		xml << "			<city>#{address.city}</city>\n"
  		xml << "			<state>#{address.state}</state>\n"
  		xml << "			<zip>#{address.zip}</zip>\n"
  		xml << "			<countryCode>#{address.country.fedex_code}</countryCode>\n"
  		xml << "			<telephone>#{address.telephone}</telephone>\n"
  		xml << "		</shippingAddress>\n"
  		# Items
  		xml << "		<items>\n"
  		for item in order.order_line_items
  		  xml << "			<item>\n"
    		xml << "				<name>#{item.product.name}</name>\n"
    		xml << "				<id>#{item.product.code}</id>\n"
    		xml << "				<quantity>#{item.quantity}</quantity>\n"
    		xml << "			</item>\n"
		  end
  		xml << "		</items>\n"
  		# End
      xml << "	</order>\n"
    end
	  # End orders
	  xml << "</orders>\n"
	  return xml
	end

	# Order status name
  def status
    code = OrderStatusCode.find(:first, :conditions => ["id = ?", self.order_status_code_id])
    code.name
  end

  # Shortcut to items
  def items
    self.order_line_items
  end

	# Total for the order
  def total
    self.line_items_total + self.shipping_cost
  end

  def name
    return "#{billing_address.first_name} #{billing_address.last_name}"
  end

  def account
    self.order_user.order_account
  end

  def billing_address
		self.order_user.order_account.order_address
  end

  def shipping_address
    OrderAddress.find_shipping_address_for_user(self.order_user)
  end

	# Sets line items from the product output table on the edit page.
	#
	# Deletes any line items with a quantity of 0.
	# Adds line items with a quantity > 0.
	#
	# This is called from update in our controllers.
	# What's passed looks something like this...
	#   @products = {'1' => {'quantity' => 2}, '2' => {'quantity' => 0}, etc}
	def line_items=(products)
		# Clear out all line items
		self.order_line_items.clear
		# Go through all products
		products.each do |id, product|
		  quantity = product['quantity']
		  if quantity.blank? then
		    quantity = 0
      else
			  quantity = Integer(quantity)
		  end

			if (quantity > 0) then
				new_item = self.order_line_items.build
				logger.info("\n\nBUILDING NEW LINE ITEM\n")
				logger.info(new_item.inspect+"\n")
				new_item.quantity = quantity
				new_item.product_id = id
				new_item.unit_price = Product.find(:first, :conditions => "id = #{id}").price
				new_item.save
			end
		end
	end

	# Do we have a valid transaction id
	def contains_valid_transaction_id?()
		return (!self.auth_transaction_id.blank? && self.auth_transaction_id != 0)
	end

	# Determines if an order has a line item based on product id
	def has_line_item?(id)
		self.order_line_items.each do |item|
			return true if item.product_id == id
		end
		return false
	end

	# Gets quantity of a product if exists in current line items.
	def get_line_item_quantity(id)
		self.order_line_items.each do |item|
			return item.quantity if item.product_id == id
		end
		return 0
	end

	# Gets a subtotal for line items based on product id
	def get_line_item_total(id)
		self.order_line_items.each do |item|
			return item.total if item.product_id == id
		end
		return 0
	end

	# Grabs the total amount of all line items associated with this order
	def line_items_total
		total = 0
		for item in self.order_line_items
			total += item.total
		end
		return total
	end

	# Adds a new order note from the edit page.
	#
	# We display notes as read-only, so we only have to use a text field
	# instead of multiple records.
	def new_notes=(note)
		if !note.blank? then
			time = Time.now.strftime("%m-%d-%y %I:%M %p")
			new_note = "<p>#{note}<br/>"
			new_note << "<span class=\"info\">"
			new_note << "[#{time}]"
			new_note << "</span></p>"
			if self.notes.blank? then
				self.notes = new_note
			else
				self.notes << new_note
			end
		end
	end

	# Calculates the weight of an order
	def weight
		weight = 0
		self.order_line_items.each do |item|
			weight += item.quantity * item.product.weight
		end
		return weight
	end

  # Gets a flat shipping price for an order.
  # This is if we're not using live rate calculation usually
  #
  # A lot of people will want this overridden in their app
  def get_flat_shipping_price
    return @@handling_fee
  end

  # Gets all LIVE shipping prices for an order.
  #
  # Returns an array of OrderShippingTypes
  def get_shipping_prices
    prices = Array.new
    # If they're in the USA
    address = self.shipping_address
    if address.country_id == 1 then
      shipping_types = OrderShippingType.get_domestic
    else 
      shipping_types = OrderShippingType.get_foreign
    end

    ship = Shipping::FedEx.new(:prefs => "#{RAILS_ROOT}/config/shipping.yml")
    ship.fedex_url = SHIP_FEDEX_URL
    ship.fedex_account = SHIP_FEDEX_ACCOUNT
    ship.fedex_meter = SHIP_FEDEX_METER
    ship.sender_zip = SHIP_SENDER_ZIP
    ship.sender_country = SHIP_SENDER_COUNTRY
    ship.weight = self.weight
    ship.zip = address.zip
    ship.city = address.city
    ship.country = address.country.fedex_code

    logger.info("\n\nCREATED A SHIPPING OBJ\n#{ship.inspect}\n\n")

    for type in shipping_types
      ship.service_type = type.service_type
      ship.transaction_type = type.transaction_type
      # Rescue errors. The Shipping gem likes to throw nasty errors
      # when it can't get a price.
      #
      # Usually this means the customer didn't enter a valid address (zip code most of the time)
      # In that case we go for our own shipping prices.
      begin
        # FedEx can be flaky sometimes and return 0 for prices.
        # Make sure we always calculate a shipping rate even if they're being wacky.
        price = ship.discount_price
        if price == 0
          price = ship.price
        end
        if price == 0
          type.calculate_price(self.weight)
        else
          type.price = price + @@handling_fee
        end
      rescue
        logger.error "\n[ERROR] #{$!.message}"
        type.calculate_price(self.weight)
        type.price += @@handling_fee
      end
  #    logger.info "#{type.name} : ship.discount_price / type.price"
      prices << type
    end

    return prices

  end

  # Creates a general transaction
	# Load it with our defaults
  def create_transaction
		# If you don't load the prefs file rails throws some errors
		# ALTHOUGH I couldn't get the prefs to load properly from the yml file.
    trans = Payment::AuthorizeNet.new(:prefs => "#{RAILS_ROOT}/config/payment.yml")
    trans.login = PAY_LOGIN
    trans.password = PAY_PASS
		# If the URL is defined as a constant set it here
		# If not defined it connects to Authorize.net's default server
		# You can use this for Auth.net test accounts OR 2Checkout.com (in theory)
		trans.url = PAY_URL if PAY_URL != nil
		# The AIM guide says this is necessary, but I've gotten
		# away without using it before (you can use this or password)
		trans.transaction_key = PAY_TRANS_KEY if PAY_TRANS_KEY != nil
		# All this stuff should really be in get_auth_transaction
		# But the payment.rb gateway for SOME reason wants most of this crap
		# even though it's not required for a VOID.
		trans.amount = self.total
		trans.first_name = self.billing_address.first_name
		trans.last_name = self.billing_address.last_name
		trans.address = self.billing_address.address
		trans.city = self.billing_address.city
		trans.state = self.billing_address.state
		trans.zip = self.billing_address.zip
		trans.country = self.billing_address.country.name
		trans.card_number = self.account.cc_number
		expiration = "#{self.account.expiration_month}/#{self.account.expiration_year}"
		trans.expiration = expiration
		# Set this to a test transaction if not in production mode
		# Just a safeguard!
    if ENV['RAILS_ENV'] != "production" then
      trans.test_transaction = true
    end
    logger.info("\n\nCreated a credit card transaction\n")
    logger.info(trans.inspect)
    return trans
  end

	# Gets a transaction ready to be sent for payment processing
	def get_auth_transaction
		trans = self.create_transaction
		# Set order specific fields
		trans.type = 'AUTH_CAPTURE'
		return trans
	end

	# Gets a transaction ready to be voided
	def get_void_transaction
		trans = self.create_transaction
		# This is necessary for voiding an order
		# Return nil if we don't have a record of the transaction id
		if !self.contains_valid_transaction_id? then
			return nil
		else
			trans.transaction_id = self.auth_transaction_id
		end
		trans.type = 'VOID'
		return trans
	end

	# Cleans up a successful order
	def cleanup_successful
		self.order_status_code_id = 5
    self.new_notes="Order completed."
    self.product_cost = self.line_items_total
    self.account.clear_personal_information
    self.save
	end

	# Cleans up a failed order
	def cleanup_failed(msg)
		self.order_status_code_id = 3
    self.new_notes="Order failed!<br/>#{msg}"
    self.save
	end


  # We define deliver_receipt here because ActionMailer can't seem to render
  # components inside a template.
  #
  # I'm getting around this by passing the text into the mailer.
  def deliver_receipt
    @content_node = ContentNode.find(:first, :conditions => ["name = ?", 'OrderReceipt'])
    OrdersMailer.deliver_receipt(self, @content_node.content)
  end

  # If we're going to define deliver_receipt here, why not wrap deliver_failed as well?
  def deliver_failed
    OrdersMailer.deliver_failed(self)
  end


end
