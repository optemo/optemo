#CAMERA PARSING (Lenses, Display size, )
#   focal_lengths_to_zoom str
#   parse_ozoom str
#   get_inches str
#   to_mpix res
#   parse_res str
#   parse_lens str





# Gets the zoom of a lens given a string describing
# the lens and containing the lens' focal lengths.
def parse_lens str
  return nil if str.nil?
  lens_substr = str.scan(/with.*?\d+?.*?\d+?.*?lens/i).to_s #  || str
  return nil if lens_substr.nil?
  lens_params = lens_substr.match(/\d+(mm)?\s?-?\s?\d+(mm)?/).to_s
  return nil if lens_substr.nil? or lens_substr.strip == ""
  zoom = focal_lengths_to_zoom(lens_params)
  return zoom
end

# Given just the string that describes focal lengths of a single
# lens it gets the zoom (max focal length / min focal length)
def focal_lengths_to_zoom str
  min_focal_length = get_min_f(str)
  max_focal_length = get_max_f(str)
  zoom = (max_focal_length / min_focal_length) if min_focal_length and max_focal_length
  #debugger if zoom <= 1
  return zoom || nil
end

# Gets optical zoom from a string if there is a number in there for it.
def parse_ozoom str
  return nil if str.nil?
  ozoom =  get_f( str.match( append_regex(@@float_rxp, /\s?x (optical )?zoom/i)).to_s )
  return ozoom if ozoom and ozoom >= 1
  return nil 
end

# Converts resolution(array: [megapixels, kilopixels, pixels]) to megapixels
def to_mpix res
  return nil if res.nil?
  mpix = res[0]+ res[1]/1_000 +res[2]/1_000_000
  return mpix unless mpix == 0
  return nil
end

# Gets resolution(array: [megapixels, kilopixels, pixels]) from a string
def parse_res str
  return nil if str.nil?
  mp = get_f_with_units( str,  /(\s)?m(ega)?\s?p(ixel(s)?)?/i ) || 0
  kp = get_f_with_units( str,  /(\s)?k(ilo)?\s?p(ixel(s)?)?/i ) || 0
  p = get_f_with_units( str,  /(\s)?p(ixel(s)?)?/i ) || 0
  return [mp, kp, p] 
end

