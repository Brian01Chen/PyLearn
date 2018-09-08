#!/usr/bin/python  
#-*- coding: utf-8 -*-

import os
import re
from parsexmlsql import usersqlParse,parse_xml_sql
import parsexmlnode
import codecs


def readfile(base='.',patrn='.*(?<!update)[.]xml',circle=True):

    pattern = re.compile(patrn,re.I)
    if base == '.':
        base = os.getcwd()
    conf = os.path.join(base,'config.txt')
    if not os.path.exists(conf):
        print ('config file not exists')
    f = codecs.open(conf,'r','utf-8')
    try:
        lines = f.readlines()
        for line in lines:
            print (line)
            if (len(line.rstrip()) == 0 ):
                continue
            if (line.startswith('#')):
                continue
            if os.path.isdir(line):
                xml_list = os.listdir(line)
                for item in xml_list:
                    if pattern.match(item):
                        full_path = os.path.join(line,item)
                        parseJob(full_path)
            if os.path.isfile(line) and pattern.match(line):
                parseJob(line)
    except Exception as e:
        print ('Function readfile : ' + str(e))
        
def parseJob(filename):

    tree = parsexmlnode.getTree(filename)
    collections = parsexmlnode.getSourceCollection(tree)
    usersqldiclist = parsexmlnode.getSourceInfo(collections)
    
    for sqldict in usersqldiclist:
        print ('\n\n')
        print ('Parse XML Info :')
        print (sqldict)
        
        update_flag,update_sql = parse_xml_sql(sqldict)
        
        if update_flag == True:
            sqldict_after_update = sqldict 
            sqldict_after_update['usersql'] = update_sql
            #print (sqldict_after_update['usersql'])
            
            parsexmlnode.updateSourceInfo(sqldict_after_update,tree,filename)

if __name__ == '__main__':
    readfile()
