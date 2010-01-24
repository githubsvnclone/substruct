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
  
  def test_invalid_codes
    invalid_codes = [
      "code/with/slashes", "code?with?questionmarks",
      "code&with&ampersands", "code with spaces", "code's with apostrophes"
    ]
    invalid_codes.each do |code|
      @jm.code = code
      assert !@jm.save, "Saved with code: '#{code}' when it shouldn't have."
      assert_error_on :code, @jm
    end
  end
  
  def test_valid_codes
    valid_codes = [
      "code_with_underscores", "affiliate1", "joes_marketing",
      "code-with-dashes"
    ]
    5.times { valid_codes << Affiliate.generate_code }
    valid_codes.each do |code|
      @jm.code = code
      assert @jm.save, "Didn't save with code: '#{@jm.code}'"
    end
  end
end