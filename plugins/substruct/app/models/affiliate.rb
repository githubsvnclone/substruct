class Affiliate < ActiveRecord::Base
  SQL_VALID_ORDER_STATUS = "(order_status_code_id = 6 OR order_status_code_id = 7)"
  PAID_ORDER_DELAY = 90
  REVENUE_PERCENTAGE = 5
  # Associations
  has_many :orders
  # Earned orders are valid referred orders.
  # The status codes here are 'ordered, paid, shipped' and 'sent to fulfillment'
  has_many :valid_referred_orders, 
    :class_name => 'Order', 
    :conditions => SQL_VALID_ORDER_STATUS
  has_many :orders_to_be_paid, 
    :class_name => 'Order', 
    :conditions => %Q\
      #{SQL_VALID_ORDER_STATUS} 
      AND orders.created_on >= DATE_SUB(CURRENT_DATE(), INTERVAL #{PAID_ORDER_DELAY} DAY)
    \
  # has_many :paid_orders
  # has_many :unpaid_orders
	# Validation
	validates_presence_of :code
	validates_uniqueness_of :code
	validates_format_of :code,
	  :with => /^[0-9a-zA-Z_-]+$/,
	  :message => "Affiliate code must only contain letters or numbers. No spaces or symbols."
  validates_presence_of :email_address, :message => ERROR_EMPTY
	validates_uniqueness_of :email_address, 
	  :message => "Affiliate email address already in use."
	validates_format_of :email_address,
	  :with => /^([^@\s]+)@((?:[-a-zA-Z0-9]+\.)+[a-zA-Z]{2,})$/,
	  :message => "Please enter a valid email address."
	
	# Generates a 15 character alphanumeric code
	# that we use to track affiliates and promotions.
	def self.generate_code(size=10)
    # characters used to generate affiliate code
    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890" 
    # create a new record object to satisfy while loop initially
    record = Object.new
    # loop through, creating random affiliate codes until
    # we create one that doesn't exist in the db
    while record        
      test_code = "" 
      srand
      size.times do
        pos = rand(chars.length)
        test_code += chars[pos..pos]
      end
      # find any affiliates with this same code string
      # if none are found the while loop exits
      record = find(:first, :conditions => ["code = ?", test_code])
    end
    # return our random code
    return test_code
  end
	
	# Authenticate an affiliate.
  #
  # Example:
  #   @a = Affiliate.authenticate('bob@somewhere.com', 'BOBCODE')
  def self.authenticate(email, code)
    find(
      :first,
      :conditions => ["email_address = ? AND code = ?", email, code]
    )    
  end
  
  # INSTANCE METHODS ==========================================================
  
  
  
  # Gets months where affiliate has referred orders
  def get_earning_months
    orders = self.valid_referred_orders.find(:all, :select => ['created_on'])
    return orders.collect{|o| o.created_on.to_date.beginning_of_month }.uniq
  end
  
  # Sums earnings for get_earning_months
  def get_earnings()
    earnings = []
    self.get_earning_months.each do |month|
      conds = [
        "created_on BETWEEN DATE(?) AND DATE(?)", 
        month.beginning_of_month, month.end_of_month
      ]
      orders = self.valid_referred_orders.find(:all, :conditions => conds)
      earnings << {
        :start_date => month,
        :num_total_orders => self.orders.count(:conditions => conds),
        :num_valid_orders => orders.size,
        :revenue => orders.inject(0.0){|sum,o| sum + o.total},
        :earnings => orders.inject(0.0){|sum,o| sum + o.affiliate_earnings}
      }
    end
    return earnings
  end
end