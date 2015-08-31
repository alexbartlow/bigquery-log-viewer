#= require ./components/tab_manager

window.BigQueryLogViewer ||= {}

TabManager = BigQueryLogViewer.TabManager

class BigQueryLogViewer.ApiManager
  constructor: (@projectId, @clientId, @tablePrefix, @rowsPerPage, @nearbyRows) ->
    config =
      'client_id': @clientId,
      'scope': 'https://www.googleapis.com/auth/bigquery'
      immediate: true

    # Perform authentication.
    gapi.auth.authorize(config, (result) ->
      if result.error
        config.immediate = false
        $('#authenticate-btn').show()
        $('#authenticate-btn').on 'click', ->
          gapi.auth.authorize(config, (result) ->
            unless result.error
              gapi.client.load('bigquery', 'v2')
              $('#application').fadeIn()
              $('#authenticate-btn').hide()
          )
      else
        gapi.client.load('bigquery', 'v2')
        $('#application').fadeIn()
        $('#authenticate-btn').hide()
    )

    # Create React element.
    props =
      projectId: @projectId
      tablePrefix: @tablePrefix
      rowsPerPage: @rowsPerPage
      nearbyRows: @nearbyRows
    React.render(React.createElement(TabManager, props), $('#application')[0])
