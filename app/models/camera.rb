class Camera < ActiveRecord::Base
  named_scope :valid, :conditions => "brand IS NOT NULL AND maximumresolution IS NOT NULL AND opticalzoom IS NOT NULL AND listpriceint IS NOT NULL AND displaysize IS NOT NULL"
  
  MaxWidth = 150
  MaxHeight = 120
  def imagewidth
    @imageW ||= resize("W")
  end
  def imageheight
    @imageH ||= resize("H")
  end
  
  def resize(dir)
    dbH = Float.induced_from(imagemheight)
    dbW = Float.induced_from(imagemwidth)
    if (dbH > MaxHeight || dbW > MaxWidth)
      relh = dbH / MaxHeight
      relw = dbW / MaxWidth
      if relh > relw
        @imageH = MaxHeight
        @iamgeW = dbW/dbH*MaxHeight.to_i
      else
        @imageW = MaxWidth
        @imageH = dbH/dbW*MaxWidth.to_i
      end
    else
      @imageW = to_i
      @imageH = to_i
    end
    dir=="W" ? @imageW : @imageH
  end
end
