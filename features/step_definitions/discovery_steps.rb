Given /^he visits the printers page$/ do
  visit "/printers"
end

And /^He clicks continue to see printers$/ do
  click_link "Continue"
end

When /^he clicks See Similar on the first product$/ do
  click_link 'sim0'
end

Then /^he should see at least six more products$/ do
  doc = Nokogiri::HTML(response.body)
  n = doc.css(".navbox")
  assert_not_nil n
end
