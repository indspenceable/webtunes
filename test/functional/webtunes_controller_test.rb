require 'test_helper'

class WebtunesControllerTest < ActionController::TestCase
  test "should get interface" do
    get :interface
    assert_response :success
  end

end
