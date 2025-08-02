require "application_system_test_case"

class AccountLogosTest < ApplicationSystemTestCase
  setup do
    sign_in users(:family_admin)
  end

  test "user can upload logo for account" do
    account = accounts(:depository)

    visit edit_account_path(account)
    attach_file "account_logo", file_fixture("square-placeholder.png")
    click_button "Update Account"

    assert_selector "img[src*='square-placeholder.png']"
    assert account.reload.logo.attached?
  end
end
