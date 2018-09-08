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
        self.tokens_val = []
        self.istokensChange = False
        
    def getTokens(self):
        return self.tokens
    
    def setTokens(self,tokenval,tokenidx):
        self.tokens[tokenidx].value = tokenval

    # extract columns
    def extract_from_column(self):

        '''
        columns_group can collect all tokens between 'DML SELECT' and 'Keyword FROM'
        
        [<DML 'SELECT' at 0x3655A08>, <Whitespace ' ' at 0x3655A68>, <IdentifierList 'me.Sap...' at 0x366E228>,
         <Newline ' ' at 0x3665948>, <Keyword 'FROM' at 0x36659A8>, <Whitespace ' ' at 0x3665A08>,
         <IdentifierList 'SODS2....' at 0x366E390>,
         <Whitespace ' ' at 0x3667228>, <IdentifierList 't,SHAR...' at 0x366E480>, <Newline ' ' at 0x3667528>]
        '''
        
        tokens = self.getTokens()
        tokenlist = TokenList(tokens)
        cols_idx,cols_item = [] , []
        cols_group = []
        '''
            cols_item only keep the columns between select and from.
            Notic : exists many groups if sql have union/union all token , so need use cols_group to collect it.
        '''
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
                cols_group.append (''.join([ item.value for item in cols_item]))
        
        '''
        the cols_idx like [[10,12],[24,26]],it's two-dimnsn list , --> flatten to [10,11,12,24,25,26]
        '''
        cols_idxes = sum([list(range(cols_idx[2*i],cols_idx[2*i+1]+1)) for i in range(int(len(cols_idx)/2))],[]) 
        
        keep_tokens = [ item for idx,item in enumerate(tokens) if idx not in cols_idxes ]
        self.tokens = keep_tokens
        self.tokens_val = [item.value for item in tokens]
        return cols_group

    
    def split_column(self,strcols):

        # split string to columns use comma ',' ,exception 1)comma inside a pair of parenthesis 2)the line begin with '--'
        # record comma ','

        comma_stack = [-1,]
        split_group = []
        # find pair of parenthesis and load to stack.
        # then check comma if outside parenthesis pairs,if yes,it can used to split
        l_pare_num , r_pare_num ,stack = 0 ,0 ,[]
        
        strcols += ','
        for idx,value in enumerate(strcols):
        
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
                    split_column = strcols[comma_stack[0]+1:comma_stack[1]]
                    print ('split_column: ' + split_column)
                    if re.search(r'^\s*[\w\'(]+.*',split_column,re.M):
                        split_group.append(split_column)
                        comma_stack.pop(0)                
                    else:
                        #' --END ,' this case can't be split to a column
                        comma_stack.pop(1)
        return split_group

    # check user-defined sql column num is equal with table column num
    def is_equal_col_length(self,scols,tcols):
        if type(scols) == list and len(scols) == len(tcols):
            return True
        else:
            return False
                
    def check_column_status(self,itemval):

       #check the column type if varchar
       CHECK_REGEX_VARCHAR = re.compile(r"""
               ^case((?!timestamp\(|date\().)*end |
               ^coalesce((?!timestamp|date).)*\)  |
               ^[l|r]?trim.*                      |
               ^'(?:[^"\\]|[.])*?'                |
               ^"(?:[^'\\]|[.])*?" 
           """,re.X|re.M|re.I)
       #check the column type if int
       CHECK_REGEX_INT = re.compile(r"""
               ^[0-9]+
           """,re.X|re.M|re.I
       )
       #check the column if have alias
       CHECK_REGEX_ALIAS = re.compile(r"""
               current(\s+\w+){2,3}               |  # current timestamp as ts or current timestamp ts  
               ^(?!current)[^.]+[^\.\w]\w+$       |  # not start with current
               ^[^.]+[.].+[^\.\w]\w+$
           """,re.X|re.M|re.I
       )
       check_var_type = re.match(CHECK_REGEX_VARCHAR,itemval.lstrip())
       check_int_type = re.match(CHECK_REGEX_INT,itemval.lstrip())
       check_alias = re.match(CHECK_REGEX_ALIAS,itemval.lstrip())

       status = ''
       if check_var_type or check_int_type:
           status = 'type'
       if check_alias:
           status = status + 'als'
       return status
    
                
    def replace_column_name(self,cols,cn):
        
        trgtcols = self.trgt
        typecols = self.types
        type_trans = self.type_trans

        # get column alias
        GET_REGEX_ALIAS = re.compile(r'\w+$',re.I|re.M)

        # get column real name
        STRIP_REGEX_ALIAS = re.compile(r"""
           ^.*?(?=(\s+as\s+\w+)+$)    |
           ^.*(?=\s+\w+$)
           """,re.X|re.M|re.I
        )

        try:
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

            scols = self.split_column(cols)

            # if source sql columns can't match column num of table columns,columns not do replace operation.
            # it should be sql splited wrong/sub query/exist '*' char.
            
            if self.is_equal_col_length(scols,trgtcols) :
                map_cols = zip_longest(scols,trgtcols,typecols,type_trans)
                cols_replace = []
                for mapcol in map_cols:
                    col = mapcol[0]
                    trgtcol = mapcol[1]
                    typecol = mapcol[2]
                    type_tran = mapcol[3]
                    check_status = self.check_column_status(col)
                    if re.search(GET_REGEX_ALIAS,col):
                        col_alias_name = re.search(GET_REGEX_ALIAS,col).group()
                    else:
                        col_alias_name = ''

                    '''
                    type means column type is char or int,maybe should do type transfer
                    als means column has alias                                
                    '''
                    if check_status in ('typeals','als'):
                        try:
                            col_strip_alias_name = re.search(STRIP_REGEX_ALIAS,col).group()
                        except AttributeError:
                            print (col)
                    else:
                        col_strip_alias_name = col
                        
                    if check_status == 'type' and typecol in ('1','5'):
                        self.istokensChange = True
                        col = 'cast(' + col + ' ' + 'as' + ' ' + type_tran + ')' + ' ' + 'as' + ' ' + trgtcol
                        
                    elif check_status == 'als':
                        
                        if col_alias_name.lower() != trgtcol.lower():
                            self.istokensChange = True
                            col = col_strip_alias_name + ' ' + 'as' + ' ' + trgtcol
                            #col = re.sub(GET_REGEX_ALIAS,trgtcol,col)       
                            
                    elif check_status == 'typeals':
                        self.istokensChange = True
                        if col_alias_name.lower() != trgtcol.lower():
                            if typecol in ('1','5'):
                                col = 'cast(' + col_strip_alias_name + ' ' + 'as' + ' ' + type_tran + ')' \
                                      + ' ' + 'as' + ' ' + re.sub(GET_REGEX_ALIAS,trgtcol,col)
                            else:
                                col = re.sub(GET_REGEX_ALIAS,trgtcol,col)
                        else:
                            if typecol in ('1','5'):
                                col = 'cast(' + col_strip_alias_name + ' ' + 'as' + ' ' + type_tran + ')' \
                                      + ' ' + 'as' + ' ' + col_alias_name
                    else:
                        if col_alias_name.lower() != trgtcol.lower():
                            self.istokensChange = True
                            col = col + ' ' + 'as' + ' ' + trgtcol            
                    cols_replace.append(col)
                #print (cols_replace)
                if self.istokensChange == True:
                    cols = ','.join(cols_replace)
                    cols = ' ' + cols + '\n'
                    self.update_column_tokens(cols,cn)
            #columns num not match with the trgtcols
            else:
                self.update_column_tokens(cols,cn)
        except Exception as e:
            print ('Function replace_column_name : ' + str(e))
        return self.tokens
    
    def update_column_tokens(self,cols,cn=0) :


        tokens_part = self.tokens
        tokens_val = self.tokens_val
        
        from_index_list = [tokens_part.index(token) for token in tokens_part \
                             if token.ttype is Keyword and token.value.upper() == 'FROM']
        
        try:
            tokens_val.insert(from_index_list[cn],cols)
            self.tokens_val = tokens_val
        except Exception as e:
            print ('Function update_column_tokens : ' + str(e))

            
def parse_xml_sql(dict_object):
    parsed = usersqlParse(dict_object)
    print ('')
    print ('SQL Pared Tokens :')
    print (parsed.getTokens())
    column_group = parsed.extract_from_column()
    print (column_group)
    for cols in column_group:
        cn = column_group.index(cols)
        parsed.replace_column_name(cols,cn)
    update_sql = ''.join(parsed.tokens_val)
    print ('Update SQL Flag : ' + str(parsed.istokensChange))
    print ('')
    if parsed.istokensChange == True:
        print (update_sql)
    else:
        pass
    
    
    return parsed.istokensChange,update_sql
    
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


