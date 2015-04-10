window.BigQueryLogViewer ||= {}

class BigQueryLogViewer.RowResource
  constructor: (@timestamp, @host, @pid, @rid, @severity, @msg) ->
    @timestamp = new Date(1000 * @timestamp)
    @rid = parseInt(@rid)

  key: ->
    "#{@pid}-#{@rid}"

  tss: ->
    @timestamp.toString("dd MMM HH:mm:ss")
  
  tsm: ->
    s = "000" + @timestamp.getMilliseconds()
    s.substr(s.length - 3)

  longMsg: ->
    @msg.length > 200

  msgPrefix: ->
    @msg.substring(0,200)

  msgSuffix: ->
    @msg.substring(200)