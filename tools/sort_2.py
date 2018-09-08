import random
import math

# 第一次排序，最大的元素已经放在List的末尾
def buble_sort(L):
    lg = len(L)
    for i in range(lg-1):
        for j in range(lg-i-1):
            if L[j] > L[j+1]:
                k,h = L[j], L[j+1]
                L[j], L[j+1] = h,k
    return L

def selection_sort(L):
    # 首先在未排序序列中找到最小（大）元素，存放到排序序列的起始位置，
    # 然后，再从剩余未排序元素中继续寻找最小（大）元素，然后放到已排序序列的末尾。
    # 那么，第i趟排序(i=1,2,3…n-1)开始时，当前有序区和无序区分别为R[1..i-1]和R(i..n）。
    # 该趟排序从当前无序区中-选出关键字最小的记录 R[k],将它与无序区第一个记录交换
    # 以此类推，直到所有元素均排序完毕。
    lg = len(L)
    for i in range(lg-1):
        minIndex = i
        for j in range(i,lg-1):
            
            if L[minIndex] > L[j+1]:
                minIndex = j+1
        k, h = L[i], L[minIndex]
        L[i],L[minIndex] = h, k
        print(L)
    return L


def insert_sort(L):
    lg = len(L)
    for i range(1,lg):
        for j in range(i):
            if L[i] < L[j]:
                        temp = L[j]
                        L[j] = L[j+1]
                        L[j] = L[i]



    
def binary_split(la,lb):

    k = math.floor((lb-la)/2)
    return la,la+k,la+k,lb


def quick_sort(L,la,lb):
    la0,lb0,la1,lb1 = binary_split(la,lb)

    for j in range():
        while la < i < lb:
        
            if L[i] > L[la]:
                L[la],L[i] = L[i],L[la]
        

            quick_sort(L,la0,lb0)
            quick_sort(L,la1,lb1)
    
    return L

if __name__ == '__main__':
    L = [10,3,89,182,2,327,6,21,123,55,88,64,32,9,103]
    L = selection_sort(L)
    print(L)






if __name__ == '__main__':
    L = [10,3,89,182,2,327,6,21,123,55,88,64,32,9,103]
    upd_L = quick_sort(L,0,len(L))
    print (upd_L)
