# frozen_string_literal: true

require "bundler"
Bundler.setup

require "pp"
require "json"

require "zoho_crm"
require "dotenv/load"
require "sinatra"

ZohoCRM::API.configure do |config|
  config.region = "eu"
  config.sandbox = true

  config.client_id = ENV["ZOHO_CRM_API_CLIENT_ID"]
  config.client_secret = ENV["ZOHO_CRM_API_CLIENT_SECRET"]
  config.redirect_url = ENV["ZOHO_CRM_REDIRECT_URI"]
  config.scopes = %w[
    ZohoCRM.modules.all
    ZohoCRM.settings.fields.READ
    ZohoCRM.settings.custom_views.READ
    ZohoCRM.settings.modules.READ
  ]
end

oauth_client = ZohoCRM::API::OAuth::Client.new(JSON.parse(ENV.fetch("ZOHO_AUTH", "{}")))
api_client = ZohoCRM::API::Client.new(oauth_client)

set :show_exceptions, false

helpers do
  def oauth_client_not_authorized
    halt 401, {"Content-Type" => "text/plain"},
      "Zoho API not authorized. Go to /zoho/auth.\n"\
      "You can also register this app as a client by going to /zoho/register."
  end
end

get "/fields/:module_name" do
  content_type :json

  if oauth_client.authorized?
    response = api_client.get("settings/fields", query: {module: params[:module_name]})

    data = response.parse["fields"].map { |f| [f["field_label"], f["api_name"]] }

    JSON.pretty_generate(Hash[data])
  else
    oauth_client_not_authorized
  end
end

get "/" do
  if oauth_client.authorized?
    content_type :json

    JSON.pretty_generate({
      access_token: oauth_client.token.access_token,
      refresh_token: oauth_client.token.refresh_token,
      expires_in_sec: oauth_client.token.expires_in_sec,
      expires_in: oauth_client.token.expires_in,
      token_type: oauth_client.token.token_type,
      api_domain: oauth_client.token.api_domain,
    })
  else
    oauth_client_not_authorized
  end
end

# Get a record
get "/contacts/:id" do
  content_type :json

  if oauth_client.authorized?
    data = api_client.show(params[:id], module_name: "Contacts")

    JSON.pretty_generate(data)
  else
    oauth_client_not_authorized
  end
end

# Create a new record
post "/contacts" do
  content_type :json

  if oauth_client.authorized?
    request.body.rewind
    contact_attributes = JSON.parse(request.body.read)

    data = api_client.create(contact_attributes, module_name: "Contacts")

    status 201

    JSON.pretty_generate(data)
  else
    oauth_client_not_authorized
  end
end

# Update a record
patch "/contacts/:id" do
  content_type :json

  if oauth_client.authorized?
    request.body.rewind
    contact_attributes = JSON.parse(request.body.read)

    if api_client.update(params[:id], contact_attributes, module_name: "Contacts")
      status 200
    else
      status 422
    end
  else
    oauth_client_not_authorized
  end
end

# Insert or Update a record (Upsert)
put "/contacts" do
  content_type :json

  if oauth_client.authorized?
    request.body.rewind
    contact_attributes = JSON.parse(request.body.read)

    data = api_client.upsert(contact_attributes, module_name: "Contacts", duplicate_check_fields: %w[Email])

    status data["new_record"] ? 201 : 200

    JSON.pretty_generate(data["id"])
  else
    oauth_client_not_authorized
  end
end

# Delete a record
delete "/contacts/:id" do
  content_type :json

  if oauth_client.authorized?
    if api_client.destroy(params[:id], module_name: "Contacts")
      status 200
    else
      status 422
    end
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
    halt response.status, {"Content-Type" => "text/plain"},
      "{ params: #{params.inspect} response: #{response.inspect} }"
  end
end

error do |e|
  content_type :json

  pretty_error =
    case e
    when ZohoCRM::API::OAuth::Error
      {
        error_class: e.class,
        message: e.message,
        token: e.token,
      }
    when ZohoCRM::API::HTTPRequestError
      status e.response.status.code

      {
        error_class: e.class,
        error: e.response.parse,
      }
    when APIRequestError
      status e.status_code

      {
        error_class: e.class,
        message: e.message,
        error_code: e.error_code,
      }
    else
      {
        error_class: e.class,
        message: e.message,
      }
    end

  JSON.pretty_generate(pretty_error)
end
