namespace :schema do
  task :change_style_in_facets => :environment do
    Facet.where("used_for = 'sortby' AND name = 'saleprice_factor_high'").update_all(:style => "asc", :name => "saleprice_factor")
  end

  task :undo_change_style_in_facets => :environment do
    Facet.where("used_for = 'sortby' AND name = 'saleprice_factor' AND style = 'asc'").update_all(:style => "", :name => 'saleprice_factor_high')
  end
end