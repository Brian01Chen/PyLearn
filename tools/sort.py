import math


# 第一次排序，最大的元素已经放在List的末尾
def buble_sort(L):
    lg = len(L)
    for i in range(lg-1):
        for j in range(lg-i-1):
            if L[j] > L[j+1]:
                k, h = L[j], L[j+1]
                L[j], L[j+1] = h, k
    return L


def selection_sort(L):
    # 首先在未排序序列中找到最小（大）元素，存放到排序序列的起始位置，
    # 然后，再从剩余未排序元素中继续寻找最小（大）元素，然后放到已排序序列的末尾。
    # 那么，第i趟排序(i=1,2,3…n-1)开始时，当前有序区和无序区分别为R[1..i-1]和R(i..n）。
    # 该趟排序从当前无序区中-选出关键字最小的记录 R[k],将它与无序区第一个记录交换
    # 以此类推，直到所有元素均排序完毕。
    lg = len(L)
    for i in range(lg-1):  # 从无序区选择最小值与无序区第一个进行交换，最多需要交换lg-1次，
        minIndex = i
        for j in range(i, lg-1):
            if L[minIndex] > L[j+1]:
                minIndex = j+1
        k, h = L[i], L[minIndex]
        L[i], L[minIndex] = h, k
    return L


def insert_sort(L):
    '''
    当L = [3, 10, 89, 182, 2, 327, 6, 21, 123, 55, 88, 64, 32, 9, 103]时，此时i =4
    插入排序将进行4次比较完成i=4的调整！
    [2, 10, 89, 182, 3, 327, 6, 21, 123, 55, 88, 64, 32, 9, 103]
    [2, 3, 89, 182, 10, 327, 6, 21, 123, 55, 88, 64, 32, 9, 103]
    [2, 3, 10, 182, 89, 327, 6, 21, 123, 55, 88, 64, 32, 9, 103]
    [2, 3, 10, 89, 182, 327, 6, 21, 123, 55, 88, 64, 32, 9, 103]
    '''
    lg = len(L)
    for i in range(1, lg):
        key = L[i]
        for j in range(i):
            if key < L[j]:
                temp = L[j]
                L[j] = L[i]
                L[i] = temp
    return L


def binary_split(la, lb):
    k = math.floor((lb-la)/2)
    return la, la+k, la+k, lb


# 保持原始list不变
def merge(L, la0, lb0, la1, lb1):
    # L[la0:lb0] , L[la1:lb1] 都是有序的List
    temp = []
    li, lj = 0, 0
    while li < lb0 - la0 and lj < lb1 - la1:
        try:
            if L[la0+li] < L[la1+lj]:
                temp.append(L[la0+li])
                li += 1
            else:
                temp.append(L[la1+lj])
                lj += 1
            if li == lb0 - la0:
                temp += L[la1+lj:lb1]
                break
            if lj == lb1 - la1:
                temp += L[la0+li:lb0]
                break
        except IndexError as e:
            print(e)
    L[la0:lb1] = temp
    return L


# 合并子列表
def merge_sub_list(a, b):
    temp = []
    i, j = 0, 0
    while i < len(a) and j < len(b):
        if a[i] < b[j]:
            temp.append(a[i])
            i += 1
        else:
            temp.append(b[j])
            j += 1
        if i == len(a):
            temp += b[j:len(b)]
        if j == len(b):
            temp += a[i:len(a)]
    return temp


def merge_sort(L, la, lb):
    if lb - la < 2:
        return L
    la0, lb0, la1, lb1 = binary_split(la, lb)
    merge_sort(L, la0, lb0)
    merge_sort(L, la1, lb1)
    merge(L, la0, lb0, la1, lb1)
    return L


def partition(L, la, lb):
    li, lj = la, lb-1
    key = la
    while li < lj:
        while L[lj] > L[key] and li < lj:
            lj -= 1
        L[key], L[lj] = L[lj], L[key]
        key = lj
        while L[li] <= L[key] and li < lj:
            li += 1
        L[key], L[li] = L[li], L[key]
        key = li

    return lj


# 快速排序 原地排序，不需要传参数
def quick_sort(array, left, right):
    if left >= right:
        return
    low = left
    high = right
    key = array[low]
    while left < right:
        while left < right and array[right] > key:
            right -= 1
        array[left] = array[right]
        while left < right and array[left] <= key:
            left += 1
        array[right] = array[left]
    array[right] = key
    quick_sort(array, low, left - 1)
    quick_sort(array, left + 1, high)


def quick_sort_partition(array, left, right):

    low = left
    high = right
    mid = partition(array, low, high)
    quick_sort(array, low, mid)
    quick_sort(array, mid, high)


def quick_sort_stack(array, l, r):

    if l >= r:
        return
    stack = []
    stack.append(l)
    stack.append(r)
    while stack:

        low = stack.pop(0)
        high = stack.pop(0)
        if high - low <= 0:
            continue
        x = array[high]
        i = low - 1
        for j in range(low, high):
            if array[j] <= x:
                i += 1
                array[i], array[j] = array[j], array[i]
                print(array, i, j, x)
        array[i + 1], array[high] = array[high], array[i + 1]
        stack.extend([low, i, i + 2, high])

'''
[10, 3, 89, 182, 2, 327, 6, 21, 123, 55, 88, 64, 32, 9, 103]
[10, 3, 9, 6, 2, 327, 182, 21, 123, 55, 88, 64, 32, 89, 103]
4
[9, 3, 6, 2, 327, 10, 182, 21, 123, 55, 88, 64, 32, 89, 103]
'''


def heap_sort(L):
    #堆排序
    L.insert(0, 0)
    lb, le = 0, len(L)
    print(L)
    print(math.log(le, 2))
    for j in range(1, math.floor(le/2)):
        lmin, k = L[j], j
        if L[2*j] > L[2*j+1]:
            L[2*j], L[2*j+1] = L[2*j+1], L[2*j]
        if L[2*j] < lmin:
            lmin, k = L[2*j], 2*j
        L[j], L[k] = L[k], L[j]
    L.pop(0)
    return L


if __name__ == '__main__':
    L = [10, 3, 89, 182, 2, 327, 6, 21, 123, 55, 88, 64, 32, 9, 103]
    heap_sort(L)
    print(L)

