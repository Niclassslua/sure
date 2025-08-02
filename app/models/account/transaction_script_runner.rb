require "open3"
require "json"

class Account::TransactionScriptRunner
  class PushTanRequired < StandardError; end

  attr_reader :account

  def initialize(account)
    @account = account
  end

  def run(procedure: nil, device: nil)
    return 0 unless account.sync_script_path.present?

    env = {}
    env["TAN_PROCEDURE"] = procedure if procedure.present?
    env["TAN_DEVICE"] = device if device.present?

    stdout, stderr, _status = Open3.capture3(env, "python3", account.sync_script_path)

    output = [ stdout, stderr ].join("\n")
    if output.match?(/push[- ]?tan/i)
      raise PushTanRequired, "pushTAN authorization required"
    end

    transactions = JSON.parse(stdout.presence || "[]")
    added = 0

    transactions.each do |tx|
      date = Date.parse(tx["date"].to_s)
      amount = BigDecimal(tx["amount"].to_s)
      name = tx["name"].to_s
      currency = tx["currency"].presence || account.currency

      exists = account.entries.where(
        date: date,
        name: name,
        amount: amount,
        currency: currency,
        entryable_type: "Transaction"
      ).exists?
      next if exists

      account.entries.create!(
        date: date,
        name: name,
        amount: amount,
        currency: currency,
        entryable: Transaction.new
      )
      added += 1
    end

    added
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse transaction script output: #{e.message}")
    0
  end
end
