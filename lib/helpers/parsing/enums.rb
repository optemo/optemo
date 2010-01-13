module EnumParser
  def clean_enum dirtyenum, enumlist=[]
    return nil unless dirtyenum
    temp = dirtyenum.downcase.gsub(/\s/,'')
    enumlist.each do |e|
      return e if temp.match(/#{e}/ix)
      return e if e.match(/#{temp}/ix)
    end
    return nil
  end
end