# -*- coding: utf-8 -*-


import re
import sys, os, shutil
from p_request import getRequest

from time import sleep,ctime



def wrap_result(flatp):
    def one_xlat(text):
        flatext = flatp.search(text)
        if flatext:
            return flatp.search(text).group()
        else:
            return ''
    return one_xlat


# Find Next Page Url to get Job Info
def NextPage(data,home_flag):
    Next_Page_Regex = re.compile(r'''
       (?<=<li\sclass="bk"><a\shref=").*?(?="["=;\w\s\.\(\)]+>)
    ''',re.X|re.S|re.I)
    before_next_page = Next_Page_Regex.findall(data)
    
    if home_flag == True:
        return before_next_page[0]
    elif len(before_next_page) == 2:
        return before_next_page[1]
    return ''

def JobParse(data):
    
    Job_Info_Regex = re.compile(r'<div\sclass="el">.*?</div>',re.X|re.S|re.I)
    Company_Regex = re.compile(r'''(?<=(<span class="t2"><a\starget="_blank"\stitle=")).*?(?=")''',re.S|re.I)
    Position_Regex = re.compile(r'(?<=(title=")).*?(?=")',re.S|re.I)
    Location_Regex = re.compile(r'''(?<="t3">).*?(?=</)''',re.S|re.I)
    Salary_Regex = re.compile(r'''(?<="t4">).*?(?=</)''',re.S|re.I)
    Publish_Day_Regex = re.compile(r'''(?<="t5">).*?(?=</)''',re.S|re.I)
    
    joblist = re.finditer(Job_Info_Regex,data)
    jobinfo = {}.fromkeys(('company','position','location','salary','publish_day'))
    
    for i in joblist:
        each_job = i.group()
        company = wrap_result(Company_Regex)(each_job)
        jobinfo['company'] = company
        position = wrap_result(Position_Regex)(each_job)
        jobinfo['position'] = position
        location = wrap_result(Location_Regex)(each_job)
        jobinfo['location'] = location
        salary = wrap_result(Salary_Regex)(each_job)
        jobinfo['salary'] = salary
        publish_day = wrap_result(Publish_Day_Regex)(each_job)
        jobinfo['publish_day'] = publish_day
        yield jobinfo

def get_all_job(url):
    home_flag = True
    localpath = u'C:\\Users\\IBM_ADMIN\\AppData\Local\Programs\Python\Python35\mydata\\51job\\'
    if os.path.exists(localpath):
        #删除整个目录树
        shutil.rmtree(localpath)
    os.makedirs(localpath)
    
    while( url != ''):
        data = getRequest(url).decode('gbk')
        url = NextPage(data,home_flag)
        home_flag = False
        print (url)
        jobs = JobParse(data)
        
        for job in jobs:
            jobstr= '%s|%s|%s|%s|%s\n' % ( \
                        job['company'],job['position'],job['location'],job['salary'],job['publish_day'])
            loc = job['location']
            local_file = '%s\%s.txt' % (localpath,loc)

            with open(local_file,'a') as f:
                f.write(jobstr)


if __name__ == '__main__':
    idxurl = u'http://search.51job.com/list/000000%252C00,000000,0000,00,9,99,%2B,2,1.html?\
               lang=c&stype=1&postchannel=0000&workyear=99&cotype=99&degreefrom=01&\
               jobterm=99&companysize=99&lonlat=0%2C0&radius=-1&ord_field=0&confirmdate=9&\
               fromType=&dibiaoid=0&address=&line=&specialarea=00&from=&welfare='
    get_all_job(idxurl)
