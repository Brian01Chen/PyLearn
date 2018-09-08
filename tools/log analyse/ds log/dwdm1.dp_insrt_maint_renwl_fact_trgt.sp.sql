DROP PROCEDURE DWDM1.DP_INSRT_MAINT_RENWL_FACT_TRGT
@
CREATE PROCEDURE DWDM1.DP_INSRT_MAINT_RENWL_FACT_TRGT(IN P_LOG_NAME VARCHAR(128),
                                                      IN P_END_DATE DATE,
                                                      IN P_START_DATE DATE,
                                                      OUT P_STATUS INTEGER)

-- ======================================================================
--
-- Author: 
--
-- History:
-- ----------------------------------------------------------------------
--
-- Sep 2 2013  Ethan  DSW 13.4:  1. Add columns  APPLNC_QTY_FLAG,TRGT_NON_IBM_APPLNC_FLAG
--                               2. Fetch value from HW_MACH_MODEL_G,HW_MACH_SERIAL_NUM_G
--                               3. Change apl.APPLNC_FLAG = 1 to AL3.APPLNC_QTY_FLAG = 1
--                               4. Ues bus_mdl_type_code instead of REVN_STREAM_CAT_CODE
--                               5. add with ur for 
-- 12 17 2013-Ethan-DSW 14.1:Add Exclude entitlements coming due for renewal on or after the divestiture EOL Date
-- 01 08 2014-Ethan-DSW 14.1:change HW_MACH_SERIAL_NUM to HW_MACH_SERIAL_NUM_G and HW_MACH_MODEL to HW_MACH_MODEL_G on line 330
-- 01 22 2014-Ethan-DSW 14.2:Change subset EVOL_CHECK from meoh,change soli join condition
-- 01 26 2014-Ethan-DSW 14.2:Add bp_trnsfr_of_ownrshp_flag logic and apxfow
-- 07/31/2014 May - DSW 14.4: Include multi year Tokens having S&S revenue in S&S Dashboard (ACV & VRR)
-- 12/03/2015 Tim - Add one column into Target Work table insert from Target archive table, SALES_ORD_HIGH_LEVEL_ITEM
-- 12/21/2015 Susie - DSW 16.1 Change for exclude Bridge to Cloud business logic
-- ====================================================================== 
                                                     
    SPECIFIC INS_MNT_RNWL_TRGT
    MODIFIES SQL DATA
    NOT DETERMINISTIC
    NULL CALL
    LANGUAGE SQL
    BEGIN NOT ATOMIC

    ------------------------------------------------------------- 1.9
    -- Variables declarations
    -------------------------------------------------------------
    -- Generic Variables
     DECLARE SQLCODE                    INTEGER     DEFAULT 0 ;
     DECLARE SQLSTATE                   CHAR(5)     DEFAULT '00000';

    -- Generic HANDLER variables
     DECLARE H_SQLCODE                  INTEGER     DEFAULT 0;
     DECLARE H_SQLSTATE                 CHAR(5)     DEFAULT '00000';
     DECLARE H_APPL_NAME                CHAR(20)    DEFAULT 'USER_COLL';

     -- Debug Variables
     DECLARE d_location                 VARCHAR(256);
     DECLARE v_rows_affected            INTEGER     DEFAULT 0;
     DECLARE v_not_found                SMALLINT    DEFAULT 0;
     DECLARE v_status                   INTEGER     DEFAULT 0 ;
     DECLARE v_message                  VARCHAR(256);

     --Local Variables
     DECLARE v_sqlstmt              VARCHAR(2048) ;
     DECLARE v_proc_name            CHARACTER(40)  DEFAULT 'dp_insrt_maint_renwl_fact_trgt';
     DECLARE v_rows_inserted        INTEGER        DEFAULT 0;
--LPP CHANGE START 
     DECLARE v_p_start_date DATE ;
     DECLARE v_p_end_date DATE ;
--LPP CHANGE END
    --*****************************************************************************
    --Condition Declaration
    --*****************************************************************************
    DECLARE TERM_ON_FATAL_ERROR         CONDITION FOR SQLSTATE '80000';
    DECLARE SQL_RESET                   CONDITION FOR SQLSTATE '80100';

 -- Declare Temp Table

  BEGIN
    --*****************************************************************************
    --SQL Reset Handlers Declaration
    --*****************************************************************************
        DECLARE CONTINUE HANDLER FOR sql_reset
          BEGIN NOT ATOMIC
           SET h_sqlcode    = 0;
           SET h_sqlstate   = '00000';
           SET p_status  = 0;
          END;

        DECLARE CONTINUE HANDLER FOR NOT FOUND
          BEGIN NOT ATOMIC
           SET V_NOT_FOUND = 1;
          END;

    --*****************************************************************************
    -- Exception Handler Declaration
    --*****************************************************************************
        DECLARE CONTINUE HANDLER FOR SQLEXCEPTION, SQLWARNING
          BEGIN NOT ATOMIC
            SELECT SQLCODE, SQLSTATE
            INTO   h_sqlcode, h_sqlstate
            FROM   SYSIBM.SYSDUMMY1;

            IF (UTOL.F_GET_ERR_ACTION(h_sqlstate, h_appl_name) < 0 ) THEN
              SET v_message = h_appl_name ||': Exit Handler Detected Fatal Error';
              SET v_message = v_message || ': sql_code: ' || CAST(h_sqlcode as CHAR(6));
              SET v_message = v_message || ':sql_state: ' || h_sqlstate ;
              SET v_message = v_message || ':at section: '|| d_location;
              CALL UTOL.LPRINT(P_LOG_NAME, V_MESSAGE);
              SIGNAL TERM_ON_FATAL_ERROR;
            END IF;
          END;

        DECLARE EXIT HANDLER FOR term_on_fatal_error
          BEGIN NOT ATOMIC
            SET v_message = v_proc_name;
            SET v_message = h_appl_name ||': Exit Handler Detected Fatal Error';
            SET v_message = v_message || ': sql_code: ' || CAST(h_sqlcode as CHAR(6));
            SET v_message = v_message || ':sql_state: ' || h_sqlstate ;
            SET v_message = v_message || ':at section: '|| d_location;
            CALL UTOL.LPRINT(p_log_name, v_message);
            SET P_STATUS = 9;
          END;
    --/*****************************************************************************
    --* Initialization
    --******************************************************************************/
    --Validate Input Parameters
    IF p_log_name is Null THEN
       SET p_log_name = v_proc_name || UTOL.f_gen_stamp(current timestamp);
    END IF;

    IF p_end_date IS NULL THEN
       SET  v_message = 'RMS-ERR : ' || v_proc_name || ' p_end_date input parameter cannot be null' ;
       CALL UTOL.lprint(p_log_name, v_message);
       SET P_STATUS = 9;
       RETURN P_STATUS;
    END IF;

    IF p_start_date IS NULL THEN
        SET  v_message = 'RMS-ERR : ' || v_proc_name || ' p_start_date input parameter cannot be null' ;
        CALL UTOL.lprint(p_log_name, v_message);
        SET P_STATUS = 9;
        RETURN P_STATUS;
    END IF;
--LPP CHANGE START
     set v_p_start_date = P_START_DATE;
     set v_p_end_date = P_END_DATE;
     SET  v_message = 'RMS-INF : Input parameters P_START_DATE :' || cast(v_p_start_date as char(12)) || 'P_END_DATE :' || cast(v_p_end_date as char(12)) ;
     CALL UTOL.lprint(p_log_name, v_message);
	 
	 
--LPP CHANGE END
    SET d_location = 'Truncate DWDM1.MAINTNC_MNGED_ENTMT_ORD table';

    SET  v_message = '1.0 Truncate dwdm1.maintnc_mnged_entmt_ord table at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);

    SET v_sqlstmt = 'ALTER TABLE DWDM1.MAINTNC_MNGED_ENTMT_ORD ACTIVATE NOT LOGGED INITIALLY WITH EMPTY TABLE';
    PREPARE sql1 FROM v_sqlstmt;
    EXECUTE sql1;

    IF h_sqlcode < 0 THEN
       SET v_message = ' RMS-ERR : Failed to truncate dwdm1.maintnc_mnged_entmt_ord table. Process failed with'
                              || 'SQL CODE: '  || CAST(h_sqlcode as CHAR(6))
                              || 'SQL State: ' || h_sqlstate;
       CALL UTOL.LPRINT( p_log_name, v_message );
       SET p_status = 9;
       GOTO ERROR_EXIT;
    END IF;

    SET d_location = 'Insert data from sods2.mnged_entmt_ord meo into dwdm1.maintnc_mnged_entmt_ord table';
    SET  v_message = '1.1 Started Inserting data from sods2.mnged_entmt_ord meo table at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);

    --Step 1.1 : Insert the records from SODS2.MNGED_ENTMT_ORD and setup the evolution flag.

    INSERT INTO DWDM1.MAINTNC_MNGED_ENTMT_ORD
     (REC_ID,               SAP_SALES_ORG_CODE,        MNGED_ENTMT_PROG,
      SOLD_TO_CUST_NUM,     RENWL_CUST_NUM,            SAP_CTRCT_NUM,
      LINE_OF_BUS_CODE,     SW_SBSCRPTN_ID,            REVN_STREAM_CODE,
      END_DATE,             START_DATE,                PART_NUM,
      PART_QTY,             SAP_SALES_ORD_NUM,         EVOLUTION_REC_ID,
      EVOLUTION_FLAG,       ORIGNL_SAP_SALES_ORG_CODE, ORIGNL_SOLD_TO_CUST_NUM,
      ORIGNL_SAP_CTRCT_NUM, ORIGNL_PART_NUM,           ORIGNL_SAP_SALES_ORD_NUM,      
      DATA_WHS_END_USER_CUST_NUM, PRIOR_ACQ_DATA_FLG, ACQ_DATA_FLG, DATA_SRC_CD,
      TRGT_ORD_START_DATE, TRGT_ORD_END_DATE, 
      TRGT_SRC_HW_MACH_TYPE, TRGT_SRC_HW_MACH_MODEL, TRGT_SRC_HW_MACH_SERIAL_NUM,
      TRGT_APPLNC_UPGRD_FLAG,
--Add two columns
      APPLNC_QTY_FLAG,
      TRGT_NON_IBM_APPLNC_FLAG,
      BP_TRNSFR_OF_OWNRSHP_FLAG,
      ORD_LINE_ITEM_SEQ_NUM,
--Add in 16.1
      ENTMT_EXCPTN_CODE)    
    WITH EVOL_CHECK AS
        (SELECT
            MAX(MEO.REC_ID) REC_ID, MEO.SAP_SALES_ORG_CODE, MEO.SOLD_TO_CUST_NUM,
            MEO.END_DATE ,          MEO.START_DATE,         MEO.PART_NUM,
            MEO.SAP_SALES_ORD_NUM, COUNT(*) REC_COUNT
         FROM SODS2.MNGED_ENTMT_ORD MEO
         WHERE MEO.END_DATE >= P_END_DATE AND
               MEO.PART_QTY <> 0 AND
--LPP CHANGE START
		MEO.MNGED_ENTMT_PROG not in ('FCTSL', 'PASL')
--LPP CHANGE END
         GROUP BY MEO.SAP_SALES_ORG_CODE, MEO.SOLD_TO_CUST_NUM, MEO.END_DATE,
                  MEO.START_DATE,         MEO.PART_NUM,         MEO.SAP_SALES_ORD_NUM
            )
    SELECT
       MEO1.REC_ID ,            MEO1.SAP_SALES_ORG_CODE, MEO1.MNGED_ENTMT_PROG,
       MEO1.SOLD_TO_CUST_NUM,   MEO1.RENWL_CUST_NUM,     MEO1.SAP_CTRCT_NUM,
       MEO1.LINE_OF_BUS_CODE,   MEO1.SW_SBSCRPTN_ID,     MEO1.REVN_STREAM_CODE,
       MEO1.END_DATE ,          MEO1.START_DATE,         MEO1.PART_NUM,
       MEO1.PART_QTY ,          MEO1.SAP_SALES_ORD_NUM , A.REC_ID  AS EVOLUTION_REC_ID,
       CASE WHEN A.REC_COUNT = 1 THEN 'N'
            ELSE 'Y' END AS
       EVOLUTION_FLAG,          MEO1.SAP_SALES_ORG_CODE, MEO1.SOLD_TO_CUST_NUM,
       MEO1.SAP_CTRCT_NUM,      MEO1.PART_NUM,           MEO1.SAP_SALES_ORD_NUM,
       CASE WHEN MEO1.LINE_OF_BUS_CODE = 'VP' THEN MEO1.RENWL_CUST_NUM
            ELSE MEO1.SOLD_TO_CUST_NUM
       END AS DATA_WHS_END_USER_CUST_NUM,       
       'N' AS PRIOR_ACQ_DATA_FLG,
       'N' AS ACQ_DATA_FLG,
       'IBM' AS DATA_SRC_CD,
       -- Appliace columns
       MEO1.START_DATE as TRGT_ORD_START_DATE, 
       MEO1.END_DATE   as TRGT_ORD_END_DATE, 
       ''              as TRGT_SRC_HW_MACH_TYPE, 
       ''              as TRGT_SRC_HW_MACH_MODEL, 
       ''              as TRGT_SRC_HW_MACH_SERIAL_NUM,
       'N'             as TRGT_APPLNC_UPGRD_FLAG,
--Add two column
        0              as APPLNC_QTY_FLAG ,
       '0'             as TRGT_NON_IBM_APPLNC_FLAG ,
       'N'             as BP_TRNSFR_OF_OWNRSHP_FLAG ,
       null            as ORD_LINE_ITEM_SEQ_NUM,
--Added in 16.1
       MEO1.ENTMT_EXCPTN_CODE_G as ENTMT_EXCPTN_CODE
     FROM SODS2.MNGED_ENTMT_ORD MEO1 INNER JOIN EVOL_CHECK A
       ON MEO1.SAP_SALES_ORG_CODE = A.SAP_SALES_ORG_CODE AND
          MEO1.SOLD_TO_CUST_NUM   = A.SOLD_TO_CUST_NUM   AND
          MEO1.SAP_SALES_ORD_NUM  = A.SAP_SALES_ORD_NUM  AND
          MEO1.PART_NUM           = A.PART_NUM           AND
          MEO1.START_DATE         = A.START_DATE         AND
          MEO1.END_DATE           = A.END_DATE
    WHERE MEO1.PART_QTY <> 0 AND EXISTS                                                    ----Edit by Ethan: Add <>0
    (SELECT 'X' FROM RSHR2.PROD_DIMNSN PD
     LEFT OUTER JOIN DWDM0.TOKEN_MULTI_YR_SNS_PART P
        ON PD.PART_NUM = P.TOP_BILL_PART_NUM AND
           P.top_bill_revn_stream_code='SFXTLM'		
    WHERE MEO1.SW_SBSCRPTN_ID = PD.SW_SBSCRPTN_ID
    AND (PD.REVN_STREAM_CODE in ('RNWMNTSP', 'ASMAINT','ASRSSHWM','RSSHWM')
	 or p.top_bill_part_num is not null)
    AND NOT (
            COALESCE(PD.SAP_SALES_STAT_CODE,'xx') ='YD'
    AND MEO1.END_DATE >= COALESCE (PD.PROD_EOL_DATE - 1 days,TIMESTAMP_ISO ('9999-12-31')))
    )
     WITH UR;

     GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

     IF h_sqlcode < 0 THEN
        SET v_message = ' RMS-ERR : Failed to insert data into dwdm1.maintnc_mnged_entmt_ord table, with '
                              || 'SQL CODE: '  || CAST(h_sqlcode as CHAR(6))
                              || 'SQL State: ' || h_sqlstate;
         CALL UTOL.LPRINT( p_log_name, v_message );
         SET p_status = 9;
         GOTO ERROR_EXIT;
     END IF;

     SET v_message = 'RMS-INF : Inserted '||cast(v_rows_affected as char(10)) || ' rows into dwdm1.maintnc_mnged_entmt_ord table';
     CALL UTOL.LPRINT( p_log_name, v_message );
     
     
    SET d_location = 'Insert data from sods2.mnged_entmt_ord meo into dwdm1.maintnc_mnged_entmt_ord table';
    SET  v_message = '1.2 Started Inserting data from sods2.mnged_entmt_ord_hw meo table at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);

    --Step 1.2 : Insert the records from SODS2.MNGED_ENTMT_ORD_HW and setup the evolution flag.

    INSERT INTO DWDM1.MAINTNC_MNGED_ENTMT_ORD
     (REC_ID,               SAP_SALES_ORG_CODE,        MNGED_ENTMT_PROG,
      SOLD_TO_CUST_NUM,     RENWL_CUST_NUM,            SAP_CTRCT_NUM,
      LINE_OF_BUS_CODE,     SW_SBSCRPTN_ID,            REVN_STREAM_CODE,
      END_DATE,             START_DATE,                PART_NUM,
      PART_QTY,             SAP_SALES_ORD_NUM,         EVOLUTION_REC_ID,
      EVOLUTION_FLAG,       ORIGNL_SAP_SALES_ORG_CODE, ORIGNL_SOLD_TO_CUST_NUM,
      ORIGNL_SAP_CTRCT_NUM, ORIGNL_PART_NUM,           ORIGNL_SAP_SALES_ORD_NUM,
      DATA_WHS_END_USER_CUST_NUM, PRIOR_ACQ_DATA_FLG, ACQ_DATA_FLG, DATA_SRC_CD,
      TRGT_HW_MACH_TYPE, TRGT_HW_MACH_MODEL, TRGT_HW_MACH_SERIAL_NUM, TRGT_ORD_START_DATE,
      TRGT_ORD_END_DATE, TRGT_WARR_START_DATE, TRGT_WARR_END_DATE, TRGT_CONFIGRTN_ID,
      TRGT_SRC_HW_MACH_TYPE, TRGT_SRC_HW_MACH_MODEL, TRGT_SRC_HW_MACH_SERIAL_NUM,
      TRGT_APPLNC_UPGRD_FLAG,APPLNC_PART_QTY,APPLNC_NET_PART_QTY,
--Add two columns
      APPLNC_QTY_FLAG,
      TRGT_NON_IBM_APPLNC_FLAG,
--Add three columns      
      PRECDNG_DOC_NUM,
      PRECDNG_LINE_ITEM_SEQ_NUM,
      SAP_SALES_DOC_TYPE_CODE,
      BP_TRNSFR_OF_OWNRSHP_FLAG,
	  ORD_LINE_ITEM_SEQ_NUM,
--Added in 16.1 
      ENTMT_EXCPTN_CODE)                                
    WITH EVOL_CHECK AS
        (SELECT
            MAX(MEO.REC_ID) REC_ID,    MEO.SAP_SALES_ORD_NUM, 
            MEO.ORD_LINE_ITEM_SEQ_NUM, COUNT(*) REC_COUNT
         FROM SODS2.MNGED_ENTMT_ORD_HW MEO
         WHERE MEO.END_DATE >= P_END_DATE AND
               MEO.PART_QTY <> 0 AND
--LPP CHANGE START
		MEO.MNGED_ENTMT_PROG not in ('FCTSL', 'PASL')
--LPP CHANGE END
         GROUP BY MEO.SAP_SALES_ORD_NUM,  MEO.ORD_LINE_ITEM_SEQ_NUM     
        )
     , BPTRANS as ( select 
               MEO1.HW_MACH_TYPE_G
              ,MEO1.HW_MACH_MODEL_G
              ,MEO1.HW_MACH_SERIAL_NUM_G
              ,MEO1.START_DATE
    from SODS2.MNGED_ENTMT_ORD_HW MEO1 
   where REVN_STREAM_CODE =  'APXFOW'      
     AND MEO1.END_DATE >= P_END_DATE 
   )
    SELECT
       MEO1.REC_ID ,            MEO1.SAP_SALES_ORG_CODE, MEO1.MNGED_ENTMT_PROG,
       MEO1.SOLD_TO_CUST_NUM,   MEO1.RENWL_CUST_NUM,     MEO1.SAP_CTRCT_NUM,
       MEO1.LINE_OF_BUS_CODE,   MEO1.SW_SBSCRPTN_ID,     MEO1.REVN_STREAM_CODE,
       MEO1.END_DATE ,          MEO1.START_DATE,         MEO1.PART_NUM,
       MEO1.PART_QTY ,          MEO1.SAP_SALES_ORD_NUM , A.REC_ID  AS EVOLUTION_REC_ID,
       CASE WHEN A.REC_COUNT = 1 THEN 'N'
            ELSE 'Y' END AS
       EVOLUTION_FLAG,          MEO1.SAP_SALES_ORG_CODE, MEO1.SOLD_TO_CUST_NUM,
       MEO1.SAP_CTRCT_NUM,      MEO1.PART_NUM,           MEO1.SAP_SALES_ORD_NUM,
       CASE WHEN MEO1.LINE_OF_BUS_CODE = 'VP' THEN MEO1.RENWL_CUST_NUM
            ELSE MEO1.SOLD_TO_CUST_NUM
       END AS DATA_WHS_END_USER_CUST_NUM,
       'N' AS PRIOR_ACQ_DATA_FLG,
       'N' AS ACQ_DATA_FLG,
       'IBM' AS DATA_SRC_CD,
       -- Appliance columns       
       MEO1.HW_MACH_TYPE_G, MEO1.HW_MACH_MODEL_G, MEO1.HW_MACH_SERIAL_NUM_G, ORD_START_DATE, ---change HW_MACH_MODEL_G, HW_MACH_SERIAL_NUM_G
       ORD_END_DATE, MEO1.WARR_START_DATE, MEO1.WARR_END_DATE, MEO1.CONFIGRTN_ID,
       MEO1.SRC_HW_MACH_TYPE, MEO1.SRC_HW_MACH_MODEL, MEO1.SRC_HW_MACH_SERIAL_NUM,
       CASE when MEO1.APPLNC_UPGRD_FLAG = '1' then 'Y' else 'N' END as APPLNC_UPGRD_FLAG,
       MEO1.PART_QTY,
       MEO1.APPLNC_NET_PART_QTY,
