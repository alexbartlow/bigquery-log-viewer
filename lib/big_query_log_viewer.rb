require "big_query_log_viewer/engine"

module BigQueryLogViewer
  mattr_accessor :project_number, :client_id, :table_prefix, :rows_per_page
end
