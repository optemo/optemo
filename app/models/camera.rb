class Camera < ActiveRecord::Base
  has_many :saveds
  has_many :vieweds
  has_many :searches
  has_many :nodes
  named_scope :valid, :conditions => "brand IS NOT NULL AND maximumresolution IS NOT NULL AND opticalzoom IS NOT NULL AND listpriceint IS NOT NULL AND displaysize IS NOT NULL"
  named_scope :invalid, :conditions => "brand IS NULL OR maximumresolution IS NULL OR opticalzoom IS NULL OR listpriceint IS NULL OR displaysize IS NULL"
  is_indexed :fields => ['title', 'feature']
  Interesting_features = %w(brand digitalzoom displaysize itemheight itemlength itemwidth itemweight label listpricestr maximumresolution maximumfocallength minimumfocallength model opticalzoom packageheight packageweight packagelength packagewidth title upc merchant condition iseligibleforsupersavershipping)
  Max = {'MWidth' => 140, 'MHeight' => 100, 'LWidth' => 400, 'LHeight' => 300}
  def imagemw
    @imageW ||= {}
    @imageH ||= {}
    @imageW['M'] ||= resize :dir => 'Width', :size => 'M'
  end
  def imagemh
    @imageH ||= {}
    @imageW ||= {}
    @imageH['M'] ||= resize :dir => 'Height', :size => 'M'
  end
  def imagelw
    @imageH ||= {}
    @imageW ||= {}
    @imageW['L'] ||= resize :dir => 'Width', :size => 'L'
  end
  def imagelh
    @imageH ||= {}
    @imageW ||= {}
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
  
  def smlTitle
    [brand,model].join(' ')
  end
  
  def price
    salepriceint.nil? ? listpriceint : salepriceint
  end
  def pricestr
    salepriceint.nil? ? listpricestr : salepricestr
  end
  def display(attr)
    data = self.send(attr)
    if data.nil?
      return 'Unknown'
    else
      ending = case attr
        when /zoom/: ' X'
        when /size/: ' in.' 
        when /(item|package)(width|length|height)/: data = data.to_f/100
          ' in.'
        when /focal/: ' mm.'
        else ''
      end
    end
    data.to_s+ending
  end
end
