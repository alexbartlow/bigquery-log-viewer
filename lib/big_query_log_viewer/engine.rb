module BigQueryLogViewer
  class Engine < ::Rails::Engine
    isolate_namespace BigQueryLogViewer
    
    require 'less-rails'
    require 'react-rails'
    require 'jquery-rails'
  end
end
