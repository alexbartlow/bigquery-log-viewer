###* @jsx React.DOM ###

window.BigQueryLogViewer ||= {}

BigQueryLogViewer.SearchBox = React.createClass
  handleSubmit: (e) -> 
    e.preventDefault()
    @props.handleSubmit(@refs.searchInput.getDOMNode().value, @refs.startDate.getDOMNode().value, @refs.endDate.getDOMNode().value)
    
  render: ->
    `<form className="search-box form-inline" onSubmit={this.handleSubmit}>
      <div className="controls">
        Term: <input ref="searchInput" /> | 
        Start Date: <input ref="startDate" type="date" /> | 
        End Date: <input ref="endDate" type="date" /> | <input type="submit" value="Search" className="btn btn-primary" />
      </div>
    </form>`
