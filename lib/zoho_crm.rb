# frozen_string_literal: true

require "json"
require "forwardable"
require "time"
require "date"
require "bigdecimal"
require "logger"
require "http"

module ZohoCRM
  class Error < StandardError
  end
end

require_relative "zoho_crm/version"
require_relative "zoho_crm/utils"
require_relative "zoho_crm/utils/copiable"
require_relative "zoho_crm/field_set"
require_relative "zoho_crm/fields"
require_relative "zoho_crm/model"
require_relative "zoho_crm/api"
