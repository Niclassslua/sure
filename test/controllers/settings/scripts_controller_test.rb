require "test_helper"

class Settings::ScriptsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_member)
    @account = accounts(:depository)
  end

  test "shows script settings" do
    get settings_script_path
    assert_response :success
  end

  test "uploads script for account" do
    file = Tempfile.new([ "script", ".py" ])
    file.write("print('hi')")
    file.rewind

    upload = Rack::Test::UploadedFile.new(file.path, "text/x-python")
    patch settings_script_path, params: { account_id: @account.id, script: upload }
    assert_redirected_to settings_script_path(account_id: @account.id)
    @account.reload
    assert @account.sync_script_path.present?
  ensure
    file.close
    file.unlink
  end
end
