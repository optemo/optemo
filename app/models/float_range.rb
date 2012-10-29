class FloatRange
  attr_accessor :min, :max, :fname
  include ActionView::Helpers::NumberHelper
  include Comparable
  
  def initialize(min, max, fname = nil, precision=1)
    @min = min
    @max = max
    @fname = fname
    @precision = precision
  end
  
  def <=>(a)
    #Precedence for min, then max, then fname
    cmp = min <=> a.min
    if cmp == 0
      cmp = max <=> a.max
      if cmp == 0
        fname <=> a.fname
      else
        cmp
      end
    else
      cmp
    end
  end
  
  def count
    Ranges.count(@fname, min, max)
  end
  
  def unit
    @unit ||= I18n.t("#{Session.product_type}.filter.#{@fname == "pricePlusEHF" ? "saleprice" : @fname}.unit") unless @fname.nil?
  end
  
  def to_s
    if min == max
      res = prettify(min)
    else
      res = [min,max].map{|n|prettify(n)}.join(" - ")
    end
    res += " #{unit}" unless @fname == "saleprice" || @fname == "pricePlusEHF"
    res
  end
  
  private
  
  def prettify(n)
    if @fname == "saleprice" || @fname == "pricePlusEHF"
      if (n.to_i == n)
        number_to_currency(n, precision: 0)
      else
        number_to_currency(n)
      end
    else
      number_with_precision(conversions(n), precision: @precision, strip_insignificant_zeros: true)
    end
  end
  
  def conversions(n)
    #Capacity terabyte
    if @fname == "capacity" && n >= 1000
      n = n.to_f / 1000
      @unit = I18n.t("number.human.storage_units.units.tb")
    end
    n
  end
end