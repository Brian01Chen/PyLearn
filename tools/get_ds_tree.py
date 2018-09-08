import xml.etree.ElementTree as ET
import re
import sqlparse
from sqlparse import tokens
import traceback
'''
<Collection Name="Properties" Type="CustomProperty">
...
    <SubRecord>
        <Property Name="Name">USERSQL</Property>
        <Property Name="Value" PreFormatted="1"> txt</Property>
    </SubRecord>
...
<Collection Name="Columns" Type="OutputColumn">
    <SubRecord>
        <Property Name="Name">SAP_SALES_ORG_CODE</Property>
'''


def getSourceSql(filename):
    tree = ET.parse(filename)
    root = tree.getroot()
    compareDic ={}.fromkeys(('usersql','dbcolumn'))
    compareList = []
    #取DataStage XML 下的所有带'SOURCETABLES'的Record(可能存在多个Source Table)
    record = root.findall("./Job//Record[@Type='CustomOutput']")
    recordsrc = []
    for rd in record:
        for pro in rd.iter('Property'):
            if pro.text == 'SOURCETABLES':
                recordsrc.append(rd)
    for rd in recordsrc:
        Scol = []
        Tcol = []
        colls = rd.findall("./Collection")
        for coll in colls :
            #获取Source Sql
            if coll.get('Type') == 'CustomProperty':
                subrecord = coll.find(".//SubRecord/[Property='USERSQL']")
                #subrecord.iter()包括自身节点，list(subrecord)取子节点
                if len(list(subrecord))>1:
                     for item in subrecord.itertext():
                        #搜索带'SELECT'的User-Defined SQL
                        if re.search('select',item,re.I):
                            Scol.append(item)
            #获取Source 字段名
            if coll.get('Type') == 'OutputColumn':
                subrecord = coll.findall(".//SubRecord/Property[@Name='Name']")
                for subprop in subrecord:
                    if len(list(subprop)) == 0:
                        Tcol.append(subprop.text)
        compareDic['usersql'] = Scol
        compareDic['dbcolumn'] = Tcol
        compareDiccopy = compareDic.copy()
        compareList.append(copareDiccopy)
    return compareList

def parseCol(compareDic):

    #Use sqlparse module to parse sql

    # if usersql have with ..() as (select ... ) block ,it need to wrap out for sqlparse
    usersql = compareDic['usersql'][0]
    trgtcol = compareDic['dbcolumn']
    sqlwhole = []
    if usersql.startswith('with'):
        sqlt = re.split('\)(?=\s*select)',usersql)
        sqlwithin,sqlnowithin = sqlt[0] + ')',sqlt[1]
    else:
        sqlwithin = sqlnowithin = sql
    parsed = sqlparse.parse(sqlnowithin)
    sqltoken = parsed[0].tokens
    
    def checkColnum(scols,tcols):
        cols = re.split(',(?![\s\w\.\']*[\)])',scols,len(tcols)-1,re.I)
        if len(cols) == len(tcols):
            return cols
        else:
            return None
    for token in sqltoken:
        #token type: select ,distinct ,identifier,from,where,group by,order by...
        #identifier is the columns collention

        if isinstance((token),sqlparse.sql.IdentifierList):

            try:
                if 'from' in str(sqltoken[sqltoken.index(token)+1]).lower() or \
                   'from' in str(sqltoken[sqltoken.index(token)+2]).lower():
                    cols = checkColnum(str(token),trgtcol)
                    
                    cols_update = []
                    if cols:
                        i = 0
                        for col in cols:
                            col = replaceAlias(col,trgtcol[i])
                            i = i+1
                            cols_update.append(col)
                        cols_update_str = u''.join(col for col in cols_update)
                        token_update = sqlparse.sql.Token(tokens.Token,cols_update_str)
                        sqltoken[sqltoken.index(token)] = token_update       

            except IndexError:
                pass
    sqlnowith = r''.join(token.value for token in sqltoken)
    sqlwhole = r''.join((sqlwithin,sqlnowith))
    return sqlwhole


def replaceAlias(col,trgtcol):
    
    ## col           trgt                   match       fix
    ## ctrct_num_g   ctrct_num              n           ctrct_num_g as ctrct_num
    ## ctrct_num     ctrct_num_g            n           ctrct_num as ctrct_num_g
    ## 0             qty                    n           0 as qty
    ## sap as ods    sap_ods                n           sap as sap_ods
    ## me.start      start                  y
    ## coalesce(cust,'') cust_num cust_num  y
    ## end as end_g  end_g                  y
    ## 'case when lkp.ENTMT_SYS_REVN_STREAM_CAT_CODE in(&apos;LIC&apos;,&apos;SAAS&apos;) then &apos;\
    ##             01/01/1900&apos; else me.Start_Date end as start_date'   start_date  y
    
    pattern1 = re.compile('\w*[.]?\w+',re.I)
    #extract last word 
    pattern2 = re.compile('\w+$',re.I)
    if re.findall(pattern2,col):
        # if exist alias name,it should be replaced.
        if len(re.findall(pattern1,col))>1:
            if re.findall(pattern2,col)[0].lower() != trgtcol.lower():
                col = re.sub(pattern3,trgtcol,col,1)
        else:
            # if not exist alias name,it should be added.
            if re.findall(pattern2,col)[0].lower() != trgtcol.lower():
                col = col + ' ' + 'as' + ' ' + trgtcol
    else:
        # if last char is not word type ,like ')' ,then it should add alias column name
        col = col + ' ' + 'as' + ' ' + trgtcol
    return col



if __name__ == '__main__':   
    filename = r'C:\Users\IBM_ADMIN\AppData\Local\Programs\Python\Python35\mysrc\tools\log analyse\ds log\Populate_ELA_Dimnsn.xml'
    compareList = getSourceSql(filename)
    for compareDic in compareList:
        colgroup = parseCol(compareDic)

