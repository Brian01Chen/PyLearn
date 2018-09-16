import urllib.request as urllib2
import urllib, hashlib
import json
from p_request import getRequest
import os,sys



def getlnglat(address):
    #http://lbsyun.baidu.com/apiconsole/key apply a key
    
    urlhome = 'http://api.map.baidu.com'
    
    ak = '7DFORpDYrb6ieN8EZKtYpljzUKg03QXU'
    sk = 'ZgTPymZ1lTSrWBtN8n4UodHVGs6mZTrp' 
    out = '&output=json&ak=' + ak   
    queryStr = '/geocoder/v2/?address=' + address + out
    encodeStr = urllib2.quote(queryStr, safe="/:=&?#+!$,;'@()*[]")
    rawStr = encodeStr + sk
    sn = hashlib.md5(urllib.parse.quote_plus(rawStr).encode('utf-8')).hexdigest()
    url = urlhome + '/geocoder/v2/?address=' + urllib.parse.quote(address) + out + '&sn=' + sn

    temp = getRequest(url).decode('utf-8')
    temp = json.loads(temp)
    return temp['result']['location']


def readfile(filename):
    with open(filename,'r') as f:
        for line in f:
            if len(line.strip()) > 0 :
                yield line


if __name__ == '__main__':

    filename = r'C:\Users\IBM_ADMIN\AppData\Local\Programs\Python\Python35\mysrc\comp.txt'
    address = readfile(filename)
    for adr in address:
        p = getlnglat(adr)
        print ('%s: %s' % (adr, p))
