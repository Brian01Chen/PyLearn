#!/usr/bin/python  
  
from html.parser import HTMLParser   
from urllib.parse import urlparse 
import urllib  
import urllib.request as urllib2  
import http.cookiejar  
import string  
import re  
  
#登录的主页面  
hosturl = 'http://www.163.com' #金书红颜  
#post数据接收和处理的页面（我们要向这个页面发送我们构造的Post数据）  
posturl = 'http://mail.163.com' #从数据包中分析出，处理post请求的url  
  
#设置一个cookie处理器，它负责从服务器下载cookie到本地，并且在发送请求时带上本地的cookie  
cj = http.cookiejar.LWPCookieJar()  
cookie_support = urllib2.HTTPCookieProcessor(cj)  
opener = urllib2.build_opener(cookie_support, urllib2.HTTPHandler)  
urllib2.install_opener(opener)  
feedback = opener.open(hosturl)
#打开登录主页面（他的目的是从页面下载cookie，这样我们在再送post数据时就有cookie了，否则发送不成功）  
#h = urllib2.urlopen(hosturl)  
for item in cj:
    print ('Name =' + item.name)
    print ('Value =' + item.value)
#构造header，一般header至少要包含一下两项。这两项是从抓到的包里分析得出的。  
headers = {'User-Agent' : 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:45.0) Gecko/20100101 Firefox/45.0',  
           'Referer' : 'http://game.ali213.net/forum.php?fid=360&mod=forumdisplay&typ'}  
#构造Post数据，他也是从抓大的包里分析得出的。  
postData = { 
            'user' : 'chensong210223@163.com', #你的用户名  
            'pass' : 'Asongssc110' #你的密码，密码可能是明文传输也可能是密文，如果是密文需要调用相应的加密算法加密  
            }  
  
#需要给Post数据编码  
postData = urllib.parse.urlencode(postData).encode('utf-8') 
  
#通过urllib2提供的request方法来向指定Url发送我们构造的数据，并完成登录过程  
request = urllib2.Request(posturl,postData)  
response = urllib2.urlopen(request)

try:
    text = response.read()
except IOError as e:
    print (text)  