--Add two columns
       1  as APPLNC_QTY_FLAG ,
       MEO1.NON_IBM_APPLNC_FLAG,
--Add three columns       
       soli.PRECDNG_DOC_NUM,
       soli.PRECDNG_LINE_ITEM_SEQ_NUM,
       so.SAP_SALES_DOC_TYPE_CODE ,
       CASE when  
             ( MEO1.REVN_STREAM_CODE in( 'ASLISS'  , 'ASRSSHWM')     
               AND   B.HW_MACH_TYPE_G is not null ) then 'Y'   else  'N' end as BP_TRNSFR_OF_OWNRSHP_FLAG ,
       MEO1.ORD_LINE_ITEM_SEQ_NUM	 as ORD_LINE_ITEM_SEQ_NUM,
--Added in 16.1
       MEO1.ENTMT_EXCPTN_CODE_G	  as ENTMT_EXCPTN_CODE
     FROM SODS2.MNGED_ENTMT_ORD_HW MEO1               
    INNER JOIN EVOL_CHECK A    
       ON MEO1.SAP_SALES_ORD_NUM  = A.SAP_SALES_ORD_NUM  
      AND MEO1.ORD_LINE_ITEM_SEQ_NUM = A.ORD_LINE_ITEM_SEQ_NUM    
    INNER JOIN sods2.sales_ord_line_item soli
       ON MEO1.sap_sales_ord_num =  soli.sap_sales_ord_num
      AND MEO1.ord_line_item_seq_num =  soli.line_item_seq_num 
    INNER JOIN SODS2.SALES_ORD SO
       ON MEO1.sap_sales_ord_num  = SO.SAP_SALES_ORD_NUM
     LEFT OUTER JOIN BPTRANS  B
       ON B.HW_MACH_TYPE_G      =  MEO1.HW_MACH_TYPE_G
      AND B.HW_MACH_MODEL_G = MEO1.HW_MACH_MODEL_G
      AND B.HW_MACH_SERIAL_NUM_G = MEO1.HW_MACH_SERIAL_NUM_G
      AND MEO1.END_DATE   <=   B.START_DATE           
    WHERE MEO1.PART_QTY <> 0   and  EXISTS
    (SELECT 'X' FROM RSHR2.PROD_DIMNSN PD
     LEFT OUTER JOIN DWDM0.TOKEN_MULTI_YR_SNS_PART P
        ON PD.PART_NUM = P.TOP_BILL_PART_NUM AND
           P.top_bill_revn_stream_code='SFXTLM'
    WHERE MEO1.SW_SBSCRPTN_ID = PD.SW_SBSCRPTN_ID
    AND (PD.REVN_STREAM_CODE in ('RNWMNTSP', 'ASMAINT','ASRSSHWM','RSSHWM')
	 or p.top_bill_part_num is not null)
    AND NOT (
            COALESCE(PD.SAP_SALES_STAT_CODE,'xx') ='YD'
    AND MEO1.END_DATE >= COALESCE (PD.PROD_EOL_DATE - 1 days,TIMESTAMP_ISO ('9999-12-31')))
    )
     WITH UR;

     GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

     IF h_sqlcode < 0 THEN
        SET v_message = ' RMS-ERR : Failed to insert data into dwdm1.maintnc_mnged_entmt_ord table, with '
                              || 'SQL CODE: '  || CAST(h_sqlcode as CHAR(6))
                              || 'SQL State: ' || h_sqlstate;
         CALL UTOL.LPRINT( p_log_name, v_message );
         SET p_status = 9;
         GOTO ERROR_EXIT;
     END IF;

     SET v_message = 'RMS-INF : Inserted '||cast(v_rows_affected as char(10)) || ' rows into dwdm1.maintnc_mnged_entmt_ord table';
     CALL UTOL.LPRINT( p_log_name, v_message );
     
    --Step 1.3 : Update the dwdm1.maintnc_mnged_entmt_ord for the bp_trnsfr_of_ownrshp_flag. 
	 
	SET d_location = 'update bp_trnsfr_of_ownrshp_flag from DWDM1.MAINTNC_MNGED_ENTMT_ORD table ';
    SET  v_message = '1.3 Started update bp_trnsfr_of_ownrshp_flag from table DWDM1.MAINTNC_MNGED_ENTMT_ORD at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);
 
    update DWDM1.MAINTNC_MNGED_ENTMT_ORD meo
       set meo.bp_trnsfr_of_ownrshp_flag = 'Y'
     where meo.bp_trnsfr_of_ownrshp_flag = 'N'
       and exists
     (select 1
              from DWDM1.MAINTNC_MNGED_ENTMT_ORD meo1
             where meo.SOLD_TO_CUST_NUM = meo1.SOLD_TO_CUST_NUM
               and meo.TRGT_HW_MACH_TYPE = meo1.TRGT_HW_MACH_TYPE
               and meo.TRGT_HW_MACH_MODEL = meo1.TRGT_HW_MACH_MODEL
               and meo.TRGT_HW_MACH_SERIAL_NUM = meo1.TRGT_HW_MACH_SERIAL_NUM
               and meo1.bp_trnsfr_of_ownrshp_flag = 'Y');
             
     GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
     
     IF h_sqlcode < 0 THEN
        SET v_message = 'RMS-ERR : Failed to updating bp_trnsfr_of_ownrshp_flag from dwdm1.maintnc_mnged_entmt_ord table, with '
                              || 'SQL CODE: '  || CAST(h_sqlcode as CHAR(6))
                              || 'SQL State: ' || h_sqlstate;
         CALL UTOL.LPRINT( p_log_name, v_message );
         SET p_status = 9;
         GOTO ERROR_EXIT;
     END IF;

     SET v_message = 'RMS-INF : updated bp_trnsfr_of_ownrshp_flag column for rows: '||cast(v_rows_affected as char(10)) || ' in dwdm1.maintnc_mnged_entmt_ord table';
     CALL UTOL.LPRINT( p_log_name, v_message );
        
     
        
    --Step 1.4 : Update the dwdm1.maintnc_mnged_entmt_ord for the prior_acq_data_flg. 
	 
	SET d_location = 'update prior_acq_data_flg from DWDM1.MAINTNC_MNGED_ENTMT_ORD table ';
    SET  v_message = '1.4 Started update prior_acq_data_flg from table DWDM1.MAINTNC_MNGED_ENTMT_ORD at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);
 
     update DWDM1.MAINTNC_MNGED_ENTMT_ORD meo set meo.PRIOR_ACQ_DATA_FLG = 'Y' 
             where exists (
     select 1
     from dwdm1.prior_acq_entmt 
              where  meo.SOLD_TO_CUST_NUM = SOLD_TO_CUST_NUM 
                  and meo.PART_NUM = TOP_BILL_PART_NUM 
                  and meo.START_DATE = START_DATE 
                  and meo.END_DATE = END_DATE);
             
     GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
     --Remove by Ethan 
     --SET v_message = 'RMS-INF : updated PRIOR_ACQ_DATA_FLG '||cast(v_rows_affected as char(10)) || ' in dwdm1.maintnc_mnged_entmt_ord table';
     --CALL UTOL.LPRINT( p_log_name, v_message );
     
     IF h_sqlcode < 0 THEN
        SET v_message = 'RMS-ERR : Failed to updating prior_acq_data_flg from dwdm1.maintnc_mnged_entmt_ord table, with '
                              || 'SQL CODE: '  || CAST(h_sqlcode as CHAR(6))
                              || 'SQL State: ' || h_sqlstate;
         CALL UTOL.LPRINT( p_log_name, v_message );
         SET p_status = 9;
         GOTO ERROR_EXIT;
     END IF;

     SET v_message = 'RMS-INF : updated PRIOR_ACQ_DATA_FLG column for rows: '||cast(v_rows_affected as char(10)) || ' in dwdm1.maintnc_mnged_entmt_ord table';
     CALL UTOL.LPRINT( p_log_name, v_message );
             

    --Step 3 : Update the original Sale Order information for the Sales Order with ZZDR sap_sales_doc_type_code.

    SET d_location = 'Call Stored Procedure dwdm1.dp_update_maint_meo';
    SET  v_message = '3.0 Execute Stored Procedure dwdm1.dp_update_maint_meo at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);

    CALL DWDM1.DP_UPDT_MAINT_MEO(p_log_name,0,V_STATUS) ;

    IF V_STATUS <> 0 Then
      SET  v_message = 'RMS-ERR : Stored Procedure dwdm1.dp_update_maint_meo failed with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
      CALL UTOL.lprint(p_log_name, v_message);
      set p_status = 9;
      GOTO ERROR_EXIT;
    ELSE
      SET  v_message = 'RMS-INF : Stored Procedure dwdm1.dp_update_maint_meo completed successfully with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
      CALL UTOL.lprint(p_log_name, v_message);
    END IF;
    
    --Step 3.2 : Update the dwdm1.maintnc_mnged_entmt_ord for the acq_data_flg. 
 
     update DWDM1.MAINTNC_MNGED_ENTMT_ORD meo set meo.ACQ_DATA_FLG = 'Y' 
             where meo.CNTRY_CODE is null and meo.IBM_CNTRY_CODE is null 
             and meo.SAP_DISTRIBTN_CHNL_CODE is null and meo.USD_PLAN_GL_POSTED_AMT is null
             and meo.PRIOR_ACQ_DATA_FLG = 'N'  and  exists ( select 1
                           from sods2.sales_ord_line_item sol 
                           where meo.SAP_SALES_ORD_NUM = sol.SAP_SALES_ORD_NUM 
                                  and meo.PART_NUM = sol.PART_NUM 
                                  and meo.START_DATE = sol.START_DATE 
                                  and meo.END_DATE = sol.END_DATE 
                                  and sol.ACQSTN_SBSCRPTN_SPPRT_USD_TOT is not null );
                                  
     GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
     
     SET v_message = 'RMS-INF : updated ACQ_DATA_FLG '||cast(v_rows_affected as char(10)) || ' in dwdm1.maintnc_mnged_entmt_ord table';
     CALL UTOL.LPRINT( p_log_name, v_message ); 

     IF h_sqlcode < 0 THEN
        SET v_message = ' RMS-ERR : Failed to updating acq_data_flg from dwdm1.maintnc_mnged_entmt_ord table, with '
                              || 'SQL CODE: '  || CAST(h_sqlcode as CHAR(6))
                              || 'SQL State: ' || h_sqlstate;
         CALL UTOL.LPRINT( p_log_name, v_message );
         SET p_status = 9;
         GOTO ERROR_EXIT;
     END IF;
                         

    SET d_location = 'Truncate table dwdm1.maintnc_renwl_fact_trgt_work table';

    SET v_message = '4.0 Begin : Truncate table dwdm1.maintnc_renwl_fact_trgt_work table at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);

    SET v_sqlstmt = 'ALTER TABLE DWDM1.MAINTNC_RENWL_FACT_TRGT_WORK ACTIVATE NOT LOGGED INITIALLY WITH EMPTY TABLE';
    PREPARE sql1 FROM v_sqlstmt;
    EXECUTE sql1;

     IF h_sqlcode < 0 THEN
        SET v_message = ' RMS-ERR : Failed to truncate dwdm1.maintnc_renwl_fact_trgt_work. Process failed with'
                              || 'SQL CODE: '  || CAST(h_sqlcode as CHAR(6))
                              || 'SQL State: ' || h_sqlstate;
         CALL UTOL.LPRINT( p_log_name, v_message );
         SET p_status = 9;
         GOTO ERROR_EXIT;
     END IF;

    SET d_location = 'Insert into dwdm1.maintnc_renal_fact_trgt_work table from fncd1.revn_and_cost_dtl revn table';
    SET  v_message = '5.0 Begin : Insert into dwdm1.maintnc_renal_fact_trgt_work table from fncd1.revn_and_cost_dtl revn table at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);

    --Step 5 : Insert data into dwdm1.maintnc_renwl_fact_trgt_work table
    --         from all of the revenue and cost detail tables (current and archive)

       INSERT INTO DWDM1.MAINTNC_RENWL_FACT_TRGT_WORK
    (SAP_SALES_ORD_NUM,       CNTRY_CODE,            IBM_CNTRY_CODE,
     SAP_DISTRIBTN_CHNL_CODE, USD_PLAN_GL_POSTD_AMT, GL_ACCT,
     MAINTNC_START_DATE,      MAINTNC_END_DATE,      SAP_ORD_REAS_CODE,
     TOP_BILL_PART_NUM,       CTRCT_NUM,             TOP_BILL_PART_QTY,
     PART_NUM,                SAP_BILLG_DOC_TYPE_CODE, TRGT_DATA_WHS_RSEL_CUST_NUM ,
     TRGT_DATA_WHS_RSEL_CUST_ID, TRGT_DATA_WHS_PAYER_CUST_NUM, TRGT_DATA_WHS_PAYER_CUST_ID,
-- START LPP CHANGE
     TRGT_DOC_GL_POSTD_AMT, TRGT_CURRNCY_CODE, TRGT_LOCAL_UNIT_PRICE_12_MTHS,
-- END LPP CHANGE
--Add one columns
    SALES_ORD_HIGH_LEVEL_ITEM) 
    SELECT
     SAP_SALES_ORD_NUM,       CNTRY_CODE,            IBM_CNTRY_CODE,
     SAP_DISTRIBTN_CHNL_CODE, USD_PLAN_GL_POSTD_AMT, GL_ACCT,
     MAINTNC_START_DATE,      MAINTNC_END_DATE,      SAP_ORD_REAS_CODE,
     TOP_BILL_PART_NUM,       CTRCT_NUM,             TOP_BILL_PART_QTY,
     PART_NUM,                SAP_BILLG_DOC_TYPE_CODE, DATA_WHS_RSEL_CUST_NUM,
     DATA_WHS_RSEL_CUST_ID,   DATA_WHS_PAYER_CUST_NUM, DATA_WHS_PAYER_CUST_ID,
-- START LPP CHANGE
     COALESCE(REVN.DOC_GL_POSTD_AMT,0) AS	TRGT_DOC_GL_POSTD_AMT, 
     COALESCE(REVN.ORIGNL_CURRNCY_CODE,'') AS		TRGT_CURRNCY_CODE, 
     COALESCE(CASE WHEN COALESCE(REVN.PART_QTY,0) = 0 THEN 0 ELSE
        FLOAT(REVN.DOC_GL_POSTD_AMT * 12)/ 
           (
           (CASE
              WHEN TIMESTAMPDIFF(64, CHAR(COALESCE(TIMESTAMP_ISO(CASE WHEN REVN.MAINTNC_END_DATE < '9999-12-15' THEN (REVN.MAINTNC_END_DATE + 16 days) ELSE REVN.MAINTNC_END_DATE END ), '9991-12-31-00.00.00.000000')
                  - COALESCE(TIMESTAMP_ISO(REVN.MAINTNC_START_DATE) ,'9991-12-31-00.00.00.000000')))= 0
                  THEN 1
              ELSE
                   TIMESTAMPDIFF(64,CHAR(COALESCE(TIMESTAMP_ISO(CASE WHEN REVN.MAINTNC_END_DATE < '9999-12-15' THEN (REVN.MAINTNC_END_DATE + 16 days) ELSE REVN.MAINTNC_END_DATE END) ,'9991-12-31-00.00.00.000000')
                      - COALESCE(TIMESTAMP_ISO(REVN.MAINTNC_START_DATE) ,'9991-12-31-00.00.00.000000') ))
              END) *
             REVN.PART_QTY) END,0) AS TRGT_LOCAL_UNIT_PRICE_12_MTHS,
-- END LPP CHANGE,
--Add one columns
    SALES_ORD_HIGH_LEVEL_ITEM    
    FROM FNCD1.REVN_AND_COST_DTL REVN 
    WHERE REVN.SAP_ACCTG_DOC_TYPE_CODE = 'RX'       AND
          REVN.MAINTNC_END_DATE       >= P_END_DATE AND
          REVN.LINE_OF_BUS_CODE       <> 'EM'  AND
         (REVN.SAP_ORD_REAS_CODE NOT IN (select code from shar2.code_dscr where col_name = 'rebate_sap_ord_reas_code' and inact_flag = 0) OR
          REVN.SAP_ORD_REAS_CODE IS NULL)          AND
         (REVN.SAP_BILLG_DOC_TYPE_CODE NOT IN ('ZG','ZJ') OR
          REVN.SAP_BILLG_DOC_TYPE_CODE IS NULL)
