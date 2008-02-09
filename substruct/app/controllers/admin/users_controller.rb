class Admin::UsersController < Admin::BaseController
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def index
    list
    render_action 'list'
  end

  def list
    @title = 'User List'
    @users = User.find_all
  end

  def show
    @user = User.find(params[:id])
  end

  def new
		@title = "Creating New User"
    @user = User.new(params[:user])
		@roles = Role.find(:all, :order => 'name ASC')
    if @request.post? and @user.save
      flash[:notice] = 'User was successfully created.'
      redirect_to :action => 'list'
    end      
  end

  def edit
		@title = "Editing User"
    @user = User.find(params[:id])
    @user.attributes = params["user"]
		
		@roles = Role.find(:all, :order => 'name ASC')
		logger.info("[PARAMS] #{params.inspect}")
		
		# Update user
    if @request.post? and @user.save
      flash[:notice] = 'User was successfully updated.'
      redirect_to :action => 'list'
    end
    @user.password = @user.password_confirmation =  ''
  end

  def destroy
		if (User.count == 1) then
			flash[:notice] = "You have to have at least one user in the system. Try creating another one if you'd like to delete this one."
			redirect_to :back
			return
		end
    User.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
end
