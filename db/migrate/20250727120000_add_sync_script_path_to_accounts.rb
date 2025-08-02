class AddSyncScriptPathToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :sync_script_path, :string
  end
end
