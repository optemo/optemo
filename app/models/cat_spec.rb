class CatSpec < ActiveRecord::Base
  belongs_to :product
  # Get specs for a single item

  def self.cache_all(p_id)
    CachingMemcached.cache_lookup("CatSpecs#{p_id}") do
      select("name, value").where("product_id = ?", p_id).each_with_object({}){|r, h| h[r.name] = r.value}
    end  
  end

  def self.cachemany(p_ids, feat) # Returns different values 
    CachingMemcached.cache_lookup("CatSpecs#{feat}#{p_ids.join(',').hash}") do
      select("value").where(["product_id IN (?) and name = ?", p_ids, feat]).map{|x|x.value}
    end
  end
  def self.all(feat)
    CachingMemcached.cache_lookup("#{Session.product_type}Cats-#{feat}") do
      select("value").where("product_id IN (select product_id from search_products where search_id = ?) and name = ?", Product.initial, feat).map{|x|x.value}
    end
  end
  def self.alloptions(feat)
    CachingMemcached.cache_lookup("#{Session.product_type}Cats-#{feat}-options") do
      select("value").where("product_id IN (select product_id from search_products where search_id = ?) and name = ?", Product.initial, feat).map{|x|x.value}.uniq
    end
  end

  def self.colors_en_fr 
    if defined?(@@colors_map) && @@colors_map['product_type'] == Session.product_type
      colors = @@colors_map['colors']
      # if @@colors_map['product_type'] == Sesssion.product_type
      #   colors = @@colors_map['colors']
      # else
        # colors = get_colors_from_db
        # @@colors_map = {}
        # @@colors_map['colors'] = colors
        # @@colors_map['product_type'] = Session.product_type
      # end
    else
      colors = get_colors_from_db
      @@colors_map = {}
      @@colors_map['colors'] = colors
      @@colors_map['product_type'] = Session.product_type
    end
    colors
  end


  def self.get_colors_from_db
    colors = {}
    colors_en = CatSpec.where("product_type=? and name=?", Session.product_type, 'color').select('product_id, value').order('product_id')
    colors_fr = CatSpec.where("product_type=? and name=?", Session.product_type, 'color_fr').select('product_id, value').order('product_id')
    i=0
    j = 0
    while i < colors_en.size && j < colors_fr.size
      if colors_en[i].product_id == colors_fr[j].product_id
        colors[colors_en[i].value] = colors_fr[j].value
        i += 1
        j += 1
      else
        if colors_en[i].product_id > colors_fr[j].product_id
          j += 1
        else
          i += 1
        end
      end
    end
    colors
  end


end
