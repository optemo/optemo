def isnil(a)
  if a.nil?
    yield
  else
    a
  end
end

puts isnil(5+4)


puts isnil(nil){8}