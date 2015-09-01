###* @jsx React.DOM ###

window.BigQueryLogViewer ||= {}

BigQueryLogViewer.SearchBox = React.createClass
  handleSearch: (e) -> 
    e.preventDefault()
    @props.handleSearch(@refs.searchInput.getDOMNode().value, @refs.startDate.getDOMNode().value, @refs.endDate.getDOMNode().value)
    
  render: ->
    return (
      <form className='search-box form-inline' onSubmit={@handleSearch}>
        <div className='controls'>
          Term: <input ref='searchInput' /> | 
          Start Date: <input ref='startDate' type='date' /> | 
          End Date: <input ref='endDate' type='date' /> | <input type='submit' value='Search' className='btn btn-primary' />
        </div>
      </form>
    )
