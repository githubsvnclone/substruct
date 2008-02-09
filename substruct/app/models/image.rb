# Represents an image
#
class Image < UserUpload
  has_many :product_images
  has_many :products, :through => :product_images
  
end
