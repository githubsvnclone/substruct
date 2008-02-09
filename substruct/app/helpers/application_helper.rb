# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
	include Substruct
	
	def current_user_notice
    unless @session[:user]
      link_to "Log In", :controller => "/accounts", :action=>"login"
    else
      link_to "Log Out", :controller => "/accounts", :action=>"logout"
    end
  end
end
