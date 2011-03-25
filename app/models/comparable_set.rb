class ComparableSet
  def initialize
    @hash = Hash.new
  end
  
  def add(obj)
    @array = nil
    @hash[obj.id] = obj
    self
  end
  
  def to_a
    @array ||= @hash.values
  end
  
  def map(&block)
    to_a.map(&block)
  end
  
  def size
    @hash.size
  end
  
  def include?(obj)
    @hash.include? obj.id
  end
  
  def empty?
    @hash.empty?
  end
  
  #Set intersection
  def &(other_set)
    sets = [self,other_set]
    sets.reverse if other_set.size < self.size
    smaller, larger = sets
    n = self.class.new
    @hash.each_pair { |k,v| n.add(v) if larger.include?(v) }
    n
  end
  
  def classify(&block) # :yields: o
    h = {}
    @hash.each_pair { |k,v|
      x = yield(k)
      (h[x] ||= self.class.new).add(v)
    }
    h
  end
end