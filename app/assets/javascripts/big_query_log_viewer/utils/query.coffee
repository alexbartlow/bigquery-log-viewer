window.BigQueryLogViewer ||= {}

timeoutMS = 1000

class BigQueryLogViewer.Query
  constructor: (@projectId, @tablePrefix) ->
    #

  tableRange: (startDate='CURRENT_TIMESTAMP()', endDate='CURRENT_TIMESTAMP()') ->
    startDate = "TIMESTAMP('#{startDate} 00:00:00')" unless startDate == "CURRENT_TIMESTAMP()"
    endDate = "TIMESTAMP('#{endDate} 23:59:59')" unless endDate == "CURRENT_TIMESTAMP()"

    "(SELECT * FROM TABLE_DATE_RANGE(logs.#{@tablePrefix}_, #{startDate}, #{endDate}))"

  buildQuery: (startDate, endDate, conds, order) ->
    # Construct conditions.
    conds =
      for cond in conds
        value = cond.value.replace(/[\\"']/g, '\\$&').replace(/\u0000/g, '\\0') if cond.value
        switch cond.method
          when 'contains' then "#{cond.field} contains '#{value}'"
          when 'equals'
            if cond.type == 'string'
              "#{cond.field} = '#{value}'"
            else
              "#{cond.field} = #{value}"
          when 'between' then "#{cond.field} between #{cond.firstValue} and #{cond.secondValue}"

    q = "SELECT ts, rid, sev, pid, host, msg FROM #{@tableRange(startDate, endDate)}"
    q = "#{q} WHERE #{conds.join(' AND ')}" if conds.length > 0
    q = "#{q} ORDER BY #{order}" if order
    q

  pollJobUntilFinished: (jobReference, config, success, error) ->
    request = gapi.client.bigquery.jobs.getQueryResults
      projectId: jobReference.projectId,
      jobId: jobReference.jobId,
      maxResults: config.maxResults
      timeoutMs: config.timeoutMS

    @handleResponseAndPollIfNecessary(request, config, success, error)

  handleResponseAndPollIfNecessary: (request, config, success, error) ->
    request.execute (response) =>
      if response.error
        return error(response) if error?
      if response.jobComplete
        # Query finished correctly, we are ready to go
        success(response) if success?
      else
        config.jobReference ||= response.jobReference
        document.getElementById("runningQuery").textContent = "Query Running... (#{(Date.now() - config.startDate) / 1000.0 }sec elapsed)"
        # poll until BQ is done thinking
        fx = => @pollJobUntilFinished(config.jobReference, config, success, error)
        setTimeout(fx, config.timeoutMS)

  executeQuery: (query, config, success, error) ->
    console.log("Executing query: #{query}")
    config.maxResults ||= 1000
    config.startDate = Date.now()
    config.timeoutMS ||= timeoutMS
    request = gapi.client.bigquery.jobs.query
      projectId: @projectId
      timeoutMs: config.timeoutMS
      maxResults: config.maxResults
      query: query
    @handleResponseAndPollIfNecessary(request, config, success, error)

  executeListQuery: (config, success, error) ->
    console.log('Executing list query')
    config.maxResults ||= 1000
    config.startDate = Date.now()
    request = gapi.client.bigquery.jobs.getQueryResults
      projectId: @projectId
      jobId: config.jobId
      timeoutMs: timeoutMS
      maxResults: config.maxResults
      pageToken: config.pageToken
    @handleResponseAndPollIfNecessary(request, config, success, error)