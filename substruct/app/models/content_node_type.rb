class ContentNodeType < ActiveRecord::Base
  has_many :content_nodes

  def self.select_values
    find(:all, :order => "name").map {|i| [i.name, i.id]}
  end

  def self.all_type_names
    find(:all, :order => "name").map {|i| i.name}
  end
end
