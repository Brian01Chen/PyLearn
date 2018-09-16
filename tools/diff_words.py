


def row_best_match(a, b, alh, ali, blh, bli):

    besti, bestj, bestsize = alh, blh, 0
    b2j = {}

    # 获取b的key , 其中value是list
    for i, elt in enumerate(b):
        indices = b2j.setdefault(elt, [])
        indices.append(i)
    print(b2j)
    j2len = {}
    newj2len = {}
    nothing = []
    for i in range(alh, ali):
        bj = b2j.get(a[i], nothing)
        print(a[i], bj)
        for j in bj:

            k = newj2len[j] = j2len.get(j-1, 0) + 1
            print(j, newj2len)
            if k > bestsize:
                besti, bestj, bestsize = i - k + 1, j - k + 1, k
        j2len = newj2len

    return besti, bestj, bestsize


if __name__ == '__main__':

    a1 = 'aabeabc'
    b1 = 'babcd'
    besti, bestj, bestsize = row_best_match(a1, b1, 0, len(a1), 0, len(b1))
    print(besti, bestj, bestsize)