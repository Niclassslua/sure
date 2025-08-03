class RemoveSyncScriptPathFromAccounts < ActiveRecord::Migration[7.1]
  def change
    remove_column :accounts, :sync_script_path, :string
  end
end
