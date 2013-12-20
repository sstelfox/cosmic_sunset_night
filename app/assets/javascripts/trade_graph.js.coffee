
class GraphClient
  _data: ->
    return @_data_cache unless @_data_cache == undefined

    request_object = new XMLHttpRequest
    request_object.open("GET", "/api/v1/trade_data.json", false)
    request_object.send(null)

    if request_object.status == 200
      @_data_cache = JSON.parse(request_object.responseText)

    return @_data_cache

  draw: ->
    d3.select("#avg-graph").data(this._data()).enter().append("div")
      .attr("class", "bar").style("height", (d) =>
        "#{d * 5}.px"
      )

(exports ? this).GraphClient = GraphClient
