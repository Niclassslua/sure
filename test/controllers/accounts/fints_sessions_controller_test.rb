require "test_helper"

class Accounts::FintsSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
    @account = accounts(:depository)
    @account.update!(fints_api_base_url: "http://example.com")
  end

  test "confirm posts to fints api" do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/sessions/123/confirm") { [ 200, {}, { status: "processing" }.to_json ] }
    end

    connection = Faraday.new do |builder|
      builder.request :json
      builder.response :raise_error
      builder.adapter :test, stubs
    end

    Accounts::FintsSessionsController.any_instance.stubs(:client).returns(connection)

    post confirm_account_fints_session_path(account_id: @account.id, id: "123")
    assert_response :success

    stubs.verify_stubbed_calls
  end
end
