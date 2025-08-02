require "test_helper"
require "fileutils"

class Settings::ScriptsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    sign_in @user
    @account = accounts(:depository)
  end

  test "should show script settings" do
    get settings_script_path
    assert_response :success
  end

  test "should upload script for account" do
    file = fixture_file_upload("example_script.py", "text/x-python")
    put settings_script_path, params: { account_id: @account.id, script: file }
    assert_redirected_to settings_script_path(account_id: @account.id)

    @account.reload
    assert @account.sync_script_path.present?
    assert_equal File.read(Rails.root.join("test/fixtures/files/example_script.py")),
                 File.read(@account.sync_script_path)
    FileUtils.rm_f(@account.sync_script_path)
  end
end
