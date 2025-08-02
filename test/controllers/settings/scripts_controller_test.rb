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

  test "should upload script with requirements and env for account" do
    script = fixture_file_upload("example_script.py", "text/x-python")
    req = fixture_file_upload("example_requirements.txt", "text/plain")
    env = fixture_file_upload("example.env", "text/plain")

    put settings_script_path, params: { account_id: @account.id, script: script, requirements: req, env: env }
    assert_redirected_to settings_script_path(account_id: @account.id)

    @account.reload
    assert @account.sync_script_path.present?

    script_dir = Rails.root.join("storage", "scripts", "account_#{@account.id}")

    assert_equal File.read(Rails.root.join("test/fixtures/files/example_script.py")),
                 File.read(script_dir.join("script.py"))
    assert_equal File.read(Rails.root.join("test/fixtures/files/example_requirements.txt")),
                 File.read(script_dir.join("requirements.txt"))
    assert_equal File.read(Rails.root.join("test/fixtures/files/example.env")),
                 File.read(script_dir.join(".env"))
    assert_equal 0o600, File.stat(script_dir.join(".env")).mode & 0o777

    FileUtils.rm_rf(script_dir)
  end
end
