avgs = 0
10.times do
  start = Time.now
  @output = %x["./connect" "--- \nproduct_name: printer\n"]
  finish = Time.now
  avgs += finish-start
end
puts avgs/10
puts @output[0..100]