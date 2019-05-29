Example
=======

This is an example application using the `zoho-crm` gem.

Usage
-----

### 1. Install the dependencies

```console
$ bundle install
```

### 2. Add the Zoho API configuration

Copy the `.env.example` file and replace the dummy values with the Zoho API configuration of your registered client.

```console
$ cp .env.example .env
```

### 3. Run the application server

```console
$ ./server
```

By default, the server will run on port 4562. You can specify another port as the first argument:

```console
$ ./server 9292
```
