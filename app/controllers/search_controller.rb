class SearchController < ApplicationController
  def filter
    @myfilter = params[:myfilter]
    #Remove quotes for strings
    @myfilter.each_pair {|key, val| @myfilter[key] = val.to_f if key.index('_min') || key.index('_max')}
    @myfilter['layer'] = 1
    @myfilter['ids'] = 0
    @myfilter['chosen'] = [123,546,567,86,54,34,122,434,675]
    myparams = @myfilter.to_yaml
    #debugger
    output = myparams#{}%x["/optemo/site/lib/c_code/connect" "#{myparams}"]
    options = YAML.load(output)
    #parse the new ids
    newids = options.delete('chosen').join('/')
    options.delete('layer')
    options.delete('ids')
    #update filter display
    @search = Session.find(session[:user_id]).search
    @search.update_attributes(options)
    redirect_to "/cameras/list/#{newids}"
  end
end
