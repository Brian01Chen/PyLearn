#!/usr/bin/python  
#-*- coding: utf-8 -*-  
  
from ftplib import FTP
import sys,os,re



class FTPload:

    def __init__(self,hostaddr,username,password,localdir,remotedir,pattern,port=21):
        self.hostaddr = hostaddr
        self.username = username
        self.password = password
        self.localdir = localdir
        self.remotedir = remotedir
        self.pattern = pattern
        self.port = port
        self.ftp = FTP()
        self.file_list = []
    def quit(self):
        self.ftp.close()
    def login(self): 
        ftp = self.ftp
        ftp.set_debuglevel(0) #如果调试级别2，则显示详细信息  0-2
        try:
            ftp.connect(self.hostaddr,21) #连接
            ftp.login(self.username,self.password) 
            #print (ftp.getwelcome()) #显示ftp服务器欢迎信息
        except:
            print ('error login')
            sys.exit()
        return ftp  
    def is_same_size(self,localfile,remotefile):
        ftp = self.ftp
        try:
            remotesize = ftp.size(remotefile)
        except:
            remotesize = -1
        try:
            localsize = os.path.getsize(localfile)
        except:
            localsize = -1
        if remotesize == localsize:
            return 1
        else:
            return 0
    def do_file(self,line):
        m = re.search(self.pattern, line)
        if m:
            self.file_list.append(m.group(0))
    def downloadfile(self):
        
        ftp = self.ftp
        remotedir = self.remotedir
        pattern = self.pattern
        ftp.cwd(remotedir)
        bufsize = 1024 #设置缓冲块大小
        file_list = self.file_list
        if pattern == '.*':
            file_list = ftp.nlst()
        else:
            ftp.retrlines('LIST', self.do_file)
        for file in file_list:
            localfile = os.path.join(self.localdir,file)
            remotefile = '/'.join((remotedir,file)) # 远程默认Linux/Unix环境，以'/'分隔
            is_same = self.is_same_size(localfile,remotefile)
            if not os.path.isfile(localfile) or is_same == 0:
                if os.path.isfile(localfile):
                    print ('更新文件 %s 服务器文件大小%d  本地文件大小%d' %(remotefile,ftp.size(remotefile),os.path.getsize(localfile)))
                else:
                    print ('创建文件 %s 服务器文件大小%d' %(remotefile,ftp.size(remotefile)))
                fp = open(localfile,'wb') #以写模式在本地打开文件
                ftp.retrbinary('RETR ' + remotefile,fp.write,bufsize) #接收服务器上文件并写入本地文件  
        ftp.set_debuglevel(0) #关闭调试  
        self.quit() #退出ftp服务器  
########################################################################
#    暂时不用        
#    def uploadfile():  
#        ftp = self.ftp
#        remotedir = self.romotedir 
#        bufsize = 1024 #设置缓冲块大小
#        localdir = self.localdir
#        fp = open(localpath,'rb')  
#        ftp.storbinary('STOR '+ remotepath ,fp,bufsize) #上传文件  
#        ftp.set_debuglevel(0)  
#        fp.close() #关闭文件  
#        ftp.quit()  
#######################################################################

files = []
def do_file(line):
    m = re.search(r'rms_(?!log)\w*', line)
    if m:
        files.append(m.group(0))
 
#f = FTP('b01aciapp070.ahe.pok.ibm.com')
#f.login('csongbj','songssc1110')
#f.cwd('/dss_sp_output/db2page/dwdm/RMS')
#entries = f.retrlines('LIST', do_file)
#f.quit()
#for name in files:
#    print (name)
#for entry in entries:
#    print (entry)

if __name__ == '__main__':
    #服务器端地址
    hostaddr = 'b01aciapp070.ahe.pok.ibm.com'
    #本地文件路径
    localdir = r'C:\Users\IBM_ADMIN\AppData\Local\Programs\Python\Python35\mysrc\tools\log analyse\sp log'
    #服务器端文件路径
    remotedir = "/dss_sp_output/db2page/dwdm/RMS"
    username = 'csongbj'
    password = 'songssc1110'
    #文件正则过滤，满足匹配模式的文件将被下载或上传
    pattern = r'rms_(?!log)\w*'
    fp = FTPload(hostaddr,username,password,localdir,remotedir,pattern)
    fp.login()
    fp.downloadfile()
