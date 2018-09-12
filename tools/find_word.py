import os,re
from collections import Iterable


def get_sublists(path):
    if os.path.exists(path) and not os.path.isfile(path):
        sublists = os.listdir(path)
        base = os.getcwd()
        yield from [os.path.join(path, x) for x in sublists]
    else:
        yield path
    
def wrap(f):
    def wrapped_f(tlist):      
        for sub in f(tlist):
            if not os.path.isfile(sub):
                wrapped_f(sub)
        yield from f(tlist)
    return wrapped_f


def getCurrentPath(filename):
    DIR_PATH = os.path.dirname(__file__)
    FILES_DIR = os.path.join(DIR_PATH, 'files')
    k = os.path.join(FILES_DIR, filename)
    print (k)


    
#查找某个文件夹下所有某类型的文件
def find_file_list(base='.',pattern='.*'):
    cur_list = []
    repat = re.compile(pattern,re.IGNORECASE)
    if base == '.':
        base = os.getcwd()
    if os.path.exists(base):
        cur_list = os.listdir(base)
        for item in cur_list:
            full_path = os.path.join(base,item)

            if os.path.isfile(full_path):
                if repat.search(full_path):
                    yield full_path
            else :
                yield from find_file_list(full_path,pattern)
                    
#list_files(path)
#查找文件List中所有含某字符串的文件/文件内容        
def find_file(file,pattern='.*'):
    repat = re.compile(pattern,re.IGNORECASE)
    gen_flag = True
    while True:
        try:
            if type(file) == str:
                file = iter((file,))
                gen_flag = False
            
            item = next(file)
            with open(item,'r') as f:
                try:
                    for line in f:
                        #如果flag为True,则查找带字符串的文件,返回文件.
                        #否则，返回带字符串的文件内容.
                        if repat.search(line) and gen_flag == True:
                            print (item)
                            break
                        if repat.search(line) and gen_flag == False:
                            print (line)
                except UnicodeError: #utf-8不能处理部分unicode字符
                    pass
        except StopIteration:
            break

if __name__ == '__main__':
    path1 = r'C:\Users\IBM_ADMIN\EntitlementCode\DSS_FDW\\'
    pattern1 = '.*(.txt|.sql|.py|.ksh|.sh|.bat|.dsx)'
    pattern2 = r"GAIA_CUST"
    file_list = find_file_list(path1,pattern1)
    find_file(file_list,pattern2)
    filename = r'C:\Users\IBM_ADMIN\IBM\rationalsdp\workspace\DSS_Dev_02\DataStage\DWDM\\'
    filelist = wrap(get_sublists)
    ff = filelist(filename)
    
