import random

'''
avg_amount = 0
listV = [0,2]
for count in range (2000000):
    amout = 100
    for time in range(10):
        x = random.randint(0,1)
        odds = listV[x]
        amout = amout*0.6 + amout*0.4*odds
        if amout < 1:
            break
    avg_amount += amout

print (float(avg_amount)/2000000)
'''



def cal_a():

    i = 0
    r = 500
    e = 500
    a = r+e
    
    p = 0.4
    q = 0.1

    
    while (a > 1):
        x = random.uniform(0,1)
        if x < 0.5 :

            a = r+2*e
            e = p*a
            r = (1-p)*a
        else:
            a = r
            e = q*a
            r = (1-q)*a
        i+=1
        if i == 100:
            break
        #print (i,x,a)
    return a

cal_a()
'''
a = 0
for i in range(10000):
    a += cal_a()
print (a/10000)
'''
    
    



