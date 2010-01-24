class Affiliate < ActiveRecord::Base
  # Associations
  has_many :orders
	# Validation
	validates_presence_of :code
	validates_uniqueness_of :code
	validates_format_of :code,
	  :with => /^[0-9a-zA-Z_-]+$/,
	  :message => "Affiliate code must only contain letters or numbers. No spaces or symbols."
	
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
	
end