--Exclude the Periodic Billing orders
          AND NOT EXISTS
              (SELECT 1 FROM FNCD1.V_SALES_ORD_BILLG_SCHDL_SUM SCH
               WHERE REVN.SAP_SALES_ORD_NUM = SCH.SAP_SALES_ORD_NUM AND
                     REVN.LINE_ITEM_SEQ_NUM = SCH.LINE_ITEM_SEQ_NUM)
    WITH UR;

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

    IF h_sqlcode < 0 THEN
       SET v_message = ' RMS-ERR : Failed to insert into DWDM1.MAINTNC_RENWL_FACT_TRGT_WORK table. Process failed with'
                              || 'SQL CODE: '  || CAST(h_sqlcode as CHAR(6))
                              || 'SQL State: ' || h_sqlstate;
       CALL UTOL.LPRINT( p_log_name, v_message );
       SET p_status = 9;
       GOTO ERROR_EXIT;
    ELSE
       SET  v_message = 'RMS-INF : Inserted '||cast(v_rows_affected as char(10))|| ' rows into DWDM1.MAINTNC_RENWL_FACT_TRGT_WORK completed successfully with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
       CALL UTOL.LPRINT( p_log_name, v_message );       
       COMMIT;
    END IF;

    SET v_rows_inserted = v_rows_inserted + v_rows_affected;

    SET d_location = 'Truncating USER_TEMP_01.MIN_BILLG_DT table for Periodic Billing insert';
    SET v_sqlstmt  = 'ALTER TABLE USER_TEMP_01.MIN_BILLG_DT ACTIVATE NOT LOGGED INITIALLY WITH EMPTY TABLE';
    PREPARE SQL1 FROM V_SQLSTMT;
    EXECUTE SQL1;

    COMMIT;

    INSERT INTO USER_TEMP_01.MIN_BILLG_DT
      WITH MIN_DOC AS (							
       SELECT REV.SAP_SALES_ORD_NUM, REV.LINE_ITEM_SEQ_NUM, REV.TOP_BILL_PART_NUM, REV.BILLG_LINE_ITEM_SEQ_NUM,S.BILLG_PLAN_LINE_ITEM_SEQ_NUM,  min(REV.BILLG_DATE) as BILLG_DATE	FROM FNCD1.REVN_AND_COST_DTL REV						
       INNER JOIN	(SODS2.SALES_ORD_BILLG_SCHDL s					
       INNER JOIN	FNCD1.V_SALES_ORD_BILLG_SCHDL_SUM SCH					
          ON						
             s.sap_sales_ord_num = SCH.sap_sales_ord_num AND						
             s.line_item_seq_num = SCH.line_item_seq_num)						
          ON						
            REV.sap_sales_ord_num = s.sap_sales_ord_num AND						
            REV.line_item_seq_num = s.line_item_seq_num AND						
            REV.billg_plan_num = s.billg_plan_num AND						
            REV.billg_plan_line_item_seq_num = s.billg_plan_line_item_seq_num						
       WHERE  s.SCHDLD_BILLG_DATE = SCH.MIN_SCHDLD_BILLG_DATE  AND
              REV.SAP_ACCTG_DOC_TYPE_CODE='RX' AND (REV.GL_ACCT LIKE '208%' OR REV.GL_ACCT LIKE '532%')	AND
             (REV.SAP_ORD_REAS_CODE NOT IN 
             (select code from shar2.code_dscr where col_name = 'rebate_sap_ord_reas_code' and inact_flag = 0) OR
              REV.SAP_ORD_REAS_CODE IS NULL)          AND
             (REV.SAP_BILLG_DOC_TYPE_CODE NOT IN ('ZG','ZJ') OR REV.SAP_BILLG_DOC_TYPE_CODE IS NULL)    AND
              REV.MAINTNC_START_DATE >= p_start_date  AND
              REV.MAINTNC_END_DATE < '12/31/9998' AND
              REV.LINE_OF_BUS_CODE <> 'EM'			  
       group by REV.SAP_SALES_ORD_NUM,REV.LINE_ITEM_SEQ_NUM, REV.TOP_BILL_PART_NUM, REV.BILLG_LINE_ITEM_SEQ_NUM,S.BILLG_PLAN_LINE_ITEM_SEQ_NUM)									SELECT A.SAP_SALES_ORD_NUM, A.LINE_ITEM_SEQ_NUM,							
            A.TOP_BILL_PART_NUM,
            A.BILLG_LINE_ITEM_SEQ_NUM,
            A.BILLG_PLAN_LINE_ITEM_SEQ_NUM,							
            A.BILLG_DATE,														
            MIN(SAP_BILLG_DOC_NUM) SAP_BILLG_DOC_NUM							
    FROM   MIN_DOC A, FNCD1.REVN_AND_COST_DTL REV							
    WHERE REV.SAP_SALES_ORD_NUM = A.SAP_SALES_ORD_NUM AND							
          REV.LINE_ITEM_SEQ_NUM = A.LINE_ITEM_SEQ_NUM AND							
          REV.TOP_BILL_PART_NUM = A.TOP_BILL_PART_NUM AND							       						
          REV.BILLG_DATE = A.BILLG_DATE               AND
		  REV.BILLG_PLAN_LINE_ITEM_SEQ_NUM=A.BILLG_PLAN_LINE_ITEM_SEQ_NUM   AND
          REV.SAP_ACCTG_DOC_TYPE_CODE='RX'            AND							
         (REV.GL_ACCT LIKE '208%' OR REV.GL_ACCT LIKE '532%') AND
         (REV.SAP_BILLG_DOC_TYPE_CODE NOT IN ('ZG','ZJ') OR
          REV.SAP_BILLG_DOC_TYPE_CODE IS NULL)    									
   GROUP BY A.SAP_SALES_ORD_NUM, A.LINE_ITEM_SEQ_NUM,							
            A.TOP_BILL_PART_NUM,
            A.BILLG_LINE_ITEM_SEQ_NUM,
            A.BILLG_PLAN_LINE_ITEM_SEQ_NUM,							
            A.BILLG_DATE;

    GET DIAGNOSTICS  v_rows_affected = ROW_COUNT;

     IF H_SQLCODE < 0 THEN
         SET v_message    = 'RMS-ERR : Error Inserting into USER_TEMP_01.MIN_BILLG_DT Process failed with'
                             || 'SQL CODE: '  || CAST(h_sqlcode as CHAR(6))
                             || 'SQL State: ' || h_sqlstate;
         SET V_MESSAGE    = V_MESSAGE ||' at '|| CAST(CURRENT TIMESTAMP AS CHAR(26));
         CALL UTOL.LPRINT(P_LOG_NAME, V_MESSAGE);
         SET p_status = 9;
         GOTO ERROR_EXIT ;
     ELSE
         SET  v_message = 'RMS-INF : Inserted '||cast(v_rows_affected as char(10))|| ' rows into USER_TEMP_01.MIN_BILLG_DT completed successfully with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
         CALL UTOL.LPRINT( p_log_name, v_message );      
         COMMIT;
     END IF;

-- Include the periodic billing orders

    INSERT INTO DWDM1.MAINTNC_RENWL_FACT_TRGT_WORK
    (SAP_SALES_ORD_NUM,       CNTRY_CODE,            IBM_CNTRY_CODE,
     SAP_DISTRIBTN_CHNL_CODE, USD_PLAN_GL_POSTD_AMT, GL_ACCT,
     MAINTNC_START_DATE,      MAINTNC_END_DATE,      SAP_ORD_REAS_CODE,
     TOP_BILL_PART_NUM,       CTRCT_NUM,             TOP_BILL_PART_QTY,
     PART_NUM,                SAP_BILLG_DOC_TYPE_CODE, TRGT_DATA_WHS_RSEL_CUST_NUM ,
     TRGT_DATA_WHS_RSEL_CUST_ID, TRGT_DATA_WHS_PAYER_CUST_NUM, TRGT_DATA_WHS_PAYER_CUST_ID,
-- START LPP CHANGE
          TRGT_DOC_GL_POSTD_AMT, TRGT_CURRNCY_CODE, TRGT_LOCAL_UNIT_PRICE_12_MTHS,
-- END LPP CHANGE
-- Add one columns 
SALES_ORD_HIGH_LEVEL_ITEM)
    SELECT
     SAP_SALES_ORD_NUM,       CNTRY_CODE,            IBM_CNTRY_CODE,
     SAP_DISTRIBTN_CHNL_CODE,
     CASE WHEN COALESCE(REVN.DOC_GL_POSTD_AMT,0) = 0 THEN 0 ELSE
       CAST(double ((SELECT CASE WHEN REVN.DOC_GL_POSTD_AMT < 0 THEN
                       -1 * SUM(SCH.LOCAL_EXTND_PRICE_SUM)
                       ELSE SUM(SCH.LOCAL_EXTND_PRICE_SUM)
                      END
              FROM  FNCD1.REVN_AND_COST_DTL REV1, FNCD1.V_SALES_ORD_BILLG_SCHDL_SUM SCH
              WHERE REV1.SAP_SALES_ORD_NUM   = SCH.SAP_SALES_ORD_NUM     AND
                    REV1.LINE_ITEM_SEQ_NUM   = SCH.LINE_ITEM_SEQ_NUM     AND
                    REV1.SAP_SALES_ORD_NUM   = REVN.SAP_SALES_ORD_NUM     AND
                    REV1.LINE_ITEM_SEQ_NUM   = REVN.LINE_ITEM_SEQ_NUM     AND
                    REV1.TOP_BILL_PART_NUM   = REVN.TOP_BILL_PART_NUM     AND
                    REV1.SAP_HIGH_LEVEL_ITEM = REVN.SAP_HIGH_LEVEL_ITEM   AND
                    REV1.BILLG_DATE          = REVN.BILLG_DATE            AND
                    REV1.SAP_BILLG_DOC_NUM   = REVN.SAP_BILLG_DOC_NUM     AND
                    REV1.MAINTNC_END_DATE    >= P_END_DATE               
					AND EXISTS
                             (SELECT 1 FROM USER_TEMP_01.MIN_BILLG_DT SCH
                                       WHERE REV1.SAP_SALES_ORD_NUM   = SCH.SAP_SALES_ORD_NUM AND
                                             REV1.LINE_ITEM_SEQ_NUM   = SCH.LINE_ITEM_SEQ_NUM AND
                                             REV1.BILLG_PLAN_LINE_ITEM_SEQ_NUM  = SCH.BILLG_PLAN_LINE_ITEM_SEQ_NUM AND
							                 REV1.BILLG_DATE = SCH.BILLG_DATE AND
							                 REV1.SAP_BILLG_DOC_NUM=SCH.SAP_BILLG_DOC_NUM)  AND
                    REV1.SAP_ACCTG_DOC_TYPE_CODE ='RX'                   AND
                    REV1.LINE_OF_BUS_CODE <> 'EM'     and
                    (rev1.GL_ACCT LIKE '208%' OR rev1.GL_ACCT LIKE '532%') AND
                    (rev1.SAP_ORD_REAS_CODE NOT IN (select code from shar2.code_dscr where col_name = 'rebate_sap_ord_reas_code' and inact_flag = 0) OR
                       rev1.SAP_ORD_REAS_CODE IS NULL)  AND
                    (REV1.SAP_BILLG_DOC_TYPE_CODE NOT IN ('ZG','ZJ') OR REV1.SAP_BILLG_DOC_TYPE_CODE IS NULL))) *
					(double(REVN.USD_PLAN_GL_POSTD_AMT)/double(REVN.DOC_GL_POSTD_AMT ))AS DECIMAL(19,8))
     END AS USD_PLAN_GL_POSTD_AMT,
     GL_ACCT,
     MAINTNC_START_DATE,      MAINTNC_END_DATE,      SAP_ORD_REAS_CODE,
     TOP_BILL_PART_NUM,       CTRCT_NUM,             TOP_BILL_PART_QTY,
     PART_NUM,                SAP_BILLG_DOC_TYPE_CODE, DATA_WHS_RSEL_CUST_NUM,
     DATA_WHS_RSEL_CUST_ID,   DATA_WHS_PAYER_CUST_NUM, DATA_WHS_PAYER_CUST_ID,
-- START LPP CHANGE
     COALESCE(CASE WHEN COALESCE(REVN.DOC_GL_POSTD_AMT,0) = 0 THEN 0 ELSE
       CAST( (SELECT CASE WHEN REVN.DOC_GL_POSTD_AMT < 0 THEN
                       -1 * SUM(FLOAT(SCH.LOCAL_EXTND_PRICE_SUM))
                       ELSE SUM(FLOAT(SCH.LOCAL_EXTND_PRICE_SUM))
                      END
              FROM  FNCD1.REVN_AND_COST_DTL REV1, FNCD1.V_SALES_ORD_BILLG_SCHDL_SUM SCH
              WHERE REV1.SAP_SALES_ORD_NUM   = SCH.SAP_SALES_ORD_NUM     AND
                    REV1.LINE_ITEM_SEQ_NUM   = SCH.LINE_ITEM_SEQ_NUM     AND
                    REV1.SAP_SALES_ORD_NUM   = REVN.SAP_SALES_ORD_NUM     AND
                    REV1.LINE_ITEM_SEQ_NUM   = REVN.LINE_ITEM_SEQ_NUM     AND
                    REV1.TOP_BILL_PART_NUM   = REVN.TOP_BILL_PART_NUM     AND
                    REV1.SAP_HIGH_LEVEL_ITEM = REVN.SAP_HIGH_LEVEL_ITEM   AND
                    REV1.BILLG_DATE          = REVN.BILLG_DATE            AND
                    REV1.SAP_BILLG_DOC_NUM   = REVN.SAP_BILLG_DOC_NUM     AND
                    REV1.MAINTNC_END_DATE    >= P_END_DATE               
					AND EXISTS
                             (SELECT 1 FROM USER_TEMP_01.MIN_BILLG_DT SCH
                                       WHERE REV1.SAP_SALES_ORD_NUM   = SCH.SAP_SALES_ORD_NUM AND
                                             REV1.LINE_ITEM_SEQ_NUM   = SCH.LINE_ITEM_SEQ_NUM AND
                                             REV1.BILLG_PLAN_LINE_ITEM_SEQ_NUM  = SCH.BILLG_PLAN_LINE_ITEM_SEQ_NUM AND
							                 REV1.BILLG_DATE = SCH.BILLG_DATE AND
							                 REV1.SAP_BILLG_DOC_NUM=SCH.SAP_BILLG_DOC_NUM)  AND
                    REV1.SAP_ACCTG_DOC_TYPE_CODE ='RX'                   AND
                    REV1.LINE_OF_BUS_CODE <> 'EM'                        AND
                    (rev1.GL_ACCT LIKE '208%' OR rev1.GL_ACCT LIKE '532%') AND
                    
                    (rev1.SAP_ORD_REAS_CODE NOT IN (select code from shar2.code_dscr where col_name = 'rebate_sap_ord_reas_code' 
                       and inact_flag = 0) OR
                       rev1.SAP_ORD_REAS_CODE IS NULL)  AND
                    (REV1.SAP_BILLG_DOC_TYPE_CODE NOT IN ('ZG','ZJ') OR  REV1.SAP_BILLG_DOC_TYPE_CODE IS NULL)) AS DECIMAL(19,8))
     END,0) AS TRGT_DOC_GL_POSTD_AMT,
     COALESCE(REVN.ORIGNL_CURRNCY_CODE,'') AS TRGT_CURRNCY_CODE,
     COALESCE(CASE WHEN COALESCE(REVN.PART_QTY,0) = 0 THEN 0 ELSE
     (((CASE WHEN COALESCE(REVN.DOC_GL_POSTD_AMT,0) = 0 THEN 0 ELSE
            CAST( (SELECT CASE WHEN REVN.DOC_GL_POSTD_AMT < 0 THEN
                            -1 * SUM(FLOAT(SCH.LOCAL_EXTND_PRICE_SUM))
                            ELSE SUM(FLOAT(SCH.LOCAL_EXTND_PRICE_SUM))
                           END
                   FROM  FNCD1.REVN_AND_COST_DTL REV1, FNCD1.V_SALES_ORD_BILLG_SCHDL_SUM SCH
                   WHERE REV1.SAP_SALES_ORD_NUM   = SCH.SAP_SALES_ORD_NUM     AND
                         REV1.LINE_ITEM_SEQ_NUM   = SCH.LINE_ITEM_SEQ_NUM     AND
                         REV1.SAP_SALES_ORD_NUM   = REVN.SAP_SALES_ORD_NUM     AND
                         REV1.LINE_ITEM_SEQ_NUM   = REVN.LINE_ITEM_SEQ_NUM     AND
                         REV1.TOP_BILL_PART_NUM   = REVN.TOP_BILL_PART_NUM     AND
                         REV1.SAP_HIGH_LEVEL_ITEM = REVN.SAP_HIGH_LEVEL_ITEM   AND
                         REV1.BILLG_DATE          = REVN.BILLG_DATE            AND
                         REV1.SAP_BILLG_DOC_NUM   = REVN.SAP_BILLG_DOC_NUM     AND
                         REV1.MAINTNC_END_DATE    >= P_END_DATE              
						 AND EXISTS
                             (SELECT 1 FROM USER_TEMP_01.MIN_BILLG_DT SCH
                                       WHERE REV1.SAP_SALES_ORD_NUM   = SCH.SAP_SALES_ORD_NUM AND
                                             REV1.LINE_ITEM_SEQ_NUM   = SCH.LINE_ITEM_SEQ_NUM AND
                                             REV1.BILLG_PLAN_LINE_ITEM_SEQ_NUM  = SCH.BILLG_PLAN_LINE_ITEM_SEQ_NUM AND
							                 REV1.BILLG_DATE = SCH.BILLG_DATE AND
							                 REV1.SAP_BILLG_DOC_NUM=SCH.SAP_BILLG_DOC_NUM)  AND
                         REV1.SAP_ACCTG_DOC_TYPE_CODE ='RX'                   AND
                         REV1.LINE_OF_BUS_CODE <> 'EM'                        AND
                         (rev1.GL_ACCT LIKE '208%' OR rev1.GL_ACCT LIKE '532%') AND
                         
                         (rev1.SAP_ORD_REAS_CODE NOT IN (select code from shar2.code_dscr where col_name = 'rebate_sap_ord_reas_code' 
                            and inact_flag = 0) OR
                            rev1.SAP_ORD_REAS_CODE IS NULL)  AND
                         (REV1.SAP_BILLG_DOC_TYPE_CODE NOT IN ('ZG','ZJ') OR  REV1.SAP_BILLG_DOC_TYPE_CODE IS NULL)) AS DECIMAL(19,8))
     END) * 12)/(
           (CASE
              WHEN TIMESTAMPDIFF(64, CHAR(COALESCE(TIMESTAMP_ISO(CASE WHEN REVN.MAINTNC_END_DATE < '9999-12-15' THEN (REVN.MAINTNC_END_DATE + 16 days) ELSE REVN.MAINTNC_END_DATE END), '9991-12-31-00.00.00.000000')
                  - COALESCE(TIMESTAMP_ISO(REVN.MAINTNC_START_DATE) ,'9991-12-31-00.00.00.000000')))= 0
                  THEN 1
              ELSE
                   TIMESTAMPDIFF(64,CHAR(COALESCE(TIMESTAMP_ISO(CASE WHEN REVN.MAINTNC_END_DATE < '9999-12-15' THEN (REVN.MAINTNC_END_DATE + 16 days) ELSE REVN.MAINTNC_END_DATE END) ,'9991-12-31-00.00.00.000000')
                      - COALESCE(TIMESTAMP_ISO(REVN.MAINTNC_START_DATE) ,'9991-12-31-00.00.00.000000') ))
              END) *
             REVN.PART_QTY)) END,0)  AS TRGT_LOCAL_UNIT_PRICE_12_MTHS, 
