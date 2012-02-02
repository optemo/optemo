# Optemo Sliders
@module "optemo_module", ->
  #****Public Functions****
  @SliderInit = ->
    $('.slider').each ->
      t = $(this)
      min = parseFloat(t.attr('data-min'))
      max = parseFloat(t.attr('data-max'))
      mystep = parseFloat(t.attr('data-step'))

      t.slider
        from: min
        to: max
        step: mystep
        smooth: true
        round: if mystep >= 1 then 0 else if mystep * 10 >= 1 then 1 else 2
        dimension: " "+t.attr('data-unit')
        skin: "plastic"
        callback: (value) ->
          #Remove a feature selection that has been undone
          [curmin,curmax] = (parseFloat(i) for i in value.split(";"))
          if curmin == min && curmax == max
            t.parent().siblings('.range').val(";")
          else
            t.parent().siblings('.range').val(value)
          optemo_module.submitAJAX() #Auto-submit
        movable: (value) ->
          [curmin,curmax] = (parseFloat(i) for i in value.split(";"))
          curmin <= parseFloat(t.attr('data-distmax')) and curmax >= parseFloat(t.attr('data-distmin'))
        calculate: (value, label) ->
          #GB / TB conversion
          if label?
            unitmatch = /[GT]([Bo])/.exec(label.html())
            if unitmatch
              if value >= 1000
                value = value / 1000
                this.settings.round = 1
                label.html "T"+unitmatch[1]
              else
                this.settings.round = 0
                label.html "G"+unitmatch[1]
          value = value.toString()
            .replace(/,/gi, ".")
            .replace(/\ /gi, "")
          if( Number.prototype.jSliderNice )
            (new Number(value)).jSliderNice(this.settings.round).replace(/-/gi, "&minus;")
          else
            new Number(value)

      histogram(t.parent().siblings('.hist')[0])

  #Private functions
    
  #Draw slider histogram, called for each slider above
  histogram = (element, norange) ->
    raw = $(element).attr('data-data')
    if (raw)
      data = raw.split(',')
    else
      data = [0.5,0.7,0.1,0,0.3,0.8,0.6,0.4,0.3,0.3]
    #Data is assumed to be 10 normalized elements in an array
    length = 170
    height = 20
    step = 6
    shapelayer = Raphael(element,length,height)
    h = height - 1
    t = shapelayer.path
      fill: "#bad0f2"
      stroke: "#039"
      opacity: 0.75
    t.moveTo(0,height);
    pos = 7 #Initial value
    for d in data
      t.cplineTo(pos,h*(1-d)+1,5)
      t.lineTo(pos,h*(1-d)+1)
      pos += step
    t.cplineTo(pos+1,height,5)
    t.andClose()