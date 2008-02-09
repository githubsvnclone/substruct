class Tag < ActiveRecord::Base
  has_and_belongs_to_many :products
  validates_presence_of :name
	validates_uniqueness_of :name
	
	# Most used finder function for tags.
	# Selects by alpha sort.
	def self.find_alpha
		find(:all, :order => 'name ASC')
	end
	
	# Finds a list of related tags for the tag id's passed in
	# 
	# Uses the tag ids passed in
	# 	- Finds products with the tags applied (inside the subselect)
	#   - Find and returns tags also tagged to the products, but not passed in
	def self.find_related_tags(tag_id_list)
		tag_id_list_string = tag_id_list.join(",")
		sql =  "SELECT DISTINCT t.* FROM products_tags pt, tags t WHERE pt.product_id IN "
		sql << "	( SELECT products.id "
		sql << "	  FROM products "
		sql << "		JOIN products_tags on products.id = products_tags.product_id "
		sql << "		WHERE products_tags.tag_id IN (#{tag_id_list_string}) "
		sql << "		GROUP BY products.id HAVING COUNT(*)=#{tag_id_list.length} ) "
		sql << "AND t.id = pt.tag_id "
		sql << "AND t.id NOT IN (#{tag_id_list_string})"
		return find_by_sql(sql)
	end
	
	# Returns the number of products tagged with this item
	def product_count
		self.products.size
	end
end