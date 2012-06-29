class ComparableSet
  def initialize(array = nil)
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
  
  def mapfeat(f)
    to_a.map{|p|p.instance_variable_get("@#{f}")}
  end
  
  def size
    @hash.size
  end
  def include_id?(id)
    @hash.include? id
  end
  def include?(obj)
    @hash.include? obj.id
  end
  def reject!(&block)
    @array = nil
    @hash.delete_if { |k,v| yield(v) }
    self
  end
  def hash
    to_a.hash
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
    @hash.each_pair { |k,v| n.add(v) if larger.include_id?(k) }
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
  
  def to_storage
    map{|x|x.to_storage}
  end
  
  def self.from_storage(storage)
    raise IOError if storage.nil?
    set = new
    storage.each do |item|
      set.add(ProductAndSpec.from_storage(item))
    end
    set
  end
end