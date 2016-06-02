###* @jsx React.DOM ###

window.BigQueryLogViewer ||= {}

BigQueryLogViewer.SearchBox = React.createClass
  getInitialState: ->
    {
      terms: []
    }

  handleSearch: (e) ->
    e.preventDefault()
    value = @refs.searchInput.getDOMNode().value
    search_terms = @state.terms.slice(0)
    if value isnt ""
      search_terms.push(value)
      @refs.searchInput.getDOMNode().value = ""
      @setState(terms: search_terms)

    @props.handleSearch( search_terms, @refs.startDate.getDOMNode().value, @refs.endDate.getDOMNode().value, @refs.userId.getDOMNode().value, @refs.accountId.getDOMNode().value)

  handleKeyDown: (event) ->
    if event.keyCode == 8
      console.log "backspace from keydown"
    if event.keyCode == 13 && event.shiftKey
      console.log "shift enter"
      event.stopPropagation()
      event.preventDefault()

      terms = @state.terms.slice(0)
      terms.push(event.target.value)
      @setState(terms: terms)
      event.target.value = ""

  handleKeyUp: (event) ->
    if event.keyCode == 8 && event.target.selectionStart == 0 && event.shiftKey
      terms = @state.terms.slice(0)
      terms.pop()
      @setState(terms: terms)

  componentDidMount: ->
    node = @refs.searchInput.getDOMNode()
    addEvent = node.addEventListener || node.attachEvent
    addEvent("keypress", @handleKeyDown, false)
    addEvent("keyup", @handleKeyUp, false)

  componentWillUnmount: ->
    node = @refs.searchInput.getDOMNode()
    removeEvent = node.removeEventListener || node.detachEvent
    removeEvent("keypress", @handleKeyPress)
    removeEvent("keyup", @handleKeyUp)

  onRemoveTerm: (term) ->
    terms = @state.terms.slice(0)
    terms.splice(terms.indexOf(term), 1)
    @setState(terms: terms)

  render: ->
    endDate = new Date()
    startDate = new Date()
    startDate.setDate(endDate.getDate() - 1)

    return (
      <form className='navbar-form search-box form-inline' onSubmit={@handleSearch}>
        <div className='controls'>
          <div className="searchInput">
            { @state.terms.map (term, i) =>
              <span className="term" key={"#{term}-#{i}"} onClick={@onRemoveTerm.bind(@, term)}>
                {term}
              </span>
            }
            <input ref='searchInput' tabIndex='1' placeholder={'Term. Shift enter adds new term. Shift-Backspace or click to remove term.'} />
          </div>
          <input ref='startDate' type='date' defaultValue={startDate.toISOString().slice(0,10)} />
          &mdash;
          <input ref='endDate' type='date' defaultValue={endDate.toISOString().slice(0,10)} />
          <input className="padded" ref="userId", placeholder={'UserID'}/>
          <input className="padded" ref="accountId", placeholder={"AccountID"}/>
          <input type='submit' value='Search' className='btn btn-primary' />
        </div>
      </form>
    )
