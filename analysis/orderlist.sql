create or replace PROCEDURE        SP_CSC_0201_GET_ORDER_LIST
-- ==========================================================================================
-- Author       : Moon
-- Create date  : 2013-05-14
-- Description  : 접수 목록 출력 (상담원) => SP_CSC_0201_GET_ORDER_LIST
--              - 출력목록 추가(2013-06-04)
-- ==========================================================================================
-- out_CODE     : 0(실패), 1(성공)
-- ==========================================================================================
-- out_DATA     : ALD_A01_TODAY 참조
-- ==========================================================================================
-- out_VALUE    : LAST_UPDATE
-- ==========================================================================================
(
    in_USR_LEVEL_CD     IN  VARCHAR2                -- 사용자레벨구분코드
    , in_HD_CODE        IN  VARCHAR2                -- 사용자총판코드
    , in_BR_CODE        IN  VARCHAR2                -- 사용자지사코드
    , in_CALL_BR_CODE   IN  VARCHAR2                -- 콜센터코드
    , in_ORD_TYPE_CD    IN  VARCHAR2                -- 접수구분코드
    
    , in_ORD_STATUS_CD  IN  VARCHAR2                -- 접수상태코드
    , in_LAST_UPDATE    IN  VARCHAR2                -- 마지막 조회시간 YYYYMMDDHH24MISS(예: 20130529134532)
    , in_SRCH_OPTION    IN  VARCHAR2                -- 검색 구분 (1:기사명, 2:기사사번, 3:가맹점명, 4:가맹점전화, 5:고객명, 6:고객전화, 7:출발지, 8:도착지, 9:상담원ID, 10:접수번호, 11:기사연락처, 12:당일순번)
    , in_SRCH_KEYWORD   IN  VARCHAR2                -- 검색 키워드
    , in_FROM_DATE      IN  VARCHAR2                -- 기간검색 시작일자 (예: 2013-05-29)
    
    , in_TO_DATE        IN  VARCHAR2                -- 기간검색 종료일자 (예: 2013-05-29)
    , in_OWN_CALL       IN  VARCHAR2                -- 본인콜 검색 (상담원 ID)
    , in_ST_CODE        VARCHAR2                    -- 사용자가맹점코드
    , vi_USR_ID         VARCHAR2
    , vi_FIND_BR_CODE   VARCHAR2    

--  // 2013.10.18 추가
    , vi_CARD_YN        VARCHAR2                    -- 카드오더여부
--     2013.11.15 추가     
    , vi_FIND_HD_CODE   VARCHAR2    
--     2014.01.24 추가     
    , vi_FIND_PAY_LATER VARCHAR2                    -- 외상 추가    

    , out_CODE          OUT VARCHAR2
    , out_MSG           OUT VARCHAR2
    , out_DATA          OUT SYS_REFCURSOR
    , out_VALUE         OUT VARCHAR2
)
IS
    v_Cnt               NUMBER;

    v_LAST_UPDATE       VARCHAR2(14)    := TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS');

BEGIN

--  // OUT PUT 초기설정
    out_CODE            := '1';
    out_MSG             := 'SUCCESS';
    out_VALUE           := v_LAST_UPDATE;
