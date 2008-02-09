class Image < ActiveRecord::Base
  has_and_belongs_to_many :products																
  file_column :path,
	  :root_path => File.join(RAILS_ROOT, "public/system/"),
	  :web_root => 'system/',
    :magick => { 
			:versions => { 
			  "thumb" => "50x50", 
				"small" => "200x200>" 
			} 
		}
end
