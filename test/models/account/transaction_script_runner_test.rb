require "test_helper"

class TransactionScriptRunnerTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:depository)
  end

  test "imports new transactions" do
    script = Tempfile.new([ "script", ".py" ])
    script.write <<~PYTHON
      import json
      print(json.dumps([{"date": "2024-01-01", "name": "Test", "amount": "10.00", "currency": "USD"}]))
    PYTHON
    script.close

    @account.update!(sync_script_path: script.path)

    runner = Account::TransactionScriptRunner.new(@account)

    assert_difference -> { @account.entries.count }, +1 do
      assert_equal 1, runner.run
    end
  ensure
    script.unlink
  end

  test "detects push tan requirement" do
    script = Tempfile.new([ "script", ".py" ])
    script.write <<~PYTHON
      import sys, json
      sys.stderr.write("Push-Tan needed")
      print("[]")
    PYTHON
    script.close

    @account.update!(sync_script_path: script.path)

    runner = Account::TransactionScriptRunner.new(@account)

    assert_raises(Account::TransactionScriptRunner::PushTanRequired) do
      runner.run
    end
  ensure
    script.unlink
  end
end
