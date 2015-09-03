require 'rails/generators/base'

module BigQueryLogViewer
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../../templates', __FILE__)

      desc 'Creates a BigQueryLogViewer initializer.'

      def copy_initializer
        template 'big_query_log_viewer.rb', 'config/initializers/big_query_log_viewer.rb'
      end
    end
  end
end