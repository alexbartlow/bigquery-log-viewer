[![Gem Version](https://badge.fury.io/rb/big_query_log_viewer.svg)](http://badge.fury.io/rb/big_query_log_viewer)

# BigQueryLogViewer

A simple Rails engine and React app to search logs stored in Google BigQuery.

![BigQuery Log Viewer](https://cloud.githubusercontent.com/assets/1896112/9646564/7877bcda-519a-11e5-8bfb-bc34dc93de9e.png)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'big_query_log_viewer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install big_query_log_viewer

## Usage

Run the generator to create your initialization file:

    $ rails generate big_query_log_viewer:install

Open the newly created file, `config/initializers/big_query_log_viewer.rb`, and add your client ID, project number, and table prefix from the [Google Developer Console](https://console.developers.google.com).

Finally, mount the engine by adding the following to your application's `routes.rb`: 

`mount BigQueryLogViewer::Engine, at: '/some_url'`

## Linting

The project uses [coffeelint](http://www.coffeelint.org/) to maintain quality CoffeeScript syntax. It is configured to run as the default rake task.

## Authorship

Written by Zach Schneider, based on prototype by Chris Waters, for [Aha!, the world's #1 product roadmap software](http://www.aha.io/)

## Contributing

1. Fork it ( https://github.com/aha-app/bigquery-log-viewer/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
