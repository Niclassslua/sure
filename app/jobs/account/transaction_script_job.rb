class Account::TransactionScriptJob < ApplicationJob
  queue_as :default

  def perform(account, procedure: nil, device: nil)
    Account::TransactionScriptRunner.new(account).run(procedure: procedure, device: device)
    account.broadcast_sync_complete
    Turbo::StreamsChannel.broadcast_replace_to(account.family, target: "modal", html: "")
  rescue Account::TransactionScriptRunner::PushTanRequired
    account.broadcast_push_tan_required
  end
end
