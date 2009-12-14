#SEPARATOR/ETC
#   self.sep
#   many_fields_to_one multfields, atts, prefix=false
#   multiple_fields_to_one multfields, newfield, oldrec, newrec, prefix=false
#   all_vals_to_s atts
#   clean_separators atts
#   remove_sep atts
#   remove_blank_strings atts
module Separator
  
  # Puts all the values from several fields in ActiveRecord oldrec
  # to a single field in ActiveRecord newrec.
  # You can add a prefix to 'label' the subfields inside the new field.
  def multiple_fields_to_one multfields, newfield, oldrec, newrec, prefix=false
  vals = []
  multfields.each do |field|
     anotherval = oldrec.[]("#{field}")
     if anotherval and not anotherval.empty? 
       anotherval = anotherval.strip
       anotherval = field + ": #{anotherval}" if prefix
       vals << anotherval
     end 
  end
  vals.delete_if {|x| x.empty?}
  fill_in newfield, vals * "\; ", newrec unless vals.empty?
  end
  
  # Same as above but difft args
  def many_fields_to_one multfields, atts, prefix=false
      vals = []
      multfields.each do |field|
         anotherval = atts[field]
         if anotherval and not anotherval.empty? 
           anotherval = anotherval.strip
           anotherval = field + ": #{anotherval}" if prefix
           vals << anotherval
         end 
      end
      vals.delete_if {|x| x.empty?}
      return vals * "\; " unless vals.empty?
      return nil
  end
end