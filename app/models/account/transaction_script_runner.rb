require "open3"
require "json"
require "dotenv"

class Account::TransactionScriptRunner
  class PushTanRequired < StandardError; end

  Result = Struct.new(:added, :output)

  attr_reader :account

  def initialize(account)
    @account = account
  end

  # Führt das zugeordnete Python-Skript aus. Optional können TAN-Verfahren und Gerät übergeben werden.
  # Gibt die Anzahl neu hinzugefügter Einträge zurück.
  def run(procedure: nil, device: nil)
    return Result.new(0, "") unless account.sync_script_path.present?
    install_output = install_requirements

    env = {}
    env_file = File.join(File.dirname(account.sync_script_path), ".env")
    env.merge!(Dotenv.parse(env_file)) if File.exist?(env_file)
    env["TAN_PROCEDURE"] = procedure if procedure.present?
    env["TAN_DEVICE"] = device if device.present?

    stdout, stderr, status = Open3.capture3(env, "python3", account.sync_script_path)
    Rails.logger.info("Transaction script stdout:\n#{stdout}") if stdout.present?
    Rails.logger.info("Transaction script stderr:\n#{stderr}") if stderr.present?
    Rails.logger.info("Transaction script exited with status #{status.exitstatus}") unless status.success?
    output = [ stdout, stderr ].join("\n")

    # pushTAN / BestSign Hinweis erkennen
    if output.match?(/push[- ]?tan/i) || output.match?(/bestsign/i)
      # Optional: Details ins Log
      Rails.logger.info("PushTAN/BestSign Hinweis im Script-Output entdeckt.")
      raise PushTanRequired, "pushTAN/BestSign authorization required"
    end

    transactions_json = stdout.presence || "[]"
    transactions = JSON.parse(transactions_json)
    added = 0

    transactions.each do |tx|
      # Erwartete Struktur: z. B. { "date": "...", "amount": "...", "name": "...", "currency": "..." }
      begin
        date = Date.parse(tx["date"].to_s)
        amount = BigDecimal(tx["amount"].to_s)
        name = tx["name"].to_s
        currency = tx["currency"].presence || account.currency
      rescue => e
        Rails.logger.warn("Ungültige Transaktion übersprungen (Parsing-Fehler): #{e.message} -- #{tx.inspect}")
        next
      end

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

    Result.new(added, output)
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse transaction script output: #{e.message}; raw stdout: #{stdout.inspect}")
    Result.new(0, output)
  end
    private

      def install_requirements
        script_dir = File.dirname(account.sync_script_path)
        requirements = File.join(script_dir, "requirements.txt")
        return "" unless File.exist?(requirements)

        stdout, stderr, _status = Open3.capture3("python3", "-m", "pip", "install", "-r", requirements)
        [ stdout, stderr ].join("\n").strip
      end
end
