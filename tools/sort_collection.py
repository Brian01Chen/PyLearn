import random
import math

def quick_sort(L,partition):
    
    #快速排序
    while True:
        if len(partition) == 0 :
            break
        part = partition.pop()        
        lb,le = part[0],part[1]     
        if le - lb <= 1:
            break
        sub_l = L[lb:le]

        #轴pivot,将轴外的数据与pivot比较，
        #   如果 < pivot ,移到轴左边；如果 > pivot,移到轴右边
        pivot = sub_l[0]
        for hp in range(1,le-lb):
            j = sub_l.index(pivot)
            if sub_l[hp] < pivot:
                k = sub_l.pop(hp)                
                sub_l.insert(j,k)
        L[lb:le] = sub_l
        j = sub_l.index(pivot) + lb

        if j - lb > 1:
            partition.append([lb,j])
        if le - j+1 > 1:
            partition.append([j+1,le])
        print (L,partition)
        return quick_sort(L,partition)
     

def bubble_sort(L):

    #冒泡排序
    lb,le = 0 , len(L)
    for i in range(lb,le-1):
        for j in range(lb,le-1):
            #比较相邻的元素，如果j位的元素>j+1的元素，则交换
            if L[j] > L[j+1]:
                k,h = L[j],L[j+1]
                L[j],L[j+1] = h,k
    return L       
            

def radix_sort(L):

    #基数排序
    #假设已知排序数最大位数为3
    #按个位数，十位数，百位数分别将元素划分到10个桶
    for i in range(0,3):
        bucket = [[] for i in range(0,10)]

        for l in L:
            bucket[(math.floor(l/10**i))%10].append(l)
        func = lambda buck:sum(map(func,buck),[]) if isinstance(buck,list) else [buck,]
        L = func(bucket)
    return L

def heap_sort(L):
    #堆排序
    L.insert(0,0)
    lb,le = 0, len(L)
    print (L)
    print (math.log(le,2))
    for j in range(1,math.floor(le/2)):
        lmin,k = L[j],j
        if L[2*j] > L[2*j+1]:
            L[2*j],L[2*j+1]  = L[2*j+1],L[2*j]
        if L[2*j] < lmin:
            lmin,k = L[2*j],2*j
        L[j],L[k] = L[k],L[j]
    L.pop(0)
    return L

def insert_sort(L):
    #插入排序
    lb,le = 0, len(L)
    for i in range(1,le):
        k = L[i]
        #倒序寻找i前面的元素,如果比较发现L[i]<L[j]更小,则将i的元素插入到j前
        #其他[j+1,i-1]的元素下标+1
        for j in range(i-1,-1,-1):
            if (j == 0 and k < L[j]) or  \
               (j >= 1 and k < L[j] and k > L[j-1]):
                #
                L.pop(i)
                L.insert(j,k)
                i = j
    return L
  
def selection_sort(L):
    #选择排序
    lb,le = 0, len(L)
    sortedL = [0 for i in range(lb,le)]
    #第0个元素放最小的元素,第1个元素放次小的,第2个再放次小的...
    for i in range(lb,le):
        lmin,k = L [0],0
        for j in range(0,le-i):
            
            if L[j] < lmin:
                lmin,k = L [j],j
        sortedL[i] = lmin

        L.pop(k)
    return (sortedL)   

if __name__ == '__main__':

    L = [10,3,89,182,2,327,6,21,123,55,88,64,32,9,103]
    #quick_sort(L,[[0,len(L)]])
    #bubble_sort(L)
    heap_sort  (L)
    print (L)

