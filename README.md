# BigQueryLogViewer

A Rails engine to mount a user interface to search for logs stored in Google BigQuery.

## Installation

Add the gem to your Gemfile and bundle:

`gem 'big_query_log_viewer', github: 'aha-app/bigquery-log-viewer'`

Run the generator to create your initialization file:

`rails generate big_query_log_viewer:install`

Open the newly created file, `config/initializers/big_query_log_viewer.rb`, and add your client ID, project number, and table prefix from the [Google Developer Console](https://console.developers.google.com).

Finally, mount the engine by adding the following to your application's `routes.rb`: 

`mount BigQueryLogViewer::Engine, at: '/some_url'`

## Contributing

1. Fork it ( https://github.com/aha_app/bigquery-log-viewer/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request