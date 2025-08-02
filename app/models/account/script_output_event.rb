class Account::ScriptOutputEvent
  attr_reader :account, :output

  def initialize(account, output)
    @account = account
    @output = output
  end

  def broadcast
    account.broadcast_replace_to(
      account.family,
      target: "modal",
      partial: "accounts/script_output",
      locals: { account: account, output: output }
    )
  end
end
