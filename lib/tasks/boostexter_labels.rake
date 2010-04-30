desc "Run boostexter to generate strong hypothesis files for label generation"
task :btxtr_labels_training => :environment do
     $: << File.expand_path(File.dirname(RAILS_ROOT) + "/site/lib/cluster_labeling/boostexter_labels_rb")
     require 'train_boostexter.rb'

     Session.current=Session.new
     $product_type = "printer_us"
     BtxtrLabels.train_boostexter_on_all_clusters()
end

desc "Parse boostexter strong hypothesis files and create boostexter label runs in the database"
task :btxtr_labels_save_label_rules => :environment do
     $: << File.expand_path(File.dirname(RAILS_ROOT) + "/site/lib/cluster_labeling/boostexter_labels_rb")
     require 'save_combined_boostexter_rules.rb'

     Session.current=Session.new
     $product_type = "printer_us"
     BtxtrLabels.save_combined_rules_for_all_clusters()
end
