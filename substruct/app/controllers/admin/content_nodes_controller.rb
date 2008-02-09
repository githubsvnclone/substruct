class Admin::ContentNodesController < Admin::BaseController
  def index
    list
    render :action => 'list'
  end

  # Lists content nodes by type
  #
  # This grabs all available ContentNodeTypes and breaks the list down by type.
  #
  # When new types are added to the database they automatically appear here.
  def list
    @title = "Content List"
    # Get all content node types
    @list_options = ContentNodeType.all_type_names

    # Set currently viewing by key
    if params[:key] then
      @viewing_by = params[:key]
    elsif session[:last_content_list_view]
      @viewing_by = session[:last_content_list_view]
    else
      @viewing_by = @list_options[1]
    end

    # Find the id of the content node type we're viewing by
    type = ContentNodeType.find(:first, :conditions => ["name = ?", @viewing_by])

    # Paginate content
    @content_node_pages,
    @content_nodes = paginate :content_node,
                     :per_page => 10,
                     :conditions => ["content_node_type_id = ?", type.id],
                     :order => "display_on DESC, name ASC"
    session[:last_content_list_view] = @viewing_by
  end

  # Shows a content node
  def show
    @content_node = ContentNode.find(params[:id])
    @title = "Viewing '#{@content_node.title}'  "
  end

  # Creates a content node
  def new
    @title = "Creating New Content"
    @content_node = ContentNode.new
  end

  def create
    @title = "Creating a content node"
    @content_node = ContentNode.new(params[:content_node])
    if @content_node.save
      flash[:notice] = 'ContentNode was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @title = "Editing Content"
    @content_node = ContentNode.find(params[:id])
  end

  def update
    @content_node = ContentNode.find(params[:id])
    if @content_node.update_attributes(params[:content_node])
      flash[:notice] = 'ContentNode was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

	# Shows a preview of our content from the edit / create pages
	def preview
		render :layout => false
	end

  def destroy
    ContentNode.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