-- END LPP CHANGE   
    REVN.SALES_ORD_HIGH_LEVEL_ITEM as SALES_ORD_HIGH_LEVEL_ITEM
    FROM FNCD1.REVN_AND_COST_DTL REVN
    WHERE REVN.SAP_ACCTG_DOC_TYPE_CODE = 'RX'       AND
          REVN.MAINTNC_END_DATE       >= P_END_DATE AND
          REVN.LINE_OF_BUS_CODE       <> 'EM'  AND
         (REVN.SAP_ORD_REAS_CODE NOT IN (select code from shar2.code_dscr where col_name = 'rebate_sap_ord_reas_code' and inact_flag = 0) OR
          REVN.SAP_ORD_REAS_CODE IS NULL)          AND
         (REVN.SAP_BILLG_DOC_TYPE_CODE NOT IN ('ZG','ZJ') OR
          REVN.SAP_BILLG_DOC_TYPE_CODE IS NULL)
--Include the Periodic Billing orders
    AND EXISTS
        (SELECT 1 FROM USER_TEMP_01.MIN_BILLG_DT SCH
                      WHERE REVN.SAP_SALES_ORD_NUM   = SCH.SAP_SALES_ORD_NUM AND
                            REVN.LINE_ITEM_SEQ_NUM   = SCH.LINE_ITEM_SEQ_NUM AND
                            REVN.BILLG_PLAN_LINE_ITEM_SEQ_NUM  = SCH.BILLG_PLAN_LINE_ITEM_SEQ_NUM AND
							REVN.BILLG_DATE = SCH.BILLG_DATE AND
							REVN.SAP_BILLG_DOC_NUM=SCH.SAP_BILLG_DOC_NUM
        )
    WITH UR;

     GET DIAGNOSTICS  v_rows_affected = ROW_COUNT;
     
     IF H_SQLCODE < 0 THEN
         SET v_message    = 'RMS-ERR : Error Inserting into DWDM1.MAINTNC_RENWL_FACT_TRGT_WORK. Process failed with'
                             || 'SQL CODE: '  || CAST(h_sqlcode as CHAR(6))
                             || 'SQL State: ' || h_sqlstate;
         SET V_MESSAGE    = V_MESSAGE ||' at '|| CAST(CURRENT TIMESTAMP AS CHAR(26));
         CALL UTOL.LPRINT(P_LOG_NAME, V_MESSAGE);
         SET p_status = 9;
         GOTO ERROR_EXIT ;
     ELSE
         SET  v_message = 'RMS-INF : Inserted '||cast(v_rows_affected as char(10))|| ' rows into DWDM1.MAINTNC_RENWL_FACT_TRGT_WORK completed successfully with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
         CALL UTOL.LPRINT( p_log_name, v_message );       
         COMMIT;
     END IF;

   SET v_rows_inserted = v_rows_inserted + v_rows_affected;

    SET v_sqlstmt = 'ALTER TABLE DWDM1.MAINTNC_RENWL_FACT_TRGT_WORK ACTIVATE NOT LOGGED INITIALLY';
    PREPARE sql1 FROM v_sqlstmt;
    EXECUTE sql1;

    SET d_location = 'Insert into dwdm1.maintnc_renwl_fact_trgt_work table from dwdm1.maintnc_renwl_fact_trgt_arch table';
    SET  v_message = '6.0 Begin : Insert into dwdm1.maintnc_renal_fact_trgt_work table from dwdm1.maintnc_renwl_fact_trgt_arch table at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);

    INSERT INTO DWDM1.MAINTNC_RENWL_FACT_TRGT_WORK
    (SAP_SALES_ORD_NUM,       CNTRY_CODE,            IBM_CNTRY_CODE,
     SAP_DISTRIBTN_CHNL_CODE, USD_PLAN_GL_POSTD_AMT, GL_ACCT,
     MAINTNC_START_DATE,      MAINTNC_END_DATE,      SAP_ORD_REAS_CODE,
     TOP_BILL_PART_NUM,       CTRCT_NUM,             TOP_BILL_PART_QTY,
     PART_NUM,                     SAP_BILLG_DOC_TYPE_CODE, TRGT_DATA_WHS_RSEL_CUST_NUM ,
     TRGT_DATA_WHS_RSEL_CUST_ID, TRGT_DATA_WHS_PAYER_CUST_NUM, TRGT_DATA_WHS_PAYER_CUST_ID,
-- START LPP CHANGE
          TRGT_DOC_GL_POSTD_AMT, TRGT_CURRNCY_CODE, TRGT_LOCAL_UNIT_PRICE_12_MTHS,
-- END LPP CHANGE
-- Add one columns 
    SALES_ORD_HIGH_LEVEL_ITEM)
    with tst as (
     select sap_sales_ord_num from SODS2.SALES_ORD_BILLG_SCHDL
     group by sap_sales_ord_num having  count(distinct year(schdld_billg_date)) > 1),
    xyz as (
     select distinct a.sap_sales_ord_num
     from  SODS2.SALES_ORD_BILLG_SCHDL a inner join tst t on
     a.sap_sales_ord_num = t.sap_sales_ord_num
     where year(schdld_billg_date) = year(current timestamp))
    SELECT
     SAP_SALES_ORD_NUM,       CNTRY_CODE,            IBM_CNTRY_CODE,
     SAP_DISTRIBTN_CHNL_CODE, USD_PLAN_GL_POSTD_AMT, GL_ACCT,
     MAINTNC_START_DATE,      MAINTNC_END_DATE,      SAP_ORD_REAS_CODE,
     TOP_BILL_PART_NUM,       CTRCT_NUM,             TOP_BILL_PART_QTY,
     PART_NUM,                SAP_BILLG_DOC_TYPE_CODE, TRGT_DATA_WHS_RSEL_CUST_NUM ,
     TRGT_DATA_WHS_RSEL_CUST_ID, TRGT_DATA_WHS_PAYER_CUST_NUM, TRGT_DATA_WHS_PAYER_CUST_ID,
-- START LPP CHANGE
          COALESCE(TRGT_DOC_GL_POSTD_AMT,0), COALESCE(TRGT_CURRNCY_CODE,''), COALESCE(TRGT_LOCAL_UNIT_PRICE_12_MTHS,0),
-- END LPP CHANGE
-- Add one columns 
    SALES_ORD_HIGH_LEVEL_ITEM
    FROM DWDM1.MAINTNC_RENWL_FACT_TRGT_ARCH A
    WHERE A.MAINTNC_END_DATE        >= P_END_DATE  AND
         (A.SAP_ORD_REAS_CODE NOT IN (select code from shar2.code_dscr where col_name = 'rebate_sap_ord_reas_code' and inact_flag = 0) OR
          A.SAP_ORD_REAS_CODE IS NULL)          AND
         (A.SAP_BILLG_DOC_TYPE_CODE NOT IN ('ZG','ZJ') OR
          A.SAP_BILLG_DOC_TYPE_CODE IS NULL) and
    a.sap_sales_ord_num not in( select sap_sales_ord_num from xyz)
    WITH UR;

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

    IF h_sqlcode < 0 THEN
       SET v_message = ' RMS-ERR : Failed to insert data into dwdm1.maintnc_renwl_fact_trgt_work table. Process failed with'
                              || 'SQL CODE: '  || CAST(h_sqlcode as CHAR(6))
                              || 'SQL State: ' || h_sqlstate;
       CALL UTOL.LPRINT( p_log_name, v_message );
       SET p_status = 9;
       GOTO ERROR_EXIT;
    ELSE
       SET  v_message = 'RMS-INF : Inserted '||cast(v_rows_affected as char(10))|| ' rows into DWDM1.MAINTNC_RENWL_FACT_TRGT_WORK completed successfully with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
       CALL UTOL.LPRINT( p_log_name, v_message );     
       COMMIT;
    END IF;

    SET v_rows_inserted = v_rows_inserted + v_rows_affected;


--- Update the reseller and payer info in dwdm1.MAINTNC_MNGED_ENTMT_ORD

    SET V_STATUS = 0;
    SET d_location = 'Execute Stored Procedure dp_updt_maint_meo_rsel';
    SET  v_message = '7.0 Begin : Execute Stored Procedure dp_updt_maint_meo_rsel at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);

    CALL DWDM1.DP_UPDT_MAINT_MEO_RSEL(p_log_name,0,V_STATUS) ;

    IF V_STATUS <> 0 Then
      SET  v_message = 'RMS-ERR : Stored Procedure dwdm1.dp_updt_maint_meo_rsel failed with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
      CALL UTOL.lprint(p_log_name, v_message);
      SET p_status = 9;
    ELSE
      SET  v_message = 'RMS-INF : Stored Procedure dwdm1.dp_updt_maint_meo_rsel completed successfully with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
      CALL UTOL.lprint(p_log_name, v_message);
    END IF;


---Step 8 : Update the usd plan amt/top bill part qty in dwdm1.MAINTNC_MNGED_ENTMT_ORD

    SET V_STATUS = 0;
    SET d_location = 'Execute Stored Procedure dp_updt_maint_meo_bef3';
    SET  v_message = '8.0 Begin : Execute Stored Procedure dp_updt_maint_meo_bef3 at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);

    CALL DWDM1.DP_UPDT_MAINT_MEO_BEF3(p_log_name,0,V_STATUS) ;

    IF V_STATUS <> 0 Then
      SET  v_message = 'RMS-ERR : Stored Procedure dwdm1.dp_updt_maint_meo_bef3 failed with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
      CALL UTOL.lprint(p_log_name, v_message);
      SET p_status = 9;
    ELSE
      SET  v_message = 'RMS-INF : Stored Procedure dwdm1.dp_updt_maint_meo_bef3 completed successfully with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
      CALL UTOL.lprint(p_log_name, v_message);
    END IF;
    
    ---Step 8.1 : Update the aquision data in dwdm1.MAINTNC_MNGED_ENTMT_ORD

    SET V_STATUS = 0;
    SET d_location = 'Execute Stored Procedure dp_updt_maintnc_meo_prior_acq.sp';
    SET  v_message = '8.1 Begin : Execute Stored Procedure dp_updt_maintnc_meo_prior_acq.sp at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);

    CALL DWDM1.DP_UPDT_MAINTNC_MEO_PRIOR_ACQ(p_log_name,0,V_STATUS) ;

    IF V_STATUS <> 0 Then
      SET  v_message = 'RMS-ERR : Stored Procedure dwdm1.dp_updt_maintnc_meo_prior_acq.sp failed with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
      CALL UTOL.lprint(p_log_name, v_message);
      SET p_status = 9;
    ELSE
      SET  v_message = 'RMS-INF : Stored Procedure dwdm1.dp_updt_maintnc_meo_prior_acq.sp completed successfully with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
      CALL UTOL.lprint(p_log_name, v_message);
    END IF;
    
      SET V_STATUS = 0;
    SET d_location = 'Execute Stored Procedure dp_updt_maintnc_meo_acq.sp';
    SET  v_message = '8.2 Begin : Execute Stored Procedure dp_updt_maintnc_meo_acq.sp at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);

    CALL DWDM1.DP_UPDT_MAINTNC_MEO_ACQ(p_log_name,0,V_STATUS) ;

    IF V_STATUS <> 0 Then
      SET  v_message = 'RMS-ERR : Stored Procedure dwdm1.dp_updt_maintnc_meo_acq.sp failed with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
      CALL UTOL.lprint(p_log_name, v_message);
      SET p_status = 9;
    ELSE
      SET  v_message = 'RMS-INF : Stored Procedure dwdm1.dp_updt_maintnc_meo_acq.sp completed successfully with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
      CALL UTOL.lprint(p_log_name, v_message);
    END IF;

      SET V_STATUS = 0;
    SET d_location = 'Execute Stored Procedure dp_updt_maint_meo_usd_amt.sp';
    SET  v_message = '8.3 Begin : Execute Stored Procedure dwdm1.dp_updt_maint_meo_usd_amt at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);

   CALL DWDM1.DP_UPDT_MAINT_MEO_USD_AMT(p_log_name,v_status) ;

   IF V_STATUS <> 0 Then
      SET  v_message = 'RMS-ERR : Stored Procedure dwdm1.dp_updt_maint_meo_usd_amt failed with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
      CALL UTOL.lprint(p_log_name, v_message);
      SET p_status = 9;
    ELSE
      SET  v_message = 'RMS-INF : Stored Procedure dwdm1.dp_updt_maint_meo_usd_amt completed successfully with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
      CALL UTOL.lprint(p_log_name, v_message);
    END IF;


    SET  d_location = 'Truncate table dwdm2.maint_renwl_fact_2';
    SET  v_message  = '9.0 Begin : Truncate table dwdm2.maint_renwl_fact_2 at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);

    SET v_sqlstmt = 'ALTER TABLE DWDM2.MAINT_RENWL_FACT_2 ACTIVATE NOT LOGGED INITIALLY WITH EMPTY TABLE';
    PREPARE sql1 FROM v_sqlstmt;
    EXECUTE sql1;
    COMMIT;

    IF h_sqlcode < 0 THEN
       SET v_message = ' RMS-ERR : Failed to Truncate dwdm2.maint_renwl_fact_2 table and the process failed with'
                              || 'SQL CODE: '  || CAST(h_sqlcode as CHAR(6))
                              || 'SQL State: ' || h_sqlstate;
       CALL UTOL.LPRINT( p_log_name, v_message );
       SET p_status = 9;
       GOTO ERROR_EXIT;
    END IF;

    SET d_location = 'Insert into dwdm2.maint_renwl_fact_2 table from dwdm1.maintnc_mnged_entmt_ord';
    SET  v_message = '10.0 Begin : Insert into dwdm2.maint_renwl_fact_2 table from dwdm1.maintnc_mnged_entmt_ord at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);

    --Group by data and insert records in the table  dwdm2.MAINT_RENWL_FACT_2

    INSERT INTO DWDM2.MAINT_RENWL_FACT_2
    (SAP_SALES_ORG_CODE,           MNGED_ENTMT_PROG,        SOLD_TO_CUST_NUM,
     RENWL_CUST_NUM,               SAP_CTRCT_NUM,           LINE_OF_BUS_CODE,
     SW_SBSCRPTN_ID,               REVN_STREAM_CODE,        END_DATE,
     START_DATE,                   PART_NUM,                CNTRY_CODE,
     IBM_CNTRY_CODE,               SAP_DISTRIBTN_CHNL_CODE,
     BLUE_DOLLARS_FLAG,
     PRIOR_USD_PLAN_GL_POSTED_AMT, MTY_PRICE_PR_YR_BILLG,   BILLG_INFO_FLAG,
     EXPECTED_START_MONTH,         EXPECTED_START_YEAR,     EXPECTED_START_QUARTER,
     EVOLUTION_FLAG,               IBM_WHLSL_DIV_CODE,      DATA_WHS_END_USER_CUST_NUM,
     TRGT_DATA_WHS_RSEL_CUST_NUM, TRGT_DATA_WHS_RSEL_CUST_ID, TRGT_DATA_WHS_PAYER_CUST_NUM,
     TRGT_DATA_WHS_PAYER_CUST_ID,DATA_SRC_CD,
     TRGT_HW_MACH_TYPE             ,
     TRGT_HW_MACH_MODEL            ,
     TRGT_HW_MACH_SERIAL_NUM       ,
     TRGT_ORD_START_DATE           ,
     TRGT_ORD_END_DATE             ,
     TRGT_WARR_START_DATE          ,
     TRGT_WARR_END_DATE            ,
     TRGT_CONFIGRTN_ID             ,
     TRGT_SRC_HW_MACH_TYPE         ,
     TRGT_SRC_HW_MACH_MODEL        ,
     TRGT_SRC_HW_MACH_SERIAL_NUM   ,
     TRGT_APPLNC_UPGRD_FLAG        ,
     APPLNC_PART_QTY               ,
     APPLNC_NET_PART_QTY           ,
-- START LPP CHANGE
     TRGT_DOC_GL_POSTD_AMT, 
     TRGT_CURRNCY_CODE, 
     TRGT_LOCAL_UNIT_PRICE_12_MTHS,    
-- END LPP CHANGE 
-- Add two columns
    APPLNC_QTY_FLAG,
    TRGT_NON_IBM_APPLNC_FLAG,
--Add three columns      
    PRECDNG_DOC_NUM,
    PRECDNG_LINE_ITEM_SEQ_NUM,
    SAP_SALES_DOC_TYPE_CODE,
    BP_TRNSFR_OF_OWNRSHP_FLAG,
    ORD_LINE_ITEM_SEQ_NUM,
--Added in 16.1
    ENTMT_EXCPTN_CODE)  
    
    SELECT
     AL3.SAP_SALES_ORG_CODE,  AL3.MNGED_ENTMT_PROG,         AL3.SOLD_TO_CUST_NUM,
     AL3.RENWL_CUST_NUM,      AL3.SAP_CTRCT_NUM,            AL3.LINE_OF_BUS_CODE,
     AL3.SW_SBSCRPTN_ID,      AL3.REVN_STREAM_CODE,         AL3.END_DATE ,
     AL3.START_DATE,          AL3.PART_NUM, AL3.CNTRY_CODE,
     AL3.IBM_CNTRY_CODE,      AL3.SAP_DISTRIBTN_CHNL_CODE,
     CASE WHEN AL3.SAP_DISTRIBTN_CHNL_CODE = 'P' THEN 'Y' ELSE 'N' END AS BLUE_DOLLARS_FLAG,
     CAST(SUM((FLOAT(AL3.USD_PLAN_GL_POSTED_AMT)
           /(CASE WHEN COALESCE(AL3.top_bill_part_qty,0) = 0 THEN
              (case when al3.PART_QTY != 0 then
                 FLOAT(AL3.PART_QTY)
               else float(1)
               end)
            ELSE FLOAT(AL3.TOP_BILL_PART_QTY)
            END) * (case when COALESCE(al3.part_qty,0) = 0  then
                     float(1)
                    else FLOAT(AL3.PART_QTY)
                    end))) AS DECIMAL(31,5)) PRIOR_USD_PLAN_GL_POSTED_AMT ,
     SUM(((
       (FLOAT(AL3.USD_PLAN_GL_POSTED_AMT )/
         (CASE WHEN COALESCE(AL3.TOP_BILL_PART_QTY,0) = 0 THEN
              (case when al3.PART_QTY != 0 then
                 FLOAT(AL3.PART_QTY)
               else float(1)
               end)
            ELSE FLOAT(AL3.TOP_BILL_PART_QTY)
            END) *
          (case when COALESCE(al3.part_qty,0) = 0  then
                     float(1)
                    else FLOAT(AL3.PART_QTY)
                    end))))
          / FLOAT((CASE
                     WHEN TIMESTAMPDIFF(64, CHAR(COALESCE(TIMESTAMP_ISO(CASE WHEN AL3.TRGT_ORD_END_DATE < '9999-12-15' THEN (AL3.TRGT_ORD_END_DATE + 16 days) ELSE AL3.TRGT_ORD_END_DATE END), '9991-12-31-00.00.00.000000')
                                              - COALESCE(TIMESTAMP_ISO(AL3.TRGT_ORD_START_DATE) ,'9991-12-31-00.00.00.000000')))= 0
                        THEN 1
                      ELSE
                        TIMESTAMPDIFF(64,CHAR(COALESCE(TIMESTAMP_ISO(CASE WHEN AL3.TRGT_ORD_END_DATE < '9999-12-15' THEN (AL3.TRGT_ORD_END_DATE + 16 days) ELSE AL3.TRGT_ORD_END_DATE END) ,'9991-12-31-00.00.00.000000')
                                            - COALESCE(TIMESTAMP_ISO(AL3.TRGT_ORD_START_DATE) ,'9991-12-31-00.00.00.000000') ))
                   END) )) AS MTY_PRICE_PR_YR_BILLG ,
     CASE WHEN AL3.IBM_CNTRY_CODE IS NULL THEN 'N' ELSE 'Y'
     END AS billg_info_flag,
     MONTH(AL3.end_date   + 1 DAYS) AS Expected_Start_Month,
     YEAR(AL3.end_date    + 1 DAYS) AS Expected_Start_Year,
     QUARTER(AL3.END_DATE + 1 DAYS) AS Expected_Start_quarter,
     AL3.EVOLUTION_FLAG,
     AL5.IBM_WHLSL_DIV_CODE,
     AL3.DATA_WHS_END_USER_CUST_NUM,
     AL3.TRGT_DATA_WHS_RSEL_CUST_NUM,
     AL3.TRGT_DATA_WHS_RSEL_CUST_ID,
     AL3.TRGT_DATA_WHS_PAYER_CUST_NUM,
     AL3.TRGT_DATA_WHS_PAYER_CUST_ID,
     AL3.DATA_SRC_CD,
     -- Appliance columns
     AL3.TRGT_HW_MACH_TYPE             ,
     AL3.TRGT_HW_MACH_MODEL            ,
     AL3.TRGT_HW_MACH_SERIAL_NUM       ,
     AL3.TRGT_ORD_START_DATE           ,
     AL3.TRGT_ORD_END_DATE             ,
     AL3.TRGT_WARR_START_DATE          ,
     AL3.TRGT_WARR_END_DATE            ,
     AL3.TRGT_CONFIGRTN_ID             ,
     AL3.TRGT_SRC_HW_MACH_TYPE         ,
     AL3.TRGT_SRC_HW_MACH_MODEL        ,
     AL3.TRGT_SRC_HW_MACH_SERIAL_NUM   ,
     AL3.TRGT_APPLNC_UPGRD_FLAG        ,
     AL3.APPLNC_PART_QTY                   ,
     AL3.APPLNC_NET_PART_QTY               ,     
