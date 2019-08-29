Changelog
=========

[v0.3.0](https://github.com/Tracktor/zoho-crm/tree/v0.3.0) (2019-08-29)
-------------------------------------------------------------------------

### Breaking changes

- Remove the `ZohoCRM::Fields::Field.build` and `ZohoCRM::Fields::Enum.build` methods.<br>
  You should use the `ZohoCRM::Fields::Field#initialize` and `ZohoCRM::Fields::Enum#initialize` methods instead.
- Make the `ZohoCRM::FieldSet#add` method not chainable.<br>
  If you want to add multiple fields using chaining, use the `ZohoCRM::FieldSet#<<` method.

### Changes

- Instances of `ZohoCRM::Model` now have their own copy of the fields defined on the class.<br>
  This means that an instance's fields can be modified and additional fields can be added without affecting other instances.

### Features

- Add the `ZohoCRM::Utils::Copiable` module to `deep_clone` and `deep_dup` objects.
- Add a way to manually assign a static value to a model instance's field.
- Add a way to retrieve the value of a field from a model instance using the name of the field.
- Add a method to reset the state of a model instance to be the same as the one defined on the class.
  - Any static value assigned to fields will be discarded.
  - Any additional field on the instance will be discarded.

### Enhancements

- Customize the way `ZohoCRM::Model`, `ZohoCRM::FieldSet`, `ZohoCRM::Fields::Field` and `ZohoCRM::Fields::Enum` are cloned and dupped.

[v0.2.12](https://github.com/Tracktor/zoho-crm/tree/v0.2.12) (2019-08-23)
-------------------------------------------------------------------------

### Deprecations

- Deprecate the `ZohoCRM::Fields::Field.build` and `ZohoCRM::Fields::Enum.build` methods.<br>
 **They will be removed in version 0.3.0**.

[v0.2.11](https://github.com/Tracktor/zoho-crm/tree/v0.2.11) (2019-08-12)
-------------------------------------------------------------------------

### Features

- Add the ability to specify which workflows to trigger when creating, updating or upserting records.

### Fixes

- Don't "flatten" the body of requests to avoid breaking nested structures.

[v0.2.10](https://github.com/Tracktor/zoho-crm/tree/v0.2.10) (2019-07-19)
-------------------------------------------------------------------------

### Fixes

- Always use the .com region for the OAuth authorization URL

  All OAuth authorization request must be sent to https://www.accounts.zoho.com, even if the associated account is linked to the EU or IN domains.

  To quote the Zoho CRM API documentation:

  > You must make the authorization request from
  > https://www.accounts.zoho.com for EU and IN domains. After the request
  > is successful, the system automatically redirects you to your domain.

  Source: https://www.zoho.com/crm/developer/docs/api/auth-request.html

[v0.2.9](https://github.com/Tracktor/zoho-crm/tree/v0.2.9) (2019-07-16)
-----------------------------------------------------------------------

### Fixes

- Use the Zoho CRM configuration of the OAuth client instead of the default one when using the API client.

[v0.2.8](https://github.com/Tracktor/zoho-crm/tree/v0.2.8) (2019-07-16)
-----------------------------------------------------------------------

### Fixes

- Fix the Zoho CRM URL returned by the `ZohoCRM::API::Configuration#crm_url` method: The URL without a trailing slash (`/`) redirects to an error page on Zoho.

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
