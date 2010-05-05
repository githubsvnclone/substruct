require File.dirname(__FILE__) + '/../test_helper'

class PromotionCheckoutTest < ActionController::IntegrationTest
  fixtures :all
  
  def setup
    # Setup & pre-verify
    @customer = order_users(:santa)
    @expensive_item = items(:grey_coat)
    @inexpensive_item = items(:lightsaber)
    @promo = promotions(:minimum_rebate)
  end

  def test_promo_minimum_cart_value    
    assert @promo.minimum_cart_value > @inexpensive_item.price
    post 'store/add_to_cart', :id => @inexpensive_item.id
    assert_redirected_to 'store/checkout'
    assert_equal assigns(:order).items.length, 1
    
    perform_successful_checkout()
    assert_redirected_to :action => 'select_shipping_method'
    follow_redirect!
    assert_nil assigns(:order).promotion, "Promotion applied when it shouldn't have been."
  end

  # Ensure that customers can't circumvent the 'minimum cart value'
  # requirement for promotions by...
  #   * Adding products to exceed the limit
  #   * Filling out the checkout form and applying a promotion
  #   * Removing products from their cart
  #   * Hitting the "shipping method" screen
  #   * Checking out
  def test_promo_minimum_cart_value_bug
    # Setup & pre-verify
    assert (@expensive_item.price + @inexpensive_item.price) >= @promo.minimum_cart_value
    assert @promo.minimum_cart_value > @inexpensive_item.price
    
    get 'store'
    assert_response :success
    
    # ADD ITEMS TO CART
    # Using both methods just to test legacy support.
    xml_http_request(:post, 'store/add_to_cart_ajax', {:id => @expensive_item.id})
    assert_response :success
    post 'store/add_to_cart', :id => @inexpensive_item.id
    assert_redirected_to 'store/checkout'
    assert_equal assigns(:order).items.length, 2
    
    # FILL OUT CHECKOUT FORM SUCCESSFULLY
    perform_successful_checkout()
    assert_redirected_to :action => 'select_shipping_method'
    follow_redirect!
    
    # ENSURE PROMO IS APPLIED
    assert_equal @promo, assigns(:order).promotion
    
    # REMOVE EXPENSIVE ITEM FROM CART
    xml_http_request(:post, 'store/remove_from_cart_ajax', {:id => @expensive_item.id})
    assert_response :success
    
    # HIT SHIPPING METHOD PAGE
    get 'store/select_shipping_method'
    assert_response :success
    
    # VERIFY PROMO NOT APPLIED
    assert_nil assigns(:order).promotion, "Promotion still applied when it shouldn't be."
    assert_equal @inexpensive_item.price, assigns(:order).line_items_total
  end
  
  private
    # Check out with a promo code.
    def perform_successful_checkout
      post(
        'store/checkout', 
        {
          :order_account => {
            :cc_number => "4007000000027",
            :expiration_year => 4.years.from_now.year,
            :expiration_month => "1"
          },
          :shipping_address => @customer.billing_address.attributes,
          :billing_address => @customer.billing_address.attributes,
          :order_user => {
            :email_address => @customer.email_address
          },
          :order => {
            :promotion_code => @promo.code
          }
        }
      )
    end
end