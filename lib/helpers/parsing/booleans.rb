#BOOLEANS
#   infer_boolean bool_property, indicator_properties, atts, default=nil
#   get_b x

module BooleanHelper
  # Converts a string to a boolean where possible
  def get_b x
    return nil if x.nil?
    trues = ["yes", 'y',"1", 'true', 'optional']
    falses = ["no", 'n', "0", 'false']
    if trues.include? x.to_s.downcase.strip
      val = true
    elsif falses.include? x.to_s.downcase.strip
      val = false
    else
      val = nil
    end
    return val
  end
end 