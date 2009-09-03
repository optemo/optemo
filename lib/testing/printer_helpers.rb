module NavigationHelpers
  
  @@uses = {0 => "All-Purpose", 1 =>"Home Office", \
    2 => "Small Office", 3 => "Corporate Use", 4 => "Photography"}
  
  def self.uses
    return @@uses
  end
  
  def num_uses
    return @@uses.length
  end
  
end