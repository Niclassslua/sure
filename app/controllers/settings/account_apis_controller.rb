class Settings::AccountApisController < ApplicationController
  layout "settings"

  def show
    @accounts = Current.family.accounts.order(:name)
  end

  def update
    account = Current.family.accounts.find(params.require(:account_id))
    account.update!(fints_api_base_url: params.require(:account)[:fints_api_base_url])
    redirect_to settings_account_apis_path, notice: t("accounts.update.success", type: account.accountable_type.underscore.humanize)
  end
end
