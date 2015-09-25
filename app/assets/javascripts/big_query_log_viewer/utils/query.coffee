window.BigQueryLogViewer ||= {}

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

  executeQuery: (query, config, success, error) ->
    console.log("Executing query: #{query}")
    config.maxResults ||= 1000
    request = gapi.client.bigquery.jobs.query
      projectId: @projectId
      timeoutMs: 30000
      maxResults: config.maxResults
      query: query

    request.execute (response) ->
      if response.error
        error(response) if error?
      else
        success(response) if success?

  executeListQuery: (config, success, error) ->
    console.log('Executing list query')
    config.maxResults ||= 1000
    request = gapi.client.bigquery.jobs.getQueryResults
      projectId: @projectId
      jobId: config.jobId
      timeoutMs: 30000
      maxResults: config.maxResults
      pageToken: config.pageToken

    request.execute (response) ->
      if response.error
        error(response) if error?
      else
        success(response) if success?