getObjectClass = (obj) ->
    if (obj && obj.constructor && obj.constructor.toString)
       arr = obj.constructor.toString().match(
            /function\s*(\w+)/);

        if (arr && arr.length == 2)
            return arr[1]

    return undefined;


class Slider
  constructor: (@itemId, @managed=[]) ->
    @waiting = 0
    @stroke_re = new RegExp("stroke:[^;]+;", "g");
    @slider = $('#' + @itemId).slider
      value: 0
      orientation: "horizontal"
      min: 0
      max: 255
      length: 255
      animate: true
      # create: $.proxy(@onCreate, this)
      slide: $.proxy(@onSlide, this)
      change: $.proxy(@onChange, this)

  initialize: ->
    @onChange(null, value: 0)
    @onSlide(null, value: 0)

  onChange: (event, ui) ->
    that = this
    rioolgemalen = [{key: i.key} for i in @managed when i.key.indexOf("pomprg") == 0]
    #$.get "/api/update/?keys=#{rioolgemalen}",
    #    (data) -> that.updateLabels data
    $.post "/api/update/",
        timestamp: ui.value
        keys: rioolgemalen,
        (data) -> that.updateLabels data

  onSlide: (event, ui) ->
    for item in @managed
        key = item.key
        for candidate in item.value
          if candidate.timestamp > ui.value
            break
        @setStyleStroke(key, candidate.color)
    null

  updateLabels: (data) ->
    for key, value of data
        key = key.substr(4)
        $("#" + key)[0].childNodes[0].nodeValue = value

  manageObject: (item) ->
    that = this
    that.waiting += 1
    $.get "/api/bootstrap/?item=#{item}",
      (data) ->
        that.managed.push
          key: item
          value: data
        that.waiting -= 1
        if that.waiting == 0
          that.initialize()

  setStyleStroke: (itemId, value) ->
    item = $("#" + itemId)
    styleOrig = item.attr('style')
    item.attr('style', styleOrig.replace @stroke_re, "stroke:#{value};")


dec2hex = (i) ->
   ((i >> 0) + 0x10000).toString(16).substr(-2)


$('document').ready ->
  window.slider = new Slider('mySliderDiv')
  for element in $("path")
    if element.id.indexOf("leiding") == 0
      window.slider.manageObject(element.id)
  for element in $("circle")
    if element.id.indexOf("pomprg") == 0
      window.slider.manageObject(element.id)
