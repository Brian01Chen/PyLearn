#!/usr/bin/python  
#-*- coding: utf-8 -*-

import sqlparse
from sqlparse.sql import IdentifierList, Identifier , Token,TokenList
from sqlparse.tokens import Keyword,Whitespace
import re
from itertools import zip_longest

class usersqlParse(object):
    def __init__(self,source):

        #source is dict type
        self.src = source['usersql']    
        self.trgt = source.setdefault('name','')
        self.types = source.setdefault('type','')
        self.type_trans = source.setdefault('trans','')
            
        parsed = sqlparse.parse(self.src)
        self.tokens = parsed[0].tokens
        
    def getTokens(self):
        return self.tokens
    
    def setTokens(self,tokenval,tokenidx):
        self.tokens[tokenidx].value = tokenval

    def extract_from_column(self):

        '''
        pick up all tokens between 'DML SELECT' and 'Keyword FROM'
        
        [<DML 'SELECT' at 0x3655A08>, <Whitespace ' ' at 0x3655A68>, <IdentifierList 'me.Sap...' at 0x366E228>,
         <Newline ' ' at 0x3665948>, <Keyword 'FROM' at 0x36659A8>, <Whitespace ' ' at 0x3665A08>,
         <IdentifierList 'SODS2....' at 0x366E390>,
         <Whitespace ' ' at 0x3667228>, <IdentifierList 't,SHAR...' at 0x366E480>, <Newline ' ' at 0x3667528>]
        '''
        
        tokens = self.getTokens()
        tokenlist = TokenList(tokens)
        cols_idx,cols_item = [] , []
        cols_group = []
        fetch_col_flag = False
        for idx, item in enumerate(tokens):
            before_idx,before_item = tokenlist.token_prev(idx,skip_ws=True)
            next_idx,next_item = tokenlist.token_next(idx,skip_ws=True)
            if not next_item :
                break
            #capture up first column index
            if (isinstance(item,IdentifierList) or isinstance(item,Identifier)) and \
                (before_item.ttype == Keyword.DML or before_item.value.upper() == 'DISTINCT'):
                cols_idx.append(idx)
                fetch_col_flag = True
                cols_item = []                
            if fetch_col_flag == True:
                cols_item.append(item)
            #capture up last column index
            if (isinstance(item,IdentifierList) or isinstance(item,Identifier)) and \
                next_item.ttype is Keyword and next_item.value.upper() == 'FROM':
                cols_idx.append(idx)
                fetch_col_flag = False
                cols_group.append (cols_item)
        
        cols_idxes = sum([list(range(cols_idx[2*i],cols_idx[2*i+1]+1)) for i in range(int(len(cols_idx)/2))],[]) 
        
        left_tokens = [ item for idx,item in enumerate(tokens) if idx not in cols_idxes ]



    def split_column(self,strcols):

        # split string to columns use comma ',' ,exception 1)comma inside a pair of parenthesis 2)the line begin with '--'
        # record comma ','

        comma_stack = [0,]
        split_group = []
        # find pair of parenthesis and load to stack.
        # then check comma if outside parenthesis pairs,if yes,it can used to split
        l_pare_num , r_pare_num ,stack = 0 ,0 ,[]
        
        for idx,value in enumerate(strcols+','):
        
            if value == '(':
                l_pare_num += 1
                if l_pare_num == 1:
                    stack.append(idx)
            if value == ')':
                r_pare_num += 1
                if l_pare_num == r_pare_num:
                    stack.append(idx)
                    # release
                    l_pare_num , r_pare_num , stack = 0,0,[]
            # if stack is empty ,it means current comma out of pair of parenthesis.
            if value == ',':
            
                if len(stack) == 0 :
                    comma_stack.append(idx)
                    split_column = strcols[comma_stack[0]:comma_stack[1]]
                    if re.search(r'^\s+[\w\'(]+.*',split_column,re.M):
                        split_group.append(split_column)
                        comma_stack.pop(0)                
                    else:
                        #' --END ,' this case can't be split to a column
                        comma_stack.pop(1)
        return split_group    

            
def parse_xml_sql(dict_object):
    parsed = usersqlParse(dict_object)
    print ('')
    print ('SQL Pared Tokens :')
    print (parsed.getTokens())
    parsed.extract_from_column()
    tt = """
case when (select max(ODS_LOAD_DATE) from utol.load_log where table_name='ENTL1.ENTMT_SUM_FACT_ME' AND ODS_LOAD_STAT_CODE='DONE') is null
          then '1900-1-1 00:00:00.000000'
     else (select max(ODS_LOAD_DATE) from utol.load_log where table_name='ENTL1.ENTMT_SUM_FACT_ME' AND ODS_LOAD_STAT_CODE='DONE')
               end AS last_tab_ts,
\ncase when (select max(SAP_ODS_MOD_DATE) from SODS2.MNGED_ENTMT) is null
       then '1900-1-1 00:00:00.000000' else (select max(SAP_ODS_MOD_DATE) from SODS2.MNGED_ENTMT) end as cur_ta,
\ncurrent timestamp,
\ncase when colesce(ts.sap_sales_org_code,'') in ('0483','0512','0412') then 1 else 0 end as flag,
\n(qty  - 10 + 20 ) as qty,
-- filter column name,
'ENTL1.ENTMT_SUM_FACT_ME' as table_nae"""
    g = parsed.split_column(tt)
    print (g)
    