-- START LPP CHANGE
          CAST(SUM((FLOAT(AL3.TRGT_DOC_GL_POSTD_AMT)
           /(CASE WHEN COALESCE(AL3.top_bill_part_qty,0) = 0 THEN
              (case when al3.PART_QTY != 0 then
                 FLOAT(AL3.PART_QTY)
               else float(1)
               end)
            ELSE FLOAT(AL3.TOP_BILL_PART_QTY)
            END) * (case when COALESCE(al3.part_qty,0) = 0  then
                     float(1)
                    else FLOAT(AL3.PART_QTY)
                    end))) AS DECIMAL(31,5)) TRGT_DOC_GL_POSTD_AMT,

     AL3.TRGT_CURRNCY_CODE TRGT_CURRNCY_CODE, 

     SUM(CASE WHEN COALESCE(AL3.PART_QTY,0) = 0 THEN 0 ELSE

     (FLOAT(AL3.TRGT_DOC_GL_POSTD_AMT * 12)/
           (
           (CASE
              WHEN TIMESTAMPDIFF(64, CHAR(COALESCE(TIMESTAMP_ISO(CASE WHEN AL3.TRGT_ORD_END_DATE < '9999-12-15' THEN (AL3.TRGT_ORD_END_DATE + 16 days) ELSE AL3.TRGT_ORD_END_DATE END), '9991-12-31-00.00.00.000000')
                  - COALESCE(TIMESTAMP_ISO(AL3.TRGT_ORD_START_DATE) ,'9991-12-31-00.00.00.000000')))= 0
                  THEN 1
              ELSE
                   TIMESTAMPDIFF(64,CHAR(COALESCE(TIMESTAMP_ISO(CASE WHEN AL3.TRGT_ORD_END_DATE < '9999-12-15' THEN (AL3.TRGT_ORD_END_DATE + 16 days) ELSE AL3.TRGT_ORD_END_DATE END) ,'9991-12-31-00.00.00.000000')
                      - COALESCE(TIMESTAMP_ISO(AL3.TRGT_ORD_START_DATE),'9991-12-31-00.00.00.000000') ))
              END) *
             AL3.PART_QTY)) END) AS TRGT_LOCAL_UNIT_PRICE_12_MTHS,
-- AL3.TRGT_DOC_GL_POSTD_AMT   
-- AL3.PART_QTY
-- END LPP CHANGE
--Add two columns
   AL3.APPLNC_QTY_FLAG,
   AL3.TRGT_NON_IBM_APPLNC_FLAG ,
--Add three columns      
  AL3.PRECDNG_DOC_NUM,
  AL3.PRECDNG_LINE_ITEM_SEQ_NUM,
  AL3.SAP_SALES_DOC_TYPE_CODE,
  AL3.BP_TRNSFR_OF_OWNRSHP_FLAG ,
  AL3.ORD_LINE_ITEM_SEQ_NUM,
--Added in 16.1
  AL3.ENTMT_EXCPTN_CODE
    FROM DWDM1.MAINTNC_MNGED_ENTMT_ORD AL3 INNER JOIN RSHR2.PROD_DIMNSN AL5
        ON AL3.PART_NUM = AL5.PART_NUM 
    LEFT OUTER JOIN DWDM0.TOKEN_MULTI_YR_SNS_PART P
        ON AL5.PART_NUM = P.TOP_BILL_PART_NUM           
    WHERE end_date <'9999-12-15'
        AND 
        (AL5.REVN_STREAM_CODE IN (
                   'LCMNTSPT', 'LIC&MNT',  'MAINT AG', 'MNT&SPT',  'OTHUPMNT', 'OTHUPMSP',
                   'REACTMNT', 'RNWL MNT', 'RNWMNTSP', 'TRD&MNT',  'TRDMNTSP', 'VERUPSUB', 
                   'ASMAINT',  'AALSS',    'AATLSS',   'APLSS',    'APTLSS',   'CMPTRDUP', 
                   'FCTTRDUP', 'ASLISS',   'ASREIHWM', 'ASRSSHWM', 'ASUHWM',   'ASUNHWM', 
                   'ALISS',    'REIHWM',   'RSSHWM',   'AUHWM',    'AUNHWM',   'APXFOW')
         or p.top_bill_part_num is not null)                        
    GROUP BY
      AL3.SAP_SALES_ORG_CODE, AL3.MNGED_ENTMT_PROG,        AL3.SOLD_TO_CUST_NUM,
      AL3.RENWL_CUST_NUM,     AL3.SAP_CTRCT_NUM,           AL3.LINE_OF_BUS_CODE,
      AL3.SW_SBSCRPTN_ID,     AL3.REVN_STREAM_CODE,        AL3.END_DATE ,
      AL3.START_DATE,         AL3.PART_NUM,                AL3.CNTRY_CODE,
      AL3.IBM_CNTRY_CODE,     AL3.SAP_DISTRIBTN_CHNL_CODE, AL3.EVOLUTION_FLAG,
      AL5.IBM_WHLSL_DIV_CODE, AL3.DATA_WHS_END_USER_CUST_NUM,
      AL3.TRGT_DATA_WHS_RSEL_CUST_NUM, AL3.TRGT_DATA_WHS_RSEL_CUST_ID,
      AL3.TRGT_DATA_WHS_PAYER_CUST_NUM, AL3.TRGT_DATA_WHS_PAYER_CUST_ID, AL3.DATA_SRC_CD,
      AL3.TRGT_CURRNCY_CODE,
      AL3.TRGT_HW_MACH_TYPE        ,
      AL3.TRGT_HW_MACH_MODEL            ,
      AL3.TRGT_HW_MACH_SERIAL_NUM       ,
      AL3.TRGT_ORD_START_DATE           ,
      AL3.TRGT_ORD_END_DATE             ,
      AL3.TRGT_WARR_START_DATE          ,
      AL3.TRGT_WARR_END_DATE            ,
      AL3.TRGT_CONFIGRTN_ID             ,
      AL3.TRGT_SRC_HW_MACH_TYPE         ,
      AL3.TRGT_SRC_HW_MACH_MODEL        ,
      AL3.TRGT_SRC_HW_MACH_SERIAL_NUM   ,
      AL3.TRGT_APPLNC_UPGRD_FLAG        ,
      AL3.APPLNC_PART_QTY               ,
      AL3.APPLNC_NET_PART_QTY           ,
--Add two columns      
      AL3.APPLNC_QTY_FLAG               ,
      AL3.TRGT_NON_IBM_APPLNC_FLAG      ,
--Add three columns      
      AL3.PRECDNG_DOC_NUM               ,
      AL3.PRECDNG_LINE_ITEM_SEQ_NUM     ,
      AL3.SAP_SALES_DOC_TYPE_CODE       ,
      AL3.BP_TRNSFR_OF_OWNRSHP_FLAG     ,
      AL3.ORD_LINE_ITEM_SEQ_NUM	        ,
--Added in 16.1
      AL3.ENTMT_EXCPTN_CODE
      WITH UR ;
     
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
     
    IF h_sqlcode < 0 THEN
       SET v_message = ' RMS-ERR : Failed to insert data into dwdm2.maint_renwl_fact_2 table and the process failed with'
                              || 'SQL CODE: '  || CAST(h_sqlcode as CHAR(6))
                              || 'SQL State: ' || h_sqlstate;
       CALL UTOL.LPRINT( p_log_name, v_message );
       SET p_status = 9;
       GOTO ERROR_EXIT;
    ELSE
       SET  v_message = 'RMS-INF : Inserted '||cast(v_rows_affected as char(10))|| ' rows into DWDM2.MAINT_RENWL_FACT_2 completed successfully with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
       CALL UTOL.LPRINT( p_log_name, v_message );     
       COMMIT;
    END IF;

    SET  v_message = 'Inserted '||cast(v_rows_affected as char(10)) ||' rows into dwdm2.maint_renwl_fact_2 at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);

    --Delete the target data from dwdm1.maintnc_renwl_fact_trgt
    --where the TRGT_MAINTNCE_END_DATE > P_END_DATE that date

    SET d_location = 'Delete prior records from dwdm1.maintnc_renwl_fact_trgt';
    SET  v_message = '11.0 Begin : Delete prior records from dwdm1.maintnc_renwl_fact_trgt at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);

    DELETE FROM DWDM1.MAINTNC_RENWL_FACT_TRGT WHERE TRGT_MAINTNC_END_DATE >= P_END_DATE ;
    
    -- LPP Change Start    
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

    IF h_sqlcode < 0 THEN
       SET v_message = ' RMS-ERR : Failed to delete rows in DWDM1.MAINTNC_RENWL_FACT_TRGT table. Process failed with'
                              || 'SQL CODE: '  || CAST(h_sqlcode as CHAR(6))
                              || 'SQL State: ' || h_sqlstate;
       CALL UTOL.LPRINT( p_log_name, v_message );
       SET p_status = 9;
       GOTO ERROR_EXIT;
    ELSE
       SET  v_message = 'Deleted '||cast(v_rows_affected as char(10)) ||' rows in DWDM1.MAINTNC_RENWL_FACT_TRGT at ' ||cast(current timestamp as char(26)) ;
       CALL UTOL.lprint(p_log_name, v_message);
       COMMIT;
    END IF;
    -- LPP Change End    

    ---Refresh the Target data based on the current End Date
    SET d_location = 'Insert into dwdm1.maintnc_renwl_fact_trgt';
    SET  v_message = '12.0 Begin : Insert into dwdm1.maintnc_renwl_fact_trgt_ from sods2.mnged_entmt at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);

   

    INSERT INTO DWDM1.MAINTNC_RENWL_FACT_TRGT
      (SAP_SALES_ORG_CODE,            SOLD_TO_CUST_NUM,               RENWL_CUST_NUM ,
       SAP_CTRCT_NUM,                 LINE_OF_BUS_CODE,               TRGT_TOP_BILL_REVN_STREAM_CODE ,
       TRGT_MAINTNC_END_DATE,         TRGT_MAINTNC_START_DATE,        SW_SBSCRPTN_ID ,
       TRGT_EXPIRD_QTY,               TRGT_DISMANTLING_DATE,          TRGT_TOP_BILL_PART_NUM ,
       TRGT_USD_PLAN_GL_POSTD_AMT,    CNTRY_CODE,                     IBM_CNTRY_CODE,
       IBM_WWIDE_SUB_RGN_CODE,        TRGT_SAP_DISTRIBTN_CHNL_CODE,   TRGT_RENWL_PART_NUM ,
       TRGT_IBM_BLUE_DOLLARS_FLAG,    EXPCTD_ACTL_MAINTNC_END_DATE,   TRGT_MTHLY_ENTITLD_UNIT_PRICE ,
       TRGT_ENTITLD_EXPIRD_AMT,       TRGT_MTHLY_PY_BILLG_EXPIRD_AMT, TRGT_PY_BILLG_EXPIRD_AMT ,
       TRGT_PY_BILLG_ZERO_AMT_FLAG,   TRGT_BILLG_INFO_FLAG,           TRGT_EVOLTN_FLAG ,
       EXPCTD_ACTL_MTH_BETWEEN,       EXPCTD_ACTL_MAINTNC_START_MTH,  EXPCTD_ACTL_MAINTNC_START_YR ,
       EXPCTD_ACTL_MAINTNC_START_QTR, IBM_WHLSL_DIV_CODE,             DATA_WHS_END_USER_CUST_NUM,
       TRGT_DATA_WHS_RSEL_CUST_NUM,   TRGT_DATA_WHS_RSEL_CUST_ID,     TRGT_DATA_WHS_PAYER_CUST_NUM,
       TRGT_DATA_WHS_PAYER_CUST_ID,   DATA_SRC_CD, MNGED_ENTMT_PROG, -- added by leo.
       TRGT_HW_MACH_TYPE             ,
       TRGT_HW_MACH_MODEL            ,
       TRGT_HW_MACH_SERIAL_NUM       ,
       TRGT_ORD_START_DATE           ,
       TRGT_ORD_END_DATE             ,
       TRGT_WARR_START_DATE          ,
       TRGT_WARR_END_DATE            ,
       TRGT_CONFIGRTN_ID             ,
       TRGT_SRC_HW_MACH_TYPE         ,
       TRGT_SRC_HW_MACH_MODEL        ,
       TRGT_SRC_HW_MACH_SERIAL_NUM   ,
       TRGT_APPLNC_UPGRD_FLAG        ,
       TRGT_NET_QTY                  ,
       TRGT_APPLNC_FLAG              ,
-- START LPP CHANGE
       TRGT_DOC_GL_POSTD_AMT, 
       TRGT_CURRNCY_CODE, 
       TRGT_LOCAL_UNIT_PRICE_12_MTHS,
-- END LPP CHANGE
-- Add two columns
       APPLNC_QTY_FLAG,
       TRGT_NON_IBM_APPLNC_FLAG,
--Add three columns      
       PRECDNG_DOC_NUM,
       PRECDNG_LINE_ITEM_SEQ_NUM,
       SAP_SALES_DOC_TYPE_CODE,
       BP_TRNSFR_OF_OWNRSHP_FLAG,
	   ORD_LINE_ITEM_SEQ_NUM,
--Added in 16.1
       ENTMT_EXCPTN_CODE) 
 WITH temp as 
