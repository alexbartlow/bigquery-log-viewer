###* @jsx React.DOM ###

#= require ./expansion_tab
#= require ./results_tab
#= require ./search_box
#= require ./search_status

window.BigQueryLogViewer ||= {}

ExpansionTab = BigQueryLogViewer.ExpansionTab
ResultsTab = BigQueryLogViewer.ResultsTab
SearchBox = BigQueryLogViewer.SearchBox
SearchStatus = BigQueryLogViewer.SearchStatus

BigQueryLogViewer.TabManager = React.createClass
  getInitialState: ->
    BigQueryLogViewer.tabManagerComponent = @

    {
      tabManager: null
      queryInProgress: false
      numReturnedResults: null
      errorMessage: null
    }

  handleTabSwitch: (event) ->
    @state.tabManager.setActiveTab(parseInt(event.dispatchMarker.split("tab-name-")[1]))
    @forceUpdate()

  handleDeleteTab: (event) ->
    @state.tabManager.deleteTab(parseInt(event.dispatchMarker.split("tab-name-")[1]))
    @forceUpdate()

  render: ->
    # Functions to be passed to children.
    showProximity = (row) =>
      # Check to see if we've already queried this row proximity.
      if (foundTab = @state.tabManager.findExpansionTab(row.rid)) != undefined
        @state.tabManager.setActiveTab(foundTab)
        @forceUpdate()
      else
        BigQueryLogViewer.apiManager.showProximity(row)

    handleSubmit = (term, startDate, endDate) =>
      return if term == ""
      startDate = null if startDate == ""
      endDate = null if endDate == ""
      
      # Check to see if we've already searched this term.
      if (foundTab = @state.tabManager.findResultsTab(term, startDate, endDate)) != undefined
        @state.tabManager.setActiveTab(foundTab)
        @forceUpdate()
      else
        BigQueryLogViewer.apiManager.search(term, startDate, endDate)

    showBefore = =>
      @state.tabManager.activeTab().setShowBefore()
      @forceUpdate()

    showAfter = =>
      @state.tabManager.activeTab().setShowAfter()
      @forceUpdate()

    showNextPage = =>
      BigQueryLogViewer.apiManager.nextPage()

    showPrevPage = =>
      @state.tabManager.activeTab().prevPage()
      @forceUpdate()

    showPage = (page) =>
      @state.tabManager.activeTab().setActivePage(page)
      @forceUpdate()

    # Create tab bar.
    if @state.tabManager
      tabNames = []
      for tab, index in @state.tabManager.tabs
        tabClass = 
          if tab == @state.tabManager.activeTab()
            "tab-active"

        tabDivider =
          if tabNames.length > 0
            <div className={"tab-divider"}>|</div>

        tabNames.push(
          <div key={"tab-name-" + index} className={tabClass}>
            {tabDivider}
            <div onClick={@handleTabSwitch}>
              {tab.title()}
            </div>
            <div>
              <a onClick={@handleDeleteTab}>X</a>
            </div>
          </div>
        )

      tabDiv =
        if tabNames.length > 0
          <div className="tabBar">
            {tabNames}
          </div>

      # Create tab to be displayed.
      activeTab =
        if (tab = @state.tabManager.activeTab())
          if tab.resultsTab()
              <ResultsTab key={"tab-" + index} tab={tab} showProximity={showProximity} showNextPage={showNextPage} showPrevPage={showPrevPage} showPage={showPage} />
            else
              <ExpansionTab key={"tab-" + index} tab={tab} setShowBefore={showBefore} setShowAfter={showAfter} />

    return (
      <div>
        <div className={"fixed-top"}>
          <SearchBox handleSubmit={handleSubmit} />
          <SearchStatus queryInProgress={@state.queryInProgress} numReturnedResults={@state.numReturnedResults} errorMessage={@state.errorMessage} />
          {tabDiv}
        </div>
        <div className={"tabs"}>
          {activeTab}
        </div>
      </div>
    )