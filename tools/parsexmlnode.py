#!/usr/bin/python  
#-*- coding: utf-8 -*-

import re
try:
    import xml.etree.cElementTree as ET
except ImportError:
    import xml.etree.ElementTree as ET
from itertools import zip_longest

'''
<Collection Name="Properties" Type="CustomProperty">
...
    <SubRecord>
        <Property Name="Name">USERSQL</Property>
        <Property Name="Value" PreFormatted="1"> with temp as (...)
            select '1', tabname from sysibm.sysdummy1
            with ur;
        </Property>
    </SubRecord>
...
<Collection Name="Columns" Type="OutputColumn">
    <SubRecord>
        <Property Name="Name">ID</Property>
        ...
'''

def getTree(filename):
    tree = ET.parse(filename)
    return tree

def getSourceCollection(tree):

    
    root = tree.getroot()
    #get DataStage XML all Record Node which contains 'SOURCETABLES'.
    #old stage type all use the sourcetables to indicate the database stage.
    try:
        joblist = root.findall('.//Job')
        element_group = []
        for jobnode in joblist:
        
            jobname = jobnode.get('Identifier')
            print ('start to anaylse: ' + jobname)
            record = jobnode.findall(".//Record")
            recordsrc = []

            #one job can exist more than two source table 
            for rd in record:
                for pro in rd.iter('Property'):
                    if pro.text == 'SOURCETABLES':
                        recordsrc.append(rd)
            if len(recordsrc) == 0:
                continue
        
            for rd in recordsrc:
                collection = []
                colls = rd.findall("./Collection")
                for coll in colls :
                    collection.append(coll)

                element_group.append(jobnode)
                element_group.append(collection)
    except Exception as e:
        print ('Parsexmlnode.py Function getSourceCollection : ' + str(e))
    return element_group

    
    

def getSourceInfo(element_group):

    compareDic ={}.fromkeys(('jobname','node','usersql','name','type','precision','trans'))
    compareList = []
    CurrentNode = ''
    Source = ''
    Tcol = []
    Ttype = []
    Tprecision = []
    Ttrans = []
    jobname = ''
    
    for elements in element_group:
        
        if isinstance(elements,ET.Element) and elements.tag == 'Job':
            jobname = elements.get('Identifier')
            continue
        
        for ele in elements:
            
            # coll corresponding to database stage 'SQL' and 'Columns' page
            if ele.tag == 'Collection' and ele.get('Name') == 'Properties':
                sqlnode = ele.find(".//SubRecord/[Property='USERSQL']")
                #sqlnode.iter();list(sqlnode);sqlnode.itertext()
                if len(sqlnode.getchildren()) == 1:
                    continue
                for item in sqlnode.getchildren():
                    if item.text != 'USERSQL':
                        CurrentNode = item
                        Source = item.text

            # get column properties : name,type,precision,scale
            if ele.tag == 'Collection' and ele.get('Name') == 'Columns':
                try:
                    
                    Property_name = ele.iterfind('.//SubRecord/Property[@Name="Name"]')
                    Property_type = ele.findall('.//SubRecord/Property[@Name="SqlType"]')
                    Property_precision = ele.findall('.//SubRecord/Property[@Name="Precision"]')

                    '''
                            Datastage data type map relationship
                            1  char                   -8 nchar
                            2  numeric                
                            3  Decimal
                            4  integer
                            5  smallint               -5 bigint
                            6  float
                            7  Real
                            8  Double
                            9  Date
                            10 Time
                            11 timestamp
                            12 varchar                -9 nvarchar
                    '''

                    
                    def typetran(x):
                        if x == '1':
                            return 'char'
                        elif x == '12':
                            return 'varchar'
                        elif x == '4':
                            return 'integer'
                        elif x == '5':
                            return 'smallint'
                        elif x == '-5':
                            return 'bigint'
                        else:
                            return x

                    Tcol = [elem.text for elem in Property_name]
                    Ttype = [elem.text for elem in Property_type]
                    Tprecision = [elem.text for elem in Property_precision]
                    Ttrans = [ typetran(elems[0].text) + '(' + elems[1].text + ')' if elems[0].text in ('1','12') \
                                            else typetran(elems[0].text) if elems[0].text in ('4','5','-5') else elems[0].text  for elems in zip_longest(Property_type,Property_precision)]
                    #print (Ttrans)
                except Exception as e:
                    print ('Parsexmlnode.py Function getSourceInfo : ' + str(e))
        if CurrentNode == '' or Source == '':
            pass
        else:
            compareDic['jobname'] = jobname
            compareDic['node'] = CurrentNode
            compareDic['usersql'] = Source
            compareDic['name'] = Tcol
            compareDic['type'] = Ttype
            compareDic['precision'] = Tprecision
            compareDic['trans'] = Ttrans
            compareDiccopy = compareDic.copy()
            compareList.append(compareDiccopy)
        #print (compareList)
    return compareList

def updateSourceInfo(obj,tree,filename,option = 0):
    # filename backup
    filename = filename.rstrip('.xml')+'_update.xml'
    # strip columns unicode info
    if option == 0:      
        extention_list = tree.iterfind('.//Property[@Name="ExtendedPrecision"]')
        delete_count = 0
        for extention in extention_list:
            if extention.text == '1':
                extention.text = '0'
                delete_count += 1
        if delete_count > 0 :
            print ('XML Columns Unicode Delete')
    try:
        if type(obj) == dict:
            jobname = obj['jobname']
            if obj['node'].text != obj['usersql']:
                CurrentNode = obj['node']
                CurrentNode.text = obj['usersql']
                tree.write(filename,'UTF-8',True)
                print ('update done')
                print (jobname + ' User-Define SQL already updated')
        elif type(obj) == list:
            for dic in obj:
                jobname = dic['jobname']
                if dic['node'].text != dic['usersql']:
                    dic['node'].text = dic['usersql']
                    tree.write(filename,'UTF-8',True)
                    print (jobname + ' User-Define SQL already updated')
    except Exception as e:
        print ('Parsexmlnode.py Function updateSourceInfo : ' + str(e))
        
              

if __name__ == '__main__':   
    filename = r'C:\Users\IBM_ADMIN\AppData\Local\Programs\Python\Python35\mysrc\tools\log analyse\ds log\Capture_ESF_change_144.xml'
    tree = getTree(filename)
    collections = getSourceCollection(tree)
    usersqllist = getSourceInfo(collections)
    updateSourceInfo(usersqllist,tree,filename,option = 0)
    
