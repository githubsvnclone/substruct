class Admin::TagsController < Admin::BaseController
  def index
    list
    render :action => 'list'
  end

	# List manages addition/deletion of items through ajax
  def list
    @title = 'Manage Tags'
    @tags = Tag.find_alpha
render(:layout => 'layouts/modal')
  end

  def new
    @title = "Creating New Tag"
    @tag = Tag.new
  end

	# Creation reloads the entire modal page
	# ...so I don't have to deal with inserting the table row via JS
	# and duplicate the code, along with being forced to render the
	# JS code for deleting an item
  def create
    @tag = Tag.new(params[:tag])
    if @tag.save
      render(:partial => 'tag_list_row', :locals => {:tag_list_row => @tag})
    else
      render_text ""
    end
  end

  def edit
    @title = "Editing Tag"
    @tag = Tag.find(params[:id])
  end

	# Called via AJAX
  def update
    @tag = Tag.find(params[:id])
		@tag.name = params[:name]
    if @tag.save
			# Edit success
			render_text "#{@tag.id};;;#{@tag.name};;;true;;;#{Tag.count}"
    else
			# Edit failed
      render_text "#{@tag.id};;;#{@tag.name};;;false;;;#{Tag.count}"
    end
  end

	# Called via AJAX. 
  def destroy
    @tag = Tag.find(params[:id])
		tag_id = @tag.id
		@tag.destroy
		# Render nothing to denote success
    render_text ""
  end
end
