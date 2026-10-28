proc/PickWeight(list/L)
    var/total=0, item, rnd
    for(item in L) total += L[item]||1
    rnd = rand() * total
    total = 0
    for(item in L)
        total += L[item]||1
        if(total > rnd) return item
