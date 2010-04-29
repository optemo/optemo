module BtxtrLabels
  def BtxtrLabels.merge_intervals(int0, int1)
    w0 = int0[1]
    w1 = int1[1]

    int0 = int0[0]
    int1 = int1[0]

    endpoints = Set.new(int0).merge(Set.new(int1)).to_a().sort()

    numendpoints = endpoints.size()

    result = []
    for i in (0..numendpoints-2)
      interval = endpoints[i..i+1]
      weight = 0

      if interval[0] >= int0[0] and interval[1] <= int0[1]
        weight += w0
      end
      if interval[0] >= int1[0] and interval[1] <= int1[1]
        weight += w1
      end

      result.push([interval, weight])
    end

    return result
  end

  def BtxtrLabels.intervals_intersect(int0, int1)
    int0 = int0[0]
    int1 = int1[0]

    result = nil

    if int0[0] <= int1[0]
      result = Array.new(int0)
      result.push(int1[0])
      result.push(int1[1])
    else
      result = Array.new(int1)
      result.push(int0[0])
      result.push(int0[1])
    end

    sorted_result = result.sort()

    return sorted_result != result
  end

  # interval_set is made up of non-overlapping intervals in sorted order.
  def BtxtrLabels.merge_interval_with_interval_set(int0, interval_set)
    result = []
    overlaps = []

    numintervals = interval_set.size()

    if numintervals == 0
      return [int0]
    end

    if int0[0][1] < interval_set[0][0][0]
      result = Array.new(interval_set)
      result.insert(0, int0)
      return result
    end

    i = 0

    while i < numintervals
      if not intervals_intersect(int0, interval_set[i])
        result.push(interval_set[i])
        i += 1
      else
        break
      end
    end

    while i < numintervals
      if not intervals_intersect(int0, interval_set[i])
        break
      end

      new_ints = merge_intervals(int0, interval_set[i])

      int0 = new_ints[-1]

      for interval in new_ints[0..new_ints.size() - 2]
        result.push(interval)
      end

      i += 1
    end

    result.push(int0)
    for interval in interval_set[i..numintervals]
      result.push(interval)
    end

    return result
  end

  def BtxtrLabels.interval_binsearch(interval_set, value)
    min_idx = 0
    max_idx = interval_set.size() - 1

    i = 0
    
    while(true)
      mid_idx = ((max_idx - min_idx)/2.0).floor().to_i()

      gte_lep = interval_set[mid_idx][0][0] <= value
      lte_rep = value <= interval_set[mid_idx][0][1]

      if gte_lep and lte_rep
        return mid_idx
      elsif min_idx >= max_idx
        return -1
      elsif gte_lep
        min_idx = mid_idx + 1
      elsif lte_rep
        max_idx = mid_idx - 1
      else
        raise "Invalid state"
      end

      i += 1

      if i > interval_set.size()
        raise "Invalid state"
      end
    end
  end

  def BtxtrLabels.is_interval_set_disjoint(interval_set)
    num_intervals = interval_set.size()

    for i in (1..num_intervals-1).to_a()
      int_l = interval_set[i-1][0]
      int_r = interval_set[i][0]

      if int_l[1] < int_r[0]
        # there's a gap!
        return true
      end
    end

    return false
  end
end
