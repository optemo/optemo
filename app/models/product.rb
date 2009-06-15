module ProductProperties
  Max = {'SWidth' => 70, 'SHeight' => 50,'MWidth' => 140, 'MHeight' => 100, 'LWidth' => 400, 'LHeight' => 300} unless defined?(Max)
  def imagesw
    @imageW ||= {}
    @imageH ||= {}
    @imageW['S'] ||= resize :dir => 'Width', :size => 'S'
  end
  def imagesh
    @imageH ||= {}
    @imageW ||= {}
    @imageH['S'] ||= resize :dir => 'Height', :size => 'S'
  end
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
    case opts[:size]
      when 'S': return unless imagesheight && imageswidth
      when 'M': return unless imagemheight && imagemwidth
      when 'L': return unless imagelheight && imagelwidth
    end
    dbH = case opts[:size] 
      when 'S': Float.induced_from(imagesheight)
      when 'M': Float.induced_from(imagemheight) 
      when 'L': Float.induced_from(imagelheight)
    end
    dbW = case opts[:size]
      when 'S': Float.induced_from(imageswidth)
      when 'M': Float.induced_from(imagemwidth) 
      when 'L': Float.induced_from(imagelwidth)
    end
    maxHeight = Max[opts[:size]+'Height']
    maxWidth = Max[opts[:size]+'Width']
    if (dbH > maxHeight || dbW > maxWidth)
      relh = dbH / maxHeight
      relw = dbW / maxWidth
      if relh > relw
        @imageH[opts[:size]] = maxHeight.to_s
        @imageW[opts[:size]] = (dbW/dbH*maxHeight).to_s
      else
        @imageW[opts[:size]] = maxWidth.to_s
        @imageH[opts[:size]] = (dbH/dbW*maxWidth).to_s
      end
    else
      @imageW[opts[:size]] = dbW.to_s
      @imageH[opts[:size]] = dbH.to_s
    end
    opts[:dir]=='Width' ? @imageW[opts[:size]] : @imageH[opts[:size]]
  end
  
  def smlTitle
    [brand,model].join(' ')
  end
  
  def tinyTitle
    [brand,model.split(' ')[0]].join(' ')
  end
  
  def display(attr)
    data = self.send(attr)
    if data.nil?
      return 'Unknown'
    else
      ending = case attr
        when /zoom/: ' X'
        when /[^p][^a][^p][^e][^r]size/: ' in.' 
        when /(item|package)(width|length|height)/: data = data.to_f/100
          ' in.'
        when /resolution/: ' dpi'
        when /focal/: ' mm.'
        when /ttp/: ' seconds'
        else ''
      end
    end
    data.to_s+ending
  end
end