class AddFintsApiBaseUrlToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :fints_api_base_url, :string
  end
end
