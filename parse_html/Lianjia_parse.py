# -*- coding:utf-8 -*-
from bs4 import BeautifulSoup

import re
import urllib
import urllib.request #urllib2
import math
import codecs
import os


domain='http://bj.lianjia.com/'
url = domain + '/zufang/'


def get_All_Xiaoqu_Info():
    html_doc = urllib.request.urlopen(url).read()

    soup = BeautifulSoup(html_doc, 'html.parser')
    all_quyu_list = [[x.get('href'),x.string]  for x in soup.find(attrs={"data-index": 0}).find_all('a') \
                     if x.get('href') != '/zufang/']
    if len(all_quyu_list) > 0 :
        return all_quyu_list

def get_Xiaoqu_PageURL(quyu):
    quyuUrl = domain + quyu
    xiaoqu_url = urllib.request.urlopen(quyuUrl).read()
    xiaoqu_soup = BeautifulSoup(xiaoqu_url, 'html.parser')
    #获取当前区域的分页的信息
    quyu_page_dic = {}
    try:
        page_box = xiaoqu_soup.find('div',attrs={'class':'page-box house-lst-page-box'})
        page_url = page_box.get('page-url')
        page_data = eval(page_box.get('page-data'))
        
        quyu_page_dic['url'] = page_url[:-7]
        quyu_page_dic['tpage'] = page_data['totalPage']
    except Exception:
        print ('暂时没有内容！')
        quyu_page_dic = {'url': quyuUrl,'tpage': 0}
    return quyu_page_dic

def get_House_Info(quyu):
    urldic = {}
    house_info = {}
    house_list = []
    urldic = get_Xiaoqu_PageURL(quyu[0])
    localpath = u'C:\\Users\\IBM_ADMIN\\AppData\Local\Programs\Python\Python35\mydata\\lianjia_zufang\\'
    local_file = '%s\%s.txt' % (localpath,quyu[1])
    if not os.path.exists(localpath):
        os.makedirs(localpath)
    if urldic['tpage'] > 0: # 如果该地区存在内容，则解析各个分页信息，并写文件   
        for pg in range(1,urldic['tpage']+1):
            if pg == 1 :
                file = codecs.open(local_file,'wb','utf-8')
            else:
                file = codecs.open(local_file,'a','utf-8')
            
            print (quyu[0] + '第' + str(pg) + '页 start' )
            quyuUrl = ('%s%s%d') % (domain,urldic['url'],pg)
            xiaoqu_url = urllib.request.urlopen(quyuUrl).read()
            xiaoqu_soup = BeautifulSoup(xiaoqu_url, 'html.parser')
            seq = ('quyu','region','zone','address','meters','direction', \
                                  'floor','type','heat','price','scholl','decoration')
            house_info = dict.fromkeys(seq,'') 
            for info in xiaoqu_soup.find(id='house-lst').find_all('li'):
                    try:
                        house_info['quyu'] = info.find(class_='con').a.string.strip(u'租房')
                        house_info['region'] = info.find(class_='region').string.strip('\xa0')
                    except (AttributeError,IndexError) as reason:
                        pass
                    try:
                        house_info['address'] = info.find(class_='fang-subway-ex').span.string
                    except (AttributeError,IndexError) as reason:
                        pass
                    try:
                        house_info['zone'] = info.find(class_='zone').span.string.strip('\xa0')
                        house_info['meters'] = info.find(class_='meters').string.strip('\xa0')
                    except (AttributeError,IndexError) as reason:
                        pass
                    try:
                        house_info['direction'] = info.find(class_='meters').next_sibling.string
                    except (AttributeError,IndexError) as reason:
                        pass
                    try:
                        house_info['floor'] = info.find(class_='con').find_next('span').next_sibling.string
                        house_info['type'] = info.find(class_='con').find_next('span').find_next('span').next_sibling.string
                    except (AttributeError,IndexError) as reason:
                        pass
                    try:
                        house_info['price'] = info.find(class_='price').span.string
                        house_info['heat'] = info.find(class_='heating-ex').span.string
                    except (AttributeError,IndexError) as reason:
                        pass    
                    try:
                        house_info['scholl'] = info.find(class_='fang05-ex').span.string
                    except (AttributeError,IndexError) as reason:
                        pass
                    try:
                        house_info['decoration'] = info.find(class_='decoration-ex').span.string
                    except (AttributeError,IndexError) as reason:
                        pass
                
                    house_info_copy = house_info
                    house_list.append(house_info_copy)
                    house_str= '%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' % ( \
                                house_info['quyu'],house_info['region'],house_info['address'],house_info['zone'], house_info['scholl'], \
                                house_info['meters'],house_info['direction'],house_info['decoration'],house_info['type'],  \
                                house_info['floor'],house_info['heat'],house_info['price'])
                    file.write(house_str)
        file.close()
    return house_list

if __name__ == '__main__':
    quyulist = get_All_Xiaoqu_Info()
    print (quyulist)
    for quyu in quyulist:
        get_House_Info(quyu)

    

   


