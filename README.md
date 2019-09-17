zoho-crm
========

A gem to make working with Zoho CRM less painful.

Requirements
------------

This gem requires Ruby version 2.6 or greater.

Installation
------------

Add this line to your application's Gemfile:

```ruby
gem "zoho-crm"
```

And then execute:

```console
$ bundle install
```

Usage
-----

### Quickstart

#### `ZohoCRM::Model`

```ruby
require "zoho_crm"

class ZohoUser < ZohoCRM::Model
  zoho_module "Contact"
  zoho_field :email, as: "Email_Address"
  zoho_field :full_name do |user|
    "#{user.first_name} #{user.last_name}"
  end
end

user = User.new(email: "john.smith@example.com", first_name: "John", last_name: "Smith")
zoho_user = ZohoUser.new(user)
json = zoho_user.as_json
```

---

#### `ZohoCRM::API`

```ruby
require "zoho_crm"

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

# OAuth authorization flow... (see the example app)

# Get a record
api_client.show("12345", module_name: "Contacts")

# Create a new record
contact_attributes = {
  "Email" => "hello.world@example.com",
  "First_Name" => "Mister",
  "Last_Name" => "World",
  "Phone" => "+33 6 12 34 56 78",
}
api_client.create(contact_attributes, module_name: "Contacts")

# Update a record
api_client.update("12345", {"First_name" => "John"}, module_name: "Contacts")

# Insert or Update a record (Upsert)
contact_attributes = {
  "Email" => "hello.world@example.com",
  "First_Name" => "Mister",
  "Last_Name" => "World",
  "Phone" => "+33 6 12 34 56 78",
}
api_client.upsert(contact_attributes, module_name: "Contacts", duplicate_check_fields: ["Email"])

# Delete a record
api_client.destroy("12345", module_name: "Contacts")
```

For a more complete example, look at the [example application](./example).

Development
-----------

After checking out the repo, run [`bin/setup`](./bin/setup) to install dependencies. Then, run `rake spec` to run the tests. You can also run [`bin/console`](./bin/console) for an interactive prompt that will allow you to experiment.

The default Rake task is setup to run the test suite then link the code:

```console
$ rake
```

### Dependencies

Development dependencies are in the gem specification — see the [`zoho-crm.gemspec`](./zoho-crm.gemspec) file. If you need to add a dependency, add it to that file. **Do not add any gem to the Gemfile**.

```ruby
spec.add_development_dependency "faker", "~> 1.9"
```

### Code style

The [standard][] gem is used to enforce coding style. A Rake task is available to check the code style:

```console
$ rake standard
```

There is also a Rake task to fix code style offenses:

```console
$ rake standard:fix
```

[standard]: https://github.com/testdouble/standard

### Tests

Tests are written using [RSpec][]. You can run the test suite using the dedicated Rake task:

```console
$ rake spec
```

[RSpec]: https://rspec.info/

### Documentation

The API documentation is generated using [YARD][]:

```console
$ rake yard
```

The documentation files will be generated under the `doc/` directory. You can browse the documentation by opening `doc/index.html` in a browser.

[YARD]: https://yardoc.org/

Contributing
------------

Bug reports and pull requests are welcome on GitHub at https://github.com/Tracktor/zoho-crm.
