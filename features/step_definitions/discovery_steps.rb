Given /^He visits the printers page$/ do
  visit "/printers"
end

And /^He clicks continue to see printers$/ do
  click_link "Continue"
end

When /^He clicks (\d) See Similar$/ do |num|
  click_link 'sim'+num
end

Then /^He should see at least one product$/ do
  doc = Nokogiri::HTML(response.body)
  n = doc.css(".navbox")
  assert_not_nil n
end

When /^He selects (.*)$/ do |selection|
  select selection, :from => 'myfilter_brand'
  submit_form 'filter_form'
end

When /^He removes (.*)$/ do |selection|
  pending
end


Then /^He should see 9 Brother Printers$/ do
  doc = Nokogiri::HTML(response.body)
  n = doc.css(".easylink")
  assert_match(/(Brother.*){9}/, n.text)
  assert_equal n.length, 9
end

Then /^He should see (\d) brand selectors$/ do |num|
  doc = Nokogiri::HTML(response.body)
  n = doc.css("#filter_form a")
  assert_equal n.length, num.to_i
end
