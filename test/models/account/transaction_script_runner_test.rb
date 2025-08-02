require "test_helper"
require "tmpdir"

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
      result = runner.run
      assert_equal 1, result.added
      assert_match "Test", result.output
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
  end

  test "installs requirements if present" do
    Dir.mktmpdir do |dir|
      script_path = File.join(dir, "script.py")
      File.write(script_path, "print('[]')")

      requirements_path = File.join(dir, "requirements.txt")
      File.write(requirements_path, "requests==2.31.0")

      @account.update!(sync_script_path: script_path)
      runner = Account::TransactionScriptRunner.new(@account)

      install_status = stub
      run_status = stub

      Open3.expects(:capture3).with("python3", "-m", "pip", "install", "-r", requirements_path).returns([ "", "", install_status ])
      Open3.expects(:capture3).with({}, "python3", script_path).returns([ "[]", "", run_status ])

      runner.run
    end
  end
end