(
        select
        ME.SAP_SALES_ORG_CODE,      ME.SOLD_TO_CUST_NUM,                ME.RENWL_CUST_NUM,
        ME.SAP_CTRCT_NUM,           ME.LINE_OF_BUS_CODE,                ME.SW_SBSCRPTN_ID,
        ME.REVN_STREAM_CODE,        ME.END_DATE , ME.START_DATE ,
        ME.SW_SBSCRPTN_ID as product, 
        case when mee.ENTMT_EXCPTN_QTY is not null and me.SBSCRPTN_ID_QTY > mee.ENTMT_EXCPTN_QTY then (me.SBSCRPTN_ID_QTY - mee.ENTMT_EXCPTN_QTY)
        else ME.SBSCRPTN_ID_QTY end as SBSCRPTN_ID_QTY,
        ME.DISMANTLING_DATE, ME.MNGED_ENTMT_PROG, 
		case when mee.ENTMT_EXCPTN_QTY is not null and me.NET_SBSCRPTN_ID_QTY > mee.ENTMT_EXCPTN_QTY then (me.NET_SBSCRPTN_ID_QTY - mee.ENTMT_EXCPTN_QTY)
        else ME.NET_SBSCRPTN_ID_QTY end as NET_SBSCRPTN_ID_QTY,
        case when mee.ENTMT_EXCPTN_QTY is not null and me.SBSCRPTN_ID_QTY <= mee.ENTMT_EXCPTN_QTY then mee.entmt_excptn_code else '' end as entmt_excptn_code
        from sods2.mnged_entmt me left outer join 
        sods2.mnged_entmt_excptn mee  -- get rows without BTS and BTS for full move 
		      on me.SAP_SALES_ORG_CODE = mee.SAP_SALES_ORG_CODE
              and me.SOLD_TO_CUST_NUM = mee.SOLD_TO_CUST_NUM
              and me.RENWL_CUST_NUM = mee.RENWL_CUST_NUM
              and coalesce(me.SAP_CTRCT_NUM,'') = coalesce(mee.SAP_CTRCT_NUM,'')
              and me.LINE_OF_BUS_CODE = mee.LINE_OF_BUS_CODE
              and me.REVN_STREAM_CODE = mee.REVN_STREAM_CODE
              and me.END_DATE = mee.END_DATE   
              and me.START_DATE = mee.START_DATE
              and me.SW_SBSCRPTN_ID = mee.SW_SBSCRPTN_ID
              and mee.entmt_excptn_code = 'BTS' -- Only focus on BTS rows
			  

union 
        
        select
        ME.SAP_SALES_ORG_CODE,      ME.SOLD_TO_CUST_NUM,                ME.RENWL_CUST_NUM,
        ME.SAP_CTRCT_NUM,           ME.LINE_OF_BUS_CODE,                ME.SW_SBSCRPTN_ID,
        ME.REVN_STREAM_CODE,        ME.END_DATE , ME.START_DATE ,
        ME.SW_SBSCRPTN_ID as product, 
        ME.ENTMT_EXCPTN_QTY,
        me_old.DISMANTLING_DATE, ME.MNGED_ENTMT_PROG, ME.ENTMT_EXCPTN_QTY as NET_SBSCRPTN_ID_QTY,
        ME.entmt_excptn_code
        from sods2.mnged_entmt_excptn me
        join sods2.mnged_entmt me_old 
                on me.SAP_SALES_ORG_CODE = me_old.SAP_SALES_ORG_CODE
               and me.SOLD_TO_CUST_NUM = me_old.SOLD_TO_CUST_NUM
               and me.RENWL_CUST_NUM = me_old.RENWL_CUST_NUM
               and coalesce(me.SAP_CTRCT_NUM,'') = coalesce(me_old.SAP_CTRCT_NUM,'')
               and me.LINE_OF_BUS_CODE = me_old.LINE_OF_BUS_CODE
               and me.REVN_STREAM_CODE = me_old.REVN_STREAM_CODE
               and me.END_DATE = me_old.END_DATE   
               and me.START_DATE = me_old.START_DATE
               and me.SW_SBSCRPTN_ID = me_old.SW_SBSCRPTN_ID
               and me.entmt_excptn_code = 'BTS' -- Only focus on BTS rows
        
         where me_old.SBSCRPTN_ID_QTY > me.ENTMT_EXCPTN_QTY  -- same qty for BTS will be feed by first sql above
),
	TEST AS
     (SELECT
        ME.SAP_SALES_ORG_CODE,      ME.SOLD_TO_CUST_NUM,                ME.RENWL_CUST_NUM,
        ME.SAP_CTRCT_NUM,           ME.LINE_OF_BUS_CODE,                ME.SW_SBSCRPTN_ID,
        ME.REVN_STREAM_CODE,        ME.END_DATE PRIOR_MAINTNC_END_DATE, ME.START_DATE PRIOR_MAINTNC_START_DATE,
        ME.PRODUCT, 
        CASE WHEN AL3.APPLNC_QTY_FLAG = 1 then AL3.APPLNC_PART_QTY    --Edit qty flag by Ethan
             ELSE  ME.SBSCRPTN_ID_QTY END EXPIRED_VOLUME,
        ME.DISMANTLING_DATE,
        AL3.PART_NUM PRIOR_TOP_BILL_PART_NUM, AL3.PRIOR_USD_PLAN_GL_POSTED_AMT, AL3.CNTRY_CODE,
        AL3.IBM_CNTRY_CODE,         AL6.IBM_WWIDE_SUB_RGN_CODE,         AL3.SAP_DISTRIBTN_CHNL_CODE AS PRIOR_DISTRIBTN_CHNL_CODE,
        AL3.BLUE_DOLLARS_FLAG,
        (CASE WHEN ME.DISMANTLING_DATE <=  ME.END_DATE + 1 DAYS AND
                   ME.DISMANTLING_DATE < '9999-12-15'
                THEN (CASE WHEN TIMESTAMPDIFF(64,CHAR(TIMESTAMP_ISO(ME.DISMANTLING_DATE + 12 MONTHS)
                                                    - TIMESTAMP_ISO(ME.END_DATE + 1 DAYS))) = 0
                             THEN ME.END_DATE + 12 MONTHS
                           ELSE ME.DISMANTLING_DATE + 12 MONTHS -1 DAYS
                       END)
              WHEN (ME.DISMANTLING_DATE IS NULL)
                THEN ME.END_DATE + 12 MONTHS
              ELSE
                 (CASE WHEN TIMESTAMPDIFF(64,CHAR(TIMESTAMP_ISO(ME.END_DATE+1 DAYS)
                                                - TIMESTAMP_ISO(ME.DISMANTLING_DATE) )) = 0
                         THEN ME.DISMANTLING_DATE + 12 MONTHS
                       ELSE ME.DISMANTLING_DATE -1 DAYS
                  END)
         END ) Expected_Maint_End_Date,
       
      cast(DWDM1.F_MNTLY_ENTITLD_UNIT_PRICE(me.SOLD_TO_CUST_NUM, al7.SAP_CTRCT_NUM, me.SW_SBSCRPTN_ID, AL3.TRGT_ORD_START_DATE, AL3.TRGT_ORD_END_DATE + 1 day, AL7.VOL_DISC_LEVEL_CODE, me.REVN_STREAM_CODE) as decimal(19,2))
         AS mty_Unit_Price_Entitled ,
      (SELECT AL9.PART_NUM
       FROM  RSHR2.PROD_DIMNSN al9
             LEFT OUTER JOIN DWDM0.TOKEN_MULTI_YR_SNS_PART P
               ON al9.PART_NUM = P.TOP_BILL_PART_NUM AND
                  P.top_bill_revn_stream_code='SFXTLM'
             , WWPP2.CAMBRDG_FNSHD_PART_INFO al10
       WHERE  AL9.SW_SBSCRPTN_ID = ME.SW_SBSCRPTN_ID AND
              AL9.SW_SBSCRPTN_ID <> 'N/AP'           AND
              ((ME.REVN_STREAM_CODE in ('IFXTLM','SFXTLM') AND p.top_bill_part_num is not null)
               OR
               (ME.REVN_STREAM_CODE not in ('IFXTLM','SFXTLM') AND AL9.REVN_STREAM_CODE in ('ASRSSHWM', 'RSSHWM', 'RNWMNTSP','ASMAINT'))
              ) AND
              AL9.PART_NUM=AL10.PART_NUM             AND
              AL10.PROD_OBSLTE_FLAG=0
       ORDER BY AL9.ADD_DATE DESC
       FETCH FIRST 1 ROWS ONLY) as RENWL_PART_NUM,
       FLOAT(DWDM1.F_MNTLY_ENTITLD_UNIT_PRICE(me.SOLD_TO_CUST_NUM, al7.SAP_CTRCT_NUM, me.SW_SBSCRPTN_ID, AL3.TRGT_ORD_START_DATE, AL3.TRGT_ORD_END_DATE + 1 day, AL7.VOL_DISC_LEVEL_CODE, me.REVN_STREAM_CODE)) *
             FLOAT(DWDM1.F_MTHS_BTWN_DISMANTLNG_END_DATE(me.DISMANTLING_DATE, AL3.TRGT_ORD_END_DATE)) *
             FLOAT(CASE WHEN AL3.APPLNC_QTY_FLAG = 1 then AL3.APPLNC_PART_QTY ELSE ME.SBSCRPTN_ID_QTY END)  AS  Expired_Amount_Entitled_Price, --Edit qty flag by Ethan
       CAST ((AL3.MTY_PRICE_PR_YR_BILLG) as decimal(19,2)) AS MTY_PRICE_PR_YR_BILLG,
       CAST( AL3.MTY_PRICE_PR_YR_BILLG *
               DWDM1.F_MTHS_BTWN_DISMANTLNG_END_DATE(me.DISMANTLING_DATE, AL3.TRGT_ORD_END_DATE) as decimal(19,2)) as expired_Amt_Prior_Yr_Bill_Pr,
        CASE WHEN (coalesce(al3.Mty_Price_Pr_Yr_Billg,0.0) = 0.0 OR
                   al3.Mty_Price_Pr_Yr_Billg=0.0 )
              THEN 'Y' ELSE 'N'
        END Zero_Dlls_PY_Billng_Flag,
        AL3.BILLG_INFO_FLAG BILLING_INFO_FLAG,
        AL3.EVOLUTION_FLAG ,
        DWDM1.F_MTHS_BTWN_DISMANTLNG_END_DATE(me.DISMANTLING_DATE, me.END_DATE) as Prior_Months_Between,
        MONTH(me.end_date + 1 days)   Expected_Start_Month,
        YEAR(me.end_date + 1 days)    Expected_Start_Year,
        QUARTER(me.end_date + 1 days) Expected_Start_quarter,
        AL3.IBM_WHLSL_DIV_CODE,
        coalesce(AL3.DATA_WHS_END_USER_CUST_NUM,ME.SOLD_TO_CUST_NUM) as
        data_whs_end_user_cust_num, AL3.TRGT_DATA_WHS_RSEL_CUST_NUM,
        AL3.TRGT_DATA_WHS_RSEL_CUST_ID, AL3.TRGT_DATA_WHS_PAYER_CUST_NUM,
        AL3.TRGT_DATA_WHS_PAYER_CUST_ID,
        AL3.DATA_SRC_CD,
        ME.MNGED_ENTMT_PROG, -- added by leo.
        AL3.TRGT_HW_MACH_TYPE             ,
        AL3.TRGT_HW_MACH_MODEL            ,
        AL3.TRGT_HW_MACH_SERIAL_NUM       ,
        AL3.TRGT_ORD_START_DATE           ,
        AL3.TRGT_ORD_END_DATE             ,
        AL3.TRGT_WARR_START_DATE          ,
        AL3.TRGT_WARR_END_DATE            ,
        AL3.TRGT_CONFIGRTN_ID             ,
        AL3.TRGT_SRC_HW_MACH_TYPE         ,
        AL3.TRGT_SRC_HW_MACH_MODEL        ,
        AL3.TRGT_SRC_HW_MACH_SERIAL_NUM   ,
        AL3.TRGT_APPLNC_UPGRD_FLAG        ,
        CASE WHEN AL3.APPLNC_QTY_FLAG = 1 then AL3.APPLNC_NET_PART_QTY ELSE ME.NET_SBSCRPTN_ID_QTY END  AS TRGT_NET_QTY, --Edit qty flag by Ethan
		
        CASE WHEN PROD.BUS_MDL_TYPE_CODE IN ('AP','AT','NO','NR','AS') THEN 1 ELSE 0 END AS  TRGT_APPLNC_FLAG,

-- START LPP CHANGE
           COALESCE(TRGT_DOC_GL_POSTD_AMT,0) AS TRGT_DOC_GL_POSTD_AMT,
           COALESCE(AL3.TRGT_CURRNCY_CODE, '   ') TRGT_CURRNCY_CODE, 
           CASE WHEN COALESCE(CASE WHEN AL3.APPLNC_QTY_FLAG = 1 then AL3.APPLNC_PART_QTY ELSE ME.SBSCRPTN_ID_QTY END,0) = 0 THEN 0 ELSE --Edit qty flag by Ethan
             (FLOAT(AL3.TRGT_DOC_GL_POSTD_AMT * 12)/
           (
           (CASE
              WHEN TIMESTAMPDIFF(64, CHAR(COALESCE(TIMESTAMP_ISO(CASE WHEN ME.END_DATE < '9999-12-15' THEN (ME.END_DATE + 16 days) ELSE ME.END_DATE END), '9991-12-31-00.00.00.000000')
                  - COALESCE(TIMESTAMP_ISO(ME.START_DATE) ,'9991-12-31-00.00.00.000000')))= 0
                  THEN 1
              ELSE
                   TIMESTAMPDIFF(64,CHAR(COALESCE(TIMESTAMP_ISO(CASE WHEN ME.END_DATE < '9999-12-15' THEN (ME.END_DATE + 16 days) ELSE ME.END_DATE END) ,'9991-12-31-00.00.00.000000')
                      - COALESCE(TIMESTAMP_ISO(ME.START_DATE) ,'9991-12-31-00.00.00.000000') ))
              END) *
             CASE WHEN AL3.APPLNC_QTY_FLAG = 1 then AL3.APPLNC_PART_QTY ELSE ME.SBSCRPTN_ID_QTY END) ) END AS TRGT_LOCAL_UNIT_PRICE_12_MTHS,
-- END LPP CHANGE  
-- Add two columns
        AL3.APPLNC_QTY_FLAG  ,
        AL3.TRGT_NON_IBM_APPLNC_FLAG,
--Add three columns      
       AL3.PRECDNG_DOC_NUM,
       AL3.PRECDNG_LINE_ITEM_SEQ_NUM,
       AL3.SAP_SALES_DOC_TYPE_CODE ,
       COALESCE(AL3.BP_TRNSFR_OF_OWNRSHP_FLAG,'N') AS BP_TRNSFR_OF_OWNRSHP_FLAG,
	   AL3.ORD_LINE_ITEM_SEQ_NUM,
--Added in 16.1
       COALESCE(AL3.ENTMT_EXCPTN_CODE,'') as ENTMT_EXCPTN_CODE
     FROM temp ME
              LEFT OUTER JOIN DWDM2.MAINT_RENWL_FACT_2 AL3
                ON    (ME.SAP_SALES_ORG_CODE = AL3.SAP_SALES_ORG_CODE AND
                      ME.SOLD_TO_CUST_NUM = AL3.SOLD_TO_CUST_NUM AND
                      ME.RENWL_CUST_NUM = AL3.RENWL_CUST_NUM AND
                      COALESCE(ME.SAP_CTRCT_NUM,'000000') = COALESCE(AL3.SAP_CTRCT_NUM,'000000') AND
                      ME.MNGED_ENTMT_PROG = AL3.MNGED_ENTMT_PROG AND
                      ME.SW_SBSCRPTN_ID = AL3.SW_SBSCRPTN_ID AND
                      ME.REVN_STREAM_CODE = AL3.REVN_STREAM_CODE AND
                      ME.START_DATE = AL3.START_DATE AND
                      ME.END_DATE = AL3.END_DATE AND
                      ME.entmt_excptn_code = COALESCE(AL3.ENTMT_EXCPTN_CODE,'') and -- added condition for BTS
                      ME.END_DATE >= P_END_DATE)
              LEFT OUTER JOIN RSHR2.WWIDE_GEOGPHY_DIMNSN AL6
                ON AL3.IBM_CNTRY_CODE = AL6.IBM_CNTRY_CODE
              LEFT OUTER JOIN SODS2.CTRCT_TERMS AL7
                ON AL7.SAP_CTRCT_NUM = ME.SAP_CTRCT_NUM
              LEFT OUTER JOIN  RSHR2.PROD_DIMNSN PROD    
                ON AL3.PART_NUM = PROD.PART_NUM            
     WHERE  (me.SBSCRPTN_ID_QTY > 0 or COALESCE(AL3.BP_TRNSFR_OF_OWNRSHP_FLAG,'N') = 'Y' ) and
            me.end_date >=  P_END_DATE and
            me.end_date < '12/31/9998' and
--LPP CHANGE START
--Start Substitution List Change
            ME.MNGED_ENTMT_PROG NOT IN ('FCTSL', 'PASL') and 
            EXISTS
             (SELECT 'X' FROM RSHR2.PROD_DIMNSN PD
              LEFT OUTER JOIN DWDM0.TOKEN_MULTI_YR_SNS_PART P
               ON PD.PART_NUM = P.TOP_BILL_PART_NUM AND
                  P.top_bill_revn_stream_code='SFXTLM'
               WHERE ME.SW_SBSCRPTN_ID = PD.SW_SBSCRPTN_ID
                 AND (PD.REVN_STREAM_CODE in ('RNWMNTSP', 'ASMAINT','ASRSSHWM','RSSHWM')
                      or p.top_bill_part_num is not null)
                 AND NOT (COALESCE(PD.SAP_SALES_STAT_CODE,'xx') ='YD' AND ME.END_DATE >= COALESCE (PD.PROD_EOL_DATE - 1 days,TIMESTAMP_ISO ('9999-12-31')))) 
--End Substiution List Change
--LPP CHANGE END
        )
    SELECT
       SAP_SALES_ORG_CODE,           SOLD_TO_CUST_NUM,          RENWL_CUST_NUM,
       SAP_CTRCT_NUM,                LINE_OF_BUS_CODE,          REVN_STREAM_CODE,
       PRIOR_MAINTNC_END_DATE,       PRIOR_MAINTNC_START_DATE,  PRODUCT,
       EXPIRED_VOLUME,               DISMANTLING_DATE,          PRIOR_TOP_BILL_PART_NUM,
       PRIOR_USD_PLAN_GL_POSTED_AMT, CNTRY_CODE,                IBM_CNTRY_CODE,
       IBM_WWIDE_SUB_RGN_CODE,       PRIOR_DISTRIBTN_CHNL_CODE, RENWL_part_num,
       CASE WHEN BLUE_DOLLARS_FLAG IS NULL THEN 'N' ELSE BLUE_DOLLARS_FLAG END BLUE_DOLLARS_FLAG,
       EXPECTED_MAINT_END_DATE,      MTY_UNIT_PRICE_ENTITLED,   EXPIRED_AMOUNT_ENTITLED_PRICE,
       MTY_PRICE_PR_YR_BILLG,        EXPIRED_AMT_PRIOR_YR_BILL_PR,
       CASE WHEN ZERO_DLLS_PY_BILLNG_FLAG IS NULL THEN 'N'
              ELSE ZERO_DLLS_PY_BILLNG_FLAG
       END ZERO_DLLS_PY_BILLNG_FLAG,
       CASE WHEN BILLING_INFO_FLAG IS NULL THEN 'N' ELSE BILLING_INFO_FLAG
       END BILLING_INFO_FLAG,
       CASE WHEN EVOLUTION_FLAG IS NULL THEN 'N' ELSE EVOLUTION_FLAG
       END EVOLUTION_FLAG,
       PRIOR_MONTHS_BETWEEN,         EXPECTED_START_MONTH,      EXPECTED_START_YEAR,
       EXPECTED_START_QUARTER,       IBM_WHLSL_DIV_CODE,--,        SAP_CTRCT_VARIANT_CODE
       DATA_WHS_END_USER_CUST_NUM,  TRGT_DATA_WHS_RSEL_CUST_NUM,  TRGT_DATA_WHS_RSEL_CUST_ID,
       TRGT_DATA_WHS_PAYER_CUST_NUM, TRGT_DATA_WHS_PAYER_CUST_ID,COALESCE(DATA_SRC_CD, 'IBM'),
       MNGED_ENTMT_PROG, -- added by leo.       
       TRGT_HW_MACH_TYPE             ,
       TRGT_HW_MACH_MODEL            ,
       TRGT_HW_MACH_SERIAL_NUM       ,
       TRGT_ORD_START_DATE           ,
       TRGT_ORD_END_DATE             ,
       TRGT_WARR_START_DATE          ,
       TRGT_WARR_END_DATE            ,
       TRGT_CONFIGRTN_ID             ,
       TRGT_SRC_HW_MACH_TYPE         ,
       TRGT_SRC_HW_MACH_MODEL        ,
       TRGT_SRC_HW_MACH_SERIAL_NUM   ,
       TRGT_APPLNC_UPGRD_FLAG        ,
       TRGT_NET_QTY                  ,
       TRGT_APPLNC_FLAG              ,
-- START LPP CHANGE
       TRGT_DOC_GL_POSTD_AMT, 
       TRGT_CURRNCY_CODE, 
       TRGT_LOCAL_UNIT_PRICE_12_MTHS ,    
