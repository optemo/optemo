class Product < ActiveRecord::Base
  has_many :cat_specs
  has_many :bin_specs
  has_many :cont_specs
  has_and_belongs_to_many :searches
  
  define_index do
    #fields
    indexes "LOWER(title)", :as => :title
    indexes "product_type", :as => :product_type
    set_property :enable_star => true
    set_property :min_prefix_len => 2
    ThinkingSphinx.updates_enabled = false
    ThinkingSphinx.deltas_enabled = false
  end
  
  def self.cached(id)
    CachingMemcached.cache_lookup("Product#{id}"){find(id)}
  end
  
  #Returns an array of results
  def self.manycached(ids)
    res = CachingMemcached.cache_lookup("ManyProducts#{ids.join(',').hash}"){find(ids)}
    if res.class == Array
      res
    else
      [res]
    end
  end
  
  def self.initial
    #Algorithm for calculating id of initial products in product_searches table
    #We probably need a better algorithm to check for collisions
    chars = []
    Session.current.product_type.each_char{|c|chars<<c.getbyte(0)*chars.size}
    chars.sum*-1
  end
  
  scope :instock, :conditions => {:instock => true}
  scope :valid, lambda {
    {:conditions => (Session.current.continuous["filter"].map{|f|"id in (select product_id from cont_specs where #{Session.current.minimum[f] ? "value > " + Session.current.minimum[f].to_s : "value > 0"}#{" and value < " + Session.current.maximum[f].to_s if Session.current.maximum[f]} and name = '#{f}' and product_type = '#{Session.current.product_type}')"}+\
    Session.current.binary["filter"].map{|f|"id in (select product_id from bin_specs where value IS NOT NULL and name = '#{f}' and product_type = '#{Session.current.product_type}')"}+\
    Session.current.categorical["filter"].map{|f|"id in (select product_id from cat_specs where value IS NOT NULL and name = '#{f}' and product_type = '#{Session.current.product_type}')"}).join(" and ")}
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
      when 'S' then return unless imgsh && imgsw
      when 'M' then return unless imgmh && imgmw
      when 'L' then return unless imglh && imglw
    end
    dbH = case opts[:size] 
      when 'S' then Float(imgsh)
      when 'M' then Float(imgmh) 
      when 'L' then Float(imglh)
    end
    dbW = case opts[:size]
      when 'S' then Float(imgsw)
      when 'M' then Float(imgmw) 
      when 'L' then Float(imglw)
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
    @brand ||= cat_specs.cache_all(id)["brand"]
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

  def mobile_descurl
    @descurl ||= "/compare/show/"+[id,brand,model].join('-').tr(' /','_-')
    "/show/"+[id,brand,model].join('-').tr(' /','_-')
  end
  
  def display(attr, data) # This function is probably superceded by resolutionmaxunit, etc., defined in the appropriate YAML file (e.g. printer_us.yml)
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
        when /(item|package)(weight)/
          data = data.to_f/100
          ' lbs'
        when /focal/
          ' mm.'
        when /ttp/
          ' seconds'
        else ''
      end
    end
    data.to_s+ending
  end
  
  def self.per_page
    9
  end
end
