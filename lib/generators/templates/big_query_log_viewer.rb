# Configuration settings for BigQueryLogViewer.

# Your client ID from the Google developer console.
BigQueryLogViewer.client_id = ''

# Your project number from the Google developer console.
BigQueryLogViewer.project_number = ''

# The prefix of your table.
# Assumes the suffix is the log date - so if each table is named as 'app_logs_YYYY-MM-DD' 
# then you would put 'app_logs' here
BigQueryLogViewer.table_prefix = ''

# The number of rows to display on each results page.
BigQueryLogViewer.rows_per_page = 100

# The number of nearby rows to show in each direction when a row is expanded.
BigQueryLogViewer.nearby_rows = 500