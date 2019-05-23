zoho-crm
========

A gem to make working with Zoho CRM less painful.

Requirements
------------

This gem requires Ruby version 2.5 or greater.

Installation
------------

Add this line to your application's Gemfile:

```ruby
gem "zoho-crm", require: "zoho_crm"
```

And then execute:

```console
$ bundle
```

Usage
-----

### Quickstart

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

Development
-----------

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version and push git commits and tags.

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

Tests are written using [RSpec][]. The default Rake task is setup to run the test suite:

```console
$ rake
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
