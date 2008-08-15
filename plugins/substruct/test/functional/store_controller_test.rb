require File.dirname(__FILE__) + '/../test_helper'

class StoreControllerTest < ActionController::TestCase
  fixtures :orders, :order_line_items, :order_addresses, :order_users, :order_shipping_types, :items
  fixtures :order_accounts, :order_status_codes, :countries, :promotions, :preferences, :wishlist_items
  fixtures :tags


  # TODO: Appears that the cart and cart_container partials arent used, the cart partial is referenced
  # in some places of store controller, but the actions can simply render nothing returning an state of success.
  # In the views, the form_remote_tag or link_to_remote helper methods can simply ommit the update option,
  # then an Ajax.Request object will be created instead of an Ajax.Updater. Anyway a DOM node pointed by it
  # is never manipulated, always an entire show_cart view inside the modal window is shown or reloaded,
  # using showPopWin() or window.location.reload() on complete. 

  # Test the index action.
  def test_should_show_index
    get :index
    assert_response :success
    assert_template 'index'
    assert_equal assigns(:title), "Store"
    assert_not_nil assigns(:tags)
    assert_not_nil assigns(:products)
  end


  # We should get a list of products using a search term.
  def test_should_search
    a_term = "an"
    get :search, :search_term => a_term
    assert_response :success
    assert_equal assigns(:title), "Search Results for: #{a_term}"
    # It should only list products, not variations.
    assert assigns(:products)
    assert_equal assigns(:products).size, 2
    assert_template 'index'


    # Now with a term, that returns only one result.
    a_term = "lightsaber"
    get :search, :search_term => a_term
    assert_response :redirect
    assert_redirected_to :action => :show
    assert assigns(:products)
    assert_equal assigns(:products).size, 1
    
    follow_redirect
    assert_equal assigns(:title), assigns(:products)[0].name
  end


  # We should get a list of products that belongs to a tag.
  def test_should_show_by_tags
    # Call it first without a tag.
    get :show_by_tags, :tags => []
    assert_response :missing

    # Now call it again with a tag.
    a_tag = tags(:weapons)
    get :show_by_tags, :tags => [a_tag.name]
    assert_response :success
    assert_equal assigns(:title), "Store #{assigns(:viewing_tags).collect { |t| ' > ' + t.name}}"
    assert assigns(:products)
    assert_template 'index'

    # Now call it again with a tag and a subtag.
    a_tag = tags(:weapons)
    a_subtag = tags(:mass_destruction)
    get :show_by_tags, :tags => [a_tag.name, a_subtag.name]
    assert_response :success
    assert_equal assigns(:title), "Store #{assigns(:viewing_tags).collect { |t| ' > ' + t.name}}"
    assert assigns(:products)
    assert_template 'index'
    
    # Call it again with an invalid tag.
    get :show_by_tags, :tags => ["invalid"]
    assert_response :missing

    # Call it again with an invalid child tag.
    get :show_by_tags, :tags => [a_tag.name, "invalid"]
    assert_response :missing
 end


  # Test the display_product.
  def test_should_display_product
    # TODO: If this method is not used anymore, get rid of it.
    a_product = items(:lightsaber)
    another_product = items(:uranium_portion)
    
    # Get the result of one product that have images.
    get :display_product, :id => a_product.id
    # Get the result of one product that don't have images.
    get :display_product, :id => another_product.id
  end
  
  
  # Test the show action.
  def test_should_show_show
    a_product = items(:lightsaber)
    
    # TODO: A code is being passed to a hash parameter called id.
    get :show, :id => a_product.code
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:product)
    assert_equal assigns(:title), a_product.name
    assert_equal assigns(:variations).size, 3


    # Now with an invalid code.
    get :show, :id => "invalid"
    assert_response :redirect
    assert_redirected_to :action => :index
    follow_redirect
    assert_select "p", :text => /Sorry, we couldn/
  end
  
  
  # Test the show cart action. This is the action that shows the modal cart.
  def test_should_show_cart
    get :show_cart
    
    # Here we get as a response an entire html page to render inside a modal layout.
    # puts @response.body
  end


  # Test the add to cart action.
  def test_should_add_to_cart
    # TODO: This action don't work passing variations. 
    # TODO: If this action is not used anymore, get rid of it. 

    # Try adding a product.
    a_product = items(:holy_grenade)
    post :add_to_cart, :id => a_product.id
    assert_response :redirect
    assert_redirected_to :action => :checkout
    a_cart = assigns(:cart)
    assert_equal a_cart.items.length, 1

    # Try adding an invalid product.
    a_cart.empty!
    # Make sure this id don't exist.
    a_product.destroy
    post :add_to_cart, :id => a_product.id
    assert_response :redirect
    assert_redirected_to :action => :index
    follow_redirect
    assert_select "p", :text => /Sorry, you tried to buy a product that we don/
  end


  # Test the add to cart ajax action.
  def test_should_add_to_cart_ajax
    # TODO: This method isn't respecting the inventory control option.
    # Try adding a product.
    a_product = items(:towel)
    xhr(:post, :add_to_cart_ajax, :id => a_product.id)
    # Here nothing is rendered directly, but a showPopWin() javascript function is executed.
    a_cart = assigns(:cart)
    assert_equal a_cart.items.length, 1

    # Try adding a variation.
    a_variation = items(:red_lightsaber)
    xhr(:post, :add_to_cart_ajax, :variation => a_variation.id, :quantity => "2")
    # Here nothing is rendered directly, but a showPopWin() javascript function is executed.
    a_cart = assigns(:cart)
    assert_equal a_cart.items.length, 2

    # Try adding another product (that should not be available).
    a_product = items(:holy_grenade)
    xhr(:post, :add_to_cart_ajax, :id => a_product.id, :quantity => "2")
    assert_response 400
    # Here nothing is rendered directly, but a showPopWin() javascript function is executed.
    a_cart = assigns(:cart)
    # It should not have added anything.
    assert_equal a_cart.items.length, 2
  end
  
  
  # Test the remove from cart ajax action.
  def test_should_remove_from_cart_ajax
    # Try adding a product.
    a_product = items(:towel)
    xhr(:post, :add_to_cart_ajax, :id => a_product.id)
    # Here nothing is rendered directly, but a showPopWin() javascript function is executed.
    a_cart = assigns(:cart)
    assert_equal a_cart.items.length, 1

    # Try removing a product.
    xhr(:post, :remove_from_cart_ajax, :id => a_product.id)
    # Here nothing is rendered directly, but a window.location.reload() javascript function is executed.
    a_cart = assigns(:cart)
    assert_equal a_cart.items.length, 0
    
    # Try removing an invalid product.
    # Make sure this id don't exist.
    a_product.destroy
    xhr(:post, :remove_from_cart_ajax, :id => a_product.id)
    # Here a text is rendered.
  end


  # Test the empty cart ajax action.
  def test_should_empty_cart_ajax
    # Try adding a product.
    a_product = items(:towel)
    xhr(:post, :add_to_cart_ajax, :id => a_product.id)
    # Here nothing is rendered directly, but a showPopWin() javascript function is executed.
    a_cart = assigns(:cart)
    assert_equal a_cart.items.length, 1

    xhr(:post, :empty_cart_ajax)
    # Here nothing is rendered directly, but a window.location.reload() javascript function is executed.

    assert_equal assigns(:cart).items.length, 0
    assert_equal session[:order_id], nil
  end


  # Test the empty cart action.
  def test_should_empty_cart
    # Try adding a product.
    a_product = items(:towel)
    xhr(:post, :add_to_cart_ajax, :id => a_product.id)
    # Here nothing is rendered directly, but a showPopWin() javascript function is executed.
    a_cart = assigns(:cart)
    assert_equal a_cart.items.length, 1

    post :empty_cart
    assert_response :redirect
    assert_redirected_to :action => :index

    assert_equal assigns(:cart).items.length, 0
    assert_equal session[:order_id], nil
  end


  # Test the empty cart action.
  def test_should_empty_cart_after_checkout
    test_should_checkout
    
    an_order_id = session[:order_id]
    
    post :empty_cart
    assert_response :redirect
    assert_redirected_to :action => :index

    assert_equal assigns(:cart).items.length, 0
    assert_equal session[:order_id], nil
    
    # Assert the order was destroyed.
    assert_raise(ActiveRecord::RecordNotFound) {
      Order.find(an_order_id)
    }
  end
  
  
  # Test the checkout action.
  def test_should_checkout
    # Add a product to the cart.
    a_product = items(:towel)
    xhr(:post, :add_to_cart_ajax, :id => a_product.id)
    # Here nothing is rendered directly, but a showPopWin() javascript function is executed.
    a_cart = assigns(:cart)
    assert_equal a_cart.items.length, 1

    get :checkout
    assert_response :success
    assert_template 'checkout'
    assert_equal assigns(:title), "Please enter your information to continue this purchase."
    assert_not_nil assigns(:items)
    assert_not_nil assigns(:cc_processor)
    
    # Post to it an order.
    post :checkout,
    :order_account => {
      :cc_number => "4007000000027",
      :expiration_year => 4.years.from_now.year,
      :expiration_month => "1"
    },
    :shipping_address => {
      :city => "",
      :zip => "",
      :country_id => countries(:US).id,
      :first_name => "",
      :telephone => "",
      :last_name => "",
      :address => "",
      :state => ""
    },
    :billing_address => {
      :city => "Duckburg",
      :zip => "00000",
      :country_id => countries(:US).id,
      :first_name => "Uncle",
      :telephone => "000000000",
      :last_name => "Scrooge",
      :address => "Money Bin at the top of Killmotor Hill",
      :state => "Calisota"
    },
    :order_user => {
      :email_address => "uncle.scrooge@whoknowswhere.com"
    }
    
    assert_response :redirect
    assert_redirected_to :action => :select_shipping_method


    get :checkout
    assert_response :success
    assert_template 'checkout'
    assert_equal assigns(:title), "Please enter your information to continue this purchase."
    assert_not_nil assigns(:items)
    assert_not_nil assigns(:cc_processor)
    
    # Post it again with the order already saved.
    post :checkout,
    :order_account => {
      :cc_number => "4007000000027",
      :expiration_year => 4.years.from_now.year,
      :expiration_month => "1"
    },
    :shipping_address => {
      :city => "",
      :zip => "",
      :country_id => countries(:US).id,
      :first_name => "",
      :telephone => "",
      :last_name => "",
      :address => "",
      :state => ""
    },
    :billing_address => {
      :city => "Duckburg",
      :zip => "00000",
      :country_id => countries(:US).id,
      :first_name => "Uncle",
      :telephone => "000000000",
      :last_name => "Scrooge",
      :address => "Money Bin at the top of Killmotor Hill",
      :state => "Calisota"
    },
    :order_user => {
      :email_address => "uncle.scrooge@whoknowswhere.com"
    }
  end
  
  
  # Test the checkout action.
  def test_should_checkout_using_paypal
    # Now we say that we will use paypal ipn.
    assert Preference.save_settings({ "cc_processor" => "PayPal IPN" })

    # Add a product to the cart.
    a_product = items(:towel)
    xhr(:post, :add_to_cart_ajax, :id => a_product.id)
    # Here nothing is rendered directly, but a showPopWin() javascript function is executed.
    a_cart = assigns(:cart)
    assert_equal a_cart.items.length, 1

    get :checkout
    assert_response :success
    assert_template 'checkout'
    assert_equal assigns(:title), "Please enter your information to continue this purchase."
    assert_not_nil assigns(:items)
    assert_not_nil assigns(:cc_processor)
    
    # Post to it an order.
    post :checkout,
    :shipping_address => {
      :city => "",
      :zip => "",
      :country_id => countries(:US).id,
      :first_name => "",
      :telephone => "",
      :last_name => "",
      :address => "",
      :state => ""
    },
    :billing_address => {
      :city => "Duckburg",
      :zip => "00000",
      :country_id => countries(:US).id,
      :first_name => "Uncle",
      :telephone => "000000000",
      :last_name => "Scrooge",
      :address => "Money Bin at the top of Killmotor Hill",
      :state => "Calisota"
    },
    :order_user => {
      :email_address => "uncle.scrooge@whoknowswhere.com"
    }
    
    assert_response :redirect
    assert_redirected_to :action => :select_shipping_method
  end
  
  
  # Test the checkout action.
  def test_should_checkout_when_logged_as_customer
    login_as_customer :uncle_scrooge
    
    # Add a product to the cart.
    a_product = items(:towel)
    xhr(:post, :add_to_cart_ajax, :id => a_product.id)
    # Here nothing is rendered directly, but a showPopWin() javascript function is executed.
    a_cart = assigns(:cart)
    assert_equal a_cart.items.length, 1

    get :checkout
    assert_response :success
    assert_template 'checkout'
    assert_equal assigns(:title), "Please enter your information to continue this purchase."
    assert_not_nil assigns(:items)
    assert_not_nil assigns(:cc_processor)
    
    # Post to it an order.
    post :checkout,
    :order_account => {
      :cc_number => "4007000000027",
      :expiration_year => 4.years.from_now.year,
      :expiration_month => "1"
    },
    :shipping_address => {
      :city => "North Pole",
      :zip => "00000",
      :country_id => countries(:US).id,
      :first_name => "Santa",
      :telephone => "000000000",
      :last_name => "Claus",
      :address => "After second ice mountain at left",
      :state => "Alaska"
    },
    :billing_address => {
      :city => "Duckburg",
      :zip => "00000",
      :country_id => countries(:US).id,
      :first_name => "Uncle",
      :telephone => "000000000",
      :last_name => "Scrooge",
      :address => "Money Bin at the top of Killmotor Hill",
      :state => "Calisota"
    },
    :order_user => {
      :email_address => "uncle.scrooge@whoknowswhere.com"
    },
    :use_separate_shipping_address => "true"
    
    assert_response :redirect
    assert_redirected_to :action => :select_shipping_method


    get :checkout
    assert_response :success
    assert_template 'checkout'
    assert_equal assigns(:title), "Please enter your information to continue this purchase."
    assert_not_nil assigns(:items)
    assert_not_nil assigns(:cc_processor)
    
    # Post it again with the order already saved.
    post :checkout,
    :order_account => {
      :cc_number => "4007000000027",
      :expiration_year => 4.years.from_now.year,
      :expiration_month => "1"
    },
    :shipping_address => {
      :city => "North Pole",
      :zip => "00000",
      :country_id => countries(:US).id,
      :first_name => "Santa",
      :telephone => "000000000",
      :last_name => "Claus",
      :address => "After second ice mountain at left",
      :state => "Alaska"
    },
    :billing_address => {
      :city => "Duckburg",
      :zip => "00000",
      :country_id => countries(:US).id,
      :first_name => "Uncle",
      :telephone => "000000000",
      :last_name => "Scrooge",
      :address => "Money Bin at the top of Killmotor Hill",
      :state => "Calisota"
    },
    :order_user => {
      :email_address => "uncle.scrooge@whoknowswhere.com"
    },
    :use_separate_shipping_address => "true"
  end
  
  
  # Test the checkout action.
  def test_should_checkout_and_break
    # Add a product to the cart.
    a_product = items(:towel)
    xhr(:post, :add_to_cart_ajax, :id => a_product.id)
    # Here nothing is rendered directly, but a showPopWin() javascript function is executed.
    a_cart = assigns(:cart)
    assert_equal a_cart.items.length, 1

    # Stub the order_line_items method to raise an exception.
    Order.any_instance.stubs(:order_line_items).raises('An error!')

    get :checkout
    assert_response :success
    assert_template 'checkout'
    assert_equal assigns(:title), "Please enter your information to continue this purchase."
    assert_not_nil assigns(:items)
    assert_not_nil assigns(:cc_processor)
    
    # Post to it an order.
    post :checkout,
    :order_account => {
      :cc_number => "4007000000027",
      :expiration_year => 4.years.from_now.year,
      :expiration_month => "1"
    },
    :shipping_address => {
      :city => "",
      :zip => "",
      :country_id => countries(:US).id,
      :first_name => "",
      :telephone => "",
      :last_name => "",
      :address => "",
      :state => ""
    },
    :billing_address => {
      :city => "Duckburg",
      :zip => "00000",
      :country_id => countries(:US).id,
      :first_name => "Uncle",
      :telephone => "000000000",
      :last_name => "Scrooge",
      :address => "Money Bin at the top of Killmotor Hill",
      :state => "Calisota"
    },
    :order_user => {
      :email_address => "uncle.scrooge@whoknowswhere.com"
    }
    
    assert_response :success
    assert_select "div#flash" do
      assert_select "div", :text => /There were some problems with the information you entered/
    end
  end
  
  
  # Test the checkout action.
  def test_should_checkout_with_empty_cart
    # Add a product to the cart.
    a_product = items(:towel)
    xhr(:post, :add_to_cart_ajax, :id => a_product.id)
    # Here nothing is rendered directly, but a showPopWin() javascript function is executed.
    a_cart = assigns(:cart)
    # Empty it.
    a_cart.empty!
    assert_equal a_cart.items.length, 0

    get :checkout
    assert_response :redirect
    assert_redirected_to :action => :index
    assert_equal assigns(:title), "Please enter your information to continue this purchase."
    assert_not_nil assigns(:items)
    assert_not_nil assigns(:cc_processor)
  end
  
  
  # Test the checkout action.
  def test_should_checkout_with_unavailable_products
    # Add a product to the cart.
    a_product = items(:towel)
    xhr(:post, :add_to_cart_ajax, :id => a_product.id, :quantity => 32)
    xhr(:post, :add_to_cart_ajax, :id => a_product.id, :quantity => 10)
    # Here nothing is rendered directly, but a showPopWin() javascript function is executed.
    a_cart = assigns(:cart)
    assert_equal a_cart.items.length, 1

    get :checkout
    assert_response :success
    assert_template 'checkout'
    assert_equal assigns(:title), "Please enter your information to continue this purchase."
    assert_not_nil assigns(:items)
    assert_not_nil assigns(:cc_processor)
    
    # Post to it an order.
    post :checkout,
    :order_account => {
      :cc_number => "4007000000027",
      :expiration_year => 4.years.from_now.year,
      :expiration_month => "1"
    },
    :shipping_address => {
      :city => "",
      :zip => "",
      :country_id => countries(:US).id,
      :first_name => "",
      :telephone => "",
      :last_name => "",
      :address => "",
      :state => ""
    },
    :billing_address => {
      :city => "Duckburg",
      :zip => "00000",
      :country_id => countries(:US).id,
      :first_name => "Uncle",
      :telephone => "000000000",
      :last_name => "Scrooge",
      :address => "Money Bin at the top of Killmotor Hill",
      :state => "Calisota"
    },
    :order_user => {
      :email_address => "uncle.scrooge@whoknowswhere.com"
    }
    
    assert_response :redirect
    assert_redirected_to :action => :index
    follow_redirect
    assert_select "div#flash" do
      assert_select "div", :text => /have gone out of stock before you could purchase them/
    end
  end
  
  
  # Test the checkout action.
  def test_should_checkout_with_unavailable_products_and_some_more
    # Add a product to the cart.
    a_product = items(:towel)
    xhr(:post, :add_to_cart_ajax, :id => a_product.id, :quantity => 32)
    xhr(:post, :add_to_cart_ajax, :id => a_product.id, :quantity => 10)
    another_product = items(:holy_grenade)
    xhr(:post, :add_to_cart_ajax, :id => another_product.id)
    # Here nothing is rendered directly, but a showPopWin() javascript function is executed.
    a_cart = assigns(:cart)
    assert_equal a_cart.items.length, 2

    get :checkout
    assert_response :success
    assert_template 'checkout'
    assert_equal assigns(:title), "Please enter your information to continue this purchase."
    assert_not_nil assigns(:items)
    assert_not_nil assigns(:cc_processor)
    
    # Post to it an order.
    post :checkout,
    :order_account => {
      :cc_number => "4007000000027",
      :expiration_year => 4.years.from_now.year,
      :expiration_month => "1"
    },
    :shipping_address => {
      :city => "",
      :zip => "",
      :country_id => countries(:US).id,
      :first_name => "",
      :telephone => "",
      :last_name => "",
      :address => "",
      :state => ""
    },
    :billing_address => {
      :city => "Duckburg",
      :zip => "00000",
      :country_id => countries(:US).id,
      :first_name => "Uncle",
      :telephone => "000000000",
      :last_name => "Scrooge",
      :address => "Money Bin at the top of Killmotor Hill",
      :state => "Calisota"
    },
    :order_user => {
      :email_address => "uncle.scrooge@whoknowswhere.com"
    }
    
    assert_response :success
    assert_template 'checkout'
    assert_select "div#flash" do
      assert_select "div", :text => /have gone out of stock before you could purchase them/
    end
  end
  
  
  # Test the select shipping method action.
  def test_should_select_shipping_method
    # Execute an earlier test as this one deppends on it to have an order in the session.
    test_should_checkout


    get :select_shipping_method
    assert_response :success
    assert_template 'select_shipping_method'
    assert_equal assigns(:title), "Select Your Shipping Method - Step 2 of 3"
    assert_not_nil assigns(:items)
    assert_not_nil assigns(:default_price)
  end
  
  
  # Test the select shipping method action.
  def test_should_select_shipping_method_without_an_order
    # TODO: The @order == nil will never be true because of the before_filter find_order_and_redirect_if_nil.

    get :select_shipping_method
    assert_response :redirect
    assert_redirected_to :action => :index
  end  
  

  # Test the view shipping method action.
  def test_should_view_shipping_method
    # TODO: If this action is not used anymore, get rid of it. 
    get :view_shipping_method
    assert_response 302
  end
  
  
  # Test the set shipping method action.
  def test_should_set_shipping_method_with_confirmation
    # Execute an earlier test as this one deppends on it.
    test_should_select_shipping_method

    # Post to it when the show confirmation preference is true.
    assert Preference.save_settings({ "store_show_confirmation" => "1" })
    post :set_shipping_method, :ship_type_id => order_shipping_types(:ups_ground).id
    assert_response :redirect
    assert_redirected_to :action => :confirm_order
    follow_redirect
    assert_template 'confirm_order'
    assert_equal assigns(:title), "Please confirm your order. - Step 3 of 3"
  end


  # Test the set shipping method action.
  def test_should_set_shipping_method_without_confirmation
    # Execute an earlier test as this one deppends on it.
    test_should_select_shipping_method

    # Post to it when the show confirmation preference is false.
    assert Preference.save_settings({ "store_show_confirmation" => "0" })
    post :set_shipping_method, :ship_type_id => order_shipping_types(:ups_ground).id
    assert_response :redirect
    assert_redirected_to :action => :finish_order
  end

  # Test the confirm order action.
  def test_should_confirm_order
    # Execute an earlier test as this one deppends on it.
