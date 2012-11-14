class CompareController < ApplicationController
  layout 'optemo', :except => "sitemap"
  require 'open-uri'
  require 'base64'
  require 'digest/md5'

  # Cache key includes hostname (which ensures we cache French content correctly), as well as hash of all parameters.
  caches_action :index, :create, :cache_path => Proc.new { |controller| {params_hash: controller.hash_params(controller.params)} } 

  def create
    index
  end

  def index
    Session.quebec = params[:is_quebec] == "true" ? true : false
    if (params[:keyword] && params[:keyword] =~ /[0-9BM]\d{7}/ && Product.find_by_sku(params[:keyword])!=nil )
      # Redirect directly to the PDP
      render text: "[REDIRECT]#{ TextSpec.cacheone((Product.find_by_sku(params[:keyword])).id, "productUrl")}"
    else
      create_search_and_render
    end
  end

  # Converts params hash to sorted array, then converts to string and hashes using MD5. Finally
  # returns base-64 encoded version of MD5 hash, with trailing '=' deleted.
  def hash_params(params)
    params_as_array = sort_params(params)
    hash = Base64.strict_encode64(Digest::MD5.digest(params_as_array.to_s))
    # Remove the trailing pad characters as they can cause problems with embedded links in some email clients. 
    # The pad characters are only required if you need to recover the original binary
    # data from the encoded version, and the length of the binary data is not known. In our case, we know that
    # the data length is always 128 bits. Also, we do not actually need to recover the binary data from the 
    # base-64 encoded version.
    while hash.end_with? "="
      hash.chop!
    end
    hash
  end

  private 

  def create_search_and_render
    search = lookup_or_create_search

    Session.initialize_with_search(search)
      
    correct_render
  end
  
  def lookup_or_create_search
    search = nil

    hist = params[:hist]
    if not hist.nil?
      search = find_search_by_params_hash(hist)
    end

    params_hash = nil
    if search.nil?
      # Hash just the parameters that are stored in the database.
      search_params = params.select do |param, value|
        ["page", "keyword", "sortby", "continuous", "binary", "categorical", "landing"].include?(param)
      end
      params_hash = hash_params(search_params)
      search = find_search_by_params_hash(params_hash)
      if not search.nil? and not params[:expanded].nil?
        # We currently do not store the :expanded parameter in the database, so initialize it here.
        search.expanded = params[:expanded].keys
      end
    end

    if search.nil?
      # Create a new search.
      filters = {continuous:  params[:continuous],
                 binary:      params[:binary],
                 categorical: params[:categorical],
                 expanded:    params[:expanded]}
      search = Search.create({page: params[:page], 
                              keyword: params[:keyword],  
                              sortby: params[:sortby], 
                              filters: filters,
                              landing: params[:landing], 
                              params_hash: params_hash})
    else
      # We found an existing search with the same parameters. Check if we need
      # to update the updated_at field. We use the updated_at field in deciding whether an old
      # search can be removed from the table.
      delta = Time.now.utc - search.updated_at.utc

      if delta >= 24 * 60 * 60 # Throttle frequency of updates.
        search.touch
      end
    end
    
    search
  end

  def find_search_by_params_hash(params_hash) 
    # The column collation is case-insensitive, so we need to filter out hashes that 
    # differ only by case manually.
    searches = Search.find_all_by_params_hash(params_hash)
    searches.find { |item| item.params_hash == params_hash }
  end
  
  # Takes a hash and converts it to an array where each element is in turn an array of the form [key, value].
  # The returned array is sorted on the key in the original hash. For values which are hashes, this method
  # calls itself recursively to convert the value in to a sorted array.
  def sort_params(params)
    result = []
    params.each_pair do |key, value|
      if value.is_a? Hash
        result << [key, sort_params(value)]
      else
        result << [key, value]
      end
    end
    result.sort{ |a, b| a[0] <=> b[0] }
  end

  def correct_render
    if params[:ajax] || params[:embedding]
      render 'ajax', :layout => false
    else
      render 'compare'
    end
  end
end
