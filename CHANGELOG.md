Changelog
=========

[v0.2.7](https://github.com/Tracktor/zoho-crm/tree/v0.2.7) (2019-07-16)
-----------------------------------------------------------------------

### Features

- Add the `ZohoCRM::API::Configuration#crm_url` method to return the URL of the Zoho CRM.

[v0.2.6](https://github.com/Tracktor/zoho-crm/tree/v0.2.6) (2019-07-15)
-----------------------------------------------------------------------

### Features

- Add the `ZohoCRM::API.configs` method to list registered configurations.

[v0.2.5](https://github.com/Tracktor/zoho-crm/tree/v0.2.5) (2019-07-15)
-----------------------------------------------------------------------

### Enhancements

- Add the ability to use multiple Zoho CRM configuration:
  - Instances of the `ZohoCRM::API::Configuration` have an `environment` attribute.
  - The `ZohoCRM::API.config` and `ZohoCRM::API.configure` methods now accept an environment name as argument.
  - The `ZohoCRM::API::OAuth::Client#initialize` method takes an environment name as argument.

### Fixes

- Update the gem specification to use the correct version of the gem in the Changelog URI.

[v0.2.4](https://github.com/Tracktor/zoho-crm/tree/v0.2.4) (2019-07-05)
-----------------------------------------------------------------------

### Enhancements

- Add more info to the `ZohoCRM::API::APIRequestError` class using additional parameters:
  - `details`: A `Hash` containing details related to the error.
  - `response`: The `HTTP::Response` response object.

[v0.2.3](https://github.com/Tracktor/zoho-crm/tree/v0.2.3) (2019-06-04)
-----------------------------------------------------------------------

### Features

- Add the `ZohoCRM::Model.zoho_enum` method to add enum fields to a model.

[v0.2.2](https://github.com/Tracktor/zoho-crm/tree/v0.2.2) (2019-05-31)
-----------------------------------------------------------------------

### Features

- Add the `#to_h`/`#to_hash` methods to the `ZohoCRM::API::OAuth::Token` class.

[v0.2.1](https://github.com/Tracktor/zoho-crm/tree/v0.2.1) (2019-05-31)
-----------------------------------------------------------------------

### Features

- Add JSON serialization methods to the `ZohoCRM::API::OAuth::Token` class.

### Fixes

- Fix typo in the YARD doc comments on the `ZohoCRM::API::OAuth::Token#initialize` method.

[v0.2.0](https://github.com/Tracktor/zoho-crm/tree/v0.2.0) (2019-05-29)
-----------------------------------------------------------------------

- Add a requirement for Ruby 2.5 or greater.
- Allow the gem to be required with `"zoho-crm"` or `"zoho_crm"`.

### Features

- Add an API client.
- Add an example app.

[v0.1.0](https://github.com/Tracktor/zoho-crm/tree/v0.1.0) (2019-05-21)
-----------------------------------------------------------------------

Initial Release.
