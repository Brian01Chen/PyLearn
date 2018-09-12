def combinations(iterable, r):
    # combinations('ABCD', 2) --> AB AC AD BC BD CD
    # combinations(range(4), 3) --> 012 013 023 123
    pool = tuple(iterable)
    n = len(pool)
    if r > n:
        return
    indices = list(range(r))
    yield tuple(pool[i] for i in indices)
    while True:
        for i in reversed(range(r)):
            if indices[i] != i + n - r:
                # i+n-r = n-(r-i) 表示到达边界
                break
        else:
            return 
        indices[i] += 1
        for j in range(i+1, r):
            indices[j] = indices[j-1] + 1
        yield tuple(pool[i] for i in indices)


def permutation(iterable, r):
    # permutation('ABCD', 2) --> AB AC AD BA BC BD CA CB CD DA DB DC
    pool = tuple(iterable)
    n = len(pool)
    if r > n:
        return
    indices = list(range(n))
    cycles = list(range(n, n-r, -1))
    yield tuple(pool[i] for i in indices[:r])
    while n:
        for i in reversed(range(r)):
            print (i,cycles)
            cycles[i] -= 1
            print (i,cycles)
            if cycles[i] == 0:
                indices[i:] = indices[i+1:] + indices[i:i+1]
                cycles[i] = n - i
                print (i,indices,cycles)
            else:
                j = cycles[i]
                indices[i], indices[-j] = indices[-j], indices[i]
                print (i,j,indices,cycles)
                print (tuple(pool[i] for i in indices[:r]))
                yield tuple(pool[i] for i in indices[:r])
                break
        else:
            return

if __name__ == '__main__':
    iterable = 'ABCD'
    r = 2
    permuiter = permutation(iterable,r)
    print (list(permuiter))
