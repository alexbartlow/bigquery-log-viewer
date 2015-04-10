window.BigQueryLogViewer ||= {}

class BigQueryLogViewer.TabResource
  constructor: (firstPage) ->
    @pages = [firstPage]
    @activePageIndex = 0

  activePage: ->
    @pages[@activePageIndex]

  activePageData: ->
    @pages[@activePageIndex].rowData

  resultsTab: ->
    @tabType == "results"

  expansionTab: ->
    @tabType == "expansion"