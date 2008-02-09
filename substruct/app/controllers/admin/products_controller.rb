class Admin::ProductsController < Admin::BaseController
  def index
    list
    render :action => 'list'
  end

	# Lists all products
  def list
    @title = "All Product List"
    @tags = Tag.find_alpha
    @product_pages, 
			@products = paginate :products, 
			:per_page => 30, 
			:order_by => "name ASC"
  end

	# Lists products by tag
  def list_by_tags
		@tags = Tag.find_alpha

    @list_options = Tag.find_alpha

    if params[:key] then
      @viewing_by = params[:key]
    elsif session[:last_product_list_view] then
      @viewing_by = session[:last_product_list_view]
    else
      @viewing_by = @list_options[0].id
    end

    @tag = Tag.find(:first, :conditions => ["id=?", @viewing_by])
    if @tag == nil then
			redirect_to :action => 'list'
			return
    end

    @title = "Product List For Tag - '#{@tag.name}'"

    conditions = nil

    session[:last_product_list_view] = @viewing_by


    @products = @tag.products
    render :action => 'list'
  end


  def show
    @product = Product.find(params[:id])
  end

  def new
    @title = "New Product"
		@image = Image.new
    @product = Product.new
		@tags = Tag.find_alpha
  end

  def create
    @title = "New Product"
    @product = Product.new(params[:product])
		if @product.save
			# Save product tags
			# Our method doesn't save tags properly if the product doesn't already exist.
			# Make sure it gets called after the product has an ID
			@product.tags = params[:product][:tags] if params[:product][:tags]
			# Save product images
			if (!params[:image][:path].blank?) then
				@product.images.build(params[:image])
			end
			# Save again to keep our changes
			@product.save!
      flash[:notice] = "Product '#{@product.name}' was successfully created."
      redirect_to :action => 'list'
    else
			@image = Image.new
      render :action => 'new'
    end
  end

  def edit
    @title = "Editing A Product"
    @product = Product.find(params[:id])
		@image = Image.new
		@tags = Tag.find_alpha
  end

  def update
    @product = Product.find(params[:id])
		@tags = Tag.find_alpha
    if @product.update_attributes(params[:product])
			image_path = params[:image][:path]
			logger.info("\n\n[info] IMAGE PATH LENGTH: #{image_path.length}")
			logger.info("\n[info] IMAGE PATH: #{image_path}")
			logger.info("\n[info] IMAGE BLANK?: #{image_path.blank?}\n\n")
			if (!image_path.blank? && image_path.length > 0) then
				for image in @product.images
					image.destroy
				end
				@product.images.build(params[:image])
				@product.save!
			end
      flash[:notice] = "Product '#{@product.name}' was successfully updated."
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    Product.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

	# Search uses the list view as well.
	# We create a custom paginator to show search results since there might be a ton
	def search
	  @search_term = params[:term]

	  if !@search_term then
	    @search_term = session[:last_search_term]
	  end
	  # Save this for after editing
	  session[:last_search_term] = @search_term

	  # Need this so that links show up
	  @title = "Search Results For '#{@search_term}'"

	  @search_count = Product.search(@search_term, true, nil)
	  @product_pages = Paginator.new(self, @search_count, 30, params[:page])
	  # to_sql is an array
	  # it seems to return the limits in reverse order for mysql's liking
	  the_sql = @product_pages.current.to_sql.reverse.join(',')
	  @products = Product.search(@search_term, false, the_sql)

	  render :action => 'list'
	end


	# Called when updating Tags from the product edit page
	# Returns the rendered partial for our Tag list
	def get_tags
		@tags = Tag.find_alpha
		if params[:id] then
			@product = Product.find(params[:id])
		else
			@product = Product.new
		end
		@partial_name = params[:partial_name]
		render(:partial => @partial_name,
					 :collection => @tags,
					 :locals => {:product => @product})
	end

end
