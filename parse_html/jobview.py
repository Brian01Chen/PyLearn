import urllib.request as urllib2
import urllib,hashlib
import json
from folium import Map,FeatureGroup,Popup,Marker,LayerControl,Icon
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
    return temp

def readJobFile():

    start_loc = getlnglat('北京')['result']['location']  
    m = Map(location=[start_loc['lat'],start_loc['lng']],zoom_start=8)
    path = r'C:\Users\IBM_ADMIN\AppData\Local\Programs\Python\Python35\mydata\testjob'
    
    loc_file_list = os.listdir(path)
    for job_file in loc_file_list:
        if job_file.startswith(u'北京') or 1==1:
            job_file = os.path.join(path,job_file)
            with open(job_file,'r') as f:
                for line in f:
                    jobinfo = {}.fromkeys(('company','position','location','salary'))
                    lineinfo = line.split('|')
                    jobinfo['company'] = lineinfo[0]
                    jobinfo['position'] = lineinfo[1]
                    jobinfo['address'] = lineinfo[2]
                    jobinfo['salary'] = lineinfo[3]

                    try:
                        loc = getlnglat(jobinfo['company'])['result']['location']
                        maker = Marker(location=[loc['lat'],loc['lng']],
                                        popup=Popup('%s\n%s\n%s' % \
                                                (jobinfo['company'],
                                                jobinfo['position'],
                                                jobinfo['salary'])
                                                ),
                                        icon=Icon())
                        m.add_child(maker)
                        
                    except :
                        info = sys.exc_info()
                        print (info[0],':',info[1])
                        print (jobinfo['company'] )
                        pass
    m.save('51job.html')

readJobFile()

