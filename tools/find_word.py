import os
import re
import math
import types

# define file type
File_Type = '.*(.txt|.sql|.py|.ksh|.sh|.bat|.dsx)'
# show detail message about the match line
ShowMsg = True


def list_files(path):
    # if type is directory , then collapse it.
    if os.path.exists(path) and not os.path.isfile(path):
        dirs = os.listdir(path)
        yield from [os.path.join(path, x) for x in dirs if re.search(File_Type, x, re.I)]
    else:
        yield path


# list_files wrapper， a func show all sub files.
# Usage:
#      func = list_files(path)
#      for f in list_all_files(func):
#          print(f)
def list_all_files(f):
    def wrapped_f(path):
        for sub in f(path):
            wrapped_f(sub)
        yield from f(path)
    return wrapped_f


def match_keyword(file, keyword, ttype=True):
    filter_words = re.compile(keyword, re.I)
    # if not a valid file, exit
    if not os.path.isfile(file):
        pass
    with open(file, 'r') as f:
        lines = f.readlines()
        try:
            pre_line = ''
            for line in lines:
                if line.strip().startswith('--'):
                    continue
                if filter_words.search(line):
                    if not ttype:
                        return file
                    else:
                        pre_msg = '\   ' + pre_line if pre_line else ''
                        msg = file + '\n' + pre_msg + '\-----> ' + line
                        return msg
                pre_line = line
        # some unicode character can't deal with utf-8
        except UnicodeError:
            pass


def binary_search(keyword, sub_set):
    if isinstance(sub_set, types.GeneratorType):
        sub_set = list(sub_set)
    if type(sub_set) == str:
        sub_set = [sub_set, ]
    if len(sub_set) >= 2:
        mid = math.floor(len(sub_set) / 2)
        # binary search
        yield from binary_search(keyword, sub_set[0: mid])
        yield from binary_search(keyword, sub_set[mid:len(sub_set)])
    # if sub_set is a list and only one element, fetch the element
    elif len(sub_set) == 1:
        fname = sub_set[0]
        if os.path.isfile(fname):
            yield match_keyword(fname, keyword, ShowMsg)
        elif os.path.isdir(fname):
            files = list_files(fname)
            yield from binary_search(keyword, list(files))
        else:
            error_msg = 'invalid path or file: %s' % fname
            yield error_msg


if __name__ == '__main__':
    file_path = r'C:\Users\SongChen\DSW_Project\DSS\Database\DWDM'

    results = binary_search(r'DWDM1.MAINTNC', file_path)
    for result in results:
        if result:
            print(result)