-- END LPP CHANGE 
-- Add two columns 
       APPLNC_QTY_FLAG  ,
       TRGT_NON_IBM_APPLNC_FLAG ,
--Add three columns      
       PRECDNG_DOC_NUM,
       PRECDNG_LINE_ITEM_SEQ_NUM,
       SAP_SALES_DOC_TYPE_CODE,
       BP_TRNSFR_OF_OWNRSHP_FLAG,
       ORD_LINE_ITEM_SEQ_NUM,
--Added in 16.1
       ENTMT_EXCPTN_CODE
    FROM TEST t LEFT OUTER JOIN DWDM0.TOKEN_MULTI_YR_SNS_PART P
         ON t.PRIOR_TOP_BILL_PART_NUM = P.TOP_BILL_PART_NUM 
    WHERE 
	(REVN_STREAM_CODE IN (
              'LCMNTSPT', 'LIC&MNT',  'MAINT AG', 'MNT&SPT',  'OTHUPMNT', 'OTHUPMSP',
              'REACTMNT', 'RNWL MNT', 'RNWMNTSP', 'TRD&MNT',  'TRDMNTSP', 'VERUPSUB', 
              'ASMAINT',  'AALSS',    'AATLSS',   'APLSS',    'APTLSS',   'CMPTRDUP', 
              'FCTTRDUP', 'ASLISS',   'ASREIHWM', 'ASRSSHWM', 'ASUHWM',   'ASUNHWM', 
              'ALISS',    'REIHWM',   'RSSHWM',   'AUHWM',    'AUNHWM',   'APXFOW')
     or p.top_bill_part_num is not null)                               
    WITH UR;

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

    IF h_sqlcode < 0 THEN
       SET v_message = ' RMS-ERR : Failed to insert data into dwdm1.maintnc_renwl_fact_trgt table and the process failed with'
                              || ' SQL CODE: '  || CAST(h_sqlcode as CHAR(6))
                              || ' SQL State: ' || h_sqlstate;
       CALL UTOL.LPRINT( p_log_name, v_message );
       SET p_status = 9;
       GOTO ERROR_EXIT;
    ELSE
       SET  v_message = 'RMS-INF : Inserted '||cast(v_rows_affected as char(10))|| ' rows into DWDM1.MAINTNC_RENWL_FACT_TRGT completed successfully with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
       CALL UTOL.LPRINT( p_log_name, v_message );      
       COMMIT;
    END IF;

    -- Records existing in both MEO and MEO_HW Chnage End 
    -- Delete the records in RMS TARGET for MEO	
    DELETE from DWDM1.MAINTNC_RENWL_FACT_TRGT tt
    where tt.TRGT_REC_ID in 
    (
    select distinct tgt.TRGT_REC_ID
    from SODS2.MNGED_ENTMT_ORD meo, SODS2.MNGED_ENTMT_ORD_HW hw, DWDM1.MAINTNC_RENWL_FACT_TRGT tgt
    where meo.RENWL_CUST_NUM= hw.RENWL_CUST_NUM
        and meo.SOLD_TO_CUST_NUM = hw.SOLD_TO_CUST_NUM
        and meo.LINE_OF_BUS_CODE = hw.LINE_OF_BUS_CODE
        and meo.SAP_SALES_ORG_CODE = hw.SAP_SALES_ORG_CODE
        and meo.SW_SBSCRPTN_ID= hw.SW_SBSCRPTN_ID
        and meo.START_DATE=hw.START_DATE
        and meo.END_DATE_G=hw.END_DATE_G
        and meo.MNGED_ENTMT_PROG= hw.MNGED_ENTMT_PROG
        and meo.SAP_CTRCT_NUM_G=hw.SAP_CTRCT_NUM_G
        and meo.REVN_STREAM_CODE=hw.REVN_STREAM_CODE
        and meo.REVN_STREAM_CODE in ('LCMNTSPT', 'LIC&MNT',  'MAINT AG','MNT&SPT',  'OTHUPMNT', 'OTHUPMSP','REACTMNT', 'RNWL MNT', 'RNWMNTSP', 'TRD&MNT' ,  'TRDMNTSP', 'VERUPSUB', 'ASMAINT', 'AALSS','AATLSS','APLSS','APTLSS','CMPTRDUP', 'FCTTRDUP', 'ASLISS', 'ASREIHWM', 'ASRSSHWM', 'ASUHWM', 'ASUNHWM', 'ALISS', 'REIHWM', 'RSSHWM', 'AUHWM', 'AUNHWM',  'APXFOW')
        and meo.END_DATE >= P_END_DATE
        and meo.MNGED_ENTMT_PROG not in ('FCTSL', 'PASL')	
        and meo.PART_QTY <> 0	
        and tgt.APPLNC_QTY_FLAG=0
        and meo.SAP_SALES_ORG_CODE = tgt.SAP_SALES_ORG_CODE 
        and meo.SOLD_TO_CUST_NUM = tgt.SOLD_TO_CUST_NUM
        and meo.RENWL_CUST_NUM = tgt.RENWL_CUST_NUM
        and COALESCE(meo.SAP_CTRCT_NUM,'000000') = COALESCE(tgt.SAP_CTRCT_NUM,'000000')
        and meo.LINE_OF_BUS_CODE = tgt.LINE_OF_BUS_CODE
        and meo.SW_SBSCRPTN_ID = tgt.SW_SBSCRPTN_ID
        and meo.REVN_STREAM_CODE = tgt.TRGT_TOP_BILL_REVN_STREAM_CODE
        and meo.START_DATE = tgt.TRGT_MAINTNC_START_DATE
        and meo.END_DATE = tgt.TRGT_MAINTNC_END_DATE
    );
	
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    IF h_sqlcode < 0 THEN
       SET v_message = ' RMS-ERR : Failed to delete data from dwdm1.maintnc_renwl_fact_trgt table for records existing in both MEO and MEO_HW and the process failed with'
                              || ' SQL CODE: '  || CAST(h_sqlcode as CHAR(6))
                              || ' SQL State: ' || h_sqlstate;
       CALL UTOL.LPRINT( p_log_name, v_message );
       SET p_status = 9;
       GOTO ERROR_EXIT;
    ELSE
       SET  v_message = 'RMS-INF : Deleted '||cast(v_rows_affected as char(10))|| ' rows from DWDM1.MAINTNC_RENWL_FACT_TRGT successfully for records existing in both MEO and MEO_HW with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
       CALL UTOL.LPRINT( p_log_name, v_message );      
       COMMIT;
    END IF;
	
    -- Insert the newly calculated records into RMS TARGET for MEO
    INSERT INTO DWDM1.MAINTNC_RENWL_FACT_TRGT
      (SAP_SALES_ORG_CODE,            SOLD_TO_CUST_NUM,               RENWL_CUST_NUM ,
       SAP_CTRCT_NUM,                 LINE_OF_BUS_CODE,               TRGT_TOP_BILL_REVN_STREAM_CODE ,
       TRGT_MAINTNC_END_DATE,         TRGT_MAINTNC_START_DATE,        SW_SBSCRPTN_ID ,
       TRGT_EXPIRD_QTY,               TRGT_DISMANTLING_DATE,          TRGT_TOP_BILL_PART_NUM ,
       TRGT_USD_PLAN_GL_POSTD_AMT,    CNTRY_CODE,                     IBM_CNTRY_CODE,
       IBM_WWIDE_SUB_RGN_CODE,        TRGT_SAP_DISTRIBTN_CHNL_CODE,   TRGT_RENWL_PART_NUM ,
       TRGT_IBM_BLUE_DOLLARS_FLAG,    EXPCTD_ACTL_MAINTNC_END_DATE,   TRGT_MTHLY_ENTITLD_UNIT_PRICE ,
       TRGT_ENTITLD_EXPIRD_AMT,       TRGT_MTHLY_PY_BILLG_EXPIRD_AMT, TRGT_PY_BILLG_EXPIRD_AMT ,
       TRGT_PY_BILLG_ZERO_AMT_FLAG,   TRGT_BILLG_INFO_FLAG,           TRGT_EVOLTN_FLAG ,
       EXPCTD_ACTL_MTH_BETWEEN,       EXPCTD_ACTL_MAINTNC_START_MTH,  EXPCTD_ACTL_MAINTNC_START_YR ,
       EXPCTD_ACTL_MAINTNC_START_QTR, IBM_WHLSL_DIV_CODE,             DATA_WHS_END_USER_CUST_NUM,
       TRGT_DATA_WHS_RSEL_CUST_NUM,   TRGT_DATA_WHS_RSEL_CUST_ID,     TRGT_DATA_WHS_PAYER_CUST_NUM,
       TRGT_DATA_WHS_PAYER_CUST_ID,   DATA_SRC_CD, MNGED_ENTMT_PROG, -- added by leo.
       TRGT_HW_MACH_TYPE             ,
       TRGT_HW_MACH_MODEL            ,
       TRGT_HW_MACH_SERIAL_NUM       ,
       TRGT_ORD_START_DATE           ,
       TRGT_ORD_END_DATE             ,
       TRGT_WARR_START_DATE          ,
       TRGT_WARR_END_DATE            ,
       TRGT_CONFIGRTN_ID             ,
       TRGT_SRC_HW_MACH_TYPE         ,
       TRGT_SRC_HW_MACH_MODEL        ,
       TRGT_SRC_HW_MACH_SERIAL_NUM   ,
       TRGT_APPLNC_UPGRD_FLAG        ,
       TRGT_NET_QTY                  ,
       TRGT_APPLNC_FLAG              ,
-- START LPP CHANGE
       TRGT_DOC_GL_POSTD_AMT, 
       TRGT_CURRNCY_CODE, 
       TRGT_LOCAL_UNIT_PRICE_12_MTHS,
-- END LPP CHANGE
-- Add two columns
       APPLNC_QTY_FLAG,
       TRGT_NON_IBM_APPLNC_FLAG,
--Add three columns      
       PRECDNG_DOC_NUM,
       PRECDNG_LINE_ITEM_SEQ_NUM,
       SAP_SALES_DOC_TYPE_CODE,
       BP_TRNSFR_OF_OWNRSHP_FLAG,
       ORD_LINE_ITEM_SEQ_NUM,
-- Added in 16.1
       ENTMT_EXCPTN_CODE) 
	
    with temp as
    ( 
    select distinct
        meo.RENWL_CUST_NUM,
        meo.SOLD_TO_CUST_NUM,
        meo.LINE_OF_BUS_CODE,
        meo.SAP_SALES_ORG_CODE,
        meo.SW_SBSCRPTN_ID,
        meo.START_DATE,
        meo.END_DATE_G,
        meo.MNGED_ENTMT_PROG,
        meo.SAP_CTRCT_NUM_G,
        meo.REVN_STREAM_CODE
    from SODS2.MNGED_ENTMT_ORD meo, SODS2.MNGED_ENTMT_ORD_HW hw
    where meo.RENWL_CUST_NUM= hw.RENWL_CUST_NUM
        and meo.SOLD_TO_CUST_NUM = hw.SOLD_TO_CUST_NUM
        and meo.LINE_OF_BUS_CODE = hw.LINE_OF_BUS_CODE
        and meo.SAP_SALES_ORG_CODE = hw.SAP_SALES_ORG_CODE
        and meo.SW_SBSCRPTN_ID= hw.SW_SBSCRPTN_ID
        and meo.START_DATE=hw.START_DATE
        and meo.END_DATE_G=hw.END_DATE_G
        and meo.MNGED_ENTMT_PROG= hw.MNGED_ENTMT_PROG
        and meo.SAP_CTRCT_NUM_G=hw.SAP_CTRCT_NUM_G
        and meo.REVN_STREAM_CODE=hw.REVN_STREAM_CODE
        and meo.REVN_STREAM_CODE in ('LCMNTSPT', 'LIC&MNT',  'MAINT AG','MNT&SPT',  'OTHUPMNT', 'OTHUPMSP','REACTMNT', 'RNWL MNT', 'RNWMNTSP', 'TRD&MNT' ,  'TRDMNTSP', 'VERUPSUB', 'ASMAINT', 'AALSS','AATLSS','APLSS','APTLSS','CMPTRDUP', 'FCTTRDUP', 'ASLISS', 'ASREIHWM', 'ASRSSHWM', 'ASUHWM', 'ASUNHWM', 'ALISS', 'REIHWM', 'RSSHWM', 'AUHWM', 'AUNHWM',  'APXFOW')	
    ),
    -- Calculate the sum(PART_QTY) from MEO for records existing in both MEO and MEO_HW
    bi_records as 
    (
    select 
        meo.RENWL_CUST_NUM,
        meo.SOLD_TO_CUST_NUM,
        meo.LINE_OF_BUS_CODE,
        meo.SAP_SALES_ORG_CODE,
        meo.SW_SBSCRPTN_ID,
        meo.START_DATE,
        meo.END_DATE,
        meo.MNGED_ENTMT_PROG,
        meo.SAP_CTRCT_NUM,
        meo.REVN_STREAM_CODE,
        sum(meo.PART_QTY) as PART_QTY
    from SODS2.MNGED_ENTMT_ORD meo, temp t
    where meo.RENWL_CUST_NUM= t.RENWL_CUST_NUM
        and meo.SOLD_TO_CUST_NUM = t.SOLD_TO_CUST_NUM
        and meo.LINE_OF_BUS_CODE = t.LINE_OF_BUS_CODE
        and meo.SAP_SALES_ORG_CODE = t.SAP_SALES_ORG_CODE
        and meo.SW_SBSCRPTN_ID= t.SW_SBSCRPTN_ID
        and meo.START_DATE=t.START_DATE
        and meo.END_DATE_G=t.END_DATE_G
        and meo.MNGED_ENTMT_PROG= t.MNGED_ENTMT_PROG
        and meo.SAP_CTRCT_NUM_G=t.SAP_CTRCT_NUM_G
        and meo.REVN_STREAM_CODE=t.REVN_STREAM_CODE
        and meo.END_DATE >= P_END_DATE
        and meo.MNGED_ENTMT_PROG not in ('FCTSL', 'PASL')	
        and meo.PART_QTY <> 0
    group by
        meo.RENWL_CUST_NUM,
        meo.SOLD_TO_CUST_NUM,
        meo.LINE_OF_BUS_CODE,
        meo.SAP_SALES_ORG_CODE,
        meo.SW_SBSCRPTN_ID,
        meo.START_DATE,
        meo.END_DATE,
        meo.MNGED_ENTMT_PROG,
        meo.SAP_CTRCT_NUM,
        meo.REVN_STREAM_CODE
    ),
	
    TEST AS
    (SELECT
        ME.SAP_SALES_ORG_CODE,      ME.SOLD_TO_CUST_NUM,                ME.RENWL_CUST_NUM,
        ME.SAP_CTRCT_NUM,           ME.LINE_OF_BUS_CODE,                ME.SW_SBSCRPTN_ID,
        ME.REVN_STREAM_CODE,        ME.END_DATE PRIOR_MAINTNC_END_DATE, ME.START_DATE PRIOR_MAINTNC_START_DATE,
        ME.SW_SBSCRPTN_ID PRODUCT, 
        BR.PART_QTY as EXPIRED_VOLUME,
        ME.DISMANTLING_DATE,
        AL3.PART_NUM PRIOR_TOP_BILL_PART_NUM, AL3.PRIOR_USD_PLAN_GL_POSTED_AMT, AL3.CNTRY_CODE,
        AL3.IBM_CNTRY_CODE,         AL6.IBM_WWIDE_SUB_RGN_CODE,         AL3.SAP_DISTRIBTN_CHNL_CODE AS PRIOR_DISTRIBTN_CHNL_CODE,
        AL3.BLUE_DOLLARS_FLAG,
        (CASE WHEN ME.DISMANTLING_DATE <=  ME.END_DATE + 1 DAYS AND
                   ME.DISMANTLING_DATE < '9999-12-15'
                THEN (CASE WHEN TIMESTAMPDIFF(64,CHAR(TIMESTAMP_ISO(ME.DISMANTLING_DATE + 12 MONTHS)
                                                    - TIMESTAMP_ISO(ME.END_DATE + 1 DAYS))) = 0
                             THEN ME.END_DATE + 12 MONTHS
                           ELSE ME.DISMANTLING_DATE + 12 MONTHS -1 DAYS
                       END)
              WHEN (ME.DISMANTLING_DATE IS NULL)
                THEN ME.END_DATE + 12 MONTHS
              ELSE
                 (CASE WHEN TIMESTAMPDIFF(64,CHAR(TIMESTAMP_ISO(ME.END_DATE+1 DAYS)
                                                - TIMESTAMP_ISO(ME.DISMANTLING_DATE) )) = 0
                         THEN ME.DISMANTLING_DATE + 12 MONTHS
                       ELSE ME.DISMANTLING_DATE -1 DAYS
                  END)
         END ) Expected_Maint_End_Date,
       
      cast(DWDM1.F_MNTLY_ENTITLD_UNIT_PRICE(me.SOLD_TO_CUST_NUM, al7.SAP_CTRCT_NUM, me.SW_SBSCRPTN_ID, AL3.TRGT_ORD_START_DATE, AL3.TRGT_ORD_END_DATE + 1 day, AL7.VOL_DISC_LEVEL_CODE, me.REVN_STREAM_CODE) as decimal(19,2))
         AS mty_Unit_Price_Entitled ,
      (SELECT AL9.PART_NUM
       FROM  RSHR2.PROD_DIMNSN al9
             LEFT OUTER JOIN DWDM0.TOKEN_MULTI_YR_SNS_PART P
               ON al9.PART_NUM = P.TOP_BILL_PART_NUM AND
                  P.top_bill_revn_stream_code='SFXTLM'
             , WWPP2.CAMBRDG_FNSHD_PART_INFO al10
       WHERE  AL9.SW_SBSCRPTN_ID = ME.SW_SBSCRPTN_ID AND
              AL9.SW_SBSCRPTN_ID <> 'N/AP'           AND
              ((ME.REVN_STREAM_CODE in ('IFXTLM','SFXTLM') AND p.top_bill_part_num is not null)
               OR
               (ME.REVN_STREAM_CODE not in ('IFXTLM','SFXTLM') AND AL9.REVN_STREAM_CODE in ('ASRSSHWM', 'RSSHWM', 'RNWMNTSP','ASMAINT'))
              ) AND
              AL9.PART_NUM=AL10.PART_NUM             AND
              AL10.PROD_OBSLTE_FLAG=0
       ORDER BY AL9.ADD_DATE DESC
       FETCH FIRST 1 ROWS ONLY) as RENWL_PART_NUM,
       FLOAT(DWDM1.F_MNTLY_ENTITLD_UNIT_PRICE(me.SOLD_TO_CUST_NUM, al7.SAP_CTRCT_NUM, me.SW_SBSCRPTN_ID, AL3.TRGT_ORD_START_DATE, AL3.TRGT_ORD_END_DATE + 1 day, AL7.VOL_DISC_LEVEL_CODE, me.REVN_STREAM_CODE)) *
             FLOAT(DWDM1.F_MTHS_BTWN_DISMANTLNG_END_DATE(me.DISMANTLING_DATE, AL3.TRGT_ORD_END_DATE)) *
             FLOAT(BR.PART_QTY)  AS  Expired_Amount_Entitled_Price, --Edit qty flag by Ethan
       CAST ((AL3.MTY_PRICE_PR_YR_BILLG) as decimal(19,2)) AS MTY_PRICE_PR_YR_BILLG,
       CAST( AL3.MTY_PRICE_PR_YR_BILLG *
               DWDM1.F_MTHS_BTWN_DISMANTLNG_END_DATE(me.DISMANTLING_DATE, AL3.TRGT_ORD_END_DATE) as decimal(19,2)) as expired_Amt_Prior_Yr_Bill_Pr,
        CASE WHEN (coalesce(al3.Mty_Price_Pr_Yr_Billg,0.0) = 0.0 OR
                   al3.Mty_Price_Pr_Yr_Billg=0.0 )
              THEN 'Y' ELSE 'N'
        END Zero_Dlls_PY_Billng_Flag,
        AL3.BILLG_INFO_FLAG BILLING_INFO_FLAG,
        AL3.EVOLUTION_FLAG ,
        DWDM1.F_MTHS_BTWN_DISMANTLNG_END_DATE(me.DISMANTLING_DATE, me.END_DATE) as Prior_Months_Between,
        MONTH(me.end_date + 1 days)   Expected_Start_Month,
        YEAR(me.end_date + 1 days)    Expected_Start_Year,
        QUARTER(me.end_date + 1 days) Expected_Start_quarter,
        AL3.IBM_WHLSL_DIV_CODE,
        coalesce(AL3.DATA_WHS_END_USER_CUST_NUM,ME.SOLD_TO_CUST_NUM) as
        data_whs_end_user_cust_num, AL3.TRGT_DATA_WHS_RSEL_CUST_NUM,
        AL3.TRGT_DATA_WHS_RSEL_CUST_ID, AL3.TRGT_DATA_WHS_PAYER_CUST_NUM,
        AL3.TRGT_DATA_WHS_PAYER_CUST_ID,
        AL3.DATA_SRC_CD,
        ME.MNGED_ENTMT_PROG, -- added by leo.
        AL3.TRGT_HW_MACH_TYPE             ,
        AL3.TRGT_HW_MACH_MODEL            ,
        AL3.TRGT_HW_MACH_SERIAL_NUM       ,
        AL3.TRGT_ORD_START_DATE           ,
        AL3.TRGT_ORD_END_DATE             ,
        AL3.TRGT_WARR_START_DATE          ,
        AL3.TRGT_WARR_END_DATE            ,
        AL3.TRGT_CONFIGRTN_ID             ,
        AL3.TRGT_SRC_HW_MACH_TYPE         ,
        AL3.TRGT_SRC_HW_MACH_MODEL        ,
        AL3.TRGT_SRC_HW_MACH_SERIAL_NUM   ,
        AL3.TRGT_APPLNC_UPGRD_FLAG        ,
        BR.PART_QTY AS TRGT_NET_QTY, --Edit qty flag by Ethan
        CASE WHEN PROD.BUS_MDL_TYPE_CODE IN ('AP','AT','NO','NR','AS') THEN 1 ELSE 0 END AS  TRGT_APPLNC_FLAG,

-- START LPP CHANGE
           COALESCE(TRGT_DOC_GL_POSTD_AMT,0) AS TRGT_DOC_GL_POSTD_AMT,
           COALESCE(AL3.TRGT_CURRNCY_CODE, '   ') TRGT_CURRNCY_CODE, 
           CASE WHEN COALESCE(BR.PART_QTY,0) = 0 THEN 0 ELSE --Edit qty flag by Ethan
             (FLOAT(AL3.TRGT_DOC_GL_POSTD_AMT * 12)/
           (
           (CASE
              WHEN TIMESTAMPDIFF(64, CHAR(COALESCE(TIMESTAMP_ISO(CASE WHEN ME.END_DATE < '9999-12-15' THEN (ME.END_DATE + 16 days) ELSE ME.END_DATE END), '9991-12-31-00.00.00.000000')
                  - COALESCE(TIMESTAMP_ISO(ME.START_DATE) ,'9991-12-31-00.00.00.000000')))= 0
                  THEN 1
              ELSE
                   TIMESTAMPDIFF(64,CHAR(COALESCE(TIMESTAMP_ISO(CASE WHEN ME.END_DATE < '9999-12-15' THEN (ME.END_DATE + 16 days) ELSE ME.END_DATE END) ,'9991-12-31-00.00.00.000000')
                      - COALESCE(TIMESTAMP_ISO(ME.START_DATE) ,'9991-12-31-00.00.00.000000') ))
              END) *
             BR.PART_QTY) ) END AS TRGT_LOCAL_UNIT_PRICE_12_MTHS,
-- END LPP CHANGE  
-- Add two columns
        AL3.APPLNC_QTY_FLAG  ,
        AL3.TRGT_NON_IBM_APPLNC_FLAG,
--Add three columns      
       AL3.PRECDNG_DOC_NUM,
       AL3.PRECDNG_LINE_ITEM_SEQ_NUM,
       AL3.SAP_SALES_DOC_TYPE_CODE ,
       COALESCE(AL3.BP_TRNSFR_OF_OWNRSHP_FLAG,'N') AS BP_TRNSFR_OF_OWNRSHP_FLAG,
	   AL3.ORD_LINE_ITEM_SEQ_NUM,
--Added in 16.1
       AL3.ENTMT_EXCPTN_CODE
	 FROM bi_records BR
              inner JOIN SODS2.MNGED_ENTMT ME
                ON    (ME.SAP_SALES_ORG_CODE = BR.SAP_SALES_ORG_CODE AND
                      ME.SOLD_TO_CUST_NUM = BR.SOLD_TO_CUST_NUM AND
                      ME.RENWL_CUST_NUM = BR.RENWL_CUST_NUM AND
                      COALESCE(ME.SAP_CTRCT_NUM,'000000') = COALESCE(BR.SAP_CTRCT_NUM,'000000') AND
                      ME.LINE_OF_BUS_CODE = BR.LINE_OF_BUS_CODE AND
                      ME.SW_SBSCRPTN_ID = BR.SW_SBSCRPTN_ID AND
                      ME.REVN_STREAM_CODE = BR.REVN_STREAM_CODE AND
                      ME.START_DATE = BR.START_DATE AND
                      ME.END_DATE = BR.END_DATE)
              LEFT OUTER JOIN DWDM2.MAINT_RENWL_FACT_2 AL3
                ON    (ME.SAP_SALES_ORG_CODE = AL3.SAP_SALES_ORG_CODE AND
                      ME.SOLD_TO_CUST_NUM = AL3.SOLD_TO_CUST_NUM AND
                      ME.RENWL_CUST_NUM = AL3.RENWL_CUST_NUM AND
                      COALESCE(ME.SAP_CTRCT_NUM,'000000') = COALESCE(AL3.SAP_CTRCT_NUM,'000000') AND
                      ME.MNGED_ENTMT_PROG = AL3.MNGED_ENTMT_PROG AND
                      ME.SW_SBSCRPTN_ID = AL3.SW_SBSCRPTN_ID AND
                      ME.REVN_STREAM_CODE = AL3.REVN_STREAM_CODE AND
                      ME.START_DATE = AL3.START_DATE AND
                      ME.END_DATE = AL3.END_DATE AND
                      ME.END_DATE >= P_END_DATE AND
                      AL3.APPLNC_QTY_FLAG = 0)
              LEFT OUTER JOIN RSHR2.WWIDE_GEOGPHY_DIMNSN AL6
                ON AL3.IBM_CNTRY_CODE = AL6.IBM_CNTRY_CODE
              LEFT OUTER JOIN SODS2.CTRCT_TERMS AL7
                ON AL7.SAP_CTRCT_NUM = ME.SAP_CTRCT_NUM
              LEFT OUTER JOIN  RSHR2.PROD_DIMNSN PROD    
                ON AL3.PART_NUM = PROD.PART_NUM            
     WHERE  (me.SBSCRPTN_ID_QTY > 0 or COALESCE(AL3.BP_TRNSFR_OF_OWNRSHP_FLAG,'N') = 'Y' ) and
            me.end_date >=  P_END_DATE and
            me.end_date < '12/31/9998' and
--LPP CHANGE START
--Start Substitution List Change
            ME.MNGED_ENTMT_PROG NOT IN ('FCTSL', 'PASL') and 
            EXISTS
             (SELECT 'X' FROM RSHR2.PROD_DIMNSN PD
              LEFT OUTER JOIN DWDM0.TOKEN_MULTI_YR_SNS_PART P
               ON PD.PART_NUM = P.TOP_BILL_PART_NUM AND
                  P.top_bill_revn_stream_code='SFXTLM'
               WHERE ME.SW_SBSCRPTN_ID = PD.SW_SBSCRPTN_ID
                 AND (PD.REVN_STREAM_CODE in ('RNWMNTSP', 'ASMAINT','ASRSSHWM','RSSHWM')
                      or p.top_bill_part_num is not null)
                 AND NOT (COALESCE(PD.SAP_SALES_STAT_CODE,'xx') ='YD' AND ME.END_DATE >= COALESCE (PD.PROD_EOL_DATE - 1 days,TIMESTAMP_ISO ('9999-12-31')))) 
--End Substiution List Change
--LPP CHANGE END
        )
    SELECT
       SAP_SALES_ORG_CODE,           SOLD_TO_CUST_NUM,          RENWL_CUST_NUM,
       SAP_CTRCT_NUM,                LINE_OF_BUS_CODE,          REVN_STREAM_CODE,
       PRIOR_MAINTNC_END_DATE,       PRIOR_MAINTNC_START_DATE,  PRODUCT,
       EXPIRED_VOLUME,               DISMANTLING_DATE,          PRIOR_TOP_BILL_PART_NUM,
       PRIOR_USD_PLAN_GL_POSTED_AMT, CNTRY_CODE,                IBM_CNTRY_CODE,
       IBM_WWIDE_SUB_RGN_CODE,       PRIOR_DISTRIBTN_CHNL_CODE, RENWL_part_num,
       CASE WHEN BLUE_DOLLARS_FLAG IS NULL THEN 'N' ELSE BLUE_DOLLARS_FLAG END BLUE_DOLLARS_FLAG,
       EXPECTED_MAINT_END_DATE,      MTY_UNIT_PRICE_ENTITLED,   EXPIRED_AMOUNT_ENTITLED_PRICE,
       MTY_PRICE_PR_YR_BILLG,        EXPIRED_AMT_PRIOR_YR_BILL_PR,
       CASE WHEN ZERO_DLLS_PY_BILLNG_FLAG IS NULL THEN 'N'
              ELSE ZERO_DLLS_PY_BILLNG_FLAG
       END ZERO_DLLS_PY_BILLNG_FLAG,
       CASE WHEN BILLING_INFO_FLAG IS NULL THEN 'N' ELSE BILLING_INFO_FLAG
       END BILLING_INFO_FLAG,
       CASE WHEN EVOLUTION_FLAG IS NULL THEN 'N' ELSE EVOLUTION_FLAG
       END EVOLUTION_FLAG,
       PRIOR_MONTHS_BETWEEN,         EXPECTED_START_MONTH,      EXPECTED_START_YEAR,
       EXPECTED_START_QUARTER,       IBM_WHLSL_DIV_CODE,--,        SAP_CTRCT_VARIANT_CODE
       DATA_WHS_END_USER_CUST_NUM,  TRGT_DATA_WHS_RSEL_CUST_NUM,  TRGT_DATA_WHS_RSEL_CUST_ID,
       TRGT_DATA_WHS_PAYER_CUST_NUM, TRGT_DATA_WHS_PAYER_CUST_ID,COALESCE(DATA_SRC_CD, 'IBM'),
       MNGED_ENTMT_PROG, -- added by leo.       
       TRGT_HW_MACH_TYPE             ,
       TRGT_HW_MACH_MODEL            ,
       TRGT_HW_MACH_SERIAL_NUM       ,
       TRGT_ORD_START_DATE           ,
       TRGT_ORD_END_DATE             ,
       TRGT_WARR_START_DATE          ,
       TRGT_WARR_END_DATE            ,
       TRGT_CONFIGRTN_ID             ,
       TRGT_SRC_HW_MACH_TYPE         ,
       TRGT_SRC_HW_MACH_MODEL        ,
       TRGT_SRC_HW_MACH_SERIAL_NUM   ,
       TRGT_APPLNC_UPGRD_FLAG        ,
       TRGT_NET_QTY                  ,
       TRGT_APPLNC_FLAG              ,
