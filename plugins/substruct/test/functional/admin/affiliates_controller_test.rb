require File.dirname(__FILE__) + '/../../test_helper'

class Admin::AffiliatesControllerTest < ActionController::TestCase
  fixtures :all
  
  def setup
    login_as :admin
    @affil = affiliates(:joes_marketing)
  end
  
  def assert_no_affiliate
    assert_redirected_to :action => 'list'
    assert flash[:notice] = "Sorry, that affiliate code is invalid"
  end
  
  def test_list
    get :list
    assert_response :success
  end
  
  def test_new
    get :new
    assert_response :success
  end

  # CREATE
  
  def test_cant_get_create
    assert_cant_get(:create, {:action => :index})
  end
  
  def test_create_success
    assert_difference "Affiliate.count" do
      post :create,
        :affiliate => {
          :code => 'abcdef',
          :first_name => 'joe',
          :last_name => 'blow'
        }
      assert_redirected_to :action => 'list'
    end
  end
  
  def test_create_fail
    assert_no_difference "Affiliate.count" do
      post :create,
        :affiliate => {}
      assert_response :success
      assert_template 'new'
    end
  end
  
  # UPDATE
  
  def test_cant_get_update
    assert_cant_get(:update, {:action => :index})
  end
  
  def test_update_success
    new_first = 'joe mama'
    new_last = 'bamalama'
    post :update,
      :affiliate => {
        :first_name => new_first,
        :last_name => new_last,
        :code => @affil.code,
        :address => @affil.address,
        :city => @affil.city,
        :state => @affil.state,
        :zip => @affil.zip,
        :telephone => @affil.telephone
      },
      :id => @affil.id
    assert_redirected_to :action => 'list'
    assert !flash[:notice].blank?
    
    @affil.reload
    assert_equal new_first, @affil.first_name
    assert_equal new_last, @affil.last_name
  end
  
  # DESTROY
  
  def test_cant_get_destroy
    assert_cant_get(:destroy, {:action => :index})
  end
  
  def test_destroy_success
    assert_difference "Affiliate.count", -1 do
      post :destroy, :id => @affil.id
    end
  end
  
  def test_destroy_invalid
    assert_no_difference "Affiliate.count" do
      post :destroy, :id => 'fake_affil_id'
      assert_no_affiliate
    end
  end
  
  # SHOW ORDERS 
  
  def test_show_orders
    get :show_orders, :id => @affil.id
    assert_response :success
  end
  
  def test_show_orders_invalid
    get :show_orders, :id => 'invalid_id'
    assert_no_affiliate
  end
  
end