/*
    상담원 CS
        상담원 레벨      : (CALL_BR_CODE = in_CALL_BR_CODE)(발주) OR (CTH_CALL_BR_CODE = in_CALL_BR_CODE)(수주)
        지사사용자 레벨  : (ORD_HD_CODE = in_HD_CODE AND ORD_BR_CODE = in_BR_CODE) OR (CTH_HD_CODE = in_HD_CODE AND CTH_BR_CODE = in_BR_CODE) 
        총판사용자 레벨  : (ORD_HD_CODE = in_HD_CODE) OR (CTH_HD_CODE = in_HD_CODE)
    가맹점 CS
        가맹점사용자 레벨: (ORD_ST_CODE = in_ST_CODE) OR (PER_ST_CODE = in_ST_CODE)             
*/
    IF in_USR_LEVEL_CD LIKE '2%' THEN
        OPEN out_DATA FOR
            SELECT A01.ORD_NO
                , A01.ORD_TYPE_CD, A01.TODAY_NO, A01.TODAY_ADD_NO, A01.ORD_STATUS_CD, A01.ORD_PRE_STATUS_CD             -- 1 ~ 5
                , A01.ORD_CU_GRP_TYPE, A01.ORD_CU_NO, A01.ORD_CU_TEL, A01.ORD_CU_TEL2, A01.ORD_CU_NAME                  -- 6 ~ 10
                , A01.ORD_CU_TYPE_CD, A01.ORD_CU_LEVEL_CD, A01.ORD_CU_END_CNT, A01.ORD_HD_CODE, A01.ORD_HD_NAME         -- 11 ~ 15
                , A01.ORD_BR_CODE, A01.ORD_BR_NAME, A01.ORD_ST_CODE, A01.ORD_ST_NAME, A01.ORD_TEL                       -- 16 ~ 20
                , A01.CALL_BR_CODE, A01.IN_DATE, A01.IN_USR_ID, A01.ORD_DATE, A01.UPDATE_DATE                           -- 21 ~ 25
                , A01.UPDATE_USR_ID, A01.CANCEL_DATE, A01.CANCEL_TYPE_CD, A01.CANCEL_MEMO, A01.CTH_DATE                 -- 26 ~ 30
                , A01.CTH_WK_CODE, A01.CTH_WK_NAME, A01.ORD_MEMO, A01.SA_ADDR1, A01.SA_ADDR2                            -- 31 ~ 35
                , A01.SA_ADDR3, A01.SA_ADDR4, A01.SA_ADDR5, A01.SA_ADDR6, A01.SA_ADDR7                                  -- 36 ~ 40
                , A01.SA_ADDR8, A01.SA_MAP_X, A01.SA_MAP_Y, A01.EA_ADDR1, A01.EA_ADDR2                                  -- 41 ~ 45
                , A01.EA_ADDR3, A01.EA_ADDR4, A01.EA_ADDR5, A01.EA_ADDR6, A01.EA_ADDR7                                  -- 46 ~ 50
                , A01.EA_ADDR8, A01.EA_MAP_X, A01.EA_MAP_Y, A01.PRE_ORD_YN, A01.PRE_ORD_DATE                            -- 51 ~ 55
                , A01.PAY_TYPE_CD, A01.ORD_AMT, A01.SRV_AMT
                , (DVRY_ADJ_AMT - ADD_DVRY_CHARGE - SUPP_AMT) AS DVRY_AMT
                , A01.PICKUP_DATE                              -- 56 ~ 60
                , A01.PAY_CASH, A01.PAY_CARD, A01.PAY_MILEAGE, A01.LAST_UPDATE, A01.CTH_HD_CODE                         -- 61 ~ 65
                , A01.CTH_BR_CODE, A01.CTH_HD_NAME, A01.CTH_BR_NAME, A01.SA_ADDR9, A01.EA_ADDR9                         -- 66 ~ 70
                , A01.PER_HD_CODE, A01.PER_HD_NAME, A01.PER_BR_CODE, A01.PER_BR_NAME, A01.PER_ST_CODE                   -- 71 ~ 75
                , A01.PER_ST_NAME, A01.GOODS_NAMES, A01.FINISH_DATE, A01.CTH_WK_TEL, A01.DVRY_CANCEL_TIME               -- 76 ~ 80
                , A01.COOK_TIME, A01.PDA_MEMO, A01.DUP_ORDER_CNT, A01.ORD_ST_TEL, A01.PER_ST_TEL                        -- 81 ~ 85
                , A01.CTH_WK_BR_NUM, A01.DVRY_PAY_TYPE, A01.CARD_APPR_NUM, A01.CARD_NAME, A01.MONTH                     -- 86 ~ 90
                , A01.ALERT_VIEW_YN, A01.UPDATE_CNT, A01.PARTNER_CODE, A01.CTH_YN, A01.PAY_LATER                        -- 91 ~ 95  
                , A01.DVRY_ADJ_AMT                                                                                      -- 96                                                                   
                , A01.ORD_VRFY_DATE                                                                                     -- 97                                                                    
                , A01.PAY_BANK
                , A01.SUPP_AMT
                , A01.KM_PRODUCT
                , CASE WHEN SUBSTR(in_USR_LEVEL_CD, 1, 1) = '3' AND
                            A01.ORD_HD_CODE IN('H0142','H0095','H4202') AND
                            (A01.CTH_BR_CODE IS NOT NULL OR (A01.ORD_STATUS_CD = 9 AND CANCEL_TYPE_CD <> '11')) AND
                            NOT((NVL(A01.ORD_HD_CODE,'X') = in_HD_CODE AND NVL(A01.ORD_BR_CODE,'X') = in_BR_CODE) OR 
                                (NVL(A01.CTH_HD_CODE,'X') = in_HD_CODE AND NVL(A01.CTH_BR_CODE,'X') = in_BR_CODE)) THEN 'D'
                       WHEN SUBSTR(in_USR_LEVEL_CD, 1, 1) = '4' AND
                            A01.ORD_HD_CODE IN('H0142','H0095','H4202') AND
                            (A01.CTH_BR_CODE IS NOT NULL OR (A01.ORD_STATUS_CD = 9 AND CANCEL_TYPE_CD <> '11')) AND
                            NOT((NVL(A01.ORD_HD_CODE,'X') = in_HD_CODE) OR
                                (NVL(A01.CTH_HD_CODE,'X') = in_HD_CODE)) THEN 'D'
                       WHEN (in_LAST_UPDATE IS NOT NULL AND in_ORD_STATUS_CD IS NOT NULL
                       AND  INSTR(','||in_ORD_STATUS_CD, ','||A01.ORD_STATUS_CD||',', -1, 1) = 0) THEN 'D'
                       WHEN (in_LAST_UPDATE IS NOT NULL AND in_SRCH_OPTION IS NOT NULL)
                       AND  NOT((in_SRCH_OPTION = '1' AND A01.CTH_WK_NAME LIKE '%'||in_SRCH_KEYWORD||'%')
                            OR (in_SRCH_OPTION = '2' AND A01.CTH_WK_BR_NUM LIKE '%'||in_SRCH_KEYWORD||'%')
                            OR (in_SRCH_OPTION = '3' AND (A01.ORD_ST_NAME LIKE '%'||in_SRCH_KEYWORD||'%'))
                            OR (in_SRCH_OPTION = '4' AND (A01.ORD_ST_TEL LIKE '%'||in_SRCH_KEYWORD||'%'))
                            OR (in_SRCH_OPTION = '5' AND A01.ORD_CU_NAME LIKE '%'||in_SRCH_KEYWORD||'%')
                            OR (in_SRCH_OPTION = '6' AND A01.ORD_CU_TEL LIKE '%'||in_SRCH_KEYWORD||'%')
                            OR (in_SRCH_OPTION = '7' AND A01.SA_ADDR3 || A01.SA_ADDR8 || A01.SA_ADDR9 || A01.SA_ADDR6 LIKE '%'||in_SRCH_KEYWORD||'%')
                            OR (in_SRCH_OPTION = '8' AND A01.EA_ADDR3 || A01.EA_ADDR8 || A01.EA_ADDR9 || A01.EA_ADDR6 LIKE '%'||in_SRCH_KEYWORD||'%')
                            OR (in_SRCH_OPTION = '9' AND A01.IN_USR_ID = in_SRCH_KEYWORD)
                            OR (in_SRCH_OPTION = '10' AND A01.ORD_NO = in_SRCH_KEYWORD)
                            OR (in_SRCH_OPTION = '11' AND A01.CTH_WK_TEL = in_SRCH_KEYWORD)
                            OR (in_SRCH_OPTION = '12' AND A01.TODAY_NO = in_SRCH_KEYWORD)
                            OR (in_SRCH_OPTION = '13' AND A01.ORD_MEMO LIKE '%'||in_SRCH_KEYWORD||'%')
                            OR (in_SRCH_OPTION = '14' AND A01.ORD_BR_NAME LIKE  '%'||in_SRCH_KEYWORD||'%')
                            OR (in_SRCH_OPTION = '15' AND A01.CTH_BR_NAME LIKE  '%'||in_SRCH_KEYWORD||'%')) THEN 'D'
                       ELSE 'U' END AS DEL_FLAG
