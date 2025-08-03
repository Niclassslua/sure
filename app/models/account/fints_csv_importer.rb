require 'csv'

class Account::FintsCsvImporter
  attr_reader :account, :csv_data

  def initialize(account, csv_data)
    @account = account
    @csv_data = csv_data
  end

  # Imports CSV data in Sparkasse format and returns number of new entries added
  def import!
    rows = CSV.parse(csv_data, headers: true)
    added = 0
    rows.each do |row|
      begin
        date = Date.strptime(row['date*'], '%m/%d/%Y')
        amount = BigDecimal(row['amount*'])
        name = row['name'].to_s
        currency = row['currency'].presence || account.currency
      rescue
        next
      end

      exists = account.entries.where(
        date: date,
        name: name,
        amount: amount,
        currency: currency,
        entryable_type: 'Transaction'
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
  end
end
