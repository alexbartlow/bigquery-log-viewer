#= require ./tab_resource

window.BigQueryLogViewer ||= {}

class BigQueryLogViewer.ResultsTabResource extends BigQueryLogViewer.TabResource
  constructor: (..., @term, @jobId, @startDate, @endDate) ->
    super
    @tabType = "results"

  title: ->
    if @startDate == null && @endDate == null
      "Search results: #{@term}"
    else
      "Search results: #{@term} (#{@startDate} to #{@endDate})"

  addPage: (page) ->
    @pages.push(page)

  setActivePage: (newActivePage) ->
    @activePageIndex = newActivePage

  nextPage: ->
    @activePageIndex += 1 unless @activePageIndex + 1 >= @pages.length

  prevPage: ->
    @activePageIndex -= 1 unless @activePageIndex - 1 < 0

  numPages: ->
    @pages.length

  nextPageLoaded: ->
    @numPages() > @activePageIndex + 1

  hasNextPage: ->
    @pages[@pages.length - 1].pageToken != undefined

  hasPrevPage: ->
    @activePageIndex > 0

  activePageToken: ->
    @pages[@activePageIndex].pageToken