-- 2016.11.21 추가                             
                , A01.KM_PRODUCT_TOTAL
-- 2016.11.23 추가                         
                , A01.ADD_DVRY_CHARGE
                , A01.VISIT_CNT
                , A01.TYPE_UPDATE_DATE AS TYPE_UPDATE_DATE -- 픽업예정시각
                , TRUNC((NVL(A01.FINISH_DATE, SYSDATE) - A01.ORD_DATE)*24*60) AS LAPSE_TIME -- 경과시간
                , A01.DVRY_TIME     -- 배달소요시간
                , A01.DVRY_DLY_TIME -- 배달지연시간
                , (CASE WHEN in_USR_LEVEL_CD = '23' 
                        THEN (  SELECT X.POS_ORD_STATUS 
                                FROM BAROGO_API.POS_ORDER_CHANGE X
                                WHERE X.BAROGO_ORD_NO = A01.ORD_NO )
                        ELSE 'X' END) AS POS_ORD_STATUS -- 제휴사오더상태코드
                , NVL(A01.DVRY_PRCH_AMT, 0) - (NVL(A01.SUPP_AMT,0) + NVL(A01.ADD_DVRY_CHARGE,0)) AS DVRY_PRCH_AMT -- 배달대행료_매입금액
                , NVL(A01.DVRY_PRCH_AMT, 0) AS DVRY_PRCH_SUM -- 배달대행료_매입금액_합계액
            FROM  ALD_A01_TODAY A01
            WHERE (
                A01.LAST_UPDATE >= NVL(TRIM(in_LAST_UPDATE), FN_SYS_0128_GET_ADJ_DATE(TO_CHAR(SYSDATE-9/24, 'YYYYMMDD')||'090000'))
            )
            AND (
                SUBSTR(in_USR_LEVEL_CD, 1, 1) = '2' AND ((ORD_ST_CODE IN (SELECT ST_CODE FROM ALD_GRP_USR_MAPPING WHERE USR_ID = vi_USR_ID)))     -- 가맹점 사용자
            )
            AND (in_ORD_TYPE_CD IS NOT NULL AND INSTR(in_ORD_TYPE_CD, A01.ORD_TYPE_CD, -1, 1) > 0)
            AND (
                    (in_LAST_UPDATE IS NOT NULL AND 1 = 1)
                    OR (in_LAST_UPDATE IS NULL AND in_ORD_STATUS_CD IS NOT NULL AND INSTR(','||in_ORD_STATUS_CD, ','||A01.ORD_STATUS_CD||',', -1, 1) > 0)
            )
            AND (
                    (in_OWN_CALL IS NULL AND 1 = 1)
                    OR (in_OWN_CALL IS NOT NULL AND A01.IN_USR_ID = in_OWN_CALL)
            )
            AND (
                    (in_LAST_UPDATE IS NOT NULL AND 1 = 1)
                    OR (in_SRCH_OPTION IS NULL AND 1 = 1)
                    OR (in_SRCH_OPTION = '1' AND A01.CTH_WK_NAME LIKE '%'||in_SRCH_KEYWORD||'%')
                    OR (in_SRCH_OPTION = '2' AND A01.CTH_WK_BR_NUM LIKE '%'||in_SRCH_KEYWORD||'%')
                    OR (in_SRCH_OPTION = '3' AND (A01.ORD_ST_NAME LIKE '%'||in_SRCH_KEYWORD||'%'))
                    OR (in_SRCH_OPTION = '4' AND (A01.ORD_ST_TEL LIKE '%'||in_SRCH_KEYWORD||'%'))
                    OR (in_SRCH_OPTION = '5' AND A01.ORD_CU_NAME LIKE '%'||in_SRCH_KEYWORD||'%')
                    OR (in_SRCH_OPTION = '6' AND A01.ORD_CU_TEL LIKE '%'||in_SRCH_KEYWORD||'%')
                    OR (in_SRCH_OPTION = '7' AND A01.SA_ADDR3 || A01.SA_ADDR8 || A01.SA_ADDR9 || A01.SA_ADDR6 LIKE '%'||in_SRCH_KEYWORD||'%')
                    OR (in_SRCH_OPTION = '8' AND A01.EA_ADDR3 || A01.EA_ADDR8 || A01.EA_ADDR9 || A01.EA_ADDR6 LIKE '%'||in_SRCH_KEYWORD||'%')
                    OR (in_SRCH_OPTION = '9' AND A01.IN_USR_ID = in_SRCH_KEYWORD)
                    OR (in_SRCH_OPTION = '10' AND A01.ORD_NO = in_SRCH_KEYWORD)
                    OR (in_SRCH_OPTION = '11' AND A01.CTH_WK_TEL = in_SRCH_KEYWORD)
                    OR (in_SRCH_OPTION = '12' AND A01.TODAY_NO = in_SRCH_KEYWORD)
                    OR (in_SRCH_OPTION = '13' AND A01.ORD_MEMO LIKE '%'||in_SRCH_KEYWORD||'%')
                    OR (in_SRCH_OPTION = '14' AND A01.ORD_BR_NAME LIKE  '%'||in_SRCH_KEYWORD||'%')
                    OR (in_SRCH_OPTION = '15' AND A01.CTH_BR_NAME LIKE  '%'||in_SRCH_KEYWORD||'%')
            )
            AND (
                    (NVL(vi_CARD_YN, 'N') = 'N' AND 1 = 1)
                    OR (NVL(vi_CARD_YN, 'N') = 'Y' AND A01.PAY_CARD > 0)
            )
            AND (
                    (NVL(vi_FIND_PAY_LATER, 'N') = 'Y' AND A01.PAY_LATER > 0)
                    OR (NVL(vi_FIND_PAY_LATER, 'N') <> 'Y' AND 1 = 1)
            );
            IF SYSDATE < TO_DATE('20201229150100','YYYYMMDDHH24MISS') THEN
                SP_SYS_LOG_CS ('SP_CSC_0201_GET_ORDER_LIST','in_LAST_UPDATE:'||in_LAST_UPDATE||':'|| vi_USR_ID);
            END IF;
    ELSE
        OPEN out_DATA FOR
            WITH V1_SHARE AS(  
                SELECT /*+ INLINE */ S.* FROM ALD_ADJ_BR_SHARE S
                WHERE S.LIST_SHARE_YN = 'Y'
                AND   S.USE_YN = 'Y'
                AND   S.C_BR_CODE = in_BR_CODE
            )
            SELECT A01.ORD_NO
                , A01.ORD_TYPE_CD, A01.TODAY_NO, A01.TODAY_ADD_NO, A01.ORD_STATUS_CD, A01.ORD_PRE_STATUS_CD             -- 1 ~ 5
                , A01.ORD_CU_GRP_TYPE, A01.ORD_CU_NO, A01.ORD_CU_TEL, A01.ORD_CU_TEL2, A01.ORD_CU_NAME                  -- 6 ~ 10
                , A01.ORD_CU_TYPE_CD, A01.ORD_CU_LEVEL_CD, A01.ORD_CU_END_CNT, A01.ORD_HD_CODE, A01.ORD_HD_NAME         -- 11 ~ 15
                , A01.ORD_BR_CODE, A01.ORD_BR_NAME, A01.ORD_ST_CODE, A01.ORD_ST_NAME, A01.ORD_TEL                       -- 16 ~ 20
                , A01.CALL_BR_CODE, A01.IN_DATE, A01.IN_USR_ID, A01.ORD_DATE, A01.UPDATE_DATE                           -- 21 ~ 25
                , A01.UPDATE_USR_ID, A01.CANCEL_DATE, A01.CANCEL_TYPE_CD, A01.CANCEL_MEMO, A01.CTH_DATE                 -- 26 ~ 30
                , A01.CTH_WK_CODE, A01.CTH_WK_NAME, A01.ORD_MEMO, A01.SA_ADDR1, A01.SA_ADDR2                            -- 31 ~ 35
                , A01.SA_ADDR3, A01.SA_ADDR4, A01.SA_ADDR5, A01.SA_ADDR6, A01.SA_ADDR7                                  -- 36 ~ 40
                , A01.SA_ADDR8, A01.SA_MAP_X, A01.SA_MAP_Y, A01.EA_ADDR1, A01.EA_ADDR2                                  -- 41 ~ 45
                , A01.EA_ADDR3, A01.EA_ADDR4, A01.EA_ADDR5, A01.EA_ADDR6, A01.EA_ADDR7                                  -- 46 ~ 50
                , A01.EA_ADDR8, A01.EA_MAP_X, A01.EA_MAP_Y, A01.PRE_ORD_YN, A01.PRE_ORD_DATE                            -- 51 ~ 55
                , A01.PAY_TYPE_CD, A01.ORD_AMT, A01.SRV_AMT
                , (DVRY_ADJ_AMT - ADD_DVRY_CHARGE - SUPP_AMT) AS DVRY_AMT
                , A01.PICKUP_DATE                              -- 56 ~ 60
                , A01.PAY_CASH, A01.PAY_CARD, A01.PAY_MILEAGE, A01.LAST_UPDATE, A01.CTH_HD_CODE                         -- 61 ~ 65
                , A01.CTH_BR_CODE, A01.CTH_HD_NAME, A01.CTH_BR_NAME, A01.SA_ADDR9, A01.EA_ADDR9                         -- 66 ~ 70
                , A01.PER_HD_CODE, A01.PER_HD_NAME, A01.PER_BR_CODE, A01.PER_BR_NAME, A01.PER_ST_CODE                   -- 71 ~ 75
                , A01.PER_ST_NAME, A01.GOODS_NAMES, A01.FINISH_DATE, A01.CTH_WK_TEL, A01.DVRY_CANCEL_TIME               -- 76 ~ 80
                , A01.COOK_TIME, A01.PDA_MEMO, A01.DUP_ORDER_CNT, A01.ORD_ST_TEL, A01.PER_ST_TEL                        -- 81 ~ 85
                , A01.CTH_WK_BR_NUM, A01.DVRY_PAY_TYPE, A01.CARD_APPR_NUM, A01.CARD_NAME, A01.MONTH                     -- 86 ~ 90
                , A01.ALERT_VIEW_YN, A01.UPDATE_CNT, A01.PARTNER_CODE, A01.CTH_YN, A01.PAY_LATER                        -- 91 ~ 95  
                , A01.DVRY_ADJ_AMT                                                                                      -- 96                                                                   
                , A01.ORD_VRFY_DATE                                                                                     -- 97                                                                    
                , A01.PAY_BANK
                , A01.SUPP_AMT
                , A01.KM_PRODUCT
                , CASE WHEN SUBSTR(in_USR_LEVEL_CD, 1, 1) = '3' AND
                            A01.ORD_HD_CODE IN('H0142','H0095','H4202') AND
                            (A01.CTH_BR_CODE IS NOT NULL OR (A01.ORD_STATUS_CD = 9 AND CANCEL_TYPE_CD <> '11')) AND
                            NOT((NVL(A01.ORD_HD_CODE,'X') = in_HD_CODE AND NVL(A01.ORD_BR_CODE,'X') = in_BR_CODE) OR 
                                (NVL(A01.CTH_HD_CODE,'X') = in_HD_CODE AND NVL(A01.CTH_BR_CODE,'X') = in_BR_CODE)) THEN 'D'
                       WHEN SUBSTR(in_USR_LEVEL_CD, 1, 1) = '4' AND
                            A01.ORD_HD_CODE IN('H0142','H0095','H4202') AND
                            (A01.CTH_BR_CODE IS NOT NULL OR (A01.ORD_STATUS_CD = 9 AND CANCEL_TYPE_CD <> '11')) AND
                            NOT((NVL(A01.ORD_HD_CODE,'X') = in_HD_CODE) OR
                                (NVL(A01.CTH_HD_CODE,'X') = in_HD_CODE)) THEN 'D'
                       WHEN (in_LAST_UPDATE IS NOT NULL AND in_ORD_STATUS_CD IS NOT NULL
                       AND  INSTR(','||in_ORD_STATUS_CD, ','||A01.ORD_STATUS_CD||',', -1, 1) = 0) THEN 'D'
                       WHEN (in_LAST_UPDATE IS NOT NULL AND in_SRCH_OPTION IS NOT NULL)
                       AND  NOT((in_SRCH_OPTION = '1' AND A01.CTH_WK_NAME LIKE '%'||in_SRCH_KEYWORD||'%')
                            OR (in_SRCH_OPTION = '2' AND A01.CTH_WK_BR_NUM LIKE '%'||in_SRCH_KEYWORD||'%')
                            OR (in_SRCH_OPTION = '3' AND (A01.ORD_ST_NAME LIKE '%'||in_SRCH_KEYWORD||'%'))
                            OR (in_SRCH_OPTION = '4' AND (A01.ORD_ST_TEL LIKE '%'||in_SRCH_KEYWORD||'%'))
                            OR (in_SRCH_OPTION = '5' AND A01.ORD_CU_NAME LIKE '%'||in_SRCH_KEYWORD||'%')
                            OR (in_SRCH_OPTION = '6' AND A01.ORD_CU_TEL LIKE '%'||in_SRCH_KEYWORD||'%')
                            OR (in_SRCH_OPTION = '7' AND A01.SA_ADDR3 || A01.SA_ADDR8 || A01.SA_ADDR9 || A01.SA_ADDR6 LIKE '%'||in_SRCH_KEYWORD||'%')
                            OR (in_SRCH_OPTION = '8' AND A01.EA_ADDR3 || A01.EA_ADDR8 || A01.EA_ADDR9 || A01.EA_ADDR6 LIKE '%'||in_SRCH_KEYWORD||'%')
                            OR (in_SRCH_OPTION = '9' AND A01.IN_USR_ID = in_SRCH_KEYWORD)
                            OR (in_SRCH_OPTION = '10' AND A01.ORD_NO = in_SRCH_KEYWORD)
                            OR (in_SRCH_OPTION = '11' AND A01.CTH_WK_TEL = in_SRCH_KEYWORD)
                            OR (in_SRCH_OPTION = '12' AND A01.TODAY_NO = in_SRCH_KEYWORD)
                            OR (in_SRCH_OPTION = '13' AND A01.ORD_MEMO LIKE '%'||in_SRCH_KEYWORD||'%')
                            OR (in_SRCH_OPTION = '14' AND A01.ORD_BR_NAME LIKE  '%'||in_SRCH_KEYWORD||'%')
                            OR (in_SRCH_OPTION = '15' AND A01.CTH_BR_NAME LIKE  '%'||in_SRCH_KEYWORD||'%')) THEN 'D'
                       ELSE 'U' END AS DEL_FLAG