-- START LPP CHANGE
       TRGT_DOC_GL_POSTD_AMT, 
       TRGT_CURRNCY_CODE, 
       TRGT_LOCAL_UNIT_PRICE_12_MTHS ,    
-- END LPP CHANGE 
-- Add two columns 
       APPLNC_QTY_FLAG  ,
       TRGT_NON_IBM_APPLNC_FLAG ,
--Add three columns      
       PRECDNG_DOC_NUM,
       PRECDNG_LINE_ITEM_SEQ_NUM,
       SAP_SALES_DOC_TYPE_CODE,
       BP_TRNSFR_OF_OWNRSHP_FLAG,
       ORD_LINE_ITEM_SEQ_NUM,
--Added in 16.1
       ENTMT_EXCPTN_CODE	   
    FROM TEST t LEFT OUTER JOIN DWDM0.TOKEN_MULTI_YR_SNS_PART P
         ON t.PRIOR_TOP_BILL_PART_NUM = P.TOP_BILL_PART_NUM 
    WHERE 
	(REVN_STREAM_CODE IN (
              'LCMNTSPT', 'LIC&MNT',  'MAINT AG', 'MNT&SPT',  'OTHUPMNT', 'OTHUPMSP',
              'REACTMNT', 'RNWL MNT', 'RNWMNTSP', 'TRD&MNT',  'TRDMNTSP', 'VERUPSUB', 
              'ASMAINT',  'AALSS',    'AATLSS',   'APLSS',    'APTLSS',   'CMPTRDUP', 
              'FCTTRDUP', 'ASLISS',   'ASREIHWM', 'ASRSSHWM', 'ASUHWM',   'ASUNHWM', 
              'ALISS',    'REIHWM',   'RSSHWM',   'AUHWM',    'AUNHWM',   'APXFOW')
     or p.top_bill_part_num is not null) 
     AND APPLNC_QTY_FLAG=0 	 
    WITH UR;

   GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
   IF h_sqlcode < 0 THEN
       SET v_message = ' RMS-ERR : Failed to update data into dwdm1.maintnc_renwl_fact_trgt table for records existing in both MEO and MEO_HW and the process failed with'
                              || ' SQL CODE: '  || CAST(h_sqlcode as CHAR(6))
                              || ' SQL State: ' || h_sqlstate;
       CALL UTOL.LPRINT( p_log_name, v_message );
       SET p_status = 9;
       GOTO ERROR_EXIT;
    ELSE
       SET  v_message = 'RMS-INF : Updated '||cast(v_rows_affected as char(10))|| ' rows in DWDM1.MAINTNC_RENWL_FACT_TRGT successfully for records existing in both MEO and MEO_HW with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
       CALL UTOL.LPRINT( p_log_name, v_message );      
       COMMIT;
    END IF;    
    -- Records existing in both MEO and MEO_HW Chnage End  
	
    UPDATE DWDM1.MAINTNC_RENWL_FACT_TRGT TRGT
    SET TRGT_EXPIRD_QTY = 0, TRGT_NET_QTY = 0
    WHERE (TRGT_EXPIRD_QTY <> 0 OR TRGT_NET_QTY <> 0)
         AND EXISTS (SELECT 1 FROM 
               (SELECT TRGT1.TRGT_REC_ID, ROW_NUMBER() OVER (PARTITION BY TRGT1.SAP_SALES_ORG_CODE,
                                             TRGT1.SOLD_TO_CUST_NUM, 
                                             TRGT1.RENWL_CUST_NUM,
                                             --TRGT1.LINE_OF_BUS_CODE,
                                             TRGT1.MNGED_ENTMT_PROG,
                                             TRGT1.TRGT_TOP_BILL_REVN_STREAM_CODE,
                                             TRGT1.SAP_CTRCT_NUM,     
                                             TRGT1.TRGT_MAINTNC_START_DATE, 
                                             TRGT1.TRGT_MAINTNC_END_DATE, 
                                             TRGT1.SW_SBSCRPTN_ID,
                                             TRGT1.TRGT_EXPIRD_QTY,
											 TRGT1.ENTMT_EXCPTN_CODE  --added by susie
                                             ) AS CN
                FROM DWDM1.MAINTNC_RENWL_FACT_TRGT TRGT1 
                WHERE (TRGT_EXPIRD_QTY <> 0 OR TRGT_NET_QTY <> 0)
                       AND APPLNC_QTY_FLAG = 0 --Edit by Ethan
                )  T_RANGE
           WHERE T_RANGE.CN > 1 and T_RANGE.TRGT_REC_ID = TRGT.TRGT_REC_ID
    );

   -- LPP Change Start
  GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
   IF h_sqlcode < 0 THEN
       SET v_message = ' RMS-ERR : Failed to update data into dwdm1.maintnc_renwl_fact_trgt table and the process failed with'
                              || ' SQL CODE: '  || CAST(h_sqlcode as CHAR(6))
                              || ' SQL State: ' || h_sqlstate;
       CALL UTOL.LPRINT( p_log_name, v_message );
       SET p_status = 9;
       GOTO ERROR_EXIT;
    ELSE
       SET  v_message = 'RMS-INF : Updated '||cast(v_rows_affected as char(10))|| ' rows in DWDM1.MAINTNC_RENWL_FACT_TRGT successfully with status code : '||cast(v_status as char(10)) ||' at ' ||cast(current timestamp as char(26)) ;
       CALL UTOL.LPRINT( p_log_name, v_message );      
       COMMIT;
    END IF;    
    -- LPP Chnage End  
	
    SET  v_message = 'RMS-SUCCESS: '||v_proc_name||' completed successfully at ' ||cast(current timestamp as char(26)) ;
    CALL UTOL.lprint(p_log_name, v_message);

    SET p_status = 0;
    RETURN P_STATUS;

    ERROR_EXIT:

        SET v_message = 'RMS-FAILED : with sql_code: ' || CAST(h_sqlcode as CHAR(6));
        SET v_message = v_message || ':sql_state: ' || h_sqlstate ;
        SET v_message = v_message || ':at section: '|| d_location;
        SET v_message = v_message || ' at '|| cast(current timestamp as char(26));
        CALL UTOL.LPRINT(p_log_name, v_message);
        SET P_STATUS = 9;
        RETURN  P_STATUS ;
  END;

END



@

CALL DTOL.G_SP_EXEC_GRP ('DWDM1', 'DP_INSRT_MAINT_RENWL_FACT_TRGT', 'DSSOPER')
@
CALL DTOL.G_SP_EXEC_GRP ('DWDM1', 'DP_INSRT_MAINT_RENWL_FACT_TRGT', 'DWOPER')
@
