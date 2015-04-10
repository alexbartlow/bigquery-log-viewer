###* @jsx React.DOM ###

window.BigQueryLogViewer ||= {}

BigQueryLogViewer.SearchStatus = React.createClass
  render: ->
    if @props.queryInProgress
      progress = `<span>Query running...</span>`
    else if @props.errorMessage
      progress = `<span className="error">{this.props.errorMessage}</span>`      
    else if !@props.queryInProgress and @props.numReturnedResults?
      results = `<span>Found {this.props.numReturnedResults} results</span>`
    `<div className="query-status">
      {progress}
      {results}
    </div>`