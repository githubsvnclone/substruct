class Admin::AffiliatesController < Admin::BaseController
  verify :method => :post, 
    :only => [ :create, :update, :destroy], 
    :redirect_to => {:action => :index}
  
  before_filter :get_affiliate,
    :only => [:edit, :update, :destroy, :show_orders]
  
  def index
    list
    render :action => 'list'
  end

  def list
    @title = "Affiliate List"
    @affiliates = Affiliate.find(:all, :order => 'code ASC')
  end

  # Creates a content node
  def new
    @title = "Creating New Affiliate"
    @affiliate = Affiliate.new
  end

  def create
    @title = "Creating Affiliate"
    @affiliate = Affiliate.new(params[:affiliate])
    if @affiliate.save
      flash[:notice] = 'Affiliate was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @title = "Editing Affiliate"
  end

  def update
    if @affiliate.update_attributes(params[:affiliate])
      flash[:notice] = 'Affiliate was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    @affiliate.destroy
    redirect_to :action => 'list'
  end
  
  # Shows all orders for a particular affiliate
  def show_orders
    @title = "Orders for #{@affiliate.code}"
    @orders = Order.paginate(
      :order => 'created_on DESC',
      :conditions => ["affiliate_id = ?", @affiliate.id],
      :page => params[:page],
      :per_page => 30
    )
  end
  
  private
    def get_affiliate
      @affiliate = Affiliate.find_by_id(params[:id])
      unless @affiliate
        flash[:notice] = "Sorry, that affiliate code is invalid"
        redirect_to :action => 'list'
        return false
      end
    end
end
