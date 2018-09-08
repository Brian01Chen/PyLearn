#code=utf-8
import os,re,sys
from datetime import datetime
from prettytable import PrettyTable
from ftpupdown import FTPload
from find_word import find_file_list


def time_between(start,end):
    if type(start) == str :

        start = datetime.strptime(start,'%Y-%m-%d-%H.%M.%S')
        end = datetime.strptime(end,'%Y-%m-%d-%H.%M.%S')
    dsec = (end-start).seconds
    minute,second = divmod(int(dsec),60)
    if minute>60:
        hour,minu = divmod(int(minute),60)
        minute = str(hour) + 'h' + str(minu) 
    duration = str(minute) + 'm' + str(second) + 's'
    return duration




report_list = []       
def logParse(filename,pattern='.*'):
    stepdic={}.fromkeys(('sp','runday','stid','stinfo','starttime','duration'))
    global report_list
    lsteptime = []
    log_sp = ''


    def wrap_result(flatp):
        def one_xlat(text):
            flatext = flatp.search(text)
            if flatext:
                return flatp.search(text).group() +  ' '
            else:
                return ''
        return one_xlat
    
    rulex = re.compile(pattern,re.IGNORECASE)
    PARSE_op_REGEX = re.compile(r'''
      (?P<op>select|insert|update|delete|execute|truncate) ''',re.I|re.X)
    PARSE_tb_REGEX = re.compile(r'''
      (?P<tb>[a-zA-Z]+\w*[.](?![dp|sp|sql|txt])\w+ )''',re.I|re.X)
    PARSE_sp_REGEX = re.compile(r'''
      (?P<sp>dp\w+) ''',re.I|re.X)
    PARSE_LOG_Time_REGEX = re.compile(r'\d{4}([-.]\d{2}){5}')

    file = open(filename,'r')
    lines = file.readlines()
    # 将文件倒序，从最后一行开始读
    content = lines[::-1]
    content_list = []
    end_flag = False
    
    for line in content:
        if (len(line.rstrip()) == 0):
            continue
        if (line.startswith('#')):
            continue
        steptime = rulex.search(line)
        stinfo = wrap_result(PARSE_op_REGEX)(line)+ \
                 wrap_result(PARSE_tb_REGEX)(line) + wrap_result(PARSE_sp_REGEX)(line)

        if not steptime and end_flag == False:  #获取完成时间
            
            endtime = wrap_result(PARSE_LOG_Time_REGEX)(line).strip()
            if endtime != '':
                lsteptime.append(endtime)
            end_flag = True
            
        if steptime:
            
            stepdic['runday'] = steptime.group('time')[0:10] # date format is '%Y-%m-%d'
            stepdic['stid'] = steptime.group('stid')
            stepdic['stinfo'] = stinfo
            stepdic['starttime'] = steptime.group('time')
            
            steptime = steptime.group('time')
            lsteptime.append(steptime)
            if len(lsteptime)>1:
                end = lsteptime[-2]
                start = steptime
                duration = time_between(start,end)
            else:
                duration = 0
            stepdic['duration'] = duration
            titlepat = re.compile('\w*(?=\d*$)')
            sp_name = titlepat.findall(filename,re.I)
            if len(sp_name)>0:
                sp_name = str(sp_name[0])
            else:
                sp_name = ''
            stepdic['sp'] = sp_name
            stepdic_copy = stepdic.copy()
            content_list.append(stepdic_copy)   
        
    content_list.reverse()

    # cal whole process timecount
    prcdic = {}
    prcdic['sp'] = sp_name
    prcdic['stid'] = 'total'
    prcdic['stinfo'] = stinfo
    prcdic['runday'] = lsteptime[-1][0:10]
    prcdic['starttime'] = ''
    prcdic['duration'] = time_between(lsteptime[-1],lsteptime[0])
    content_list.append(prcdic)
    report_list.extend(content_list)
    file.close()    
    return report_list

def pretty_print(lists):
    t = PrettyTable(['sp','runday','stid','stinfo','starttime','duration'])
    if len(lists) == 0 :
        t.add_row('Not Found')
    else:
        for step in lists:
            t.add_row([step['sp'],step['runday'],step['stid'],step['stinfo'],step['starttime'],step['duration']])
    print (t)
    
if __name__ == '__main__':
    #服务器端地址
    #hostaddr = 'b01aciapp070.ahe.pok.ibm.com'
    hostaddr = 'chevelle.austin.ibm.com'
    #本地文件路径
    localdir = r'C:\Users\IBM_ADMIN\AppData\Local\Programs\Python\Python35\mysrc\tools\log analyse\sp log'
    #服务器端文件路径
    #remotedir = "/dss_sp_output/db2page/dwdm/RMS"
    remotedir = '/tracker_uat_sp_output/db2reef/dwdm/RMS'
    username = 'csongbj'
    password = 'songssc0106'
    pfile = 'rms_(?=log)\w*'
    fp = FTPload(hostaddr,username,password,localdir,remotedir,pfile)
    #fp.login()
    #fp.downloadfile()
    plogfile = '(?P<stid>\d{1,2}[.]\d{1,2}).*(?P<time>\d{4}([-.]\d{2}){5})'   
    loglist = find_file_list(localdir,pfile,False)
    #for log in loglist:
        #logParse(log,plogfile)

    specific_log_name = r'rms_log_20170507150053'
    specific_log_file = os.path.join(localdir,specific_log_name)
    logParse(specific_log_file,plogfile)
    pretty_print(report_list)

