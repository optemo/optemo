class CompareController < ApplicationController
  layout 'optemo', :except => "sitemap"
  require 'open-uri'
  require 'base64'
  require 'digest/md5'

  # params_hash is the base-64 encoding of the MD5 hash of the parameters.
  attr_reader :params_hash

  # Order matters here -- we need to ensure the before_filter runs before the caches_action, since the caches_action
  # uses the params_hash as the cache key.
  before_filter :calculate_params_hash
  caches_action :index, :create, :cache_path => Proc.new { |controller| {params_hash: controller.params_hash} } 

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

  private 

  def create_search_and_render
    search = Search.find_by_params_hash(@params_hash)
    if search.nil?
      search = Search.create({page: params[:page], keyword: params[:keyword], sortby: params[:sortby], 
                              filters: params, landing: params[:landing], params_hash: @params_hash})
    end

    classVariables(search)
      
    correct_render
  end
  
  def calculate_params_hash
    @params_hash = nil
    hist = params[:hist]
    if not hist.nil?
      @params_hash = hist
    else
      # Sort the params to ensure the same param set always results in the same MD5 hash.
      params_as_array = sort_params(params)
      @params_hash = Base64.strict_encode64(Digest::MD5.digest(params_as_array.to_s))
    end
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

  def classVariables(search)
    Session.initialize_with_search(search)
    @search_view = true if params[:keyword] || !Session.search.keyword_search.blank?
  end
  
  def correct_render
    if params[:ajax] || params[:embedding]
      render 'ajax', :layout => false
    else
      render 'compare'
    end
  end
end