-- 2016.11.21 추가                             
                , A01.KM_PRODUCT_TOTAL
-- 2016.11.23 추가                         
                , A01.ADD_DVRY_CHARGE
                , A01.VISIT_CNT
                , A01.TYPE_UPDATE_DATE AS TYPE_UPDATE_DATE -- 픽업예정시각
                , TRUNC((NVL(A01.FINISH_DATE, SYSDATE) - A01.ORD_DATE)*24*60) AS LAPSE_TIME -- 경과시간
                , A01.DVRY_TIME     -- 배달소요시간
                , A01.DVRY_DLY_TIME -- 배달지연시간
                , (CASE WHEN in_USR_LEVEL_CD = '23' 
                        THEN (  SELECT X.POS_ORD_STATUS 
                                FROM BAROGO_API.POS_ORDER_CHANGE X
                                WHERE X.BAROGO_ORD_NO = A01.ORD_NO )
                        ELSE 'X' END) AS POS_ORD_STATUS -- 제휴사오더상태코드
                , NVL(A01.DVRY_PRCH_AMT, 0) - (NVL(A01.SUPP_AMT,0) + NVL(A01.ADD_DVRY_CHARGE,0)) AS DVRY_PRCH_AMT -- 배달대행료_매입금액
                , NVL(A01.DVRY_PRCH_AMT, 0) AS DVRY_PRCH_SUM -- 배달대행료_매입금액_합계액
            FROM  ALD_A01_TODAY A01
            WHERE (
                A01.LAST_UPDATE >= NVL(TRIM(in_LAST_UPDATE), FN_SYS_0128_GET_ADJ_DATE(TO_CHAR(SYSDATE-9/24, 'YYYYMMDD')||'090000'))
            )
            AND (
                    (in_USR_LEVEL_CD = '10' AND ((CALL_BR_CODE = in_CALL_BR_CODE) OR (CTH_CALL_BR_CODE = in_CALL_BR_CODE)))     -- 상담원
                    OR (SUBSTR(in_USR_LEVEL_CD, 1, 1) = '3' AND ((ORD_HD_CODE = in_HD_CODE AND ORD_BR_CODE = in_BR_CODE) OR 
                                                                 (CTH_HD_CODE = in_HD_CODE AND CTH_BR_CODE = in_BR_CODE) OR
                                                                 (  NOT (ORD_STATUS_CD IN('3','8') AND in_LAST_UPDATE IS NULL) AND
                                                                    NOT (ORD_STATUS_CD = '9' AND CANCEL_TYPE_CD <> '11' AND in_LAST_UPDATE IS NULL) AND
--                                                                          (ORD_STATUS_CD NOT IN('3','8','9') OR in_LAST_UPDATE IS NOT NULL) AND -- 주문취소, 배차취소 제외
                                                                  EXISTS(SELECT 1 FROM V1_SHARE S
                                                                        WHERE S.LIST_SHARE_YN = 'Y'
                                                                        AND   S.USE_YN = 'Y'
                                                                        AND   S.C_BR_CODE = in_BR_CODE
                                                                        AND   A01.ORD_BR_CODE = S.O_BR_CODE
                                                                        AND   NVL(A01.ORD_ST_CODE,'S000000') = DECODE(S.O_ST_CODE, 'S000000', NVL(A01.ORD_ST_CODE,'S000000'), S.O_ST_CODE)) ) ))   -- 지사 사용자
                    OR (SUBSTR(in_USR_LEVEL_CD, 1, 1) = '4' AND ((ORD_HD_CODE = in_HD_CODE) OR
                                                                 (CTH_HD_CODE = in_HD_CODE) OR
                                                                 (  NOT (ORD_STATUS_CD IN('8') AND in_LAST_UPDATE IS NULL) AND
                                                                    NOT (ORD_STATUS_CD = '9' AND CANCEL_TYPE_CD <> '11' AND in_LAST_UPDATE IS NULL) AND
                                                                  EXISTS(SELECT 1 FROM V1_SHARE S
                                                                        WHERE S.LIST_SHARE_YN = 'Y'
                                                                        AND   S.USE_YN = 'Y'
                                                                        AND   S.C_BR_CODE = in_BR_CODE
                                                                        AND   A01.ORD_BR_CODE = S.O_BR_CODE
                                                                        AND   NVL(A01.ORD_ST_CODE,'S000000') = DECODE(S.O_ST_CODE, 'S000000', NVL(A01.ORD_ST_CODE,'S000000'), S.O_ST_CODE)) ) ))  -- 총판 사용자
            )
            AND (in_ORD_TYPE_CD IS NOT NULL AND INSTR(in_ORD_TYPE_CD, A01.ORD_TYPE_CD, -1, 1) > 0)
            AND (
                    (in_LAST_UPDATE IS NOT NULL AND 1 = 1)
                    OR (in_LAST_UPDATE IS NULL AND in_ORD_STATUS_CD IS NOT NULL AND INSTR(','||in_ORD_STATUS_CD, ','||A01.ORD_STATUS_CD||',', -1, 1) > 0)
            )
            AND (
                    (in_OWN_CALL IS NULL AND 1 = 1)
                    OR (in_OWN_CALL IS NOT NULL AND A01.IN_USR_ID = in_OWN_CALL)
            )
            AND (
                    (in_LAST_UPDATE IS NOT NULL AND 1 = 1)
                    OR (in_SRCH_OPTION IS NULL AND 1 = 1)
                    OR (in_SRCH_OPTION = '1' AND A01.CTH_WK_NAME LIKE '%'||in_SRCH_KEYWORD||'%')
                    OR (in_SRCH_OPTION = '2' AND A01.CTH_WK_BR_NUM LIKE '%'||in_SRCH_KEYWORD||'%')
                    OR (in_SRCH_OPTION = '3' AND (A01.ORD_ST_NAME LIKE '%'||in_SRCH_KEYWORD||'%'))
                    OR (in_SRCH_OPTION = '4' AND (A01.ORD_ST_TEL LIKE '%'||in_SRCH_KEYWORD||'%'))
                    OR (in_SRCH_OPTION = '5' AND A01.ORD_CU_NAME LIKE '%'||in_SRCH_KEYWORD||'%')
                    OR (in_SRCH_OPTION = '6' AND A01.ORD_CU_TEL LIKE '%'||in_SRCH_KEYWORD||'%')
                    OR (in_SRCH_OPTION = '7' AND A01.SA_ADDR3 || A01.SA_ADDR8 || A01.SA_ADDR9 || A01.SA_ADDR6 LIKE '%'||in_SRCH_KEYWORD||'%')
                    OR (in_SRCH_OPTION = '8' AND A01.EA_ADDR3 || A01.EA_ADDR8 || A01.EA_ADDR9 || A01.EA_ADDR6 LIKE '%'||in_SRCH_KEYWORD||'%')
                    OR (in_SRCH_OPTION = '9' AND A01.IN_USR_ID = in_SRCH_KEYWORD)
                    OR (in_SRCH_OPTION = '10' AND A01.ORD_NO = in_SRCH_KEYWORD)
                    OR (in_SRCH_OPTION = '11' AND A01.CTH_WK_TEL = in_SRCH_KEYWORD)
                    OR (in_SRCH_OPTION = '12' AND A01.TODAY_NO = in_SRCH_KEYWORD)
                    OR (in_SRCH_OPTION = '13' AND A01.ORD_MEMO LIKE '%'||in_SRCH_KEYWORD||'%')
                    OR (in_SRCH_OPTION = '14' AND A01.ORD_BR_NAME LIKE  '%'||in_SRCH_KEYWORD||'%')
                    OR (in_SRCH_OPTION = '15' AND A01.CTH_BR_NAME LIKE  '%'||in_SRCH_KEYWORD||'%')
            )
            AND (
                    (vi_FIND_BR_CODE IS NULL AND 1 = 1)
                    OR (vi_FIND_BR_CODE IS NOT NULL AND
                        A01.ORD_BR_CODE IN(
                                (SELECT /*+ INDEX(S IDX_ADJ_BR_SHARE_2) */ O_BR_CODE
                                FROM ALD_ADJ_BR_SHARE S
                                WHERE S.LIST_SHARE_YN = 'Y'
                                AND   S.USE_YN = 'Y'
                                AND   S.C_BR_CODE = vi_FIND_BR_CODE
                                AND   NVL(A01.ORD_ST_CODE,'S000000') = DECODE(S.O_ST_CODE, 'S000000', NVL(A01.ORD_ST_CODE,'S000000'), S.O_ST_CODE)
                                UNION ALL
                                SELECT vi_FIND_BR_CODE FROM DUAL)))
            )
            AND (
                    (vi_FIND_HD_CODE IS NULL AND 1 = 1)
                    OR (vi_FIND_HD_CODE IS NOT NULL AND
                        A01.ORD_HD_CODE IN(
                                (SELECT /*+ INDEX(S IDX_ADJ_BR_SHARE_3) */ O_HD_CODE
                                FROM ALD_ADJ_BR_SHARE S
                                WHERE S.LIST_SHARE_YN = 'Y'
                                AND   S.USE_YN = 'Y'
                                AND   S.C_HD_CODE = vi_FIND_HD_CODE
                                AND   NVL(A01.ORD_ST_CODE,'S000000') = DECODE(S.O_ST_CODE, 'S000000', NVL(A01.ORD_ST_CODE,'S000000'), S.O_ST_CODE)
                                UNION ALL
                                SELECT vi_FIND_HD_CODE FROM DUAL)))
            )
            AND (
                    (NVL(vi_CARD_YN, 'N') = 'N' AND 1 = 1)
                    OR (NVL(vi_CARD_YN, 'N') = 'Y' AND A01.PAY_CARD > 0)
            )
            AND (
                    (NVL(vi_FIND_PAY_LATER, 'N') = 'Y' AND A01.PAY_LATER > 0)
                    OR (NVL(vi_FIND_PAY_LATER, 'N') <> 'Y' AND 1 = 1)
            );
    END IF;

    EXCEPTION
        WHEN OTHERS THEN
--          // ROLLBACK Process Add
            ROLLBACK;
--          // ERROR LOG Process Add
            out_CODE    := '0';
            out_MSG     := 'FAILED';
            OPEN out_DATA FOR
                SELECT out_CODE, out_MSG FROM DUAL; --20200120 jh

            SP_SYS_0102_ERROR_LOG ('SP_CSC_0201_GET_ORDER_LIST', 'USR_ID : '||vi_USR_ID||', ERROR CODE : '||SQLCODE ||', ERROR MSG : '||SUBSTR(SQLERRM, 1, 1000));

END SP_CSC_0201_GET_ORDER_LIST;