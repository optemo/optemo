class Camera < ActiveRecord::Base
  has_many :saveds
  has_many :vieweds
  has_many :similars 
  named_scope :valid, :conditions => "brand IS NOT NULL AND maximumresolution IS NOT NULL AND opticalzoom IS NOT NULL AND listpriceint IS NOT NULL AND displaysize IS NOT NULL"
  
  Max = {'MWidth' => 140, 'MHeight' => 100, 'LWidth' => 400, 'LHeight' => 300}
  def imagemw
    @imageW ||= {}
    @imageW['M'] ||= resize :dir => 'Width', :size => 'M'
  end
  def imagemh
    @imageH ||= {}
    @imageH['M'] ||= resize :dir => 'Height', :size => 'M'
  end
  def imagelw
    @imageW ||= {}
    @imageW['L'] ||= resize :dir => 'Width', :size => 'L'
  end
  def imagelh
    @imageH ||= {}
    @imageH['L'] ||= resize :dir => 'Height', :size => 'L'
  end
  
  def resize(opts = {})
    dbH = opts[:size] == 'M' ? Float.induced_from(imagemheight) : Float.induced_from(imagelheight)
    dbW = opts[:size] == 'M' ? Float.induced_from(imagemwidth) : Float.induced_from(imagelwidth)
    maxHeight = Max[opts[:size]+'Height']
    maxWidth = Max[opts[:size]+'Width']
    if (dbH > maxHeight || dbW > maxWidth)
      relh = dbH / maxHeight
      relw = dbW / maxWidth
      if relh > relw
        @imageH[opts[:size]] = maxHeight.to_s
        @imageW[opts[:size]] = (dbW/dbH*maxHeight).to_i.to_s
      else
        @imageW[opts[:size]] = maxWidth.to_s
        @imageH[opts[:size]] = (dbH/dbW*maxWidth).to_i.to_s
      end
    else
      @imageW[opts[:size]] = dbW.to_i.to_s
      @imageH[opts[:size]] = dbH.to_i.to_s
    end
    opts[:dir]=='Width' ? @imageW[opts[:size]] : @imageH[opts[:size]]
  end
end
