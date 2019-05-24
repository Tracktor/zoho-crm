# frozen_string_literal: true

require 'bundler'
Bundler.setup

require "zoho_crm"
require "dotenv/load"
require "sinatra"
require "pp"

ZohoCRM::API.configure do |config|
  config.region = "eu"
  config.sandbox = true

  config.client_id = ENV["ZOHO_CRM_API_CLIENT_ID"]
  config.client_secret = ENV["ZOHO_CRM_API_CLIENT_SECRET"]
  config.redirect_url = ENV["ZOHO_CRM_REDIRECT_URI"]
  config.scopes = %w[
    ZohoCRM.modules.all
  ]
end

oauth_client = ZohoCRM::API::OAuth::Client.new

get "/" do
  content_type :text

  if oauth_client.authorized?
    oauth_client.token.inspect
  else
    "Zoho API not registered. Go to /zoho/register"
  end
end

get "/zoho/register" do
  redirect ZohoCRM::API.config.developer_console_url
end

get "/zoho/auth" do
  redirect oauth_client.authorize_url
end

get "/auth" do
  if response.status >= 200 && response.status < 300
    oauth_client.create(grant_token: params[:code])

    redirect "/"
  else
    content_type :text

    "{ params: #{params.inspect} response: #{response.inspect} }"
  end
end
