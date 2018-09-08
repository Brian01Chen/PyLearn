#!/usr/bin/python
#coding:GBK
   
import xlrd
import xlwt
import requests
import urllib
import math
import re
   
pattern_x=re.compile(r'"x":(".+?")')
pattern_y=re.compile(r'"y":(".+?")')
   
def mercator2wgs84(mercator):
    #key1=mercator.keys()[0]
    #key2=mercator.keys()[1]
    point_x=mercator[0]
    point_y=mercator[1]
    x=point_x/20037508.3427892*180
    y=point_y/20037508.3427892*180
    y=180/math.pi*(2*math.atan(math.exp(y*math.pi/180))-math.pi/2)
    return (x,y)
   
def get_mercator(addr):
    quote_addr=urllib.request.quote(addr.encode('GBK'))
    province=urllib.request.quote(u'广东省'.encode('GBK'))
    if  quote_addr.startswith(province):
        pass
    else:
        quote_addr=province+quote_addr
    s=urllib.request.quote(u'北京市'.encode('GBK'))
    api_addr="http://api.map.baidu.com/?qt=gc&wd=%s&cn=%s&ie=GBK&oue=1&fromproduct=jsapi&res=api&callback=BMap._rd._cbk62300"%(quote_addr,s)
    req=requests.get(api_addr)
    content=req.content
    print (content)
    
def run():
    data=xlrd.open_workbook(r'C:\test\Book2.xlsx')
    rtable=data.sheets()[0]
    nrows=rtable.nrows
    values=rtable.col_values(0)
       
    workbook=xlwt.Workbook()
    wtable=workbook.add_sheet('data',cell_overwrite_ok=True)
    row=0
    for value in values:
        mercator=get_mercator(value)
        if mercator:
            wgs=mercator2wgs84(mercator)
        else:
            wgs=('NotFound','NotFound')
       
        wtable.write(row,0,value)
        wtable.write(row,1,wgs[0])
        wtable.write(row,2,wgs[1])
        row=row+1
   
    workbook.save(r'C:\test\data.xlsx')
   
if __name__=='__main__':
    run()
