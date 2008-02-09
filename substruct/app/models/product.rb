class Product < ActiveRecord::Base
  has_many :order_line_items
  has_and_belongs_to_many :images
	has_and_belongs_to_many :tags
  validates_presence_of :name

	# Searches for products
	# Uses product name, code, or description
	def self.search(search_term, count=false, limit_sql=nil)
	  if (count == true) then
	    sql = "SELECT COUNT(*) "
	  else
	    sql = "SELECT DISTINCT * "
		end
		sql << "FROM products "
		sql << "WHERE name LIKE ? "
		sql << "OR description LIKE ? "
		sql << "OR code LIKE ? "
		sql << "ORDER BY date_available DESC "
		sql << "LIMIT #{limit_sql}" if limit_sql
		arg_arr = [sql, "%#{search_term}%", "%#{search_term}%", "%#{search_term}%"]
		if (count == true) then
		  count_by_sql(arg_arr)
	  else
		  find_by_sql(arg_arr)
	  end
	end

	# Finds products by list of tag ids passed in
	#
	# We could JOIN multiple times, but selecting IN grabs us the products
	# and using GROUP BY & COUNT with the number of tag id's given
	# is a faster approach according to freenode #mysql
	def self.find_by_tags(tag_ids)
		sql =  "SELECT * "
		sql << "FROM products "
		sql << "JOIN products_tags on products.id = products_tags.product_id "
		sql << "WHERE products_tags.tag_id IN (#{tag_ids.join(",")}) "
		sql << "GROUP BY products.id HAVING COUNT(*)=#{tag_ids.length} "
		find_by_sql(sql)
	end

	# Defined to save tags from product edit view
	def tags=(list)
		tags.clear
		for id in list
			tags << Tag.find(id) if !id.empty?
		end
	end
end
