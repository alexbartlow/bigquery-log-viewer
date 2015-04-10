#= require ./tab_resource

window.BigQueryLogViewer ||= {}

class BigQueryLogViewer.ExpansionTabResource extends BigQueryLogViewer.TabResource
  constructor: (..., @highlightRid, @msg) ->
    super
    @tabType = "expansion"
    @highlightRid = parseInt(@highlightRid)
    @showBefore = false
    @showAfter = false
    @source = null

  title: ->
    @msg.substr(0, 30) + "..."

  setShowBefore: ->
    @showBefore = true

  setShowAfter: ->
    @showAfter = true

  firstRid: ->
    @activePageData()[0].rid

  lastRid: ->
    @activePageData()[@activePageData().length - 1].rid

  isHighlighted: (rid) ->
    parseInt(rid) == @highlightRid

  setSource: (sourceTab) ->
    @source = sourceTab