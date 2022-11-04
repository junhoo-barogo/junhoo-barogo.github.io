create or replace PROCEDURE        SP_CSC_0726_GET_BR_INOUT_CASH
-- ==========================================================================================
-- Author       : 정현태
-- Create date  : 2018-03-14
-- Description  : 지사캐쉬증감 목록 조회
-- ==========================================================================================
-- out_CODE     : 0(실패), 1(성공)
-- ==========================================================================================
-- out_DATA     : 
-- ==========================================================================================
-- out_VALUE    : NULL
-- ==========================================================================================
(
    in_HD_CODE          VARCHAR2
    , in_BR_CODE        VARCHAR2
    , in_STR_DATE       VARCHAR2        -- EX) 2013070507 (기본값 : 어제)
    , in_END_DATE       VARCHAR2        -- EX) 2013070607 (기본값 : 어제)

    , out_CODE          OUT VARCHAR2
    , out_MSG           OUT VARCHAR2
    , out_DATA          OUT SYS_REFCURSOR
    , out_VALUE         OUT VARCHAR2
)
IS
    v_ADJ_TODAY         DATE := TO_DATE(FN_SYS_0128_GET_ADJ_DATE(FN_SYS_0128_GET_ADJ_YMD_1(SYSDATE)||'090000'),'YYYYMMDDHH24MISS');
