require "test_helper"

class Settings::AccountApisControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:depository)
  end

  test "should get show" do
    get settings_account_api_url
    assert_response :success
  end

  test "should update account api" do
    put settings_account_api_url, params: { account_id: @account.id, fints_api_base_url: "http://example.com" }
    assert_redirected_to settings_account_api_url(account_id: @account.id)
    @account.reload
    assert_equal "http://example.com", @account.fints_api_base_url
  end
end
