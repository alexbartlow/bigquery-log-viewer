window.BigQueryLogViewer ||= {}

class BigQueryLogViewer.TabManagerResource
  constructor: ->
    @tabs = []
    @activeTabIndex = null

  setActiveTab: (index) ->
    @activeTabIndex = index

  activeTab: ->
    return null if @activeTabIndex == null
    @tabs[@activeTabIndex]

  addTab: (tab) ->
    if tab.expansionTab()
      tab.setSource(@activeTab())
    position = 
      if @activeTabIndex == null
        0
      else
        @activeTabIndex + 1
    @tabs.splice(position, 0, tab)
    position
    
  deleteTab: (index) ->
    @tabs.splice(index, 1)
    if index <= @activeTabIndex
      @activeTabIndex -= 1
    if @activeTabIndex < 0
      @activeTabIndex =
        if @numTabs() > 0
          0
        else
          null

  numTabs: ->
    @tabs.length

  findResultsTab: (term, startDate, endDate) ->
    (index for tab, index in @tabs when tab.resultsTab() && tab.term is term && tab.startDate is startDate && tab.endDate == endDate)[0]

  findExpansionTab: (rid) ->
    (index for tab, index in @tabs when tab.expansionTab() && tab.source == @activeTab() && tab.isHighlighted(rid))[0]