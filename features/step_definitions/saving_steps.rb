When /^He clicks Save It on the (\d) product$/ do |num|
  click_link_within "#box#{num.to_i-1}", "Save it"
end

Then /^that product should be added to the saved list$/ do
  doc = Nokogiri::HTML(response.body)
  n = doc.css(".saveditem")
  puts n.class
end
