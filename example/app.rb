# frozen_string_literal: true

require "bundler"
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
api_client = ZohoCRM::API::Client.new(oauth_client)

helpers do
  def oauth_client_not_authorized
    "Zoho API not authorized. Go to /zoho/auth.\n"\
      "You can also register this app as a client by going to /zoho/register."
  end
end

get "/" do
  content_type :text

  if oauth_client.authorized?
    oauth_client.token.inspect
  else
    oauth_client_not_authorized
  end
end

get "/contacts/:id" do
  content_type :text

  if oauth_client.authorized?
    resp = api_client.show(params[:id], module_name: "Contacts")

    resp.parse.inspect
  else
    oauth_client_not_authorized
  end
end

get "/zoho/register" do
  redirect ZohoCRM::API.config.developer_console_url
end

get "/zoho/auth" do
  if oauth_client.authorized?
    redirect "/"
  else
    redirect oauth_client.authorize_url
  end
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
