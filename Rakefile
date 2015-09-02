begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

load 'rails/tasks/statistics.rake'

Bundler::GemHelper.install_tasks

require 'coffeelint'

task :coffeelint do
  Coffeelint.lint_dir(File.join('app', 'assets', 'javascripts', 'big_query_log_viewer')) do |filename, lint_report|
      Coffeelint.display_test_results(filename, lint_report)
  end
end

task default: :coffeelint
