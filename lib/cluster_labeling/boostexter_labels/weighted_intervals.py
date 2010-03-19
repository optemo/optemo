def merge_intervals(int0, int1):
    w0 = int0[1]
    w1 = int1[1]

    int0 = int0[0]
    int1 = int1[0]

    endpoints = set(int0)
    endpoints |= set(int1)
    endpoints = list(endpoints)
    endpoints.sort()

    numendpoints = len(endpoints)
    
    result = []
    for i in xrange(numendpoints - 1):
        interval = endpoints[i:i+2]
        weight = 0

        if interval[0] >= int0[0] and interval[1] <= int0[1]:
            weight += w0
        if interval[0] >= int1[0] and interval[1] <= int1[1]:
            weight += w1

        result.append([interval, weight])

    return result

def intervals_intersect(int0, int1):
    int0 = int0[0]
    int1 = int1[0]

    result = None

    if int0[0] <= int1[0]:
        result = list(int0)
        result.extend(int1)
    else:
        result = list(int1)
        result.extend(int0)

    sorted_result = sorted(result)

    return not sorted_result == result

# interval_set is made up of non-overlapping intervals in sorted order.
def merge_interval_with_interval_set(int0, interval_set):
    result = []
    overlaps = []

    numintervals = len(interval_set)

    if numintervals == 0:
        return [int0]

    i = 0

    if int0[0][1] < interval_set[i][0][0]:
        result.append(int0)
        result.extend(interval_set)
        return result

    while i < numintervals:
        if not intervals_intersect(int0, interval_set[i]):
            result.append(interval_set[i])
            i += 1
        else:
            break
    
    while i < numintervals:
        if not intervals_intersect(int0, interval_set[i]):
            break

        new_ints = merge_intervals(int0, interval_set[i])

        int0 = new_ints[-1]
        result.extend(new_ints[0:len(new_ints)-1])

        i += 1

    result.append(int0)
    result.extend(interval_set[i:len(interval_set)])

    return result

def interval_binsearch(interval_set, value):
    min_idx = 0
    max_idx = len(interval_set) - 1

    i = 0

    while True:
        mid_idx = min_idx + int(floor((max_idx - min_idx)/2))

        gte_lep = interval_set[mid_idx][0][0] <= value
        lte_rep = value <= interval_set[mid_idx][0][1]

        if gte_lep and lte_rep:
            return mid_idx
        elif min_idx >= max_idx:
            return -1
        elif gte_lep:
            min_idx = mid_idx+1
        elif lte_rep:
            max_idx = mid_idx-1
        else:
            assert(False)

        i += 1

        try:
            assert(i < len(interval_set))
        except AssertionError as e:
            print interval_set, value
            print min_idx, mid_idx, max_idx
            print idexes
            raise e
        
def is_interval_set_disjoint(interval_set):
    num_intervals = len(interval_set)
    
    for i in xrange(1, num_intervals):
        int_l = interval_set[i-1][0]
        int_r = interval_set[i][0]
        
        if int_l[1] < int_r[0]:
            # there's a gap!
            return True

    return False
