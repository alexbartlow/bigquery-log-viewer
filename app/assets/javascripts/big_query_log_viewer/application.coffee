#= require react
#= require jquery

#= require ./components/tab_manager

window.randomId = ->
  Math.floor(Date.now() / 1000).toString(16) + Math.random().toString(16).slice(2,10)

window.BigQueryLogViewer ||= {}

TabManager = BigQueryLogViewer.TabManager

class BigQueryLogViewer.App
  constructor: (@projectId, @clientId, @tablePrefix, @rowsPerPage) ->
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
    React.render(React.createElement(TabManager, props), $('#application')[0])