if __name__ == '__main__':
    sql = {'precision': ['5', '20', '90', '50', '50', '35', '20', '10', '10', '10', '10', '20', '20', '250', '90', '10', '1'],
           'name': ['MIGRTN_CODE', 'CUST__035__', 'NAME', 'ADR_1', 'ADR_2', 'CITY', 'STATE_NAME', 'STATE_CODE', 'ZIPCODE', 'CNTRY_CODE_2', 'CNTRY_CODE', 'REGION',\
                    'STATUS', 'CDM_COMMENTS', 'RESELLER_NAME', 'IBM_CUST_NUM', 'NEW_RDH_SITE'],

           'trans': ['char(5)', 'char(20)', 'char(90)', 'char(50)', 'char(50)', 'char(35)', 'char(20)', 'char(10)', 'char(10)', 'char(10)', 'char(10)', 'char(20)', 'varchar(20)', 'varchar(250)', 'char(90)', 'varchar(10)', 'char(1)'],
           'usersql': "with temp as (select hello from syscat.sysdummy1) SELECT DISTINCT b.MIGRTN_CODE,b.CUST#,a.NAME,a.ADR_1,a.ADR_2,SUBSTR(TRIM(a.CITY),1,30),a.STATE_NAME,\na.STATE_CODE,a.ZIPCODE,a.CNTRY_CODE_2,a.CNTRY_CODE,a.REGION,\
            \nrtrim(coalesce(b.STATUS,'')),\nltrim(rtrim(coalesce(b.CDM_COMMENTS,''))),\na.RESELLER_NAME,\ncoalesce(b.IBM_CUST_NUM,''),\ncoalesce(b.NEW_RDH_SITE,'') \
            FROM CDM0.CUST_DATA_AUDIT_QS a, CDM1.cust_data b\nwhere a.MIGRTN_CODE = b.MIGRTN_CODE \nand a.cust# = b.CUST#;",
           'jobname': 'Update_Cust_Data_Name_Address'}
    sql2 = {'usersql':
            """
with meo as (select sold_to_cust_num from meo)

SELECT distinct '1',
case when (select max(ODS_LOAD_DATE) from utol.load_log where table_name='ENTL1.ENTMT_SUM_FACT_ME' AND ODS_LOAD_STAT_CODE='DONE') is null then '1900-1-1 00:00:00.000000' else (select max(ODS_LOAD_DATE) from utol.load_log where table_name='ENTL1.ENTMT_SUM_FACT_ME' AND ODS_LOAD_STAT_CODE='DONE') end AS last_tab_ts,
case when (select max(SAP_ODS_MOD_DATE) from SODS2.MNGED_ENTMT) is null then '1900-1-1 00:00:00.000000' else (select max(SAP_ODS_MOD_DATE) from SODS2.MNGED_ENTMT) end as cur_ta,
current timestamp,'ENTL1.ENTMT_SUM_FACT_ME' as table_nae
 FROM sysibm.sysdummy1,sysibm.sysdummy2,sysibm.sysdummy3
 
union all 

SELECT '2',
case when (select max(ODS_LOAD_DATE) from utol.load_log where table_name='ENTL1.ENTMT_SUM_FACT_ME_D' AND ODS_LOAD_STAT_CODE='DONE') is null then '1900-1-1 00:00:00.000000' else (select max(ODS_LOAD_DATE) from utol.load_log where table_name='ENTL1.ENTMT_SUM_FACT_ME_D' AND ODS_LOAD_STAT_CODE='DONE') end AS last_tab_ts,
case when (select max(DELETE_DATE) from SODS2.MNGED_ENTMT_DELETE) is null then '1900-1-1 00:00:00.000000' else (select max(DELETE_DATE) from SODS2.MNGED_ENTMT_DELETE) end as cur_tab_ts,
current timestamp as b, 'ENTL1.ENTMT_SUM_FACT_ME_D' as table_name
 FROM sysibm.sysdummy1""",'name':['id','last_tab_ts','cur_tab_ts','cur_ts','table_name']}
    sql3 = {'usersql': """SELECT me.Sap_Sales_Org_Code,me.Sap_Ctrct_Num_G,
lkp.ENTMT_SYS_REVN_STREAM_CAT_CODE,
cast(c.CODE as varchar(2)),
c.CODE_DSCR as code,
cast(sum(Sbscrptn_Id_Qty) as decimal(15,3)) as PART_QTY,
cast(sum(Net_Sbscrptn_Id_Qty) as decimal(15,3)) as NET_PART_QTY
FROM SODS2.MNGED_ENTMT me,SHAR2.ENTMT_SYS_REVN_STREAM_CODE_LOOKUP lkp, SHAR2.MNGED_ENTMT_PROG_LINE_BUS_XREF mep,temp t,SHAR2.CODE_DSCR c
""",'name' : ['Sap_Sales_Org_Code','Sap_Ctrct_Num','ENTMT_SYS_REVN_STREAM_CAT_CODE','LINE_OF_BUS_CODE','LINE_OF_BUS_CODE_DSCR',\
                      'SBSCRPTN_ID_QTY','NET_SBSCRPTN_ID_QTY']}

    
    parse_xml_sql(sql2)


