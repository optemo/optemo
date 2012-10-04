class Binary < Facet
  def checked
    dobj = selected.first
    dobj && dobj.value == true
  end
  
  def selected
    Session.search.userdatabins.select{|udb| udb.name == name}
  end
  
  def no_display
    count == 0 && !checked
  end
  
  def count #number of products in search with this facet
    BinSpec.count_feat(name)
  end
end