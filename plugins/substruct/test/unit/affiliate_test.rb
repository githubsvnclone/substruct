require File.dirname(__FILE__) + '/../test_helper'

class AffiliateTest < ActiveSupport::TestCase
  fixtures :affiliates, :orders
  
  def setup
    @jm = affiliates(:joes_marketing)
  end
  
  def test_valid_presence
    affil = Affiliate.new
    assert_valid_presence(@jm, :code)
  end
  
  def test_valid_uniqueness
    affil = Affiliate.new
    assert_valid_uniqueness(affil, @jm, :code)
  end
end