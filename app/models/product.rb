class Product < ActiveRecord::Base
  has_many :nodes
  has_many :cat_specs
  has_many :bin_specs
  has_many :cont_specs
  
  define_index do
    #fields
    indexes "LOWER(title)", :as => :title
    set_property :enable_star => true
    set_property :min_prefix_len => 2
    #attributes
    has product_type
  end
  
  def self.cached(id)
    CachingMemcached.cache_lookup("Products#{id}"){find(id)}
  end
  
  #Returns an array of results
  def self.manycached(ids)
    res = CachingMemcached.cache_lookup("Products#{ids.join('-').hash}"){find(ids)}
    if res.class == Array
      res
    else
      [res]
    end
  end
  
  named_scope :instock, :conditions => {:instock => true}
  named_scope :valid, lambda {
    {:conditions => ($Continuous["filter"].map{|f|"id in (select product_id from cont_specs where value > 0 and name = '#{f}' and product_type = '#{$product_type}')"}+\
    $Binary["filter"].map{|f|"id in (select product_id from bin_specs where value IS NOT NULL and name = '#{f}' and product_type = '#{$product_type}')"}+\
    $Categorical["filter"].map{|f|"id in (select product_id from cat_specs where value IS NOT NULL and name = '#{f}' and product_type = '#{$product_type}')"}).join(" and ")}
  }
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
      when 'S' then return unless imagesheight && imageswidth
      when 'M' then return unless imagemheight && imagemwidth
      when 'L' then return unless imagelheight && imagelwidth
    end
    dbH = case opts[:size] 
      when 'S' then Float(imagesheight)
      when 'M' then Float(imagemheight) 
      when 'L' then Float(imagelheight)
    end
    dbW = case opts[:size]
      when 'S' then Float(imageswidth)
      when 'M' then Float(imagemwidth) 
      when 'L' then Float(imagelwidth)
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

  def brand
    @brand ||= cat_specs.cache(id, "brand")
  end

  def smlTitle
    #if self.class.name == "Laptop" || self.class.name == "Flooring"
    #  title
    #else
    @smlTitle ||= [brand,model].join(' ')
    #end
  end
  
  def tinyTitle
    @tinyTitle ||= [brand.gsub("Hewlett-Packard", "HP"),model.split(' ')[0]].join(' ')
  end
  
  def descurl
    @descurl ||= "/compare/show/"+[id,brand,model].join('-').tr(' /','_-')
  end
  
  def display(attr)
    data = send(attr)
    if data.nil?
      return 'Unknown'
    elsif data == false
      return "None"
    elsif data == true
      return "Yes"
    else
      ending = case attr
        when /zoom/
          ' X'
        when /[^p][^a][^p][^e][^r]size/
          ' in.' 
        when /(item|package)(width|length|height)/
          data = data.to_f/100
          '"'
        when /(item|package)(weight)/
          data = data.to_f/100
          ' lbs'
        when /resolution/
          ' dpi'
        when /focal/
          ' mm.'
        when /ttp/
          ' seconds'
        else ''
      end
    end
    data.to_s+ending
  end
end
