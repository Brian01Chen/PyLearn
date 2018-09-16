import random


def getRandomP(n):
    list_l = [i for i in range(1,n+1)]
    listx = []
    for i in range(1,n+1):
        ele = random.choice(list_l)
        list_l.remove(ele)
        listx.append(ele)
    return listx


def getAllP(n):
    list_l = [i for i in range(1, n+1)]
    print (list_l)
    listold = []
    for i in range(1, n+1):
        if i == 1:
            listnew = [[1]]
        if i == 2:
            listnew = [[1, 2], [2, 1]]
        if i > 2:
            listnew = []
            listold = getAllP(i-1)
            for k in range(0, len(listold)):
                for j in range(0, i):
                    listtemp = listold[k][:]
                    listtemp.insert(j, i)
                    listnew.append(listtemp)

    return listnew


   

rdmlist=getRandomP(6)
alllist=getAllP(4)
print (alllist)

