module Accounts
  class FintsSessionsController < ApplicationController
    before_action :set_account

    def create
      response = client.post("/sessions") do |req|
        req.body = { days: params[:days].to_i }
        req.headers["x-pin"] = params[:pin] if params[:pin].present?
      end
      render json: JSON.parse(response.body), status: response.status
    rescue Faraday::Error => e
      render json: { error: e.message }, status: :bad_gateway
    end

    def show
      response = client.get("/sessions/#{params[:id]}")
      render json: JSON.parse(response.body), status: response.status
    rescue Faraday::Error => e
      render json: { error: e.message }, status: :bad_gateway
    end

    def confirm
      response = client.post("/sessions/#{params[:id]}/confirm")
      render json: JSON.parse(response.body), status: response.status
    rescue Faraday::Error => e
      render json: { error: e.message }, status: :bad_gateway
    end

    def result
      response = client.get("/sessions/#{params[:id]}/result")
      render plain: response.body, content_type: "text/csv"
    rescue Faraday::Error => e
      render json: { error: e.message }, status: :bad_gateway
    end

    private
      def set_account
        @account = Current.family.accounts.find(params[:account_id])
      end

      def client
        @client ||= Faraday.new(url: @account.fints_api_base_url) do |faraday|
          faraday.request :json
          faraday.response :raise_error
        end
      end
  end
end
