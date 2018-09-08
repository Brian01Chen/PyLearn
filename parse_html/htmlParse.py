from html.parser import HTMLParser 
import urllib.request as urllib2
import re,os,copy
import math,random
import threading
import queue
from time import sleep,ctime

def getRequest(url):
    request = urllib2.Request(url)
    response = urllib2.urlopen(request)
    data=response.read().decode('utf-8','replace')
    return data

def Schedule(blocks_read, block_size, total_size):
    block_total=math.ceil(total_size/block_size)
    if total_size < 0:
        print ("Read %d blocks (%d bytes)" %(blocks_read, blocks_read * block_size))
    elif blocks_read>=block_total:
        print ("Read %d blocks, %.0f%%" % (blocks_read,100))
    else:
        amount_read = blocks_read * block_size
        if (math.fmod(blocks_read,11)==0 and math.floor((blocks_read/block_total*100))%20==0):
            print ("Read %d blocks,  %d/%d, %.0f%%" % (blocks_read, amount_read, total_size, amount_read*100.0/(total_size)))

def Download(localpath,localfile,source):
    if not os.path.exists(localpath):
        os.makedirs(localpath)
    local_file = '%s\%s.mp3' % (localpath,localfile)
    if not os.path.isfile(local_file):
        urllib2.urlretrieve(source,local_file,Schedule)

def DownmutiThread(localpath,sourclist):
    task_threads = []
    count= 1
    for mc in sourclist:
        t = threading.Thread(target=Download,args=(localpath,mc['name'],mc['path']))
        count = count + 1
        task_threads.append(t)
    for task in task_threads:
        print ('start')
        task.start()
    for task in task_threads:
        task.join()
    print (count)
    print ('All Done!')

class MusicLoad(threading.Thread):
    def __init__(self,t_name,localpath,queue):
        threading.Thread.__init__(self,name=t_name)
        self.data = queue
        self.localpath = localpath
    def run(self):
        mc = {}
        while True:
            if self.data.qsize()>0:
                mc = self.data.get()
                Download(self.localpath,mc['name'],mc['path'])
            else:
                break 
    
class FyParser(HTMLParser):
    def __init__(self,rule):
        HTMLParser.__init__(self)
        self.data = ''
        self.starttag = ''
        self.endtag = ''
        self.title_flag = 0  #初始为0
        self.attrs = ''
        self.rule = rule
        self.has_next_flag = False
        self.mcfile = []
        self.nextpage = ''
        self.music = {}.fromkeys(('name','path'))
    def handle_starttag(self,tag,attrs):
        self.starttag = tag
        self.attrs = attrs
        if tag == 'embed':
            for name,value in attrs:
                if name == 'src':
                    try:
                        rules = re.compile(rule)
                        fstr = re.search(rules,value).group(1)                        
                        self.music['path'] = fstr
                        self.mc = self.music.copy()
                        self.mcfile.append(self.mc)
                        print (self.mcfile)
                        self.music.clear()
                        print (self.mcfile)
                    except AttributeError as reason:
                        print (str(reason))
        if tag == 'h1' or tag == 'h2':
            self.title_flag = 1  #标题tag激活
    def handle_endtag(self,tag):
        self.endtag = tag
        if self.endtag == 'h1' or self.endtag == 'h2':
            self.title_flag = 2  #标题tag结束
    def handle_data(self,data):
        self.data=data     
        if self.title_flag == 1: #flag为1时，可获取歌曲的标题
            self.music['name'] = self.data 
        if self.data == '下一首':
            self.nextpage = self.attrs[0][1]
            self.has_next_flag = True
    def get_files(self):
        return self.files
    def get_pages(self):
        return self.nextpage
    def get_music(self):
        return slef.music
    def gettitle(self):
        return self.data
    def has_next_flag(self):
        return self.has_next_flag
    def flush_next_flag(self):
        self.has_next_flag = False
  
if __name__ == '__main__':
    idxurl = 'http://www.tingfanyin.com'
    rule = 'file=(http.*mp3)'
    localpath = r'C:\Users\IBM_ADMIN\Downloads\mp32'
    my = FyParser(rule)
    mclist = []
    my.feed(getRequest(idxurl))
    while my.has_next_flag == True:
        my.flush_next_flag()
        my.feed(getRequest(my.nextpage))
    mclist = my.mcfile
    print (mclist)
    mclen = len(mclist)
    queue1 = queue.Queue()
    queue2 = queue.Queue()
    for i in range(random.randint(math.floor(len(mclist)/2),math.floor(len(mclist)))):
        if (len(mclist) == 0):
            break
        queue1.put(mclist.pop())
        if (len(mclist) == 0):
            break
        queue2.put(mclist.pop())
    all_tasks = []
    task1 = MusicLoad('load1',localpath,queue1)
    all_tasks.append(task1)
    task2 = MusicLoad('load2',localpath,queue2)
    all_tasks.append(task2)

    for task in all_tasks:
        task.start()
    for task in all_tasks:
        task.join()

    
    
