# Represents a file uploaded by a user.
#
# Subclassed by Image and Asset
#
# Before a save, checks to set the type, based on file extension.
#
class UserUpload < ActiveRecord::Base
  IMAGE_EXTENSIONS = ['gif', 'jpg', 'jpeg', 'png', 'bmp']
  
  # Store files in the system directory so it doesn't break Capistrano
  # deployments
  file_column :path,
    :root_path => File.join(RAILS_ROOT, "public/system/"),
    :web_root => 'system/',
    :magick => { 
  		:versions => { 
  		  "thumb" => "50x50", 
  			"small" => "200x200>" 
  		} 
    }
  
  # Checks what type of file this is based on extension.
  #
  # If it's an image, we treat it differently and save
  # as an image type.
  #
  # No, we're not using anything fancy here, just the extension set.
  #
  before_save :check_image_type
  def check_image_type
    self.type = 'Image' if IMAGE_EXTENSIONS.include?(self.extension.downcase)
  end
  
  # Returns extension
  #
  def extension
    self.path[self.path.rindex('.') + 1, self.path.size]
  end
  
  # Returns file name
  #
  def name
    self.path[self.path.rindex('/') + 1, self.path.size]
  end
  
  def relative_path
    self.path[self.path.rindex('/public/system')+7, self.path.size]
  end
  
end