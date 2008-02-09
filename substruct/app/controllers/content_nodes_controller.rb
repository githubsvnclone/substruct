class ContentNodesController < ApplicationController
  layout 'main'

  def show
    @content_node = ContentNode.find(params[:id])
  end

  # Shows an entire page of content by name
  def show_by_name
    @content_node = ContentNode.find(:first, :conditions => ["name = ?", params[:name]])
    if @content_node == nil then
      render :file => "#{RAILS_ROOT}/public/404.html", :layout => false, :status => 404
      return
    end
    # Set a title
    if @content_node.title.blank? then
      @title = @content_node.name.capitalize
    else
      @title = @content_node.title
    end
    # Render special template for blog posts
    if @content_node.is_blog_post? then
      render(:template => 'content_nodes/blog_post')
    else # Render basic template for regular pages
      render(:layout => 'main')
    end
  end

  # Shows a snippet of content
  def show_snippet
    @content_node = ContentNode.find(:first, :conditions => ["name = ?", params[:name]])
    render(:layout => false)
  end

  # Shows all blog content nodes.
  def index
		@title = "Blog"
    @content_node_pages,
    @content_nodes = paginate :content_node,
                     :per_page => 5,
                     :conditions => 'display_on <= CURRENT_DATE AND content_node_type_id = 1',
                     :order => "display_on DESC, name ASC"
    render
  end
end