BEGIN
--  // OUT PUT 초기설정
    out_CODE            := '1';
    out_MSG             := 'SUCCESS';
    out_VALUE           := NULL;

    SELECT SUM(SUM_ORD_FINISH_CNT) AS SUM_ORD_FINISH_CNT
    INTO out_VALUE
    FROM (
        SELECT COUNT(*) AS SUM_ORD_FINISH_CNT
        FROM ALD_A01_TODAY
        WHERE CTH_BR_CODE = in_BR_CODE AND ORD_STATUS_CD = 3
        AND   in_END_DATE > FN_SYS_0128_GET_ADJ_YMD_1(SYSDATE)||'07'
        AND   ORD_DATE > v_ADJ_TODAY
        UNION ALL
        SELECT SUM(SUM_ORD_FINISH_CNT) AS SUM_ORD_FINISH_CNT
        FROM ALD_STT_WK_CASH
        WHERE BR_CODE = in_BR_CODE
        AND   IN_DATE >= SUBSTR(in_STR_DATE,1,8)
        AND   IN_DATE <  SUBSTR(in_END_DATE,1,8)
    );
    
    OPEN out_DATA FOR
        WITH TMP_BR_1 AS (
            SELECT /*+ INLINE */ FN_SYS_0128_GET_ADJ_YMD_1(IN_DATE) AS ADJ_DAY, BR_CODE
                , (CASE WHEN L.ORD_NO > 0 THEN FN_SYS_0144_GET_B2B_YN(L.ORD_NO) ELSE 'N' END) AS B2B_YN
                , (CASE WHEN L.ORD_NO > 0 THEN FN_SYS_0144_GET_HQ_BL_YN(L.ORD_NO) ELSE 'N' END) AS HQ_BL_YN
                , FN_SYS_0142_GET_BT_NAME('BT',L.BR_CASH_TYPE_CD) AS CASH_TYPE_CD
                , NVL(SUM((ADD_CASH)), 0) AS BR_ADD_CASH
                , NVL(SUM((ADD_VAT)), 0) AS BR_ADD_VAT
            FROM ALD_ADJ_BR_CASH_LOG L
            WHERE BR_CODE = in_BR_CODE
            AND   in_END_DATE > FN_SYS_0128_GET_ADJ_YMD_1(SYSDATE)||'07'
            AND   IN_DATE > v_ADJ_TODAY
            GROUP BY FN_SYS_0128_GET_ADJ_YMD_1(IN_DATE), BR_CODE
                , (CASE WHEN L.ORD_NO > 0 THEN FN_SYS_0144_GET_B2B_YN(L.ORD_NO) ELSE 'N' END)
                , (CASE WHEN L.ORD_NO > 0 THEN FN_SYS_0144_GET_HQ_BL_YN(L.ORD_NO) ELSE 'N' END)
                , FN_SYS_0142_GET_BT_NAME('BT',L.BR_CASH_TYPE_CD)
            UNION ALL
            SELECT /*+ INLINE */ ADJ_DAY, BR_CODE
                , B2B_YN, NVL(L.HQ_BL_YN,'N') AS HQ_BL_YN
                , FN_SYS_0142_GET_BT_NAME('BT',L.BR_CASH_TYPE_CD) AS CASH_TYPE_CD
                , NVL(SUM((ADD_CASH)), 0) AS BR_ADD_CASH
                , NVL(SUM((ADD_VAT)), 0) AS BR_ADD_VAT
            FROM ALD_ADJ_BR_CASH_DAY L
            WHERE BR_CODE = in_BR_CODE
            AND   ADJ_DAY >= SUBSTR(in_STR_DATE,1,8)
            AND   ADJ_DAY <  SUBSTR(in_END_DATE,1,8)
            GROUP BY ADJ_DAY, BR_CODE, B2B_YN, NVL(L.HQ_BL_YN,'N')
                , FN_SYS_0142_GET_BT_NAME('BT',L.BR_CASH_TYPE_CD)
        ),  TMP_WK_1 AS (
            SELECT /*+ INLINE */ FN_SYS_0128_GET_ADJ_YMD_1(IN_DATE) AS ADJ_DAY, BR_CODE
                , (CASE WHEN L.ORD_NO > 0 THEN FN_SYS_0144_GET_B2B_YN(L.ORD_NO) ELSE 'N' END) AS B2B_YN
                , (CASE WHEN L.ORD_NO > 0 THEN FN_SYS_0144_GET_HQ_BL_YN(L.ORD_NO) ELSE 'N' END) AS HQ_BL_YN
                , FN_SYS_0142_GET_BT_NAME('WT',L.WK_CASH_TYPE_CD) AS CASH_TYPE_CD
                , NVL(SUM((ADD_CASH)), 0) AS WK_ADD_CASH
            FROM ALD_ADJ_WK_CASH_LOG L
            WHERE BR_CODE = in_BR_CODE
            AND   in_END_DATE > FN_SYS_0128_GET_ADJ_YMD_1(SYSDATE)||'07'
            AND   IN_DATE > v_ADJ_TODAY
            GROUP BY FN_SYS_0128_GET_ADJ_YMD_1(IN_DATE), BR_CODE
                , (CASE WHEN L.ORD_NO > 0 THEN FN_SYS_0144_GET_B2B_YN(L.ORD_NO) ELSE 'N' END)
                , (CASE WHEN L.ORD_NO > 0 THEN FN_SYS_0144_GET_HQ_BL_YN(L.ORD_NO) ELSE 'N' END)
                , FN_SYS_0142_GET_BT_NAME('WT',L.WK_CASH_TYPE_CD)
            UNION ALL
            SELECT /*+ INLINE */ ADJ_DAY
                , BR_CODE, B2B_YN, NVL(L.HQ_BL_YN,'N') AS HQ_BL_YN
                , FN_SYS_0142_GET_BT_NAME('WT',L.WK_CASH_TYPE_CD) AS CASH_TYPE_CD
                , NVL(SUM((ADD_CASH)), 0) AS WK_ADD_CASH
            FROM ALD_ADJ_WK_CASH_DAY L
            WHERE BR_CODE = in_BR_CODE
            AND   ADJ_DAY >= SUBSTR(in_STR_DATE,1,8)
            AND   ADJ_DAY <  SUBSTR(in_END_DATE,1,8)
            GROUP BY ADJ_DAY, BR_CODE, B2B_YN, NVL(L.HQ_BL_YN,'N')
                , FN_SYS_0142_GET_BT_NAME('WT',L.WK_CASH_TYPE_CD)
        ),  TMP_ALL_1 AS (
            SELECT X.BR_CODE, X.CASH_TYPE, X.CASH_TYPE_NM
                , NVL(X.BR_CASH_TYPE_CD, X.WK_CASH_TYPE_CD) AS CASH_TYPE_CD
                , MAX(X.BR_CASH_TYPE_CD) AS BR_CASH_TYPE_CD, MIN(X.WK_CASH_TYPE_CD) AS WK_CASH_TYPE_CD
                , SUM(X.지사캐쉬_증가) AS "지사캐쉬_증가"
                , SUM(X.지사캐쉬_감소) AS "지사캐쉬_감소"
                , SUM(X.기사캐쉬_증가) AS "기사캐쉬_증가"
                , SUM(X.기사캐쉬_감소) AS "기사캐쉬_감소"
                , (SUM(X.지사캐쉬_증가) + SUM(X.지사캐쉬_감소))
                - (SUM(X.기사캐쉬_증가) + SUM(X.기사캐쉬_감소)) AS "지사수익_합계"
                , SUM(X.지사부가세) AS "지사부가세"
                , SUM(X.지사캐쉬_증가) + SUM(X.지사캐쉬_감소) AS "지사캐쉬_합계"
                , SUM(X.기사캐쉬_증가) + SUM(X.기사캐쉬_감소) AS "기사캐쉬_합계"
                , FN_SYS_0142_GET_BT_NAME('G0',NVL(X.BR_CASH_TYPE_CD, X.WK_CASH_TYPE_CD)) AS CASH_TYPE_G0
                , FN_SYS_0142_GET_BT_NAME('G1',NVL(X.BR_CASH_TYPE_CD, X.WK_CASH_TYPE_CD)) AS CASH_TYPE_G1
                , FN_SYS_0142_GET_BT_NAME('G2',NVL(X.BR_CASH_TYPE_CD, X.WK_CASH_TYPE_CD)) AS CASH_TYPE_G2
                , FN_SYS_0142_GET_BT_NAME('GN',NVL(X.BR_CASH_TYPE_CD, X.WK_CASH_TYPE_CD)) AS CASH_TYPE_GROUP
                , X.B2B_YN, X.HQ_BL_YN
            FROM (
                SELECT /*+ INLINE */ B1.ADJ_DAY, B1.BR_CODE, 'BR' AS CASH_TYPE
                    , NVL(B1.B2B_YN,W1.B2B_YN) AS B2B_YN
                    , NVL(B1.HQ_BL_YN,W1.HQ_BL_YN) AS HQ_BL_YN
                    , B1.CASH_TYPE_CD AS BR_CASH_TYPE_CD, W1.CASH_TYPE_CD AS WK_CASH_TYPE_CD
                    , FN_SYS_0101_GET_CODE_NAME('BT', SUBSTR(B1.CASH_TYPE_CD,2,2)) AS CASH_TYPE_NM
                    , (CASE WHEN B1.BR_ADD_CASH > 0 THEN B1.BR_ADD_CASH ELSE 0 END) AS "지사캐쉬_증가"
                    , (CASE WHEN B1.BR_ADD_CASH < 0 THEN B1.BR_ADD_CASH ELSE 0 END) AS "지사캐쉬_감소"
                    , (CASE WHEN W1.WK_ADD_CASH > 0 THEN W1.WK_ADD_CASH ELSE 0 END) AS "기사캐쉬_증가"
                    , (CASE WHEN W1.WK_ADD_CASH < 0 THEN W1.WK_ADD_CASH ELSE 0 END) AS "기사캐쉬_감소"
                    , B1.BR_ADD_VAT AS "지사부가세"
                FROM TMP_BR_1 B1
                LEFT OUTER JOIN TMP_WK_1 W1
                ON   B1.ADJ_DAY = W1.ADJ_DAY
                AND  B1.BR_CODE = W1.BR_CODE
                AND  B1.CASH_TYPE_CD = W1.CASH_TYPE_CD
                AND  B1.B2B_YN = W1.B2B_YN
                AND  B1.HQ_BL_YN = W1.HQ_BL_YN
                UNION ALL
                SELECT /*+ INLINE */ W1.ADJ_DAY, W1.BR_CODE, 'WK' AS CASH_TYPE
                    , NVL(W1.B2B_YN,B1.B2B_YN) AS B2B_YN
                    , NVL(W1.HQ_BL_YN,B1.HQ_BL_YN) AS HQ_BL_YN
                    , '' AS BR_CASH_TYPE_CD, W1.CASH_TYPE_CD AS WK_CASH_TYPE_CD
                    , FN_SYS_0101_GET_CODE_NAME('WT',SUBSTR(W1.CASH_TYPE_CD,2,2)) AS CASH_TYPE_NM
                    , 0 AS "지사캐쉬_증가"
                    , 0 AS "지사캐쉬_감소"
                    , (CASE WHEN W1.WK_ADD_CASH > 0 THEN W1.WK_ADD_CASH ELSE 0 END) AS "기사캐쉬_증가"
                    , (CASE WHEN W1.WK_ADD_CASH < 0 THEN W1.WK_ADD_CASH ELSE 0 END) AS "기사캐쉬_감소"
                    , 0 AS "지사부가세"
                FROM TMP_WK_1 W1
                LEFT OUTER JOIN TMP_BR_1 B1
                ON   B1.ADJ_DAY = W1.ADJ_DAY
                AND  B1.BR_CODE = W1.BR_CODE
                AND  B1.CASH_TYPE_CD = W1.CASH_TYPE_CD
                AND  B1.B2B_YN = W1.B2B_YN
                AND  B1.HQ_BL_YN = W1.HQ_BL_YN
                WHERE B1.ADJ_DAY IS NULL ) X
            GROUP BY X.BR_CODE, X.CASH_TYPE, NVL(X.BR_CASH_TYPE_CD, X.WK_CASH_TYPE_CD), X.CASH_TYPE_NM, X.B2B_YN, X.HQ_BL_YN
            ORDER BY CASH_TYPE_GROUP, X.BR_CODE, X.CASH_TYPE, SUBSTR(NVL(X.BR_CASH_TYPE_CD, X.WK_CASH_TYPE_CD),2,2), X.CASH_TYPE_NM
        ), TMP_ALL_2 AS (
            SELECT *
            FROM (
                SELECT CASH_TYPE_G0
                    , (CASE WHEN NVL(CASH_TYPE_G1,'X') NOT IN('배달대행료','라이더_배달대행수수료','상점_배달대행수수료','배달대행수수료') THEN '4.기타'
                            WHEN B2B_YN = 'Y' THEN '1.B2B'
                            WHEN HQ_BL_YN = 'Y' THEN '3.상점계약'
                            WHEN B2B_YN IN('N','S') THEN '2.로드샵' ELSE '4.기타'||B2B_YN||HQ_BL_YN END) AS "귀속구분"
                    , CASH_TYPE_G1
                    , CASH_TYPE_G2
                    , CASH_TYPE_GROUP
                    , BR_CODE, CASH_TYPE, CASH_TYPE_NM, CASH_TYPE_CD, BR_CASH_TYPE_CD, WK_CASH_TYPE_CD
                    , SUM(지사캐쉬_증가) AS 지사캐쉬_증가
                    , SUM(지사캐쉬_감소) AS 지사캐쉬_감소
                    , SUM(기사캐쉬_증가) AS 기사캐쉬_증가
                    , SUM(기사캐쉬_감소) AS 기사캐쉬_감소
                    , SUM(지사수익_합계) AS 지사수익_합계
                    , SUM(지사부가세) AS 지사부가세
                    , SUM(지사캐쉬_합계) AS 지사캐쉬_합계
                    , SUM(기사캐쉬_합계) AS 기사캐쉬_합계
                FROM   TMP_ALL_1
                GROUP BY  CASH_TYPE_G0, CASH_TYPE_G1
                    , CASH_TYPE_G2, CASH_TYPE_GROUP
                    , BR_CODE, CASH_TYPE, CASH_TYPE_NM, CASH_TYPE_CD, BR_CASH_TYPE_CD, WK_CASH_TYPE_CD
                    , (CASE WHEN NVL(CASH_TYPE_G1,'X') NOT IN('배달대행료','라이더_배달대행수수료','상점_배달대행수수료','배달대행수수료') THEN '4.기타'
                            WHEN B2B_YN = 'Y' THEN '1.B2B'
                            WHEN HQ_BL_YN = 'Y' THEN '3.상점계약'
                            WHEN B2B_YN IN('N','S') THEN '2.로드샵' ELSE '4.기타'||B2B_YN||HQ_BL_YN END)
                ORDER BY CASH_TYPE_G0 DESC, "귀속구분", CASH_TYPE_G1, CASH_TYPE_G2
            )
            WHERE 1=1
        ), TMP_SE_VIEW AS (
            SELECT A.LOG_DATE, A.BR_CASH
                , 'C0.종료일마감잔액,C1.예치금마감액,C2.고용보험예치금마감액,C3.부가세예치금마감액,C4.상점마이너스마감액,C5.라이더플러스마감액' AS TTL
                , A.BR_CASH
                    ||','||A.BR_DEPOSIT_CASH
                    ||','||A.BR_EINS_DPST
                    ||','||A.BR_VAT_DEPOSIT
                    ||','||A.ST_MINUS_CASH
                    ||','||A.WK_PLUS_CASH AS DTL
            FROM APPSIS.ALD_ADJ_BR_CASH_STAT A
            WHERE HD_CODE = in_HD_CODE
            AND   BR_CODE = in_BR_CODE
            AND   LOG_DATE IN(TO_CHAR(TO_DATE(SUBSTRB(in_STR_DATE,1,8),'YYYYMMDD')-1,'YYYYMMDD')
                            , TO_CHAR(TO_DATE(SUBSTRB(in_END_DATE,1,8),'YYYYMMDD')-1,'YYYYMMDD'))
            UNION ALL
            SELECT FN_SYS_0128_GET_ADJ_YMD_1(SYSDATE) AS LOG_DATE, A.BR_CASH
                , 'C0.종료일마감잔액,C1.예치금마감액,C2.고용보험예치금마감액,C3.부가세예치금마감액,C4.상점마이너스마감액,C5.라이더플러스마감액' AS TTL
                , A.BR_CASH
                    ||','||A.DEPOSIT_CASH
                    ||','||FN_SYS_0149_EINS_DPST_TODAY(A.BR_CODE)
                    ||','||A.VAT_DEPOSIT_CASH 
                    ||','||(SELECT SUM(ST_CASH) FROM ALD_GRP_ST_INFO WHERE BR_CODE = A.BR_CODE AND ST_CASH < 0)
                    ||','||(SELECT SUM(WK_CASH) FROM ALD_GRP_WK_INFO WHERE BR_CODE = A.BR_CODE AND WK_CASH > 0) AS DTL
            FROM APPSIS.V02_GRP_BR_INFO A
            WHERE BR_CODE = in_BR_CODE
            AND   in_END_DATE > FN_SYS_0128_GET_ADJ_YMD_1(SYSDATE)||'07'
        )
        SELECT CASH_TYPE_G0||'-요약' AS CASH_TYPE_G0, 'ALL' AS 귀속구분, 'ALL' AS CASH_TYPE_G1, 'ALL' AS CASH_TYPE_CD, 'ALL' AS CASH_TYPE_NM
            , NULL AS STR_DATE
            , NULL AS END_DATE
            , SUM(지사캐쉬_합계) - SUM(지사부가세) AS 공급가액
            , SUM(지사부가세) AS 부가세
            , SUM(지사캐쉬_합계) AS 입출금합계
            , 'ALL' AS CASH_TYPE
        FROM TMP_ALL_2 T
        WHERE CASH_TYPE_G0 IN('수익','비용','기타')
        GROUP BY CASH_TYPE_G0
        UNION ALL
        SELECT CASH_TYPE_G0, 귀속구분, NVL(CASH_TYPE_G2,CASH_TYPE_G1) AS CASH_TYPE_G1, CASH_TYPE_CD, CASH_TYPE_NM
            , in_STR_DATE AS STR_DATE
            , in_END_DATE AS END_DATE
            , 지사캐쉬_합계 - 지사부가세 AS 공급가액
            , 지사부가세 AS 부가세
            , 지사캐쉬_합계 AS 입출금합계
            , CASH_TYPE AS CASH_TYPE
        FROM TMP_ALL_2 T
        WHERE CASH_TYPE_G0 IN('수익','비용','기타')
        UNION ALL
        SELECT '마감잔액' AS CASH_TYPE_G0
            , A.LOG_DATE AS "귀속구분"
            , NULL AS CASH_TYPE_G1
            , 'S00' AS CASH_TYPE_CD
            , 'A.시작 캐쉬마감잔액' AS CASH_TYPE_NM
            , NULL AS STR_DATE
            , NULL AS END_DATE
            , NULL AS "공급가액"
            , NULL AS "부가세"
            , A.BR_CASH AS "입출금합계"
            , 'ALL' AS CASH_TYPE
        FROM TMP_SE_VIEW A
        WHERE LOG_DATE = TO_CHAR(TO_DATE(SUBSTRB(in_STR_DATE,1,8),'YYYYMMDD')-1,'YYYYMMDD')
        UNION ALL
        SELECT '마감잔액' AS CASH_TYPE_G0
            , A.LOG_DATE AS "귀속구분"
            , NULL AS CASH_TYPE_G1  
            , 'E00' AS CASH_TYPE_CD
            , A.TTL AS CASH_TYPE_NM
            , NULL AS STR_DATE
            , NULL AS END_DATE
            , NULL AS "공급가액"
            , NULL AS "부가세"
            , TO_NUMBER(A.DTL) AS "입출금합계"
            , 'ALL' AS CASH_TYPE
        FROM (
            SELECT LOG_DATE
                , REGEXP_SUBSTR(TTL||',','[^,]+', 1, LEVEL) AS TTL
                , REGEXP_SUBSTR(DTL||',','[^,]+', 1, LEVEL) AS DTL
            FROM (  SELECT * FROM TMP_SE_VIEW
                    WHERE LOG_DATE = TO_CHAR(TO_DATE(SUBSTRB(in_END_DATE,1,8),'YYYYMMDD')-1,'YYYYMMDD') )
            CONNECT BY REGEXP_SUBSTR(TTL||',', '[^,]+', 1, LEVEL) IS NOT NULL
                    AND REGEXP_SUBSTR(DTL||',', '[^,]+', 1, LEVEL) IS NOT NULL
            ORDER BY TTL) A
        UNION ALL
        SELECT '허브수익확인' AS CASH_TYPE_G0, 귀속구분, NVL(CASH_TYPE_G2,CASH_TYPE_G1) AS CASH_TYPE_G1, CASH_TYPE_CD, CASH_TYPE_NM
            , in_STR_DATE AS STR_DATE
            , in_END_DATE AS END_DATE
            , (CASE WHEN CASH_TYPE_CD LIKE 'B%' THEN 지사캐쉬_합계 ELSE 기사캐쉬_합계 END) AS 공급가액
            , 0 AS 부가세
            , (CASE WHEN CASH_TYPE_CD LIKE 'B%' THEN 지사캐쉬_합계 ELSE 기사캐쉬_합계 END) AS 입출금합계
            , CASH_TYPE AS CASH_TYPE
        FROM TMP_ALL_2 T
        WHERE CASH_TYPE_G2 IS NOT NULL
        ; 

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            out_CODE    := '0';
            out_MSG     := 'FAILED';
            OPEN out_DATA FOR
                SELECT out_CODE, out_MSG FROM DUAL; --20200129 jh

            SP_SYS_0102_ERROR_LOG ('SP_CSC_0726_GET_BR_INOUT_CASH', 'ERROR CODE : '||SQLCODE ||', ERROR MSG : '||SUBSTR(SQLERRM, 1, 1000));

END SP_CSC_0726_GET_BR_INOUT_CASH;