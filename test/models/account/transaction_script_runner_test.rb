require "test_helper"

class Account::TransactionScriptRunnerTest < ActiveSupport::TestCase
  test "logs script output" do
    account = accounts(:depository)
    script_path = Rails.root.join("test/fixtures/files/example_script.py")
    account.update!(sync_script_path: script_path.to_s)

    io = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(io)

    begin
      Account::TransactionScriptRunner.new(account).run
      assert_match "[]", io.string
    ensure
      Rails.logger = original_logger
    end
  end
end