#    test_should_select_shipping_method

    # TODO: The code have an unreachable part, the order_shipping_type_id will never be nil because
    # the database schema don't let it.
 #   assert_equal assigns(:order).order_shipping_type_id, nil
    
    # Get the confirm order action when the shipping is nil.
 #   get :confirm_order
 #   assert_response :redirect
 #   assert_redirected_to :action => :select_shipping_method
  end


  # Test the finish order action.
  def test_should_finish_order_with_authorize
    # Execute an earlier test as this one deppends on it.
    test_should_set_shipping_method_without_confirmation
   
    an_order = Order.find(session[:order_id])

    # Now we say that we will use authorize. Mock the method.
    assert Preference.save_settings({ "cc_processor" => "Authorize.net" })
    Order.any_instance.expects(:run_transaction_authorize).once.returns(true)
    
    # Save initial quantity
    an_order_line_item = assigns(:order).order_line_items.first
    initial_quantity = an_order_line_item.item.quantity

    # Post to the finish order action.
    post :finish_order
    assert_response :success
    assert_select "h3", :text => /Card processed successfully/

    # Clean it up as we are mocking the method and it will not execute by itself.
    an_order.cleanup_successful
    # Quantity should be updated.
    an_order_line_item.item.reload
    assert_equal an_order_line_item.item.quantity, initial_quantity - an_order_line_item.quantity
  end


  # Test the finish order action.
  def test_should_finish_order_with_authorize_with_error
    # Execute an earlier test as this one deppends on it.
    test_should_set_shipping_method_without_confirmation
   
    # Now we say that we will use authorize. Mock the method.
    assert Preference.save_settings({ "cc_processor" => "Authorize.net" })
    Order.any_instance.expects(:run_transaction_authorize).once.returns(false)

    # Save initial quantity
    an_order_line_item = assigns(:order).order_line_items.first
    initial_quantity = an_order_line_item.item.quantity

    # Post to the finish order action.
    post :finish_order
    assert_response :redirect
    assert_redirected_to :action => :checkout
    follow_redirect
    assert_select "p", :text => /Sorry, but your transaction didn/

    # Quantity should NOT be updated.
    an_order_line_item.item.reload
    assert_equal an_order_line_item.item.quantity, initial_quantity
  end
  
  
  # Test the finish order action.
  def test_should_finish_order_with_paypal
    # Execute an earlier test as this one deppends on it.
    test_should_set_shipping_method_without_confirmation
   
    an_order = Order.find(session[:order_id])

    # Now we say that we will use paypal ipn. Mock the method.
    assert Preference.save_settings({ "cc_processor" => "PayPal IPN" })
    Order.any_instance.expects(:run_transaction_paypal_ipn).once.returns(5)

    # Save initial quantity
    an_order_line_item = assigns(:order).order_line_items.first
    initial_quantity = an_order_line_item.item.quantity

    # Post to the finish order action.
    post :finish_order
    assert_response :success
    assert_select "h3", :text => /Transaction processed successfully/

    # Clean it up as we are mocking the method and it will not execute by itself.
    an_order.cleanup_successful
    # Quantity should be updated.
    an_order_line_item.item.reload
    assert_equal an_order_line_item.item.quantity, initial_quantity - an_order_line_item.quantity
  end


  # Test the finish order action.
  def test_should_finish_order_with_paypal_without_ipn_confirmation
    # Execute an earlier test as this one deppends on it.
    test_should_set_shipping_method_without_confirmation
   
    # Now we say that we will use paypal ipn. Mock the method.
    assert Preference.save_settings({ "cc_processor" => "PayPal IPN" })
    Order.any_instance.expects(:run_transaction_paypal_ipn).once.returns(4)

    # Save initial quantity
    an_order_line_item = assigns(:order).order_line_items.first
    initial_quantity = an_order_line_item.item.quantity

    # Post to the finish order action.
    post :finish_order
    assert_response :success
    assert_select "h3", :text => /have not heard back from them yet/

    # Quantity should NOT be updated.
    an_order_line_item.item.reload
    assert_equal an_order_line_item.item.quantity, initial_quantity
  end
  
  
  # Test the finish order action.
  def test_should_finish_order_with_paypal_with_error
    # Execute an earlier test as this one deppends on it.
    test_should_set_shipping_method_without_confirmation
   
    # Now we say that we will use paypal ipn. Mock the method.
    assert Preference.save_settings({ "cc_processor" => "PayPal IPN" })
    Order.any_instance.expects(:run_transaction_paypal_ipn).once.returns(3)

    # Save initial quantity
    an_order_line_item = assigns(:order).order_line_items.first
    initial_quantity = an_order_line_item.item.quantity

    # Post to the finish order action.
    post :finish_order
    assert_response :redirect
    assert_redirected_to :action => :checkout
    follow_redirect
    assert_select "p", :text => /Something went wrong and your transaction failed/

    # Quantity should NOT be updated.
    an_order_line_item.item.reload
    assert_equal an_order_line_item.item.quantity, initial_quantity
  end

  
  end
