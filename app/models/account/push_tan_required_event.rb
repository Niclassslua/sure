class Account::PushTanRequiredEvent
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def broadcast
    account.broadcast_replace_to(
      account.family,
      target: "modal",
      partial: "accounts/push_tan_required",
      locals: { account: account }
    )
  end
end
