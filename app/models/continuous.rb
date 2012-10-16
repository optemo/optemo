class Continuous < Facet
  def ranges
    return nil unless ui == "ranges"
    cache_name = Session.quebec && name == "saleprice" ? :pricePlusEHF : name.to_sym #Substitude EHF price for regular price
    ranges = Ranges.cache[cache_name]
    if name == "saleprice"  # saleprice ranges are hard-coded, so no need to process them given the selection
      ranges = ranges.map!{|r| FloatRange.new(r.min.round(2),r.max.round(2),name)}
    else
      ranges = Ranges.modifyRanges(selected.map(&:range), ranges, name)
    end
    ranges
  end
  
  #Does the distribution have just a single value?
  def single_value
    return nil if ui == 'ranges'
    distribution.first[2] != distribution.first[3] ? nil : distribution.first[2]
  end
  
  def sliderSettings
    step = calcInterval(distribution.first[2].floor,distribution.first[3].ceil)
    fname = name == "pricePlusEHF" ? "saleprice" : name
    {current: Maybe(Session.search.userdataconts.select{|m|m.name == name}.first),
    step: step,
    datamin: roundedInterval(distribution.first[2],step,true),
    datamax: roundedInterval(distribution.first[3],step,false),
    unit: I18n.t("#{Session.product_type}.filter.#{fname}.unit") || ''}
  end
  
  def no_display
    if ui == "ranges"
      !ranges.inject(false){|res,e| res || e.count > 0}
    else #Sliders
      distribution.blank?
    end
  end
  
  def distribution
    return [] if ui == 'ranges'
    num_buckets = 24
    discretized = Session.search.solr_search(mycats: Session.search.userdatacats, mybins: Session.search.userdatabins, myconts: Session.search.userdataconts).facet(name.to_sym).rows
    if (!discretized.empty?)
      min_all = Rails.cache.fetch("Min#{Session.search.keyword_search}#{Session.product_type}#{name}") {discretized.first.value}
      max_all = Rails.cache.fetch("Max#{Session.search.keyword_search}#{Session.product_type}#{name}") {discretized.last.value}
      saved_cont = Session.search.userdataconts.find{|m|m.name == name}
      if saved_cont.nil?
        min = discretized.first.value
        max = discretized.last.value
      else
        min = saved_cont.min
        max = saved_cont.max
      end
      step = (max_all - min_all + 0.00000001) / num_buckets
      dist = Array.new(num_buckets,0)
      #Bucket the data
      dist.each_with_index do |bucket,i|
        low = min_all + step * i
        high = low + step
        sum = 0
        if (min..max) === low or (min..max) === high
          sum = discretized.select{|p| (low..high)===p.value and (min..max)===p.value }.inject(0){|res,ele| res+ele.count}
        end
        dist[i] = sum
      end
      unless discretized.select{|p| (min..max)===p.value }.empty?
        dataMin = discretized.select{|p| (min..max)===p.value }.first.value
        dataMax = discretized.select{|p| (min..max)===p.value }.last.value
      else
        dataMin = min
        dataMax = max
      end
      #Normalize to a max of 1
      maxval = dist.max
      dist.map!{|i| i.to_f / maxval}
      [[dataMin,dataMax]+[min_all,max_all],dist]
    else
      []
    end
  end
  
  def selected
    (Session.search.userdataconts+Session.search.parentconts).select{|d| d.name == name}
  end
  
  private

  def calcInterval(min,max)
    range = max - min
    interval = 0
    [1000, 500, 100, 50, 10, 5, 1, 0.5, 0.1, 0.05, 0.01].each do |s|
      interval = s
      break if range/s > 30 #30 was selected arbitrarly, so that it looks good in the sliders
    end
    interval
  end
  
  def roundedInterval(val,interval,down = true)
    if down
      (val/interval).floor*interval
    else
      (val/interval).ceil*interval
    end
  end
end
