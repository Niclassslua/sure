class Account::TransactionScriptJob < ApplicationJob
  queue_as :default

  def perform(account, procedure: nil, device: nil)
    result = Account::TransactionScriptRunner.new(account).run(procedure: procedure, device: device)
    account.broadcast_script_output(result.output)
  rescue Account::TransactionScriptRunner::PushTanRequired
    account.broadcast_push_tan_required
  end
end
