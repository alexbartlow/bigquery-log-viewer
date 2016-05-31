###* @jsx React.DOM ###

window.BigQueryLogViewer ||= {}

BigQueryLogViewer.SearchBox = React.createClass
  handleSearch: (e) -> 
    e.preventDefault()
    @props.handleSearch
      @refs.searchInput.getDOMNode().value,
      @refs.startDate.getDOMNode().value,
      @refs.endDate.getDOMNode().value,
      @refs.userId.getDOMNode().value,
      @refs.accountId.getDOMNode().value

  render: ->
    return (
      <form className='navbar-form search-box form-inline' onSubmit={@handleSearch}>
        <div className='controls'>
          <input ref='searchInput' placeholder={'Term'} />
          Start Date: <input ref='startDate' type='date' />
          End Date: <input ref='endDate' type='date' />
          <input ref="userId", placeholder={'UserID'}/>
          <input ref="accountId", placeholder={"AccountID"}/>
          <input type='submit' value='Search' className='btn btn-primary' />
        </div>
      </form>
    )
