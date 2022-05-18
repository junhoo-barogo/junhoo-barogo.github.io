create or replace PROCEDURE        SP_SYS_0301_ADJ_ORDER_02
-- ==========================================================================================
-- Author       : Moon
-- Create date  : 2013-05-14
-- Description  : 오더 정산 (02:배달)
-- ==========================================================================================
-- out_CODE     : 0(실패), 1(성공)
-- ==========================================================================================
(
    vi_ORD_NO           NUMBER
    , vi_ORD_TYPE_CD    NUMBER
    , vi_ORD_HD_CODE    VARCHAR2
    , vi_ORD_BR_CODE    VARCHAR2
    , vi_ORD_ST_CODE    VARCHAR2
    , vi_ORD_ST_NAME    VARCHAR2

    , vi_PER_HD_CODE    VARCHAR2
    , vi_PER_BR_CODE    VARCHAR2
    , vi_PER_ST_CODE    VARCHAR2
    , vi_CTH_HD_CODE    VARCHAR2
    , vi_CTH_BR_CODE    VARCHAR2

    , vi_CTH_WK_CODE    VARCHAR2
    , vi_CTH_WK_NAME    VARCHAR2
    , vi_DUP_ORDER_CNT  NUMBER
    , vi_DVRY_PAY_TYPE  VARCHAR2
    , vi_DVRY_AMT       NUMBER
    , vi_SRV_AMT        NUMBER

    , vi_ORD_AMT        NUMBER
    , vi_ORD_CU_NO      NUMBER
    , vi_ORD_CU_TEL     VARCHAR2
    , vi_PAY_CARD       NUMBER
    , vi_PAY_CASH       NUMBER

    , vi_PAY_MILEAGE    NUMBER
    , vi_DVRY_ADJ_AMT   NUMBER
    , vi_DVRY_PRCH_AMT  NUMBER
    , vi_PARTNER_CODE   VARCHAR2
    , vi_CARD_APPR_NUM  VARCHAR2
    , vi_SUPP_AMT       NUMBER
    , vi_KM_PRODUCT_TOTAL NUMBER
    , vi_DVRY_DISC_AMT  NUMBER
    , vi_GOODS_PAY_TYPE VARCHAR2
)
IS

--  // 발주_총판/지사 정산비율 정의
    v_O_HD_BR_CODE      VARCHAR2(5 BYTE)    := NULL;
    v_O_HD_DVRY_ST_PAY  NUMBER(5,2)         := 0.00;
    v_O_HD_SRV_PAY      NUMBER(5,2)         := 0.00;
    v_O_HD_DVRY_PAY     NUMBER(5,2)         := 0.00;
    v_O_HD_ST_DVRY_PAY  NUMBER(5,2)         := 0.00; -- 20150113추가
    v_O_HD_ORD_MARGIN   NUMBER(5,2)         := 0.00;
    v_O_BR_DVRY_ST_PAY  NUMBER(5,2)         := 0.00;
    v_O_BR_SRV_PAY      NUMBER(5,2)         := 0.00;
    v_O_BR_DVRY_PAY     NUMBER(5,2)         := 0.00;
    v_O_BR_ST_DVRY_PAY  NUMBER(5,2)         := 0.00; -- 20150113추가
    v_O_BR_ORD_MARGIN   NUMBER(5,2)         := 0.00;

--  // 발주_배차_정산비율 정의
    v_O_CAL_RATE        NUMBER              := 100;
    v_O_CAL_WK_RATE     NUMBER              :=   0; -- 수발주비율_기사수수료
    v_O_CAL_ST_RATE     NUMBER              := 100; -- 수발주비율_가맹점수수료
    v_O_CAL_SM_RATE     NUMBER              := 100; -- 수발주비율_가맹관리비

--  // 처리_총판/지사 정산비율 정의
    v_P_HD_BR_CODE      VARCHAR2(5 BYTE)    := NULL;
    v_P_HD_ORD_ST_PAY   NUMBER(5,2)         := 0.00;
    v_P_HD_DVRY_ST_PAY  NUMBER(5,2)         := 0.00;
    v_P_HD_DVRY_PAY     NUMBER(5,2)         := 0.00;
    v_P_BR_ORD_ST_PAY   NUMBER(5,2)         := 0.00;
    v_P_BR_DVRY_ST_PAY  NUMBER(5,2)         := 0.00;
    v_P_BR_DVRY_PAY     NUMBER(5,2)         := 0.00;

--  // 처리_배차_정산비율 정의
    v_P_CAL_RATE        NUMBER              := 100;

--  // 배차_총판/지사 정산비율 정의
    v_C_HD_BR_CODE      VARCHAR2(5 BYTE)    := NULL;
    v_C_HD_SRV_PAY      NUMBER(5,2)         := 0.00;
    v_C_HD_DVRY_PAY     NUMBER(5,2)         := 0.00;
    v_C_BR_SRV_PAY      NUMBER(5,2)         := 0.00;
    v_C_BR_DVRY_PAY     NUMBER(5,2)         := 0.00;

--  // 가맹점 배달대행수수료 정의
    v_DVRY_ST_PAY_1     NUMBER              := 0;       -- 가맹점 배달대행수수료 정액
    v_DVRY_ST_PAY_2     NUMBER(5,2)         := 0.00;    -- 가맹점 배달대행수수료 정률
    v_DVRY_ST_PAY_MSG   VARCHAR2(20 BYTE)   := NULL;    -- 가맹점 배달대행수수료 차감방식(정액/정률) 표시
    v_DVRY_ST_L_PAY_OHD_RATE NUMBER         := 0;       -- 가맹점 배달대행수수료 비율(발주총판)
    v_DVRY_ST_L_PAY_OBR_RATE NUMBER         := 0;       -- 가맹점 배달대행수수료 비율(발주지사)
    v_DVRY_ST_L_PAY_CBR_RATE NUMBER         := 0;       -- 가맹점 배달대행수수료 비율(배차수행지사)
    v_DVRY_ST_L_PAY_HQ_RATE  NUMBER         := 0;       -- 가맹점 배달대행수수료 비율(본사)
    v_DVRY_ST_L_PAY_AMT NUMBER              := 0;       -- 가맹점 배달대행수수료 합계
    v_DVRY_ST_L_PAY_VAT NUMBER              := 0;       -- 가맹점 배달대행수수료 부가세 합계
    v_DVRY_ST_L_PAY_CBR_AMT NUMBER          := 0;       -- 가맹점 배달대행수수료 수행지사
    v_DVRY_ST_L_PAY_OBR_AMT NUMBER          := 0;       -- 가맹점 배달대행수수료 발주지사
    v_DVRY_ST_L_PAY_OHD_AMT NUMBER          := 0;       -- 가맹점 배달대행수수료 발주총판
    v_DVRY_ST_L_PAY_HQ_AMT NUMBER           := 0;       -- 가맹점 배달대행수수료 본사
    v_DVRY_ST_L_PAY_CBR_VAT NUMBER          := 0;       -- 가맹점 배달대행수수료 수행지사 부가세
    v_DVRY_ST_L_PAY_OBR_VAT NUMBER          := 0;       -- 가맹점 배달대행수수료 발주지사 부가세
    v_DVRY_ST_L_PAY_OHD_VAT NUMBER          := 0;       -- 가맹점 배달대행수수료 발주총판 부가세
    v_DVRY_ST_L_PAY_HQ_VAT NUMBER           := 0;       -- 가맹점 배달대행수수료 본사 부가세
    v_DVRY_ST_L_PAY_OB_VAT NUMBER           := 0;       -- 가맹점 배달대행수수료 부가세 - 발주지사귀속부가세

    v_DVRY_ST_PAY_4_HQ  NUMBER              := 0;       -- 배달대행료 본사선차감 정액
    v_DVRY_ST_PAY_5_HQ  NUMBER(5,2)         := 0.00;    -- 배달대행료 본사선차감 정률
    v_DVRY_ST_PAY_4_HD  NUMBER              := 0;       -- 배달대행료 총판선차감 정액
    v_DVRY_ST_PAY_5_HD  NUMBER(5,2)         := 0.00;    -- 배달대행료 총판선차감 정률
    v_DVRY_ST_PAY_4_BR  NUMBER              := 0;       -- 배달대행료 지사선차감 정액
    v_DVRY_ST_PAY_5_BR  NUMBER(5,2)         := 0.00;    -- 배달대행료 지사선차감 정률
    v_DVRY_DC_PAY_4_HQ  NUMBER              := 0;       -- 배달대행료 본사선차감 정액-묶음배송
    v_DVRY_DC_PAY_5_HQ  NUMBER(5,2)         := 0.00;    -- 배달대행료 본사선차감 정률-묶음배송
    v_DVRY_DC_PAY_4_HD  NUMBER              := 0;       -- 배달대행료 총판선차감 정액-묶음배송
    v_DVRY_DC_PAY_5_HD  NUMBER(5,2)         := 0.00;    -- 배달대행료 총판선차감 정률-묶음배송
    v_DVRY_DC_PAY_4_BR  NUMBER              := 0;       -- 배달대행료 지사선차감 정액-묶음배송
    v_DVRY_DC_PAY_5_BR  NUMBER(5,2)         := 0.00;    -- 배달대행료 지사선차감 정률-묶음배송
    v_DVRY_FEE_DISC_RATE  NUMBER(3)           := 0;       -- 지사배달대행수수료_차감률 (%)
    v_WK_FEE_DISC_RATE    NUMBER(3)           := 0;       -- 기사배달대행수수료_차감률 (%)
    -- 선차감
    v_DVRY_ST_PAY_BR_AMT  NUMBER              := 0;       -- 배달대행료 지사선차감합계(정액+정률)
    v_DVRY_ST_PAY_HD_AMT  NUMBER              := 0;       -- 배달대행료 총판선차감합계(정액+정률)
    v_DVRY_ST_PAY_HQ_AMT  NUMBER              := 0;       -- 배달대행료 본사선차감합계(정액+정률)
    v_DVRY_ST_PAY_TT_AMT  NUMBER              := 0;       -- 배달대행료 전체선차감합계(정액+정률)
    v_DVRY_ST_PAY_BR_VAT  NUMBER              := 0;       -- 배달대행료 지사선차감합계부가세(정액+정률)
    v_DVRY_ST_PAY_HD_VAT  NUMBER              := 0;       -- 배달대행료 총판선차감합계부가세(정액+정률)
    v_DVRY_ST_PAY_HQ_VAT  NUMBER              := 0;       -- 배달대행료 본사선차감합계부가세(정액+정률)
    v_DVRY_ST_PAY_OB_VAT  NUMBER              := 0;       -- 배달대행료 지사선차감합계부가세(정액+정률) - 발주지사귀속부가세
    -- 선차감할인
    v_DIS_DVRY_PAY_FLAG   VARCHAR2(1 BYTE)    := 'X';    -- 배달대행선차감구분(S:가맹점,B:지사,A:모두,X:사용안함)
    v_DIS_DVRY_PAY_4_HQ   NUMBER              := 0;       -- 거리_선차감할인_본사
    v_DIS_DVRY_PAY_4_HD   NUMBER              := 0;       -- 거리_선차감할인_총판
    v_DIS_DVRY_PAY_4_BR   NUMBER              := 0;       -- 거리_선차감할인_지사

--  // 기사 차감/충전 금액 합계
    v_WK_FEE_FIX_SUM    NUMBER              := 0;       -- 기사의 배달대행수수료 정액 합계
    v_WK_FEE_RATE_SUM   NUMBER              := 0;       -- 기사의 배달대행수수료 정률 합계
    v_WK_FEE_SUM        NUMBER              := 0;       -- 기사의 배달대행수수료 합계
    v_WK_FEE_CBR_SUM    NUMBER              := 0;       -- 본사귀속정산-기사의 배달대행수수료 합계(수행지사수익)
    v_WK_FEE_CBR_AMT    NUMBER              := 0;       -- 본사귀속정산-기사의 배달대행수수료 공급가액(수행지사수익)
    v_WK_FEE_CBR_VAT    NUMBER              := 0;       -- 본사귀속정산-기사의 배달대행수수료 부가세액(수행지사수익)
    v_WK_FEE_CBR_RATE   NUMBER              := 0;       -- 기사의 배달대행수수료 비율(수주지사)
    v_WK_FEE_OBR_RATE   NUMBER              := 0;       -- 기사의 배달대행수수료 비율(발주지사)
    v_WK_FEE_OBR_SUM    NUMBER              := 0;       -- 기사의 배달대행수수료 합계 발주지사
    v_WK_FEE_OBR_AMT    NUMBER              := 0;       -- 기사의 배달대행수수료 합계 발주지사
    v_WK_FEE_OBR_VAT    NUMBER              := 0;       -- 기사의 배달대행수수료 합계 발주지사 부가세
    v_WK_FEE_MSG        VARCHAR2(20 BYTE)   := NULL;    -- 기사의 배달대행수수료 그룹 차감방식(정액/정률) 표시
    -- 기사배달대행료
    v_DVRY_PAY_WK         NUMBER              := 0;       -- 기사배달대행료 수수료 합계
    v_DVRY_PAY_WK_T       NUMBER              := 0;       -- 기사배달대행료 수수료 원천세
    v_DVRY_PAY_WK_T_HQ    NUMBER              := 0;       -- 기사배달대행료 수수료 원천세 본사귀속
    v_DVRY_PAY_WK_BR_AMT  NUMBER              := 0;       -- 기사배달대행료 지사
    v_DVRY_PAY_WK_BR_VAT  NUMBER              := 0;       -- 기사배달대행료 지사 부가세
    v_DVRY_PAY_WK_OB_VAT  NUMBER              := 0;       -- 기사배달대행료 발주지사-귀속부가세
    v_DVRY_PAY_WK_HQ_VAT  NUMBER              := 0;       -- 기사배달대행료 본사-귀속부가세
    -- 기사지원금
    v_SUPP_TOT            NUMBER              := 0;
    v_SUPP_AMT            NUMBER              := 0;
    v_SUPP_VAT            NUMBER              := 0;
    -- 가맹점 배달대행관리비
    v_DVRY_ST_M_PAY_1   NUMBER              := 0;       -- 해당가맹점의 배달대행관리비 정액
    v_DVRY_ST_M_PAY_2   NUMBER(5,2)         := 0.00;    -- 해당가맹점의 배달대행관리비 정률
    v_DVRY_ST_M_PAY_MSG VARCHAR2(20 BYTE)   := NULL;    -- 가맹점 배달대행관리비 차감방식(정액/정률) 표시
    v_DVRY_ST_M_PAY_OHD_RATE NUMBER         := 0;       -- 가맹점 배달대행관리비 비율(발주총판)
    v_DVRY_ST_M_PAY_OBR_RATE NUMBER         := 0;       -- 가맹점 배달대행관리비 비율(발주지사)
    v_DVRY_ST_M_PAY_CBR_RATE NUMBER         := 0;       -- 가맹점 배달대행관리비 비율(배차수행지사)
    v_DVRY_ST_M_PAY_HQ_RATE  NUMBER         := 0;       -- 가맹점 배달대행관리비 비율(본사)
    v_DVRY_ST_M_PAY_AMT NUMBER              := 0;       -- 가맹점 배달대행관리비 합계
    v_DVRY_ST_M_PAY_VAT NUMBER              := 0;       -- 가맹점 배달대행관리비 부가세
    v_DVRY_ST_M_PAY_OBR_AMT  NUMBER         := 0;       -- 가맹점 배달대행관리비 발주지사
    v_DVRY_ST_M_PAY_CBR_AMT  NUMBER         := 0;       -- 가맹점 배달대행관리비 수주지사
    v_DVRY_ST_M_PAY_OHD_AMT  NUMBER         := 0;       -- 가맹점 배달대행관리비 발주총판
    v_DVRY_ST_M_PAY_HQ_AMT  NUMBER          := 0;       -- 가맹점 배달대행관리비 본사
    v_DVRY_ST_M_PAY_OBR_VAT  NUMBER         := 0;       -- 가맹점 배달대행관리비 발주지사 부가세
    v_DVRY_ST_M_PAY_CBR_VAT  NUMBER         := 0;       -- 가맹점 배달대행관리비 수주지사 부가세
    v_DVRY_ST_M_PAY_OHD_VAT  NUMBER         := 0;       -- 가맹점 배달대행관리비 발주총판 부가세
    v_DVRY_ST_M_PAY_HQ_VAT  NUMBER          := 0;       -- 가맹점 배달대행관리비 본사 부가세
    v_DVRY_ST_M_PAY_OB_VAT  NUMBER          := 0;       -- 가맹점 배달대행관리비 부가세 - 발주지사귀속부가세

    v_WK_FEE_FIX        NUMBER              := 0;       -- 해당기사의 배달대행수수료 그룹이 없으면 기본수수료 정액
    v_WK_FEE_RATE       NUMBER(5,2)         := 0.00;    -- 해당기사의 배달대행수수료 그룹이 없으면 기본수수료 정률
    v_WK_DGRP_NAME      ALD_GRP_WK_DVRY_FEE.WK_DGRP_NAME%TYPE;         -- 해당기사의 배달대행수수료 그룹명
    v_DUP_ORDER_CNT     NUMBER              := vi_DUP_ORDER_CNT;       -- 해당기사의 복수건수그룹이 없으면 기본복수건수

    v_VAT_RATE          NUMBER              := 0;       -- 가맹점부가세정률(0:이면 사용안함)
    v_PAY_3_VAT_RATE    NUMBER              := 0;       -- 가맹점관리비부가세정률(0:이면 사용안함)
    v_WK_DGRP_NO        NUMBER              := 0;       -- 기사  -기사수수료그룹

    v_DVRY_FEE_FIX      NUMBER              := 0;       -- 수행지사_배달대행수수료 정액
    v_O_DVRY_FEE_FIX    NUMBER              := 0;       -- 발주지사_배달대행수수료 정액
    v_ST_OPTION_YN_7    VARCHAR2(1 BYTE)    := 'N';     -- 발주가맹점_부가세본사귀속여부
    v_BR_OPTION_YN_10   VARCHAR2(1 BYTE)    := 'N';     -- 수행지사_부가세본사귀속여부
    v_HQ_BL_YN          VARCHAR2(1 BYTE)    := 'N';     -- 부가세/원천세본사귀속여부
    v_DIRECT_YN         VARCHAR2(1 BYTE)    := 'N';     -- 수행지사_직영여부
    v_WK_TAX_RATE       NUMBER              := 0;       -- 수행지사_기사원천세비율
    v_WK_TAX_YN         VARCHAR2(1 BYTE)    := 'N';     -- 수행지사_기사원천세적용여부
    v_EMPL_TYPE         ALD_GRP_WK_INFO.EMPL_TYPE%TYPE;     -- 라이더_고용형태(SY_CD=WE)
    v_C_BR_VAT_YN       ALD_GRP_BR_INFO.BR_VAT_YN%TYPE;         -- 수행지사_부가세적용여부
    v_O_BR_VAT_YN       ALD_GRP_BR_INFO.BR_VAT_YN%TYPE;         -- 발주지사_부가세적용여부
    v_C_HD_BR_VAT_YN    ALD_GRP_BR_INFO.BR_VAT_YN%TYPE;         -- 수행총판지사_부가세적용여부
    v_O_HD_BR_VAT_YN    ALD_GRP_BR_INFO.BR_VAT_YN%TYPE;         -- 발주총판지사_부가세적용여부
    v_DVRY_FEE_VAT_YN   ALD_GRP_BR_INFO.DVRY_FEE_VAT_YN%TYPE;   --  수행지사_지사배달대행수수료_부가세포함여부
    v_B2B_YN            VARCHAR2(1 BYTE)    := 'N';     -- B2B 발주총판 여부
    v_MATCH_YN          VARCHAR2(1 BYTE)    := 'N';     -- 기사지원금가능_지사지급 여부
    v_BR_DVRY_PAY_FLAG  ALD_GRP_BR_INFO.BR_DVRY_PAY_FLAG%TYPE;  -- 수행지사_선차감적용방법(B:지사,S:가맹점)
    v_DVRY_BR_PAY_4_HQ  ALD_GRP_BR_INFO.DVRY_PAY_4%TYPE;        -- 수행지사_본사선차감_건당_정액
    v_DVRY_BR_PAY_5_HQ  ALD_GRP_BR_INFO.DVRY_PAY_5%TYPE;        -- 수행지사_본사선차감_건당_정률
    v_DVRY_BR_PAY_4_BR  ALD_GRP_BR_INFO.DVRY_PAY_4_BR%TYPE;     -- 수행지사_지사선차감_건당_정액
    v_DVRY_BR_PAY_5_BR  ALD_GRP_BR_INFO.DVRY_PAY_5_BR%TYPE;     -- 수행지사_지사선차감_건당_정률
    v_DVRY_BR_PAY_4_HD  ALD_GRP_BR_INFO.DVRY_PAY_4_HD%TYPE;     -- 수행지사_총판선차감_건당_정액
    v_DVRY_BR_PAY_5_HD  ALD_GRP_BR_INFO.DVRY_PAY_5_HD%TYPE;     -- 수행지사_총판선차감_건당_정률

    -- 매입배달대행료_선차감
    v_PRCH_CHARGE         ALD_GRP_DVRY_PRCH.PRCH_CHARGE%TYPE := 0;         -- 매입배달대행료
    v_PRCH_DVRY_PAY_4_HQ  ALD_GRP_DVRY_PRCH.DVRY_PAY_4_HQ%TYPE := 0;       -- 매입배달대행료_선차감정액_본사
    v_PRCH_DVRY_PAY_4_HD  ALD_GRP_DVRY_PRCH.DVRY_PAY_4_HD%TYPE := 0;       -- 매입배달대행료_선차감정액_총판
    v_PRCH_DVRY_PAY_4_BR  ALD_GRP_DVRY_PRCH.DVRY_PAY_4_BR%TYPE := 0;       -- 매입배달대행료_선차감정액_지사
    v_PRCH_DVRY_PAY_5_HQ  ALD_GRP_DVRY_PRCH.DVRY_PAY_5_HQ%TYPE := 0;       -- 매입배달대행료_선차감정율_본사
    v_PRCH_DVRY_PAY_5_HD  ALD_GRP_DVRY_PRCH.DVRY_PAY_5_HD%TYPE := 0;       -- 매입배달대행료_선차감정율_총판
    v_PRCH_DVRY_PAY_5_BR  ALD_GRP_DVRY_PRCH.DVRY_PAY_5_BR%TYPE := 0;       -- 매입배달대행료_선차감정율_지사
    
    v_DVRY_ORG_AMT      NUMBER              := 0;       -- 배달대행비용(정산기준액_원금액)
    v_DVRY_ORG_VAT      NUMBER              := 0;       -- 배달대행비용(정산기준액_원금액부가세)
    v_DVRY_ADJ_AMT      NUMBER              := 0;       -- 배달대행비용(정산기준액)
    v_DVRY_PRCH_AMT     NUMBER              := vi_DVRY_PRCH_AMT;       -- 배달대행료(매입)
    v_DVRY_SALS_AMT     NUMBER              := 0;       -- 배달대행료(매출)
    v_DVRY_SALS_VAT     NUMBER              := 0;       -- 배달대행료(매출부가세)
    v_DVRY_GAP_AMT      NUMBER              := 0;       -- 배달대행료(매출매입 차액)
    v_DVRY_GAP_VAT      NUMBER              := 0;       -- 배달대행료(매출매입 차액부가세)
    v_DVRY_HQS_VAT      NUMBER              := 0;       -- 세무정산귀속-부가세
    v_DVRY_HQF_AMT      NUMBER              := 0;       -- 세무정산귀속-정산수수료
    v_DVRY_HQF_VAT      NUMBER              := 0;       -- 세무정산귀속-정산수수료부가세
    v_VAN_TERM_KIND     VARCHAR2(1 BYTE)    := '0';    -- VAN터미널종류(0:가맹점,1:바로고지사)

--  // 주문대행비용 정의
    v_ORD_ST_PAY_1      NUMBER              := 0;
    v_ORD_ST_PAY_2      NUMBER(5,2)         := 0.00;
    v_ORD_MARGIN        NUMBER              := 0;

--  // 봉사료비용 정의
    v_WK_SUPP_FIX       NUMBER              := 0;
    v_WK_SUPP_RATE      NUMBER(5,2)         := 0.00;

--  // 고객 정보
    v_CU_MILEAGE            NUMBER          := 0;
    v_RECOMM_CU_NO          NUMBER          := 0;
    v_RECOMM_CU_MILEAGE     NUMBER          := 0;

--  // 상품마진, 마일리지 정보
    v_MARGIN_FIX        NUMBER              := 0;
    v_MARGIN_RATE       NUMBER              := 0;
    v_MILE_FIX          NUMBER              := 0;
    v_MILE_RATE         NUMBER              := 0;
    v_STEP      VARCHAR2(1000 BYTE)    := 'STEP_0_0';

--  // 지사 차감/충전 금액 합계
    v_DVRY_FEE_FIX_SUM_ORG  NUMBER              := 0;       -- 지사배달대행수수료 정액 합계(원차감액)
    v_DVRY_FEE_FIX_AMT_ORG  NUMBER              := 0;       -- 지사배달대행수수료 정액 합계(원차감공급액)
    v_DVRY_FEE_FIX_SUM      NUMBER              := 0;       -- 지사배달대행수수료 정액 합계(차감액)
    v_DVRY_FEE_FIX_AMT      NUMBER              := 0;       -- 지사배달대행수수료 정액 합계(차감공급액)
    v_DVRY_FEE_FIX_OHD_AMT  NUMBER              := 0;       -- 지사배달대행수수료 정액 합계(발주총판)
    v_DVRY_FEE_FIX_OBR_AMT  NUMBER              := 0;       -- 지사배달대행수수료 정액 합계(발주지사)
    v_DVRY_FEE_FIX_CBR_AMT  NUMBER              := 0;       -- 지사배달대행수수료 정액 합계(배차수행지사)
    v_DVRY_FEE_FIX_HQ_AMT   NUMBER              := 0;       -- 지사배달대행수수료 정액 합계(본사)
    v_DVRY_FEE_FIX_OHD_RATE NUMBER              := 0;       -- 지사배달대행수수료 정액 비율(발주총판)
    v_DVRY_FEE_FIX_OBR_RATE NUMBER              := 0;       -- 지사배달대행수수료 정액 비율(발주지사)
    v_DVRY_FEE_FIX_CBR_RATE NUMBER              := 0;       -- 지사배달대행수수료 정액 비율(배차수행지사)
    v_DVRY_FEE_FIX_HQ_RATE  NUMBER              := 0;       -- 지사배달대행수수료 정액 비율(본사)

    v_DVRY_FEE_FIX_VAT_ORG  NUMBER              := 0;       -- 지사배달대행수수료 정액 합계(원차감액) 부가세
    v_DVRY_FEE_FIX_VAT      NUMBER              := 0;       -- 지사배달대행수수료 정액 합계(차감액) 부가세
    v_DVRY_FEE_FIX_OHD_VAT  NUMBER              := 0;       -- 지사배달대행수수료 정액 합계(발주총판) 부가세
    v_DVRY_FEE_FIX_OBR_VAT  NUMBER              := 0;       -- 지사배달대행수수료 정액 합계(발주지사) 부가세
    v_DVRY_FEE_FIX_OB_VAT   NUMBER              := 0;       -- 지사배달대행수수료 정액 합계(발주지사) 부가세 - 발주지사귀속부가세
    v_DVRY_FEE_FIX_CBR_VAT  NUMBER              := 0;       -- 지사배달대행수수료 정액 합계(배차수행지사) 부가세
    v_DVRY_FEE_FIX_HQ_VAT   NUMBER              := 0;       -- 지사배달대행수수료 정액 합계(본사)

    v_DVRY_FEE_ADD_AMT      NUMBER              := 0;       -- 지사배달대행수수료 추가분 공급가액(본사)
    v_DVRY_FEE_ADD_VAT      NUMBER              := 0;       -- 지사배달대행수수료 추가분 세액(본사)

    v_WK_SUPP_FIX_SUM   NUMBER              := 0;       -- 해당기사의 봉사료수수료 정액 합계
    v_WK_SUPP_RATE_SUM  NUMBER              := 0;       -- 해당기사의 봉사료수수료 정률 합계
    v_WK_SUPP_SUM       NUMBER              := 0;       -- 기사의 봉사료수수료 합계
    v_WK_SUPP_AMT       NUMBER              := 0;       -- 기사의 봉사료수수료 합계
    v_WK_SUPP_OHD_AMT   NUMBER              := 0;       -- 기사의 봉사료수수료 합계(발주총판)
    v_WK_SUPP_OBR_AMT   NUMBER              := 0;       -- 기사의 봉사료수수료 합계(발주지사)
    v_WK_SUPP_CBR_AMT   NUMBER              := 0;       -- 기사의 봉사료수수료 합계(배차수행지사)
    v_WK_SUPP_HQ_AMT    NUMBER              := 0;       -- 기사의 봉사료수수료 합계(본사)
    v_WK_SUPP_VAT       NUMBER              := 0;       -- 기사의 봉사료수수료 합계 부가세
    v_WK_SUPP_OHD_VAT   NUMBER              := 0;       -- 기사의 봉사료수수료 합계(발주총판) 부가세
    v_WK_SUPP_OBR_VAT   NUMBER              := 0;       -- 기사의 봉사료수수료 합계(발주지사) 부가세
    v_WK_SUPP_CBR_VAT   NUMBER              := 0;       -- 기사의 봉사료수수료 합계(배차수행지사) 부가세
    v_WK_SUPP_HQ_VAT    NUMBER              := 0;       -- 기사의 봉사료수수료 합계(본사)
    v_WK_SUPP_OB_VAT    NUMBER              := 0;       -- 기사의 봉사료수수료 합계(발주지사) 부가세 - 발주지사귀속부가세
    v_WK_SUPP_OHD_RATE  NUMBER              := 0;       -- 기사의 봉사료수수료 비율(발주총판)
    v_WK_SUPP_OBR_RATE  NUMBER              := 0;       -- 기사의 봉사료수수료 비율(발주지사)
    v_WK_SUPP_CBR_RATE  NUMBER              := 0;       -- 기사의 봉사료수수료 비율(배차수행지사)
    v_WK_SUPP_HQ_RATE   NUMBER              := 0;       -- 기사의 봉사료수수료 비율(본사)

--  // 가맹점 가맹비 정보
    CURSOR CSR_ST_PAY_INFO (c_ST_CODE VARCHAR2) IS
        SELECT  S.ORD_PAY_1, S.ORD_PAY_2, S.DVRY_PAY_1, S.DVRY_PAY_2
                , S.DVRY_PAY_4, S.DVRY_PAY_5
                , S.DVRY_PAY_4_HD, S.DVRY_PAY_5_HD
                , S.DVRY_PAY_4_BR, S.DVRY_PAY_5_BR
                , NVL(D.DVRY_PAY_4,0)     AS DVRY_DC_PAY_4_HQ
                , NVL(D.DVRY_PAY_5,0)     AS DVRY_DC_PAY_5_HQ
                , NVL(D.DVRY_PAY_4_HD,0)  AS DVRY_DC_PAY_4_HD
                , NVL(D.DVRY_PAY_5_HD,0)  AS DVRY_DC_PAY_5_HD
                , NVL(D.DVRY_PAY_4_BR,0)  AS DVRY_DC_PAY_4_BR
                , NVL(D.DVRY_PAY_5_BR,0)  AS DVRY_DC_PAY_5_BR
                , NVL(D.DVRY_FEE_DISC_RATE,100)  AS DVRY_FEE_DISC_RATE
                , NVL(D.WK_FEE_DISC_RATE,100)  AS WK_FEE_DISC_RATE
                , S.DVRY_M_PAY_1, S.DVRY_M_PAY_2, S.VAN_TERM_KIND
                , S.VAT_RATE, S.PAY_3_VAT_RATE
                , NVL(P.DVRY_PAY_FLAG,'X') AS DIS_DVRY_PAY_FLAG
                , NVL(P.DVRY_PAY_4_HQ,0) AS DIS_DVRY_PAY_4_HQ
                , NVL(P.DVRY_PAY_4_HD,0) AS DIS_DVRY_PAY_4_HD
                , NVL(P.DVRY_PAY_4_BR,0) AS DIS_DVRY_PAY_4_BR
                , NVL(SUBSTRB(S.OPTION_YN,7,1),'N') AS ST_OPTION_YN_7
                , NVL(H.PRCH_CHARGE,0)   AS PRCH_CHARGE
                , NVL(H.DVRY_PAY_4_HQ,0) AS PRCH_DVRY_PAY_4_HQ
                , NVL(H.DVRY_PAY_4_HD,0) AS PRCH_DVRY_PAY_4_HD
                , NVL(H.DVRY_PAY_4_BR,0) AS PRCH_DVRY_PAY_4_BR
                , NVL(H.DVRY_PAY_5_HQ,0) AS PRCH_DVRY_PAY_5_HQ
                , NVL(H.DVRY_PAY_5_HD,0) AS PRCH_DVRY_PAY_5_HD
                , NVL(H.DVRY_PAY_5_BR,0) AS PRCH_DVRY_PAY_5_BR
        FROM  ALD_GRP_ST_INFO S
        LEFT OUTER JOIN ALD_GRP_ST_DISC_INFO D
        ON    S.ST_CODE = D.ST_CODE
        LEFT OUTER JOIN (
            SELECT * FROM ALD_GRP_DVRY_DIS_PAY
            WHERE ST_CODE = c_ST_CODE
            AND   DIS_ST <= vi_KM_PRODUCT_TOTAL AND vi_KM_PRODUCT_TOTAL < DIS_ED
            AND   ROWNUM = 1) P
        ON    S.ST_CODE = P.ST_CODE
        LEFT OUTER JOIN (
            SELECT * FROM ALD_GRP_DVRY_PRCH
            WHERE ST_CODE = c_ST_CODE
            AND   DIS_ST <= vi_KM_PRODUCT_TOTAL AND vi_KM_PRODUCT_TOTAL < DIS_ED
            AND   ROWNUM = 1) H
        ON    S.ST_CODE = H.ST_CODE
        WHERE S.ST_CODE = c_ST_CODE;

--  // 가맹점배달대행수수료 거리구간금액 설정정보
    CURSOR CSR_ST_PAY_KM_INFO (c_ST_CODE VARCHAR2) IS
        SELECT  DVRY_PAY_1, DVRY_PAY_2
        FROM    ALD_GRP_ST_DVRY_PAY
        WHERE   ST_CODE = c_ST_CODE
        AND     DIS_ST <= vi_KM_PRODUCT_TOTAL AND vi_KM_PRODUCT_TOTAL < DIS_ED
        AND     ROWNUM = 1;

--  // 기사 배달대행수수료 정보 - 적용기사별
    CURSOR CSR_WK_D_PAY_INFO_WK (c_WK_CODE VARCHAR2, c_DVRY_AMT NUMBER, c_ORD_ST_CODE VARCHAR2) IS
        SELECT  WD.WK_FEE_FIX, WD.WK_FEE_RATE, WG.WK_DGRP_NAME, WK.WK_DGRP_NO
        FROM    ALD_GRP_WK_INFO WK, ALD_GRP_WK_DVRY_FEE WG, ALD_GRP_WK_DVRY_FEE_DETAIL WD
        WHERE   WK.WK_DGRP_NO = WG.WK_DGRP_NO
        AND     WK.WK_DGRP_NO = WD.WK_DGRP_NO
        AND     WD.DVRY_PAY_S <= c_DVRY_AMT AND c_DVRY_AMT <= WD.DVRY_PAY
        AND     WK.WK_CODE = c_WK_CODE
        AND     NOT EXISTS(
                    SELECT 1 FROM ALD_GRP_DGRP_EXP_ST
                    WHERE USE_YN = 'Y'
                    AND   WK_DGRP_NO = WK.WK_DGRP_NO
                    AND   ST_CODE = c_ORD_ST_CODE);

--  // 기사 배달대행수수료 정보 - 적용가맹점별
    CURSOR CSR_WK_D_PAY_INFO_ST (f_BR_CODE VARCHAR2, f_DVRY_AMT NUMBER, f_ORD_ST_CODE VARCHAR2) IS
        SELECT  WD.WK_FEE_FIX, WD.WK_FEE_RATE, WG.ST_DGRP_NAME, WK.ST_DGRP_NO
        FROM    ALD_GRP_WK_DVRY_FEE_ST WK, ALD_GRP_ST_DVRY_FEE WG, ALD_GRP_ST_DVRY_FEE_DETAIL WD
        WHERE   WK.ST_DGRP_NO = WG.ST_DGRP_NO
        AND     WK.ST_DGRP_NO = WD.ST_DGRP_NO
        AND     WD.DVRY_PAY_S <= f_DVRY_AMT AND f_DVRY_AMT <= WD.DVRY_PAY
        AND     WK.C_BR_CODE = f_BR_CODE
        AND     WK.O_ST_CODE = f_ORD_ST_CODE
        AND     WK.USE_YN = 'Y';

--  // 기사 복수건수 전환 정보
    CURSOR CSR_WK_C_PAY_INFO (c_WK_CODE VARCHAR2, c_DUP_ORDER_CNT NUMBER) IS
        SELECT NVL(CD.WK_DUP_CNT,c_DUP_ORDER_CNT) AS DUP_CNT
            , WK.EMPL_TYPE
        FROM ALD_GRP_WK_INFO WK
        LEFT OUTER JOIN ALD_GRP_WK_DUP_CNT_DETAIL CD
        ON   WK.WK_CGRP_NO = CD.WK_CGRP_NO
        AND  CD.DUP_CNT_S <= c_DUP_ORDER_CNT AND c_DUP_ORDER_CNT <= CD.DUP_CNT
        WHERE WK.WK_CODE = c_WK_CODE;

--  // 발주_총판/지사 정산비율 정보
    CURSOR CSR_HD_BR_PAY_INFO_O (c_HD_CODE VARCHAR2, c_BR_CODE VARCHAR2) IS
        SELECT  P.HEAD_BR_CODE, B.BR_VAT_YN
                , (100 - P.HQ_DVRY_ST_PAY - S.BR_DVRY_ST_PAY) HD_DVRY_ST_PAY
                , (100 - P.HQ_SRV_PAY - S.BR_SRV_PAY) HD_SRV_PAY
                , (100 - P.HQ_DVRY_PAY - S.BR_DVRY_PAY) HD_DVRY_PAY
                , (100 - P.HQ_ST_DVRY_PAY - S.BR_ST_DVRY_PAY) HD_ST_DVRY_PAY
                , (100 - P.HQ_ORD_MARGIN - S.BR_ORD_MARGIN) HD_ORD_MARGIN
                , S.BR_DVRY_ST_PAY
                , S.BR_SRV_PAY
                , S.BR_DVRY_PAY
                , S.BR_ST_DVRY_PAY
                , S.BR_ORD_MARGIN
        FROM    ALD_ADJ_HQ_HD_RATE P, ALD_ADJ_HD_BR_RATE S, ALD_GRP_BR_INFO B
        WHERE   P.HD_CODE = S.HD_CODE
        AND     P.HEAD_BR_CODE = B.BR_CODE
                AND S.HD_CODE = c_HD_CODE AND S.BR_CODE = c_BR_CODE;

--  // 배차_총판/지사 정산비율 정보
    CURSOR CSR_HD_BR_PAY_INFO_C (c_HD_CODE VARCHAR2, c_BR_CODE VARCHAR2) IS
        SELECT  P.HEAD_BR_CODE, B.BR_VAT_YN
                , (100 - P.HQ_SRV_PAY - S.BR_SRV_PAY) HD_SRV_PAY
                , (100 - P.HQ_DVRY_PAY - S.BR_DVRY_PAY) HD_DVRY_PAY
                , S.BR_SRV_PAY
                , S.BR_DVRY_PAY
        FROM    ALD_ADJ_HQ_HD_RATE P, ALD_ADJ_HD_BR_RATE S, ALD_GRP_BR_INFO B
        WHERE   P.HD_CODE = S.HD_CODE
        AND     P.HEAD_BR_CODE = B.BR_CODE
                AND S.HD_CODE = c_HD_CODE AND S.BR_CODE = c_BR_CODE;

--  // 수발주비율 정보
    CURSOR CSR_BR_SHARE_INFO (c_O_HD_CODE VARCHAR2, c_O_BR_CODE VARCHAR2, c_O_ST_CODE VARCHAR2, c_C_HD_CODE VARCHAR2, c_C_BR_CODE VARCHAR2) IS
        SELECT  O_CAL_RATE, O_CAL_WK_RATE, O_CAL_ST_RATE, O_CAL_SM_RATE
        FROM    ALD_ADJ_BR_SHARE
        WHERE   O_HD_CODE = c_O_HD_CODE
        AND     O_BR_CODE = c_O_BR_CODE
        AND     DECODE(O_ST_CODE, 'S000000', c_O_ST_CODE, O_ST_CODE) = c_O_ST_CODE
        AND     C_HD_CODE = c_C_HD_CODE
        AND     C_BR_CODE = c_C_BR_CODE
        AND     USE_YN = 'Y';

--  // 배차기사기사 봉사료수수료 정보
    CURSOR CSR_WK_S_PAY_INFO (c_WK_CODE VARCHAR2, c_SRV_AMT NUMBER) IS
        SELECT  WD.WK_SUPP_FIX, WD.WK_SUPP_RATE
        FROM    ALD_GRP_WK_INFO WK, ALD_GRP_WK_SERV_PAY_DETAIL WD
        WHERE   WK.WK_SGRP_NO = WD.WK_SGRP_NO
                AND SERV_PAY_S <= c_SRV_AMT AND c_SRV_AMT <= SERV_PAY
                AND WK.WK_CODE = c_WK_CODE;

--  // 배차지사 정보
    CURSOR CSR_BR_INFO_C (c_BR_CODE VARCHAR2) IS
        SELECT  B.DVRY_FEE_FIX, B.DVRY_FEE_VAT_YN, B.DIRECT_YN, B.WK_TAX_RATE, B.WK_TAX_YN
                , B.BR_VAT_YN, B.BR_DVRY_PAY_FLAG
                , B.DVRY_PAY_4, B.DVRY_PAY_5, B.DVRY_PAY_4_BR, B.DVRY_PAY_5_BR, B.DVRY_PAY_4_HD, B.DVRY_PAY_5_HD
                , NVL(SUBSTRB(C.BR_OPTION_YN,10,1),'N') AS BR_OPTION_YN_10
        FROM    ALD_GRP_BR_INFO B
        LEFT OUTER JOIN ALD_GRP_SEARCH_CFG C
        ON   B.BR_CODE = C.BR_CODE
        WHERE   B.BR_CODE = c_BR_CODE;

--  // 발주지사 정보
    CURSOR CSR_BR_INFO_O (c_BR_CODE VARCHAR2) IS
        SELECT  B.BR_VAT_YN
            , (CASE WHEN FN_SYS_0147_GET_B2B_YN(B.HD_CODE) = 'O_B2B'
                    THEN 'Y' ELSE 'N' END) AS B2B_YN -- (CASE WHEN B.HD_CODE IN('H0095','H0203', 'H4202') THEN 'Y' ELSE 'N' END) AS B2B_YN
            , DECODE(B.DVRY_FEE_FIX,0,100, B.DVRY_FEE_FIX) AS O_DVRY_FEE_FIX
            , B.MATCH_YN
        FROM    ALD_GRP_BR_INFO B
        WHERE   B.BR_CODE = c_BR_CODE;

BEGIN

v_STEP := 'STEP_0_1';

--  // 발주 가맹점 가맹비 정보
    OPEN    CSR_ST_PAY_INFO (vi_ORD_ST_CODE);
    FETCH   CSR_ST_PAY_INFO INTO v_ORD_ST_PAY_1, v_ORD_ST_PAY_2
                                , v_DVRY_ST_PAY_1, v_DVRY_ST_PAY_2
                                , v_DVRY_ST_PAY_4_HQ, v_DVRY_ST_PAY_5_HQ
                                , v_DVRY_ST_PAY_4_HD, v_DVRY_ST_PAY_5_HD
                                , v_DVRY_ST_PAY_4_BR, v_DVRY_ST_PAY_5_BR
                                , v_DVRY_DC_PAY_4_HQ, v_DVRY_DC_PAY_5_HQ
                                , v_DVRY_DC_PAY_4_HD, v_DVRY_DC_PAY_5_HD
                                , v_DVRY_DC_PAY_4_BR, v_DVRY_DC_PAY_5_BR
                                , v_DVRY_FEE_DISC_RATE, v_WK_FEE_DISC_RATE
                                , v_DVRY_ST_M_PAY_1, v_DVRY_ST_M_PAY_2, v_VAN_TERM_KIND
                                , v_VAT_RATE, v_PAY_3_VAT_RATE
                                , v_DIS_DVRY_PAY_FLAG, v_DIS_DVRY_PAY_4_HQ, v_DIS_DVRY_PAY_4_HD, v_DIS_DVRY_PAY_4_BR
                                , v_ST_OPTION_YN_7
                                , v_PRCH_CHARGE
                                , v_PRCH_DVRY_PAY_4_HQ
                                , v_PRCH_DVRY_PAY_4_HD
                                , v_PRCH_DVRY_PAY_4_BR
                                , v_PRCH_DVRY_PAY_5_HQ
                                , v_PRCH_DVRY_PAY_5_HD
                                , v_PRCH_DVRY_PAY_5_BR
                                ;
    CLOSE   CSR_ST_PAY_INFO;
v_STEP := 'STEP_0_2: vi_DVRY_ADJ_AMT'||vi_DVRY_ADJ_AMT||',v_DVRY_ST_PAY_4:'||v_DVRY_ST_PAY_4_HQ||'v_DVRY_ST_PAY_5:'||v_DVRY_ST_PAY_5_HQ;

    IF (v_DVRY_ST_PAY_1 + v_DVRY_ST_PAY_2) = 0 THEN
        OPEN    CSR_ST_PAY_KM_INFO (vi_ORD_ST_CODE);
        FETCH   CSR_ST_PAY_KM_INFO INTO v_DVRY_ST_PAY_1, v_DVRY_ST_PAY_2;
        CLOSE   CSR_ST_PAY_KM_INFO;
    END IF;

v_STEP := 'STEP_0_4';

--  // 배차기사 복수건수 전환 정보
    OPEN    CSR_WK_C_PAY_INFO (vi_CTH_WK_CODE, vi_DUP_ORDER_CNT);
    FETCH   CSR_WK_C_PAY_INFO INTO v_DUP_ORDER_CNT, v_EMPL_TYPE;
    CLOSE   CSR_WK_C_PAY_INFO;
v_STEP := 'STEP_0_5';

--  // 발주_총판/지사 정산비율 정보
    OPEN    CSR_HD_BR_PAY_INFO_O (vi_ORD_HD_CODE, vi_ORD_BR_CODE);
    FETCH   CSR_HD_BR_PAY_INFO_O INTO v_O_HD_BR_CODE, v_O_HD_BR_VAT_YN, v_O_HD_DVRY_ST_PAY, v_O_HD_SRV_PAY, v_O_HD_DVRY_PAY, v_O_HD_ST_DVRY_PAY
                                    , v_O_HD_ORD_MARGIN, v_O_BR_DVRY_ST_PAY, v_O_BR_SRV_PAY, v_O_BR_DVRY_PAY, v_O_BR_ST_DVRY_PAY, v_O_BR_ORD_MARGIN;
    CLOSE   CSR_HD_BR_PAY_INFO_O;
v_STEP := 'STEP_0_6';

--  // 배차_총판/지사 정산비율 정보
    OPEN    CSR_HD_BR_PAY_INFO_C (vi_CTH_HD_CODE, vi_CTH_BR_CODE);
    FETCH   CSR_HD_BR_PAY_INFO_C INTO v_C_HD_BR_CODE, v_C_HD_BR_VAT_YN, v_C_HD_SRV_PAY, v_C_HD_DVRY_PAY
                                        , v_C_BR_SRV_PAY, v_C_BR_DVRY_PAY;
    CLOSE   CSR_HD_BR_PAY_INFO_C;
v_STEP := 'STEP_0_7';

--  // 발주_배차 간 수발주비율 정보
    IF vi_ORD_BR_CODE <> vi_CTH_BR_CODE THEN

        OPEN    CSR_BR_SHARE_INFO (vi_ORD_HD_CODE, vi_ORD_BR_CODE, vi_ORD_ST_CODE, vi_CTH_HD_CODE, vi_CTH_BR_CODE);
        FETCH   CSR_BR_SHARE_INFO INTO v_O_CAL_RATE, v_O_CAL_WK_RATE, v_O_CAL_ST_RATE, v_O_CAL_SM_RATE;
        CLOSE   CSR_BR_SHARE_INFO;

    END IF;
v_STEP := 'STEP_0_8';

--  // 배차기사 봉사료수수료 정보
    OPEN    CSR_WK_S_PAY_INFO (vi_CTH_WK_CODE, vi_SRV_AMT);
    FETCH   CSR_WK_S_PAY_INFO INTO v_WK_SUPP_FIX, v_WK_SUPP_RATE;
    CLOSE   CSR_WK_S_PAY_INFO;
v_STEP := 'STEP_0_9';

--  // 배차지사 정보
    OPEN    CSR_BR_INFO_C (vi_CTH_BR_CODE);
    FETCH   CSR_BR_INFO_C INTO  v_DVRY_FEE_FIX, v_DVRY_FEE_VAT_YN, v_DIRECT_YN, v_WK_TAX_RATE, v_WK_TAX_YN, v_C_BR_VAT_YN, v_BR_DVRY_PAY_FLAG
                            , v_DVRY_BR_PAY_4_HQ, v_DVRY_BR_PAY_5_HQ, v_DVRY_BR_PAY_4_BR, v_DVRY_BR_PAY_5_BR, v_DVRY_BR_PAY_4_HD, v_DVRY_BR_PAY_5_HD
                            , v_BR_OPTION_YN_10;
    CLOSE   CSR_BR_INFO_C;

--  // 발주지사 정보
    OPEN    CSR_BR_INFO_O (vi_ORD_BR_CODE);
    FETCH   CSR_BR_INFO_O INTO  v_O_BR_VAT_YN, v_B2B_YN, v_O_DVRY_FEE_FIX, v_MATCH_YN;
    CLOSE   CSR_BR_INFO_O;

    -- 발주지사가 부가세대상이 아니면 가맹점부가세율=0%
    IF v_O_BR_VAT_YN = 'N' THEN
        v_VAT_RATE := 0;
        v_PAY_3_VAT_RATE := 0;
    END IF;

    IF v_VAT_RATE > 0 AND v_ST_OPTION_YN_7 = 'Y' AND (v_BR_OPTION_YN_10 = 'Y' OR v_B2B_YN = 'N') THEN
        v_HQ_BL_YN := 'Y'; -- 부가세/원천세본사귀속여부
    ELSIF v_VAT_RATE > 0 AND (v_ST_OPTION_YN_7 IN('S','G') AND v_B2B_YN = 'N') THEN
        v_HQ_BL_YN := v_ST_OPTION_YN_7; -- 부가세/원천세귀속구분 - 세무정산
    END IF;

    -- // 배달대행료(복수건 포함) 계산
    IF vi_DVRY_ADJ_AMT = 0 THEN
        v_DVRY_ADJ_AMT := (vi_DVRY_AMT * vi_DUP_ORDER_CNT);
    ELSE
        v_DVRY_ADJ_AMT := vi_DVRY_ADJ_AMT;
    END IF;

    -- // 기사지원금 설정(B2B가 아닌경우 발주지사부담) ==> 설정사항(MATCH_YN)으로 변경
    IF (v_MATCH_YN = 'Y' OR v_B2B_YN = 'N') AND vi_SUPP_AMT > 0 THEN
        v_SUPP_TOT     := vi_SUPP_AMT;
        v_DVRY_ADJ_AMT := GREATEST(v_DVRY_ADJ_AMT - v_SUPP_TOT,0);
        v_DVRY_PRCH_AMT := GREATEST(v_DVRY_PRCH_AMT - v_SUPP_TOT,0);
        IF v_C_BR_VAT_YN = 'Y' AND v_HQ_BL_YN = 'N' THEN -- 부가세/원천세 본사귀속 여부
            v_SUPP_VAT := v_SUPP_TOT * (10/100);
            v_SUPP_AMT := v_SUPP_TOT;
        ELSE
            v_SUPP_VAT := 0; -- FN_SYS_0132_GET_VAT(v_SUPP_TOT);
            v_SUPP_AMT := v_SUPP_TOT - v_SUPP_VAT;
        END IF;
    END IF;

    v_DVRY_SALS_AMT := v_DVRY_ADJ_AMT;
    v_DVRY_SALS_VAT := ROUND(v_DVRY_ADJ_AMT * v_VAT_RATE/100, 1);
    IF (v_DVRY_ADJ_AMT <> v_DVRY_PRCH_AMT AND v_DVRY_PRCH_AMT <> 0) THEN -- 매출매입이 다른 경우 매입기준으로 정산한다.
        v_DVRY_ADJ_AMT := v_DVRY_PRCH_AMT;
        v_DVRY_GAP_AMT := (v_DVRY_SALS_AMT - v_DVRY_PRCH_AMT);
        v_DVRY_GAP_VAT := ROUND(v_DVRY_GAP_AMT * v_VAT_RATE/100,1);
    END IF;
    v_DVRY_ORG_AMT := v_DVRY_ADJ_AMT;
    v_DVRY_ORG_VAT := ROUND(v_DVRY_ADJ_AMT * v_VAT_RATE/100, 1);

    -- 발주가맹점(본사귀속정산)이고 수행허브(본사귀속정산)인 경우
    IF v_HQ_BL_YN = 'Y' THEN
        v_DVRY_FEE_ADD_AMT := TRUNC((v_DVRY_ORG_AMT + v_SUPP_TOT) * 2/100,0);
        v_DVRY_FEE_ADD_VAT := TRUNC(v_DVRY_FEE_ADD_AMT * v_VAT_RATE/100,1);
        IF v_B2B_YN = 'N' THEN
            IF SYSDATE >= TO_DATE('20220101070000','YYYYMMDDHH24MISS') THEN
--            IF SYSDATE >= TO_DATE('20211223070000','YYYYMMDDHH24MISS') THEN
                v_DVRY_FEE_ADD_AMT := 50;
                v_DVRY_FEE_ADD_VAT := 5;
            ELSE
                v_DVRY_FEE_ADD_AMT := 100;
                v_DVRY_FEE_ADD_VAT := 10;
            END IF;
        END IF;
    ELSIF v_HQ_BL_YN = 'S' THEN
        v_DVRY_HQF_AMT := 50; -- 세무정산귀속-정산수수료
        v_DVRY_HQF_VAT := 5;  -- 세무정산귀속-정산수수료부가세
    ELSIF v_HQ_BL_YN = 'G' THEN
        v_DVRY_HQF_AMT := 30; -- 기장정산귀속-정산수수료
        v_DVRY_HQF_VAT := 3;  -- 기장정산귀속-정산수수료부가세
    END IF;

    -- 선차감 적용 지사설정
    IF v_HQ_BL_YN IN('S','G') THEN
        v_DVRY_ST_PAY_4_BR := 0; -- 지사     선차감액 정액
        v_DVRY_ST_PAY_4_HD := 0; -- 총판지사 선차감액 정액
        v_DVRY_ST_PAY_4_HQ := 0; -- 본사     선차감액 정액
        v_DVRY_ST_PAY_5_BR := 0; -- 지사     선차감액 정율
        v_DVRY_ST_PAY_5_HD := 0; -- 총판지사 선차감액 정율
        v_DVRY_ST_PAY_5_HQ := 0; -- 본사     선차감액 정율
    ELSIF v_PRCH_CHARGE > 0 THEN
        v_DVRY_ADJ_AMT := v_DVRY_PRCH_AMT;
        v_DVRY_ST_PAY_4_BR := v_PRCH_DVRY_PAY_4_BR; -- 지사     선차감액 정액
        v_DVRY_ST_PAY_4_HD := v_PRCH_DVRY_PAY_4_HD; -- 총판지사 선차감액 정액
        v_DVRY_ST_PAY_4_HQ := v_PRCH_DVRY_PAY_4_HQ; -- 본사     선차감액 정액
        v_DVRY_ST_PAY_5_BR := v_PRCH_DVRY_PAY_5_BR; -- 지사     선차감액 정율
        v_DVRY_ST_PAY_5_HD := v_PRCH_DVRY_PAY_5_HD; -- 총판지사 선차감액 정율
        v_DVRY_ST_PAY_5_HQ := v_PRCH_DVRY_PAY_5_HQ; -- 본사     선차감액 정율
    ELSIF v_VAT_RATE > 0 AND vi_DVRY_DISC_AMT < 0 THEN -- 묶음배송(할인금액<0)
        v_DVRY_ST_PAY_4_BR := v_DVRY_DC_PAY_4_BR; -- 지사     선차감액 정액
        v_DVRY_ST_PAY_4_HD := v_DVRY_DC_PAY_4_HD; -- 총판지사 선차감액 정액
        v_DVRY_ST_PAY_4_HQ := v_DVRY_DC_PAY_4_HQ; -- 본사     선차감액 정액
        v_DVRY_ST_PAY_5_BR := v_DVRY_DC_PAY_5_BR; -- 지사     선차감액 정율
        v_DVRY_ST_PAY_5_HD := v_DVRY_DC_PAY_5_HD; -- 총판지사 선차감액 정율
        v_DVRY_ST_PAY_5_HQ := v_DVRY_DC_PAY_5_HQ; -- 본사     선차감액 정율
    ELSIF v_VAT_RATE > 0 AND v_BR_DVRY_PAY_FLAG = 'B' THEN
        v_DVRY_ST_PAY_4_BR := v_DVRY_BR_PAY_4_BR; -- 지사     선차감액 정액
        v_DVRY_ST_PAY_4_HD := v_DVRY_BR_PAY_4_HD; -- 총판지사 선차감액 정액
        v_DVRY_ST_PAY_4_HQ := v_DVRY_BR_PAY_4_HQ; -- 본사     선차감액 정액
        v_DVRY_ST_PAY_5_BR := v_DVRY_BR_PAY_5_BR; -- 지사     선차감액 정율
        v_DVRY_ST_PAY_5_HD := v_DVRY_BR_PAY_5_HD; -- 총판지사 선차감액 정율
        v_DVRY_ST_PAY_5_HQ := v_DVRY_BR_PAY_5_HQ; -- 본사     선차감액 정율
    END IF;

    -- 선차감 할인적용
    IF ((v_DVRY_ST_PAY_4_BR+v_DVRY_ST_PAY_4_HD+v_DVRY_ST_PAY_4_HQ+v_DVRY_ST_PAY_5_BR+v_DVRY_ST_PAY_5_HD+v_DVRY_ST_PAY_5_HQ) > 0)
    AND v_PRCH_CHARGE = 0 -- 매입기준이 아닌 경우
    AND (v_DIS_DVRY_PAY_FLAG IN('A','B','S'))
    AND NOT(v_BR_DVRY_PAY_FLAG = 'B' AND v_DIS_DVRY_PAY_FLAG = 'S')
    AND NOT(v_BR_DVRY_PAY_FLAG = 'S' AND v_DIS_DVRY_PAY_FLAG = 'B') THEN
        v_DVRY_ST_PAY_4_BR := v_DVRY_ST_PAY_4_BR + v_DIS_DVRY_PAY_4_BR; -- 지사     선차감액 정액
        v_DVRY_ST_PAY_4_HD := v_DVRY_ST_PAY_4_HD + v_DIS_DVRY_PAY_4_HD; -- 총판지사 선차감액 정액
        v_DVRY_ST_PAY_4_HQ := v_DVRY_ST_PAY_4_HQ + v_DIS_DVRY_PAY_4_HQ; -- 본사     선차감액 정액
    END IF;

    -- 선차감 합계
    IF v_DVRY_ADJ_AMT > 0 THEN
        v_DVRY_ST_PAY_BR_AMT := GREATEST(v_DVRY_ST_PAY_4_BR + TRUNC((v_DVRY_ADJ_AMT + v_SUPP_AMT) * v_DVRY_ST_PAY_5_BR/100), 0); -- 지사     선차감액
        v_DVRY_ST_PAY_HD_AMT := GREATEST(v_DVRY_ST_PAY_4_HD + TRUNC((v_DVRY_ADJ_AMT + v_SUPP_AMT) * v_DVRY_ST_PAY_5_HD/100), 0); -- 총판지사 선차감액
        v_DVRY_ST_PAY_HQ_AMT := GREATEST(v_DVRY_ST_PAY_4_HQ + TRUNC((v_DVRY_ADJ_AMT + v_SUPP_AMT) * v_DVRY_ST_PAY_5_HQ/100), 0); -- 본사     선차감액
        v_DVRY_ST_PAY_TT_AMT := (v_DVRY_ST_PAY_HQ_AMT + v_DVRY_ST_PAY_HD_AMT + v_DVRY_ST_PAY_BR_AMT);
    END IF;
        
    IF v_DVRY_ST_PAY_HQ_AMT > 0 OR v_DVRY_ST_PAY_HD_AMT > 0 OR v_DVRY_ST_PAY_BR_AMT > 0 THEN
        v_DVRY_ADJ_AMT := v_DVRY_ORG_AMT - (v_DVRY_ST_PAY_TT_AMT);
    END IF;

    -- 선차감 부가세 할당
    IF v_C_BR_VAT_YN = 'Y' AND v_DVRY_ST_PAY_BR_AMT > 0 THEN
        v_DVRY_ST_PAY_BR_VAT := v_DVRY_ST_PAY_BR_AMT * v_VAT_RATE/100;
    END IF;
    IF v_C_HD_BR_VAT_YN = 'Y' AND v_DVRY_ST_PAY_HD_AMT > 0 THEN
        v_DVRY_ST_PAY_HD_VAT := v_DVRY_ST_PAY_HD_AMT * v_VAT_RATE/100;
    END IF;
    IF v_B2B_YN = 'Y' THEN -- B2B가맹점인 경우 차감 부가세를 본사로 귀속
        IF ((v_DVRY_ST_PAY_TT_AMT * v_VAT_RATE/100) -(v_DVRY_ST_PAY_BR_VAT + v_DVRY_ST_PAY_HD_VAT)) > 0 THEN
            v_DVRY_ST_PAY_HQ_VAT := (v_DVRY_ST_PAY_TT_AMT * v_VAT_RATE/100) - (v_DVRY_ST_PAY_BR_VAT + v_DVRY_ST_PAY_HD_VAT);
        END IF;
    ELSE                   -- 일반가맹점인 경우 차감 부가세를 발주지사로 귀속
        IF v_DVRY_ST_PAY_HQ_AMT > 0 THEN
            v_DVRY_ST_PAY_HQ_VAT := FN_SYS_0132_GET_VAT(v_DVRY_ST_PAY_HQ_AMT + (v_DVRY_ST_PAY_HQ_AMT * v_VAT_RATE/100));
            v_DVRY_ST_PAY_HQ_AMT := (v_DVRY_ST_PAY_HQ_AMT + (v_DVRY_ST_PAY_HQ_AMT * v_VAT_RATE/100)) - v_DVRY_ST_PAY_HQ_VAT;
        END IF;
        IF ((v_DVRY_ST_PAY_TT_AMT * v_VAT_RATE/100) -(v_DVRY_ST_PAY_BR_VAT + v_DVRY_ST_PAY_HD_VAT + v_DVRY_ST_PAY_HQ_VAT)) > 0 THEN
            v_DVRY_ST_PAY_OB_VAT := (v_DVRY_ST_PAY_TT_AMT * v_VAT_RATE/100) -(v_DVRY_ST_PAY_BR_VAT + v_DVRY_ST_PAY_HD_VAT + v_DVRY_ST_PAY_HQ_VAT);
        END IF;
        IF v_HQ_BL_YN = 'Y' AND v_DVRY_ST_PAY_OB_VAT <> 0 THEN -- 본사귀속정산인 경우 본사로 귀속
            v_DVRY_ST_PAY_HQ_VAT := v_DVRY_ST_PAY_HQ_VAT + v_DVRY_ST_PAY_OB_VAT;
            v_DVRY_ST_PAY_OB_VAT := 0;
        END IF;
    END IF;
    
    v_DVRY_ST_PAY_HQ_AMT := v_DVRY_ST_PAY_HQ_AMT + v_DVRY_GAP_AMT; -- 매입/매출 차액을 본사 선차감에 할당
    v_DVRY_ST_PAY_HQ_VAT := v_DVRY_ST_PAY_HQ_VAT + v_DVRY_GAP_VAT; -- 매입/매출 차액을 본사 선차감에 할당

    -- // 가맹점배달대행수수료
--    IF v_HQ_BL_YN = 'S' THEN
--        v_DVRY_ST_PAY_1 := 0;
--        v_DVRY_ST_PAY_2 := 0;
--    END IF;
    IF v_DVRY_ST_PAY_1 > 0 AND v_DVRY_ST_PAY_2 > 0.00 THEN
        v_DVRY_ST_PAY_MSG := '정액+정률, ';
    ELSIF v_DVRY_ST_PAY_1 > 0 THEN
        v_DVRY_ST_PAY_MSG := '정액, ';
    ELSIF v_DVRY_ST_PAY_2 > 0.00 THEN
        v_DVRY_ST_PAY_MSG := '정률, ';
    END IF;
    -- 가맹점배달대행수수료 합계
    v_DVRY_ST_L_PAY_AMT := (v_DVRY_ST_PAY_1 * vi_DUP_ORDER_CNT) + (v_DVRY_ORG_AMT * (v_DVRY_ST_PAY_2 / 100)); -- 정액 + 정률
    v_DVRY_ST_L_PAY_VAT := (v_DVRY_ST_L_PAY_AMT * (v_VAT_RATE/100));

    v_DVRY_ST_L_PAY_OBR_RATE := (v_O_BR_ST_DVRY_PAY / 100) * (v_O_CAL_ST_RATE / 100);
    v_DVRY_ST_L_PAY_CBR_RATE := (v_O_BR_ST_DVRY_PAY / 100) * ((100 - v_O_CAL_ST_RATE) / 100);
    v_DVRY_ST_L_PAY_OHD_RATE := (v_O_HD_ST_DVRY_PAY / 100);
    v_DVRY_ST_L_PAY_HQ_RATE  := ((100 - (v_O_HD_ST_DVRY_PAY + v_O_BR_ST_DVRY_PAY)) / 100);

    v_DVRY_ST_L_PAY_OBR_AMT := v_DVRY_ST_L_PAY_AMT * v_DVRY_ST_L_PAY_OBR_RATE;
    v_DVRY_ST_L_PAY_CBR_AMT := v_DVRY_ST_L_PAY_AMT * v_DVRY_ST_L_PAY_CBR_RATE;
    v_DVRY_ST_L_PAY_OHD_AMT := v_DVRY_ST_L_PAY_AMT * v_DVRY_ST_L_PAY_OHD_RATE;
    v_DVRY_ST_L_PAY_HQ_AMT  := v_DVRY_ST_L_PAY_AMT * v_DVRY_ST_L_PAY_HQ_RATE;
    -- 가맹점배달대행수수료 부가세 할당
    IF v_O_BR_VAT_YN = 'Y' AND v_DVRY_ST_L_PAY_OBR_AMT > 0 THEN
        v_DVRY_ST_L_PAY_OBR_VAT := TRUNC(v_DVRY_ST_L_PAY_VAT * v_DVRY_ST_L_PAY_OBR_RATE);
    END IF;
    IF v_C_BR_VAT_YN = 'Y' AND v_DVRY_ST_L_PAY_CBR_AMT > 0 THEN
        v_DVRY_ST_L_PAY_CBR_VAT := TRUNC(v_DVRY_ST_L_PAY_VAT * v_DVRY_ST_L_PAY_CBR_RATE);
    END IF;
    IF v_O_HD_BR_VAT_YN = 'Y' AND v_DVRY_ST_L_PAY_OHD_AMT > 0 THEN
        v_DVRY_ST_L_PAY_OHD_VAT := TRUNC(v_DVRY_ST_L_PAY_VAT * v_DVRY_ST_L_PAY_OHD_RATE);
    END IF;
    IF v_B2B_YN = 'Y' THEN -- B2B가맹점인 경우 차감 부가세를 본사로 귀속
        v_DVRY_ST_L_PAY_CBR_VAT := 0;
        IF (v_DVRY_ST_L_PAY_VAT - (v_DVRY_ST_L_PAY_OBR_VAT + v_DVRY_ST_L_PAY_CBR_VAT + v_DVRY_ST_L_PAY_OHD_VAT)) > 0 THEN
            v_DVRY_ST_L_PAY_HQ_VAT := (v_DVRY_ST_L_PAY_VAT - (v_DVRY_ST_L_PAY_OBR_VAT + v_DVRY_ST_L_PAY_CBR_VAT + v_DVRY_ST_L_PAY_OHD_VAT));
        END IF;
    ELSE                   -- 일반가맹점인 경우 차감 부가세를 발주지사로 귀속
        IF v_DVRY_ST_L_PAY_HQ_AMT > 0 THEN
            v_DVRY_ST_L_PAY_HQ_VAT := TRUNC(v_DVRY_ST_L_PAY_VAT * v_DVRY_ST_L_PAY_HQ_RATE);
        END IF;
        -- 차감부가세 = 가맹점차감 - (발주지사 + 수행지사 + 발주총판 + 본사) ==> 발주지사
        v_DVRY_ST_L_PAY_OB_VAT := v_DVRY_ST_L_PAY_VAT - (v_DVRY_ST_L_PAY_OBR_VAT + v_DVRY_ST_L_PAY_CBR_VAT + v_DVRY_ST_L_PAY_OHD_VAT + v_DVRY_ST_L_PAY_HQ_VAT);
        IF (v_DVRY_ST_L_PAY_OB_VAT) > 0 THEN
            v_DVRY_ST_L_PAY_OBR_VAT := v_DVRY_ST_L_PAY_OBR_VAT + v_DVRY_ST_L_PAY_OB_VAT;
        END IF;
    END IF;

    -- // 배달대행관리비
    IF v_DVRY_ST_M_PAY_1 > 0 AND v_DVRY_ST_M_PAY_2 > 0.00 THEN
        v_DVRY_ST_M_PAY_MSG := '정액+정률, ';
    ELSIF v_DVRY_ST_M_PAY_1 > 0 THEN
        v_DVRY_ST_M_PAY_MSG := '정액, ';
    ELSIF v_DVRY_ST_M_PAY_2 > 0.00 THEN
        v_DVRY_ST_M_PAY_MSG := '정률, ';
    END IF;

    -- 배달대행관리비 할당
    v_DVRY_ST_M_PAY_AMT := (v_DVRY_ST_M_PAY_1 * vi_DUP_ORDER_CNT) + (v_DVRY_ORG_AMT * (v_DVRY_ST_M_PAY_2 / 100)); -- 정액 + 정률
    v_DVRY_ST_M_PAY_VAT := (v_DVRY_ST_M_PAY_AMT * (v_PAY_3_VAT_RATE/100));

    -- 본사몫은 정산시 합계하여 발주지사로부터 차감함. 따라서, 지사비율 = 지사비율+본사비율(100-(총판비율+지사비율)) 로 처리함.
    v_O_BR_DVRY_ST_PAY := v_O_BR_DVRY_ST_PAY + (100 - (v_O_HD_DVRY_ST_PAY + v_O_BR_DVRY_ST_PAY));

    v_DVRY_ST_M_PAY_OBR_RATE := (v_O_BR_DVRY_ST_PAY / 100) * (v_O_CAL_SM_RATE / 100);
    v_DVRY_ST_M_PAY_CBR_RATE := (v_O_BR_DVRY_ST_PAY / 100) * ((100 - v_O_CAL_SM_RATE) / 100);
    v_DVRY_ST_M_PAY_OHD_RATE := (v_O_HD_DVRY_ST_PAY / 100);
    v_DVRY_ST_M_PAY_HQ_RATE  := 0; -- ((100 - (v_O_HD_DVRY_ST_PAY + v_O_BR_DVRY_ST_PAY)) / 100); -- 본사비율

    v_DVRY_ST_M_PAY_OBR_AMT := v_DVRY_ST_M_PAY_AMT * v_DVRY_ST_M_PAY_OBR_RATE;
    v_DVRY_ST_M_PAY_CBR_AMT := v_DVRY_ST_M_PAY_AMT * v_DVRY_ST_M_PAY_CBR_RATE;
    v_DVRY_ST_M_PAY_OHD_AMT := v_DVRY_ST_M_PAY_AMT * v_DVRY_ST_M_PAY_OHD_RATE;
    v_DVRY_ST_M_PAY_HQ_AMT  := v_DVRY_ST_M_PAY_AMT * v_DVRY_ST_M_PAY_HQ_RATE;
    -- 배달대행관리비 부가세 할당
    IF v_O_BR_VAT_YN = 'Y' AND v_DVRY_ST_M_PAY_OBR_AMT > 0 THEN
        v_DVRY_ST_M_PAY_OBR_VAT := TRUNC(v_DVRY_ST_M_PAY_VAT * v_DVRY_ST_M_PAY_OBR_RATE);
    END IF;
    IF v_C_BR_VAT_YN = 'Y' AND v_DVRY_ST_M_PAY_CBR_AMT > 0 THEN
        v_DVRY_ST_M_PAY_CBR_VAT := TRUNC(v_DVRY_ST_M_PAY_VAT * v_DVRY_ST_M_PAY_CBR_RATE);
    END IF;
    IF v_O_HD_BR_VAT_YN = 'Y' AND v_DVRY_ST_M_PAY_OHD_AMT > 0 THEN
        v_DVRY_ST_M_PAY_OHD_VAT := TRUNC(v_DVRY_ST_M_PAY_VAT * v_DVRY_ST_M_PAY_OHD_RATE);
    END IF;
    IF v_B2B_YN = 'Y' THEN -- B2B가맹점인 경우 차감 부가세를 본사로 귀속
        v_DVRY_ST_M_PAY_CBR_VAT := 0;
        IF (v_DVRY_ST_M_PAY_VAT - (v_DVRY_ST_M_PAY_OBR_VAT + v_DVRY_ST_M_PAY_CBR_VAT + v_DVRY_ST_M_PAY_OHD_VAT)) > 0 THEN
            v_DVRY_ST_M_PAY_HQ_VAT := (v_DVRY_ST_M_PAY_VAT - (v_DVRY_ST_M_PAY_OBR_VAT + v_DVRY_ST_M_PAY_CBR_VAT + v_DVRY_ST_M_PAY_OHD_VAT));
        END IF;
    ELSE                   -- 일반가맹점인 경우 차감 부가세를 발주지사로 귀속
        IF v_DVRY_ST_M_PAY_HQ_AMT > 0 THEN
            v_DVRY_ST_M_PAY_HQ_VAT := TRUNC(v_DVRY_ST_M_PAY_VAT * v_DVRY_ST_M_PAY_HQ_RATE);
        END IF;
        -- 차감부가세 = 가맹점차감 - (발주지사 + 수행지사 + 발주총판 + 본사) ==> 발주지사
        v_DVRY_ST_M_PAY_OB_VAT := v_DVRY_ST_M_PAY_VAT - (v_DVRY_ST_M_PAY_OBR_VAT + v_DVRY_ST_M_PAY_CBR_VAT + v_DVRY_ST_M_PAY_OHD_VAT + v_DVRY_ST_M_PAY_HQ_VAT);
        IF (v_DVRY_ST_M_PAY_OB_VAT) > 0 THEN
            v_DVRY_ST_M_PAY_OBR_VAT := v_DVRY_ST_M_PAY_OBR_VAT + v_DVRY_ST_M_PAY_OB_VAT;
        END IF;
    END IF;

    -- // 지사배달대행수수료
    IF v_VAT_RATE > 0 AND vi_DVRY_DISC_AMT < 0 AND v_B2B_YN = 'Y' THEN -- B2B 묶음배송(할인금<0)
        v_DVRY_FEE_FIX := 0;
    ELSIF v_B2B_YN = 'Y' AND vi_CTH_HD_CODE NOT IN('H0155','H0154') AND FN_SYS_0147_GET_B2B_YN(vi_CTH_HD_CODE) <> 'O_B2B' THEN -- B2B인 경우 발주지사배달대행수수료 정액으로 처리 함.
        v_DVRY_FEE_FIX := v_O_DVRY_FEE_FIX;
    ELSIF vi_DVRY_DISC_AMT < 0 THEN
        v_DVRY_FEE_FIX := v_DVRY_FEE_FIX * v_DVRY_FEE_DISC_RATE/100;
    END IF;
    v_DVRY_FEE_FIX_SUM := v_DVRY_FEE_FIX * v_DUP_ORDER_CNT;      -- 지사의 배달대행수수료 정액 합계
    v_DVRY_FEE_FIX_SUM_ORG := v_DVRY_FEE_FIX_SUM;

    v_DVRY_FEE_FIX_OBR_RATE := (v_O_BR_DVRY_PAY / 100) * (v_O_CAL_RATE / 100);
    v_DVRY_FEE_FIX_CBR_RATE := (v_O_BR_DVRY_PAY / 100) * ((100 - v_O_CAL_RATE) / 100);
    v_DVRY_FEE_FIX_OHD_RATE := (v_O_HD_DVRY_PAY / 100);
    v_DVRY_FEE_FIX_HQ_RATE  := ((100 - (v_O_HD_DVRY_PAY + v_O_BR_DVRY_PAY)) / 100);

    -- 지사배달대행수수료 할당
    IF v_B2B_YN = 'N' AND v_DVRY_FEE_VAT_YN = 'Y' THEN -- 일반수행_부가세포함
        v_DVRY_FEE_FIX_VAT := FN_SYS_0132_GET_VAT(v_DVRY_FEE_FIX_SUM);   -- 지사의 배달대행수수료 정액 합계 부가세
        v_DVRY_FEE_FIX_AMT := v_DVRY_FEE_FIX_SUM - v_DVRY_FEE_FIX_VAT;
    ELSE
        v_DVRY_FEE_FIX_VAT := v_DVRY_FEE_FIX_SUM * (10/100); -- 지사의 배달대행수수료 정액 합계 부가세
        v_DVRY_FEE_FIX_AMT := v_DVRY_FEE_FIX_SUM;
    END IF;
    v_DVRY_FEE_FIX_OBR_AMT := v_DVRY_FEE_FIX_AMT * v_DVRY_FEE_FIX_OBR_RATE; -- 지사의 배달대행수수료 정액 합계(발주지사몫)
    v_DVRY_FEE_FIX_CBR_AMT := v_DVRY_FEE_FIX_AMT * v_DVRY_FEE_FIX_CBR_RATE; -- 지사의 배달대행수수료 정액 합계(배차수행지사몫)
    v_DVRY_FEE_FIX_OHD_AMT := v_DVRY_FEE_FIX_AMT * v_DVRY_FEE_FIX_OHD_RATE; -- 지사의 배달대행수수료 정액 합계(발주총판몫)
    v_DVRY_FEE_FIX_HQ_AMT  := v_DVRY_FEE_FIX_AMT - (v_DVRY_FEE_FIX_OBR_AMT + v_DVRY_FEE_FIX_CBR_AMT + v_DVRY_FEE_FIX_OHD_AMT);  -- 지사의 배달대행수수료 정액 합계(본사몫)

    -- 지사배달대행수수료 부가세 할당
    IF v_O_BR_VAT_YN = 'Y' AND v_DVRY_FEE_FIX_OBR_AMT > 0 THEN
        v_DVRY_FEE_FIX_OBR_VAT := v_DVRY_FEE_FIX_VAT * v_DVRY_FEE_FIX_OBR_RATE; -- 지사의 배달대행수수료 정액 합계(발주지사몫)
    END IF;
    IF v_C_BR_VAT_YN = 'Y' AND v_DVRY_FEE_FIX_CBR_AMT > 0 THEN
        v_DVRY_FEE_FIX_CBR_VAT := v_DVRY_FEE_FIX_VAT * v_DVRY_FEE_FIX_CBR_RATE; -- 지사의 배달대행수수료 정액 합계(배차수행지사몫)
    END IF;
    IF v_O_HD_BR_VAT_YN = 'Y' AND v_DVRY_FEE_FIX_OHD_AMT > 0 THEN
        v_DVRY_FEE_FIX_OHD_VAT := v_DVRY_FEE_FIX_VAT * v_DVRY_FEE_FIX_OHD_RATE; -- 지사의 배달대행수수료 정액 합계(발주총판몫)
    END IF;

    -- (차감대상_수행지사 = 배분대상_지사인 경우 차액만 차감)
    IF v_DVRY_FEE_FIX_CBR_RATE > 0 THEN -- 차감(수행)지사 배분율이 있는 경우
        v_DVRY_FEE_FIX_SUM := v_DVRY_FEE_FIX_SUM - (v_DVRY_FEE_FIX_SUM * v_DVRY_FEE_FIX_CBR_RATE);
        v_DVRY_FEE_FIX_CBR_AMT := 0;
        v_DVRY_FEE_FIX_CBR_VAT := 0;
    END IF;
    IF vi_CTH_BR_CODE = vi_ORD_BR_CODE AND v_DVRY_FEE_FIX_OBR_RATE > 0 THEN
        v_DVRY_FEE_FIX_SUM := v_DVRY_FEE_FIX_SUM - (v_DVRY_FEE_FIX_SUM * v_DVRY_FEE_FIX_OBR_RATE);
        v_DVRY_FEE_FIX_OBR_AMT := 0;
        v_DVRY_FEE_FIX_OBR_VAT := 0;
    END IF;
    IF vi_CTH_BR_CODE = v_O_HD_BR_CODE AND v_DVRY_FEE_FIX_OHD_RATE > 0 THEN
        v_DVRY_FEE_FIX_SUM := v_DVRY_FEE_FIX_SUM - (v_DVRY_FEE_FIX_SUM * v_DVRY_FEE_FIX_OHD_RATE);
        v_DVRY_FEE_FIX_OHD_AMT := 0;
        v_DVRY_FEE_FIX_OHD_VAT := 0;
    END IF;

    -- 지사배달대행수수료 할당(v_DVRY_FEE_FIX_SUM 변경된 값으로 다시 계산한다.)
    IF v_B2B_YN = 'N' AND v_DVRY_FEE_VAT_YN = 'Y' THEN -- 일반수행_부가세포함
        v_DVRY_FEE_FIX_VAT := FN_SYS_0132_GET_VAT(v_DVRY_FEE_FIX_SUM);   -- 지사의 배달대행수수료 정액 합계 부가세
        v_DVRY_FEE_FIX_AMT := v_DVRY_FEE_FIX_SUM - v_DVRY_FEE_FIX_VAT;
    ELSE
        v_DVRY_FEE_FIX_VAT := v_DVRY_FEE_FIX_SUM * (10/100); -- 지사의 배달대행수수료 정액 합계 부가세
        v_DVRY_FEE_FIX_AMT := v_DVRY_FEE_FIX_SUM;
    END IF;
    v_DVRY_FEE_FIX_HQ_AMT  := v_DVRY_FEE_FIX_AMT - (v_DVRY_FEE_FIX_OBR_AMT + v_DVRY_FEE_FIX_CBR_AMT + v_DVRY_FEE_FIX_OHD_AMT);  -- 지사의 배달대행수수료 정액 합계(본사몫)
    IF (v_DVRY_FEE_FIX_VAT - (v_DVRY_FEE_FIX_OBR_VAT + v_DVRY_FEE_FIX_CBR_VAT + v_DVRY_FEE_FIX_OHD_VAT)) > 0 THEN
        v_DVRY_FEE_FIX_HQ_VAT := (v_DVRY_FEE_FIX_VAT - (v_DVRY_FEE_FIX_OBR_VAT + v_DVRY_FEE_FIX_CBR_VAT + v_DVRY_FEE_FIX_OHD_VAT));
    END IF;
    -- 지사수수료추가분 합산
    v_DVRY_FEE_FIX_AMT := v_DVRY_FEE_FIX_AMT + v_DVRY_FEE_ADD_AMT + v_DVRY_HQF_AMT;
    v_DVRY_FEE_FIX_VAT := v_DVRY_FEE_FIX_VAT + v_DVRY_FEE_ADD_VAT + v_DVRY_HQF_VAT;
    v_DVRY_FEE_FIX_SUM := v_DVRY_FEE_FIX_AMT + v_DVRY_FEE_FIX_VAT;

    --  // 배차기사 배달대행수수료 정보 - 적용가맹점별
    OPEN    CSR_WK_D_PAY_INFO_ST (vi_CTH_BR_CODE, v_DVRY_ADJ_AMT, vi_ORD_ST_CODE);
    FETCH   CSR_WK_D_PAY_INFO_ST INTO v_WK_FEE_FIX, v_WK_FEE_RATE, v_WK_DGRP_NAME, v_WK_DGRP_NO;
    CLOSE   CSR_WK_D_PAY_INFO_ST;
    IF (NVL(v_WK_FEE_FIX,0) + NVL(v_WK_FEE_RATE,0)) = 0 THEN
        --  // 배차기사 배달대행수수료 정보 - 적용기사별
        OPEN    CSR_WK_D_PAY_INFO_WK (vi_CTH_WK_CODE, v_DVRY_ADJ_AMT, vi_ORD_ST_CODE);
        FETCH   CSR_WK_D_PAY_INFO_WK INTO v_WK_FEE_FIX, v_WK_FEE_RATE, v_WK_DGRP_NAME, v_WK_DGRP_NO;
        CLOSE   CSR_WK_D_PAY_INFO_WK;
    END IF;

    -- // 기사의 배달대행수수료
    IF (vi_PARTNER_CODE = '0009') -- 추가결제(SYSTEM) 지원금추가
    OR (v_VAT_RATE > 0 AND vi_DVRY_DISC_AMT < 0 AND v_B2B_YN = 'Y') THEN -- B2B 묶음배송(할인금<0)
        v_WK_FEE_FIX := 0;
        v_WK_FEE_RATE := 0;
    ELSIF vi_DVRY_DISC_AMT < 0 THEN
        v_WK_FEE_FIX := TRUNC(v_WK_FEE_FIX * v_WK_FEE_DISC_RATE/100);
        v_WK_FEE_RATE := TRUNC(v_WK_FEE_RATE * v_WK_FEE_DISC_RATE/100);
    END IF;
    v_WK_FEE_FIX_SUM   := v_WK_FEE_FIX * v_DUP_ORDER_CNT;                                  -- 기사의 배달대행수수료 정액 합계
    v_WK_FEE_RATE_SUM  := TRUNC(v_DVRY_ADJ_AMT * (v_WK_FEE_RATE / 100));                   -- 기사의 배달대행수수료 정률 합계

    IF v_WK_FEE_FIX_SUM > 0 AND v_WK_FEE_RATE_SUM > 0 THEN
        v_WK_FEE_MSG := '정액+정률, ';
    ELSIF v_WK_FEE_FIX_SUM > 0 THEN
        v_WK_FEE_MSG := '정액, ';
    ELSIF v_WK_FEE_RATE_SUM > 0.00 THEN
        v_WK_FEE_MSG := '정률, ';
    END IF;
    v_WK_FEE_SUM := TRUNC(v_WK_FEE_FIX_SUM + v_WK_FEE_RATE_SUM);   -- 기사배달대행수수료총액
    v_WK_FEE_OBR_RATE := (v_O_CAL_WK_RATE / 100);                  -- 발주지사배분율
    -- // B2B 수행지사 기사배달대행수수료 허브수익처리
    IF v_HQ_BL_YN = 'Y' AND (v_DVRY_ADJ_AMT - v_WK_FEE_SUM) >= 0 THEN -- 부가세/원천세 본사귀속 여부
        v_WK_FEE_CBR_AMT := v_WK_FEE_SUM;
        v_WK_FEE_CBR_VAT := (v_WK_FEE_SUM * 10/100);
        v_WK_FEE_CBR_SUM := v_WK_FEE_CBR_AMT + v_WK_FEE_CBR_VAT;
        v_DVRY_ADJ_AMT := v_DVRY_ADJ_AMT - v_WK_FEE_SUM;
        IF v_B2B_YN = 'Y' THEN
            v_WK_FEE_OBR_AMT := 0;
            v_WK_FEE_OBR_VAT := 0;
            v_WK_FEE_OBR_SUM := 0;
        ELSE
            v_WK_FEE_OBR_SUM := TRUNC(v_WK_FEE_CBR_SUM * v_WK_FEE_OBR_RATE);   -- 발주지사할당총액
            v_WK_FEE_OBR_VAT := FN_SYS_0132_GET_VAT(v_WK_FEE_OBR_SUM);         -- 발주지사부가세액
            v_WK_FEE_OBR_AMT := v_WK_FEE_OBR_SUM - v_WK_FEE_OBR_VAT;           -- 발주지사공급가액
            v_WK_FEE_CBR_SUM := v_WK_FEE_CBR_SUM - v_WK_FEE_OBR_SUM;
            v_WK_FEE_CBR_AMT := v_WK_FEE_CBR_AMT - v_WK_FEE_OBR_AMT;
            v_WK_FEE_CBR_VAT := v_WK_FEE_CBR_VAT - v_WK_FEE_OBR_VAT;
        END IF;
        v_WK_FEE_SUM := 0; -- 라이더차감분배하지 않음
    ELSE
        v_WK_FEE_OBR_SUM := TRUNC(v_WK_FEE_SUM * v_WK_FEE_OBR_RATE);   -- 발주지사할당총액
        v_WK_FEE_OBR_VAT := FN_SYS_0132_GET_VAT(v_WK_FEE_OBR_SUM);     -- 발주지사부가세액
        v_WK_FEE_OBR_AMT := v_WK_FEE_OBR_SUM - v_WK_FEE_OBR_VAT;       -- 발주지사공급가액
    END IF;
    -- // 배달대행료 기사분
    IF v_HQ_BL_YN IN('S','G') THEN
        v_DVRY_PAY_WK_T := 0;
    ELSIF v_HQ_BL_YN = 'Y' AND (v_DVRY_ADJ_AMT + (v_SUPP_TOT) - v_WK_FEE_SUM) > 0 THEN
        v_DVRY_PAY_WK_T_HQ := TRUNC((v_DVRY_ADJ_AMT + (v_SUPP_TOT) - v_WK_FEE_SUM) * 3.3/100); -- 배달대행료 기사분 TAX
        v_DVRY_PAY_WK_T := 0;
    ELSIF (v_VAT_RATE > 0 OR v_WK_TAX_YN = 'Y') AND (v_DVRY_ADJ_AMT + (v_SUPP_TOT) - v_WK_FEE_SUM) > 0 THEN
        v_DVRY_PAY_WK_T := TRUNC((v_DVRY_ADJ_AMT + (v_SUPP_TOT) - v_WK_FEE_SUM) * v_WK_TAX_RATE/100); -- 배달대행료 기사분 TAX
    ELSE
        v_DVRY_PAY_WK_T := 0; -- 배달대행료 기사분 TAX
    END IF;

    v_DVRY_PAY_WK := v_DVRY_ADJ_AMT - v_DVRY_PAY_WK_T - v_DVRY_PAY_WK_T_HQ;

    -- 기사배달대행료 할당
    v_DVRY_PAY_WK_BR_AMT := v_DVRY_PAY_WK + v_DVRY_PAY_WK_T;

    -- 기사배달대행료 부가세 할당
    IF v_HQ_BL_YN = 'Y' THEN -- 부가세/원천세 본사귀속 여부
        v_DVRY_PAY_WK_HQ_VAT := v_DVRY_PAY_WK_BR_AMT * (v_VAT_RATE/100) + v_DVRY_PAY_WK_T_HQ * (v_VAT_RATE/100);
        IF v_C_BR_VAT_YN = 'N' THEN
            v_DVRY_PAY_WK_HQ_VAT := v_DVRY_PAY_WK_HQ_VAT + v_DVRY_ST_PAY_BR_VAT; -- 라이더 수수료 부가세 본사에 귀속
            v_DVRY_ST_PAY_BR_VAT := 0;
        END IF;
    ELSIF v_C_BR_VAT_YN = 'Y' AND v_DVRY_PAY_WK_BR_AMT <> 0 THEN
        v_DVRY_PAY_WK_BR_VAT := v_DVRY_PAY_WK_BR_AMT * (v_VAT_RATE/100);
    ELSE
        IF v_B2B_YN = 'Y' THEN -- B2B가맹점인 경우 차감 부가세를 본사로 귀속
            v_DVRY_PAY_WK_HQ_VAT := v_DVRY_PAY_WK_BR_AMT * (v_VAT_RATE/100);
        ELSE                   -- 일반가맹점인 경우 차감 부가세를 발주지사로 귀속
            v_DVRY_PAY_WK_OB_VAT := v_DVRY_PAY_WK_BR_AMT * (v_VAT_RATE/100);
        END IF;
    END IF;

    v_WK_SUPP_OHD_RATE := (v_O_HD_SRV_PAY / 100);
    v_WK_SUPP_OBR_RATE := ((v_O_BR_SRV_PAY / 100) * (v_O_CAL_RATE / 100));
    v_WK_SUPP_CBR_RATE := ((v_O_BR_SRV_PAY / 100) * ((100 - v_O_CAL_RATE) / 100));
    v_WK_SUPP_HQ_RATE  := ((100 - (v_O_HD_SRV_PAY + v_O_BR_SRV_PAY)) / 100);
    -- 봉사료수수료 할당
    v_WK_SUPP_SUM := (v_WK_SUPP_FIX * vi_DUP_ORDER_CNT) + (vi_SRV_AMT * vi_DUP_ORDER_CNT * (v_WK_SUPP_RATE / 100)); -- 정액 + 정률
    IF v_VAT_RATE = 0 THEN
        v_WK_SUPP_VAT := FN_SYS_0132_GET_VAT(v_WK_SUPP_SUM);   -- 지사의 배달대행수수료 정액 합계 부가세
        v_WK_SUPP_AMT := v_WK_SUPP_SUM - v_WK_SUPP_VAT;
    ELSE
        v_WK_SUPP_VAT := TRUNC(v_WK_SUPP_SUM * (v_VAT_RATE/100)); -- 지사의 배달대행수수료 정액 합계 부가세
        v_WK_SUPP_AMT := v_WK_SUPP_SUM;
    END IF;
    v_WK_SUPP_OHD_AMT := v_WK_SUPP_AMT * v_WK_SUPP_OHD_RATE;
    v_WK_SUPP_OBR_AMT := v_WK_SUPP_AMT * v_WK_SUPP_OBR_RATE;
    v_WK_SUPP_CBR_AMT := v_WK_SUPP_AMT * v_WK_SUPP_CBR_RATE;
    v_WK_SUPP_HQ_AMT  := v_WK_SUPP_AMT - (v_WK_SUPP_OHD_AMT + v_WK_SUPP_OBR_AMT + v_WK_SUPP_CBR_AMT);
    
    -- 봉사료수수료 부가세 할당
    IF v_O_HD_BR_VAT_YN = 'Y' AND v_WK_SUPP_OHD_AMT > 0 THEN
        v_WK_SUPP_OHD_VAT := v_WK_SUPP_VAT * v_WK_SUPP_OHD_RATE;
    END IF;
    IF v_O_BR_VAT_YN = 'Y' AND v_WK_SUPP_OBR_AMT > 0 THEN
        v_WK_SUPP_OBR_VAT := v_WK_SUPP_VAT * v_WK_SUPP_OBR_RATE;
    END IF;
    IF v_C_BR_VAT_YN = 'Y' AND v_WK_SUPP_CBR_AMT > 0 THEN
        v_WK_SUPP_CBR_VAT := v_WK_SUPP_VAT * v_WK_SUPP_CBR_RATE;
    END IF;
    IF v_B2B_YN = 'Y' THEN -- B2B가맹점인 경우 차감 부가세를 본사로 귀속
        IF (v_WK_SUPP_VAT - (v_WK_SUPP_OHD_VAT + v_WK_SUPP_OBR_VAT + v_WK_SUPP_CBR_VAT)) > 0 THEN
            v_WK_SUPP_HQ_VAT := (v_WK_SUPP_VAT - (v_WK_SUPP_OHD_VAT + v_WK_SUPP_OBR_VAT + v_WK_SUPP_CBR_VAT));
        END IF;
    ELSE                   -- 일반가맹점인 경우 차감 부가세를 발주지사로 귀속
        IF v_WK_SUPP_HQ_AMT > 0 THEN
            v_WK_SUPP_HQ_VAT := (v_WK_SUPP_VAT - (v_WK_SUPP_OHD_VAT + v_WK_SUPP_OBR_VAT + v_WK_SUPP_CBR_VAT));
        END IF;

        IF (v_WK_SUPP_VAT - (v_WK_SUPP_OHD_VAT + v_WK_SUPP_OBR_VAT + v_WK_SUPP_CBR_VAT + v_WK_SUPP_HQ_VAT)) > 0 THEN
            v_WK_SUPP_OB_VAT := v_WK_SUPP_VAT - (v_WK_SUPP_OHD_VAT + v_WK_SUPP_OBR_VAT + v_WK_SUPP_CBR_VAT + v_WK_SUPP_HQ_VAT);
            v_WK_SUPP_OBR_VAT := v_WK_SUPP_OBR_VAT + v_WK_SUPP_OB_VAT;
        END IF;
    END IF;
    
    v_DVRY_ST_M_PAY_OBR_AMT := v_DVRY_ST_M_PAY_AMT;
    v_DVRY_ST_M_PAY_OBR_VAT := v_DVRY_ST_M_PAY_VAT;
    IF v_HQ_BL_YN IN('S','G') THEN -- 부가세/원천세귀속구분 - 세무정산
        v_DVRY_HQS_VAT := v_DVRY_SALS_VAT; --  + v_DVRY_ST_L_PAY_VAT; --  + v_DVRY_ST_M_PAY_OBR_VAT;
        v_DVRY_ST_PAY_BR_VAT := 0;
        v_DVRY_ST_PAY_OB_VAT := 0;
        v_DVRY_ST_PAY_HD_VAT := 0;
        v_DVRY_ST_PAY_HQ_VAT := 0;
        v_WK_FEE_CBR_VAT :=0;
--        v_DVRY_ST_L_PAY_OHD_VAT := 0;
--        v_DVRY_ST_L_PAY_OBR_VAT := 0;
--        v_DVRY_ST_L_PAY_CBR_VAT := 0;
--        v_DVRY_ST_L_PAY_HQ_VAT  := 0;
--        v_DVRY_ST_M_PAY_OBR_VAT := 0;
--        v_DVRY_ST_M_PAY_OHD_VAT := 0;
--        v_DVRY_ST_M_PAY_CBR_VAT := 0;
        v_DVRY_PAY_WK_BR_VAT := 0;
        v_DVRY_PAY_WK_OB_VAT := 0;
    END IF;

v_STEP := 'STEP_0_3';
---------------------------------------- 배달대행관련 시작 ----------------------------------------
--  // 배달대행료
--  // 1. 발주 가맹점캐쉬로 배달대행료 지불 (배달대행료 > 0)
    IF (vi_DVRY_PAY_TYPE = '2') AND (v_DVRY_SALS_AMT + (v_SUPP_AMT+v_SUPP_VAT) > 0) 
    AND (v_DVRY_SALS_AMT + v_SUPP_AMT) > (v_DVRY_ST_PAY_BR_AMT) -- 배달대행료 상점 차감액 > 허브선차감
    THEN
--      1-1. 발주 가맹점/ 캐쉬 차감/ (배달대행료 * 복수건수)            => A1
        IF (v_DVRY_SALS_AMT > 0) THEN
            INSERT INTO ALD_ADJ_ST_CASH_LOG
                        (HD_CODE, BR_CODE, ST_CODE, ST_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, ST_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_ORD_HD_CODE, vi_ORD_BR_CODE, vi_ORD_ST_CODE, 'A1'
                        , -(v_DVRY_SALS_AMT + v_DVRY_SALS_VAT),  -v_DVRY_SALS_AMT, -v_DVRY_SALS_VAT
                        , vi_ORD_NO, vi_DUP_ORDER_CNT||'건', 'SYSTEM');
        END IF;

--      1-2. 배달대행료-발주지사기사지원금 차감      => A5
        IF (v_SUPP_AMT+v_SUPP_VAT) > 0 THEN
            INSERT INTO ALD_ADJ_BR_CASH_LOG
                        (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_ORD_HD_CODE, vi_ORD_BR_CODE, 'A5'
                        , -(v_SUPP_AMT+v_SUPP_VAT), -v_SUPP_AMT, -v_SUPP_VAT
                        , vi_ORD_NO, vi_DUP_ORDER_CNT||'건, 기사지원금', 'SYSTEM');
        END IF;

--      1-2. 배달대행료-수행지사선차감분-충전      => A1
        IF (v_DVRY_ST_PAY_BR_AMT + v_DVRY_ST_PAY_BR_VAT) > 0 THEN
            INSERT INTO ALD_ADJ_BR_CASH_LOG
                        (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_CTH_HD_CODE, vi_CTH_BR_CODE, 'A1'
                        , (v_DVRY_ST_PAY_BR_AMT + v_DVRY_ST_PAY_BR_VAT), v_DVRY_ST_PAY_BR_AMT, v_DVRY_ST_PAY_BR_VAT
                        , vi_ORD_NO, vi_DUP_ORDER_CNT||'건, 선차감['||vi_ORD_ST_CODE||']'||vi_ORD_ST_NAME||', ['||vi_CTH_WK_CODE||']'||vi_CTH_WK_NAME, 'SYSTEM');
        END IF;

--      1-2. 라이더-배달대행수수료-충전      => C3
        IF (v_WK_FEE_SUM = 0) AND (v_WK_FEE_CBR_SUM + v_WK_FEE_OBR_SUM) > 0 THEN
            IF v_WK_FEE_CBR_SUM > 0 THEN
                INSERT INTO ALD_ADJ_BR_CASH_LOG
                            (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                            , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
                VALUES      (vi_CTH_HD_CODE, vi_CTH_BR_CODE, 'C3'
                            , (v_WK_FEE_CBR_AMT + v_WK_FEE_CBR_VAT), v_WK_FEE_CBR_AMT, v_WK_FEE_CBR_VAT
                            , vi_ORD_NO, '라이더수수료['||vi_ORD_ST_CODE||']'||vi_ORD_ST_NAME||',', 'SYSTEM');
            END IF;
            IF v_WK_FEE_OBR_SUM > 0 THEN
    --      3-2-1. 발주지사/ 캐쉬 충전/               => C3
                INSERT INTO ALD_ADJ_BR_CASH_LOG
                            (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                            , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
                VALUES      (vi_ORD_HD_CODE, vi_ORD_BR_CODE, 'C3'
                            , (v_WK_FEE_OBR_AMT + v_WK_FEE_OBR_VAT), v_WK_FEE_OBR_AMT, v_WK_FEE_OBR_VAT
                            , vi_ORD_NO, v_WK_FEE_MSG||', '||vi_DUP_ORDER_CNT||'건, 라이더수수료['||vi_CTH_WK_CODE||']'||vi_CTH_WK_NAME, 'SYSTEM')
                ;
            END IF;
        END IF;
        
--      1-2. 배달대행료-수행총판선차감분-충전      => A1
        IF (v_DVRY_ST_PAY_HD_AMT + v_DVRY_ST_PAY_HD_VAT) > 0 THEN
            INSERT INTO ALD_ADJ_BR_CASH_LOG
                        (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_CTH_HD_CODE, v_C_HD_BR_CODE, 'A1'
                        , (v_DVRY_ST_PAY_HD_AMT + v_DVRY_ST_PAY_HD_VAT), v_DVRY_ST_PAY_HD_AMT, v_DVRY_ST_PAY_HD_VAT
                        , vi_ORD_NO, vi_DUP_ORDER_CNT||'건, 선차감['||vi_ORD_ST_CODE||']'||vi_ORD_ST_NAME||', ['||vi_CTH_WK_CODE||']'||vi_CTH_WK_NAME, 'SYSTEM');
        END IF;

--      1-2. 배달대행료-발주지사(부가세여부='N')수행지사부가세-충전      => A1
        IF v_DVRY_ST_PAY_OB_VAT > 0 THEN
            INSERT INTO ALD_ADJ_BR_CASH_LOG
                        (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_ORD_HD_CODE, vi_ORD_BR_CODE, 'A1'
                        , (v_DVRY_ST_PAY_OB_VAT), 0, v_DVRY_ST_PAY_OB_VAT
                        , vi_ORD_NO, vi_DUP_ORDER_CNT||'건, 지사선차감부가세['||vi_ORD_ST_CODE||']'||vi_ORD_ST_NAME||', ['||vi_CTH_BR_CODE||']'||vi_CTH_WK_NAME, 'SYSTEM');
        END IF;
--      1-3. 배차기사 소속지사/ 캐쉬 충전       => A3
        IF (v_DVRY_PAY_WK_BR_AMT + v_DVRY_PAY_WK_BR_VAT + v_SUPP_AMT + v_SUPP_VAT) > 0 THEN
            INSERT INTO ALD_ADJ_BR_CASH_LOG
                        (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_CTH_HD_CODE, vi_CTH_BR_CODE, 'A3'
                        , (v_DVRY_PAY_WK_BR_AMT + v_SUPP_AMT) + (v_DVRY_PAY_WK_BR_VAT + v_SUPP_VAT)
                        , (v_DVRY_PAY_WK_BR_AMT + v_SUPP_AMT) , (v_DVRY_PAY_WK_BR_VAT + v_SUPP_VAT)
                        , vi_ORD_NO, vi_DUP_ORDER_CNT||'건, ['||vi_ORD_ST_CODE||']'||vi_ORD_ST_NAME||', ['||vi_CTH_WK_CODE||']'||vi_CTH_WK_NAME
                        , 'SYSTEM');
        END IF;
--      1-4. 기사배달대행료_부가세-발주지사귀속-충전
        IF v_DVRY_PAY_WK_OB_VAT > 0 THEN
            INSERT INTO ALD_ADJ_BR_CASH_LOG
                        (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_ORD_HD_CODE, vi_ORD_BR_CODE, 'A3'
                        , (v_DVRY_PAY_WK_OB_VAT), 0, v_DVRY_PAY_WK_OB_VAT
                        , vi_ORD_NO, vi_DUP_ORDER_CNT||'건, 기사배달대행료_부가세['||vi_ORD_ST_CODE||']'||vi_ORD_ST_NAME||', ['||vi_CTH_BR_CODE||']'||vi_CTH_WK_NAME, 'SYSTEM');
        END IF;

--      1-2. 배달대행료-본사선차감분-충전
        IF (v_DVRY_ST_PAY_HQ_AMT + v_DVRY_ST_PAY_HQ_VAT) <> 0 THEN
            INSERT INTO ALD_ADJ_HQ_CASH_LOG
                        (HD_CODE, BR_CODE, ST_CODE, HQ_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, HQ_CASH_MEMO)
            VALUES      (vi_ORD_HD_CODE, vi_ORD_BR_CODE, vi_ORD_ST_CODE, 'A1'
                        , (v_DVRY_ST_PAY_HQ_AMT + v_DVRY_ST_PAY_HQ_VAT), v_DVRY_ST_PAY_HQ_AMT, v_DVRY_ST_PAY_HQ_VAT
                        , vi_ORD_NO, vi_DUP_ORDER_CNT||'건, 선차감['||vi_ORD_ST_CODE||']'||vi_ORD_ST_NAME||', ['||vi_CTH_WK_CODE||']'||vi_CTH_WK_NAME);
        END IF;
--      1-4. 기사배달대행료_부가세-본사-충전
        IF v_DVRY_PAY_WK_HQ_VAT > 0 THEN
            INSERT INTO ALD_ADJ_HQ_CASH_LOG
                        (HD_CODE, BR_CODE, WK_CODE, HQ_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, HQ_CASH_MEMO)
            VALUES      (vi_CTH_HD_CODE, vi_CTH_BR_CODE, vi_CTH_WK_CODE, 'A3'
                        , (v_DVRY_PAY_WK_HQ_VAT), 0, v_DVRY_PAY_WK_HQ_VAT
                        , vi_ORD_NO, vi_DUP_ORDER_CNT||'건, 기사배달대행료_부가세');
        END IF;
--      1-5. 배차기사/ 캐쉬 충전/ (배달대행료 * 복수건수)               => A3
        IF v_DVRY_PAY_WK_BR_AMT + (v_SUPP_AMT) > 0 THEN
            INSERT INTO ALD_ADJ_WK_CASH_LOG
                        (WK_CODE, HD_CODE, BR_CODE, WK_CASH_TYPE_CD
                        , ADD_CASH, ORD_NO, WK_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_CTH_WK_CODE, vi_CTH_HD_CODE, vi_CTH_BR_CODE, 'A3'
                        , (v_DVRY_PAY_WK_BR_AMT + (v_SUPP_AMT)), vi_ORD_NO
                        , vi_DUP_ORDER_CNT||'건, ['||vi_ORD_ST_CODE||']'||vi_ORD_ST_NAME, 'SYSTEM');
        END IF;
--      1-6. 배차기사/ 캐쉬 차감/ -(기사원천세)               => T1
        IF v_DVRY_PAY_WK_T > 0 THEN
            INSERT INTO ALD_ADJ_WK_CASH_LOG
                        (WK_CODE, HD_CODE, BR_CODE, WK_CASH_TYPE_CD, ADD_CASH, ORD_NO, WK_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_CTH_WK_CODE, vi_CTH_HD_CODE, vi_CTH_BR_CODE, 'T1'
                        , -(v_DVRY_PAY_WK_T), vi_ORD_NO
                        , vi_DUP_ORDER_CNT||'건, ['||vi_ORD_ST_CODE||']'||vi_ORD_ST_NAME
                            ||',배달대행료('||(v_DVRY_PAY_WK_BR_AMT + (v_SUPP_AMT) - (v_WK_FEE_SUM))||')의 원천세('||(v_WK_TAX_RATE)||'%)'
                        , 'SYSTEM');
        END IF;
--      1-7. 배차기사/ 본사-충전/ (기사원천세)              => T1
        IF v_DVRY_PAY_WK_T_HQ > 0 THEN
            INSERT INTO ALD_ADJ_HQ_CASH_LOG
                        (HD_CODE, BR_CODE, WK_CODE, HQ_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, HQ_CASH_MEMO)
            VALUES      (vi_CTH_HD_CODE, vi_CTH_BR_CODE, vi_CTH_WK_CODE, 'T1'
                        , (v_DVRY_PAY_WK_T_HQ), v_DVRY_PAY_WK_T_HQ, 0
                        , vi_ORD_NO, vi_DUP_ORDER_CNT||',배달대행료('
                        ||(v_DVRY_PAY_WK_BR_AMT + (v_SUPP_AMT) + (v_DVRY_PAY_WK_T_HQ))||')의 원천세('||(v_WK_TAX_RATE)||'%)');
        END IF;
    END IF;

v_STEP := 'STEP_1';

--  // 가맹점: 배달대행수수료
--  // 2-1. 건당 배달가맹비_정액/정률 차감
--    IF v_DVRY_ST_PAY_1 > 0 AND vi_PARTNER_CODE <> '0009' AND v_VAT_RATE = 0 THEN -- 추가결제(SYSTEM) 제외(20150609), 부가세대상(브렌드가맹점)인 경우 제외
    IF v_DVRY_ST_L_PAY_AMT > 0 AND vi_PARTNER_CODE <> '0009' THEN -- 추가결제(SYSTEM) 제외(20150609)

--      2-1-1. 가맹점/ 캐쉬 차감/ (건당 배달가맹비 정액 * 복수건수)      => L1
        INSERT INTO ALD_ADJ_ST_CASH_LOG
                    (HD_CODE, BR_CODE, ST_CODE, ST_CASH_TYPE_CD
                    , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, ST_CASH_MEMO, IN_USR_ID)
        VALUES      (vi_ORD_HD_CODE, vi_ORD_BR_CODE, vi_ORD_ST_CODE, 'L1'
                    , -(v_DVRY_ST_L_PAY_AMT + v_DVRY_ST_L_PAY_VAT), -v_DVRY_ST_L_PAY_AMT, -v_DVRY_ST_L_PAY_VAT
                    , vi_ORD_NO, v_DVRY_ST_PAY_MSG||vi_DUP_ORDER_CNT||'건', 'SYSTEM');

--      2-1-2. 가맹점 소속 총판지사/에 충전/ (건당 배달가맹비 정액 * 복수건수) * (배달가맹비 처리총판수익% / 100)     => L1 (배달대행수수료 처리총판수익)
        IF (v_DVRY_ST_L_PAY_OHD_AMT + v_DVRY_ST_L_PAY_OHD_VAT) > 0 THEN
            INSERT INTO ALD_ADJ_BR_CASH_LOG
                        (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_ORD_HD_CODE, v_O_HD_BR_CODE, 'L1'
                        , (v_DVRY_ST_L_PAY_OHD_AMT + v_DVRY_ST_L_PAY_OHD_VAT), v_DVRY_ST_L_PAY_OHD_AMT, v_DVRY_ST_L_PAY_OHD_VAT
                        , vi_ORD_NO, v_DVRY_ST_PAY_MSG||vi_DUP_ORDER_CNT||'건, ['||vi_ORD_ST_CODE||']'||vi_ORD_ST_NAME, 'SYSTEM');
        END IF;

--      2-1-3. 가맹점 소속 지사/에 충전/ (건당 배달가맹비 정액 * 복수건수) * (배달가맹비 지사수익% / 100)         => L2
        IF (v_DVRY_ST_L_PAY_OBR_AMT + v_DVRY_ST_L_PAY_OBR_VAT) > 0 THEN
            INSERT INTO ALD_ADJ_BR_CASH_LOG
                        (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_ORD_HD_CODE, vi_ORD_BR_CODE, 'L2'
                        , (v_DVRY_ST_L_PAY_OBR_AMT + v_DVRY_ST_L_PAY_OBR_VAT), v_DVRY_ST_L_PAY_OBR_AMT, (v_DVRY_ST_L_PAY_OBR_VAT)
                        , vi_ORD_NO, v_DVRY_ST_PAY_MSG||vi_DUP_ORDER_CNT||'건, ['||vi_ORD_ST_CODE||']'||vi_ORD_ST_NAME, 'SYSTEM');
        END IF;

--      2-1-4. 가맹점 수행 지사/에 충전/ (건당 배달가맹비 정액 * 복수건수) * (배달가맹비 지사수익% / 100)         => L2
        IF (v_DVRY_ST_L_PAY_CBR_AMT + v_DVRY_ST_L_PAY_CBR_VAT) > 0 THEN
            INSERT INTO ALD_ADJ_BR_CASH_LOG
                        (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_CTH_HD_CODE, vi_CTH_BR_CODE, 'L2'
                        , (v_DVRY_ST_L_PAY_CBR_AMT + v_DVRY_ST_L_PAY_CBR_VAT), v_DVRY_ST_L_PAY_CBR_AMT, (v_DVRY_ST_L_PAY_CBR_VAT)
                        , vi_ORD_NO, v_DVRY_ST_PAY_MSG||vi_DUP_ORDER_CNT||'건, ['||vi_ORD_ST_CODE||']'||vi_ORD_ST_NAME, 'SYSTEM');
        END IF;

--      2-1.5. 본사에 충전 => L1
        IF (v_DVRY_ST_L_PAY_HQ_AMT + v_DVRY_ST_L_PAY_HQ_VAT) > 0 THEN
            INSERT INTO ALD_ADJ_HQ_CASH_LOG
                        (HD_CODE, BR_CODE, ST_CODE, HQ_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, HQ_CASH_MEMO)
            VALUES      (vi_ORD_HD_CODE, vi_ORD_BR_CODE, vi_ORD_ST_CODE, 'L1'
                        , (v_DVRY_ST_L_PAY_HQ_AMT + v_DVRY_ST_L_PAY_HQ_VAT), v_DVRY_ST_L_PAY_HQ_AMT, v_DVRY_ST_L_PAY_HQ_VAT
                        , vi_ORD_NO, v_DVRY_ST_PAY_MSG||vi_DUP_ORDER_CNT||'건');
        END IF;

    END IF;
v_STEP := 'STEP_2';

--  // 가맹점: 배달가맹관리비(20140724)
--  20140809 발주가맹점 소속 총판, 지사, 본사 비율 수정 (배달수수료비율 -> 배달가맹비율)
--  // 2-3. 건당 배달가맹비_정액 차감 -- 부가세대상(브렌드가맹점)인 경우 제외
    IF v_DVRY_ST_M_PAY_AMT > 0 AND vi_PARTNER_CODE <> '0009' THEN

--      2-3-1. 가맹점/ 캐쉬 차감/ (건당 배달가맹비 정액 * 복수건수)      => B1
        INSERT INTO ALD_ADJ_ST_CASH_LOG
                    (HD_CODE, BR_CODE, ST_CODE, ST_CASH_TYPE_CD
                    , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, ST_CASH_MEMO, IN_USR_ID)
        VALUES      (vi_ORD_HD_CODE, vi_ORD_BR_CODE, vi_ORD_ST_CODE, 'B1'
                    , -(v_DVRY_ST_M_PAY_AMT + v_DVRY_ST_M_PAY_VAT), -(v_DVRY_ST_M_PAY_AMT), -(v_DVRY_ST_M_PAY_VAT)
                    , vi_ORD_NO, v_DVRY_ST_M_PAY_MSG||vi_DUP_ORDER_CNT||'건', 'SYSTEM');

--      2-3-2. 가맹점 소속 지사/에 충전/ (건당 배달가맹비 정액 * 복수건수) * (배달가맹비 지사수익% / 100)         => B2
        INSERT INTO ALD_ADJ_BR_CASH_LOG
                (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
        VALUES  (vi_ORD_HD_CODE, vi_ORD_BR_CODE, 'B2'
                , (v_DVRY_ST_M_PAY_OBR_AMT + v_DVRY_ST_M_PAY_OBR_VAT), (v_DVRY_ST_M_PAY_OBR_AMT), (v_DVRY_ST_M_PAY_OBR_VAT)
                , vi_ORD_NO, v_DVRY_ST_M_PAY_MSG||vi_DUP_ORDER_CNT||'건, ['||vi_ORD_ST_CODE||']'||vi_ORD_ST_NAME, 'SYSTEM');

--      2-3-3. 가맹점 소속 총판지사/에 충전/ (건당 배달가맹비 정액 * 복수건수) * (배달가맹비 처리총판수익% / 100)     => B1 (배달가맹관리비 처리총판수익)
        IF (v_DVRY_ST_M_PAY_OHD_AMT + v_DVRY_ST_M_PAY_OHD_VAT) > 0 THEN

            INSERT INTO ALD_ADJ_BR_CASH_LOG
                    (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                    , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES  (vi_ORD_HD_CODE, vi_ORD_BR_CODE, 'B2'
                    , -(v_DVRY_ST_M_PAY_OHD_AMT + v_DVRY_ST_M_PAY_OHD_VAT), -(v_DVRY_ST_M_PAY_OHD_AMT), -(v_DVRY_ST_M_PAY_OHD_VAT)
                    , vi_ORD_NO, v_DVRY_ST_M_PAY_MSG||vi_DUP_ORDER_CNT||'건, ['||vi_ORD_ST_CODE||']'||vi_ORD_ST_NAME, 'SYSTEM');

            INSERT INTO ALD_ADJ_BR_CASH_LOG
                    (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                    , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES  (vi_ORD_HD_CODE, v_O_HD_BR_CODE, 'B1'
                    , (v_DVRY_ST_M_PAY_OHD_AMT + v_DVRY_ST_M_PAY_OHD_VAT), (v_DVRY_ST_M_PAY_OHD_AMT), (v_DVRY_ST_M_PAY_OHD_VAT)
                    , vi_ORD_NO, v_DVRY_ST_M_PAY_MSG||vi_DUP_ORDER_CNT||'건, ['||vi_ORD_ST_CODE||']'||vi_ORD_ST_NAME, 'SYSTEM');

        END IF;

--      2-3-4. 수행 지사/에 충전
        IF (v_DVRY_ST_M_PAY_CBR_AMT + v_DVRY_ST_M_PAY_CBR_VAT) > 0 THEN

            INSERT INTO ALD_ADJ_BR_CASH_LOG
                    (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                    , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES  (vi_ORD_HD_CODE, vi_ORD_BR_CODE, 'B2'
                    , -(v_DVRY_ST_M_PAY_CBR_AMT + v_DVRY_ST_M_PAY_CBR_VAT), -(v_DVRY_ST_M_PAY_CBR_AMT), -(v_DVRY_ST_M_PAY_CBR_VAT)
                    , vi_ORD_NO, v_DVRY_ST_M_PAY_MSG||vi_DUP_ORDER_CNT||'건, ['||vi_ORD_ST_CODE||']'||vi_ORD_ST_NAME, 'SYSTEM');

            INSERT INTO ALD_ADJ_BR_CASH_LOG
                    (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                    , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES  (vi_CTH_HD_CODE, vi_CTH_BR_CODE, 'B2'
                    , (v_DVRY_ST_M_PAY_CBR_AMT + v_DVRY_ST_M_PAY_CBR_VAT), (v_DVRY_ST_M_PAY_CBR_AMT), (v_DVRY_ST_M_PAY_CBR_VAT)
                    , vi_ORD_NO, v_DVRY_ST_M_PAY_MSG||vi_DUP_ORDER_CNT||'건, ['||vi_ORD_ST_CODE||']'||vi_ORD_ST_NAME, 'SYSTEM');

        END IF;

--      2-3.5. 본사에 충전 => B1
        /**
        IF (v_DVRY_ST_M_PAY_HQ_AMT + v_DVRY_ST_M_PAY_HQ_VAT) > 0 THEN

            INSERT INTO ALD_ADJ_HQ_CASH_LOG
                    (HD_CODE, BR_CODE, ST_CODE, HQ_CASH_TYPE_CD
                    , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, HQ_CASH_MEMO)
            VALUES  (vi_ORD_HD_CODE, vi_ORD_BR_CODE, vi_ORD_ST_CODE, 'B1'
                    , (v_DVRY_ST_M_PAY_HQ_AMT + v_DVRY_ST_M_PAY_HQ_VAT), (v_DVRY_ST_M_PAY_HQ_AMT), (v_DVRY_ST_M_PAY_HQ_VAT)
                    , vi_ORD_NO, v_DVRY_ST_M_PAY_MSG||vi_DUP_ORDER_CNT||'건');

        END IF;
        **/
    END IF;

v_STEP := 'STEP_5';
--  // 기사: 배달대행수수료
    IF (v_WK_FEE_SUM <> 0) AND (v_DVRY_ADJ_AMT > 0) AND vi_PARTNER_CODE <> '0009' THEN
--      3-1-1. 배차기사/ 캐쉬 차감/ (건당 배달대행수수료 정액 * 복수건수)              => C1
        INSERT INTO ALD_ADJ_WK_CASH_LOG
                    (WK_CODE, HD_CODE, BR_CODE, WK_CASH_TYPE_CD
                    , ADD_CASH, ORD_NO, WK_CASH_MEMO, IN_USR_ID)
        VALUES      (vi_CTH_WK_CODE, vi_CTH_HD_CODE, vi_CTH_BR_CODE, 'C1'
                    , -(v_WK_FEE_SUM), vi_ORD_NO, v_WK_FEE_MSG||', '||vi_DUP_ORDER_CNT||'건,'||v_WK_DGRP_NAME, 'SYSTEM')
        ;
        IF v_WK_FEE_OBR_SUM > 0 THEN
--      3-2-1. 배차지사/ 캐쉬 차감/               => C3
            INSERT INTO ALD_ADJ_BR_CASH_LOG
                        (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_CTH_HD_CODE, vi_CTH_BR_CODE, 'C3'
                        , -(v_WK_FEE_OBR_AMT + v_WK_FEE_OBR_VAT), -v_WK_FEE_OBR_AMT, -v_WK_FEE_OBR_VAT
                        , vi_ORD_NO, v_WK_FEE_MSG||', '||vi_DUP_ORDER_CNT||'건, 기사수수료['||vi_CTH_WK_CODE||']'||vi_CTH_WK_NAME, 'SYSTEM')
            ;
--      3-2-1. 발주지사/ 캐쉬 충전/               => C3
            INSERT INTO ALD_ADJ_BR_CASH_LOG
                        (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_ORD_HD_CODE, vi_ORD_BR_CODE, 'C3'
                        , (v_WK_FEE_OBR_AMT + v_WK_FEE_OBR_VAT), v_WK_FEE_OBR_AMT, v_WK_FEE_OBR_VAT
                        , vi_ORD_NO, v_WK_FEE_MSG||', '||vi_DUP_ORDER_CNT||'건, 기사수수료['||vi_CTH_WK_CODE||']'||vi_CTH_WK_NAME, 'SYSTEM')
            ;
        END IF;
    END IF;

--  // 3-3. 건당 배달대행수수료 나누기
    IF v_DVRY_FEE_FIX_SUM > 0 AND vi_PARTNER_CODE <> '0009' THEN -- 추가결제(SYSTEM) 제외(20150609)
--      3-3-1. 배차기사 소속지사/ 캐쉬 차감/ (건당 배달대행수수료 정액 * 복수건수)     => C1
        INSERT INTO ALD_ADJ_BR_CASH_LOG
                    (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                    , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
        VALUES      (vi_CTH_HD_CODE, vi_CTH_BR_CODE, 'C1'
                    , -(v_DVRY_FEE_FIX_AMT + v_DVRY_FEE_FIX_VAT), -v_DVRY_FEE_FIX_AMT, -v_DVRY_FEE_FIX_VAT
                    , vi_ORD_NO, '정액, '||vi_DUP_ORDER_CNT||'건, 지사수수료['||vi_CTH_WK_CODE||']'||vi_CTH_WK_NAME, 'SYSTEM')
        ;
--      // 나눠야 할 몫 = 대행수수료 = 본사 몫 + 총판 몫 + 지사 몫(= 발주 지사 몫(= 지사 몫 * 발주 비율) + 수주지사 몫(= 지사 몫 * 수주비율)))
--      3-3-2. 발주 총판지사/에 충전/ ((건당 배달대행수수료 정액 * 복수건수) * (배달대행수수료 발주총판수익% / 100))    => D1
        IF (v_DVRY_FEE_FIX_OHD_AMT + v_DVRY_FEE_FIX_OHD_VAT) > 0 THEN
            INSERT INTO ALD_ADJ_BR_CASH_LOG
                        (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_ORD_HD_CODE, v_O_HD_BR_CODE, 'D1'
                        , (v_DVRY_FEE_FIX_OHD_AMT + v_DVRY_FEE_FIX_OHD_VAT), (v_DVRY_FEE_FIX_OHD_AMT), (v_DVRY_FEE_FIX_OHD_VAT)
                        , vi_ORD_NO, '정액, '||vi_DUP_ORDER_CNT||'건,지사수수료', 'SYSTEM')
            ;
        END IF;

--      3-3-3. 발주 지사/에 충전/ ((건당 배달대행수수료 정액 * 복수건수) * (배달대행수수료 발주지사수익% / 100) * 발주_배차 간 발주비율)        => D3
        IF ((v_DVRY_FEE_FIX_OBR_AMT + v_DVRY_FEE_FIX_OBR_VAT) > 0) THEN
            INSERT INTO ALD_ADJ_BR_CASH_LOG
                        (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_ORD_HD_CODE, vi_ORD_BR_CODE, 'D3'
                        , (v_DVRY_FEE_FIX_OBR_AMT + v_DVRY_FEE_FIX_OBR_VAT), (v_DVRY_FEE_FIX_OBR_AMT), (v_DVRY_FEE_FIX_OBR_VAT)
                        , vi_ORD_NO, '정액, '||vi_DUP_ORDER_CNT||'건, 지사수수료('||v_O_CAL_RATE||'%)', 'SYSTEM')
            ;
        END IF;

--      3-3-4. 배차기사 소속지사/에 충전/ ((건당 배달대행수수료 정액 * 복수건수) * (배달대행수수료 발주지사수익% / 100) * 발주_배차 간 수주비율)         => D4
        IF ((v_DVRY_FEE_FIX_CBR_AMT + v_DVRY_FEE_FIX_CBR_VAT) > 0) THEN
            INSERT INTO ALD_ADJ_BR_CASH_LOG
                        (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_CTH_HD_CODE, vi_CTH_BR_CODE, 'D4'
                        , (v_DVRY_FEE_FIX_CBR_AMT + v_DVRY_FEE_FIX_CBR_VAT), (v_DVRY_FEE_FIX_CBR_AMT), (v_DVRY_FEE_FIX_CBR_VAT)
                        , vi_ORD_NO, '정액, '||vi_DUP_ORDER_CNT||'건, 지사수수료('||(100 - v_O_CAL_RATE)||'%)', 'SYSTEM')
            ;
        END IF;

--      3-3-5. 본사에 충전 => D1
        IF (v_DVRY_FEE_FIX_HQ_AMT + v_DVRY_FEE_FIX_HQ_VAT) > 0 THEN
            INSERT INTO ALD_ADJ_HQ_CASH_LOG
                        (HD_CODE, BR_CODE, WK_CODE, HQ_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, HQ_CASH_MEMO)
            VALUES      (vi_CTH_HD_CODE, vi_CTH_BR_CODE, vi_CTH_WK_CODE, 'D1'
                        , (v_DVRY_FEE_FIX_HQ_AMT + v_DVRY_FEE_FIX_HQ_VAT), (v_DVRY_FEE_FIX_HQ_AMT), (v_DVRY_FEE_FIX_HQ_VAT)
                        , vi_ORD_NO, '정액, '||vi_DUP_ORDER_CNT||'건, 지사수수료')
            ;
        END IF;
--      3-3-6. 본사에 충전 => D9
        IF (v_DVRY_FEE_ADD_AMT + v_DVRY_FEE_ADD_VAT) > 0 THEN
            INSERT INTO ALD_ADJ_HQ_CASH_LOG
                        (HD_CODE, BR_CODE, WK_CODE, HQ_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, HQ_CASH_MEMO)
            VALUES      (vi_CTH_HD_CODE, vi_CTH_BR_CODE, vi_CTH_WK_CODE, 'D9'
                        , (v_DVRY_FEE_ADD_AMT + v_DVRY_FEE_ADD_VAT), (v_DVRY_FEE_ADD_AMT), (v_DVRY_FEE_ADD_VAT)
                        , vi_ORD_NO, '정률, '||vi_DUP_ORDER_CNT||'건, 지사수수료')
            ;
        END IF;

        IF (v_DVRY_HQF_AMT + v_DVRY_HQF_VAT) > 0 THEN
            -- 부가세/원천세귀속구분 - 세무정산 - 정산수수료
            INSERT INTO ALD_ADJ_HQ_CASH_LOG
                        (HD_CODE, BR_CODE, ST_CODE, WK_CODE, HQ_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, HQ_CASH_MEMO)
            VALUES      (vi_ORD_HD_CODE, vi_ORD_BR_CODE, vi_ORD_ST_CODE, vi_CTH_WK_CODE, 'V1'
                        , (v_DVRY_HQF_AMT + v_DVRY_HQF_VAT), (v_DVRY_HQF_AMT), (v_DVRY_HQF_VAT)
                        , vi_ORD_NO, '['||vi_CTH_BR_CODE||'],'||vi_DUP_ORDER_CNT||'건, 정산수수료')
            ;
            IF (vi_DVRY_PAY_TYPE = '2') THEN
                -- 부가세/원천세귀속구분 - 세무정산 - 부가세
                INSERT INTO ALD_ADJ_HQ_CASH_LOG
                            (HD_CODE, BR_CODE, ST_CODE, WK_CODE, HQ_CASH_TYPE_CD
                            , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, HQ_CASH_MEMO)
                VALUES      (vi_ORD_HD_CODE, vi_ORD_BR_CODE, vi_ORD_ST_CODE, vi_CTH_WK_CODE, 'V2'
                            , (v_DVRY_HQS_VAT), 0, (v_DVRY_HQS_VAT)
                            , vi_ORD_NO, '['||vi_CTH_BR_CODE||'],'||vi_DUP_ORDER_CNT||'건, 부가세')
                ;
            END IF;
        END IF;
    END IF;
---------------------------------------- 배달대행관련 종료 ----------------------------------------
v_STEP := 'STEP_6';
---------------------------------------- 봉사료관련 시작 ----------------------------------------
--  // 봉사료
--  // 1-1. 건당 봉사료수수료(지원금)_정액 차감, 부가세대상(브렌드가맹점)인 경우 제외
    IF v_WK_SUPP_SUM > 0 AND v_VAT_RATE = 0 AND vi_PARTNER_CODE <> '0009' THEN
--      1-1-1. 배차기사/에게 봉사료수수료/ 차감/         => G1
        INSERT INTO ALD_ADJ_WK_CASH_LOG
                    (WK_CODE, HD_CODE, BR_CODE, WK_CASH_TYPE_CD
                    , ADD_CASH, ORD_NO, WK_CASH_MEMO, IN_USR_ID)
        VALUES      (vi_CTH_WK_CODE, vi_CTH_HD_CODE, vi_CTH_BR_CODE, 'G1'
                    , -(v_WK_SUPP_AMT + v_WK_SUPP_VAT), vi_ORD_NO, vi_DUP_ORDER_CNT||'건', 'SYSTEM')
        ;
--      1-1-2. 배차기사 소속지사/에서 봉사료수수료/ 차감/    => G1
        INSERT INTO ALD_ADJ_BR_CASH_LOG
                    (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                    , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
        VALUES      (vi_CTH_HD_CODE, vi_CTH_BR_CODE, 'G1'
                    , -(v_WK_SUPP_AMT + v_WK_SUPP_VAT), -(v_WK_SUPP_AMT), -(v_WK_SUPP_VAT)
                    , vi_ORD_NO, vi_DUP_ORDER_CNT||'건, ['||vi_CTH_WK_CODE||']'||vi_CTH_WK_NAME, 'SYSTEM')
        ;
--      1-1-3. 발주 총판지사/에 봉사료수수료 발주총판비율/로 충전/     => G2
        IF (v_WK_SUPP_OHD_AMT + v_WK_SUPP_OHD_VAT) > 0 THEN
            INSERT INTO ALD_ADJ_BR_CASH_LOG
                        (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_ORD_HD_CODE, v_O_HD_BR_CODE, 'G2'
                        , (v_WK_SUPP_OHD_AMT + v_WK_SUPP_OHD_VAT), v_WK_SUPP_OHD_AMT, v_WK_SUPP_OHD_VAT
                        , vi_ORD_NO, vi_DUP_ORDER_CNT||'건, ['||vi_CTH_WK_CODE||']'||vi_CTH_WK_NAME, 'SYSTEM')
            ;
        END IF;

--      1-1-4. 발주 지사/에 봉사료수수료 발주지사비율 * 발주비율로 충전/    => G4
        IF (v_WK_SUPP_OBR_AMT + v_WK_SUPP_OBR_VAT) > 0 THEN
            INSERT INTO ALD_ADJ_BR_CASH_LOG
                        (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_ORD_HD_CODE, vi_ORD_BR_CODE, 'G4'
                        , (v_WK_SUPP_OBR_AMT + v_WK_SUPP_OBR_VAT), v_WK_SUPP_OBR_AMT, v_WK_SUPP_OBR_VAT
                        , vi_ORD_NO, vi_DUP_ORDER_CNT||'건, ['||vi_CTH_WK_CODE||']'||vi_CTH_WK_NAME, 'SYSTEM')
            ;
        END IF;

--      1-1-5. 배차기사 소속 지사(수주지사)에 수주비율로 충전/ (봉사료수수료 * 발주지사비율 * 수주비율로 충전   => G5
        IF (v_WK_SUPP_CBR_AMT + v_WK_SUPP_CBR_VAT) > 0 THEN
            INSERT INTO ALD_ADJ_BR_CASH_LOG
                        (HD_CODE, BR_CODE, BR_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, BR_CASH_MEMO, IN_USR_ID)
            VALUES      (vi_CTH_HD_CODE, vi_CTH_BR_CODE, 'G5'
                        , (v_WK_SUPP_CBR_AMT + v_WK_SUPP_CBR_VAT), v_WK_SUPP_CBR_AMT, v_WK_SUPP_CBR_VAT
                        , vi_ORD_NO, vi_DUP_ORDER_CNT||'건, ['||vi_CTH_WK_CODE||']'||vi_CTH_WK_NAME, 'SYSTEM')
            ;
        END IF;

--      1-1-6. 본사에 충전 => G1
        IF (v_WK_SUPP_HQ_AMT + v_WK_SUPP_HQ_VAT) > 0 THEN
            INSERT INTO ALD_ADJ_HQ_CASH_LOG
                        (HD_CODE, BR_CODE, WK_CODE, HQ_CASH_TYPE_CD
                        , ADD_CASH, ADD_AMT, ADD_VAT, ORD_NO, HQ_CASH_MEMO)
            VALUES      (vi_CTH_HD_CODE, vi_CTH_BR_CODE, vi_CTH_WK_CODE, 'G1'
                        , (v_WK_SUPP_HQ_AMT + v_WK_SUPP_HQ_VAT), v_WK_SUPP_HQ_AMT, v_WK_SUPP_HQ_VAT
                        , vi_ORD_NO, vi_DUP_ORDER_CNT||'건')
            ;
        END IF;
    END IF;
---------------------------------------- 봉사료관련 종료 ----------------------------------------
v_STEP := 'STEP_7';
--      상품대금결제방식으로 현금결제액 캐쉬지급
    IF vi_GOODS_PAY_TYPE = '2' AND NVL(vi_PAY_CASH, 0) > 0 THEN
        SP_SYS_0305_ADJ_CASH('상품대금:지사/기사=>가맹점', vi_ORD_NO, vi_CTH_BR_CODE, vi_CTH_WK_CODE, vi_ORD_ST_CODE, NVL(vi_PAY_CASH, 0), 'SYSTEM', vi_ORD_TYPE_CD);
    END IF;
v_STEP := 'STEP_8';
--  // 정산테이블 입력
    INSERT INTO ALD_A01_CHARGE
                (ORD_NO, ORD_TYPE_CD
                , ORD_HD_CODE, ORD_BR_CODE, ORD_ST_CODE
                , PER_HD_CODE, PER_BR_CODE, PER_ST_CODE
                , CTH_HD_CODE, CTH_BR_CODE, CTH_WK_CODE
                , O_HD_BR_CODE
                , O_HD_DVRY_ST_PAY, O_HD_SRV_PAY, O_HD_DVRY_PAY, O_HD_ST_DVRY_PAY, O_HD_ORD_MARGIN
                , O_BR_DVRY_ST_PAY, O_BR_SRV_PAY, O_BR_DVRY_PAY, O_BR_ST_DVRY_PAY, O_BR_ORD_MARGIN
                , O_CAL_RATE, O_CAL_WK_RATE, O_CAL_ST_RATE, O_CAL_SM_RATE
                , P_HD_BR_CODE
                , P_HD_ORD_ST_PAY, P_HD_DVRY_ST_PAY, P_HD_DVRY_PAY
                , P_BR_ORD_ST_PAY, P_BR_DVRY_ST_PAY, P_BR_DVRY_PAY
                , P_CAL_RATE
                , C_HD_BR_CODE
                , C_HD_SRV_PAY, C_HD_DVRY_PAY
                , C_BR_SRV_PAY, C_BR_DVRY_PAY
                , DUP_ORDER_CNT, DVRY_PAY_TYPE
                , DVRY_AMT, DVRY_ST_PAY_1, DVRY_ST_PAY_2
                , DVRY_ST_PAY_4, DVRY_ST_PAY_5
                , DVRY_ST_PAY_4_HD, DVRY_ST_PAY_5_HD
                , DVRY_ST_PAY_4_BR, DVRY_ST_PAY_5_BR
                , WK_FEE_FIX, WK_FEE_RATE, DVRY_FEE_FIX
                , ORD_AMT, ORD_ST_PAY_1, ORD_ST_PAY_2, ORD_MARGIN
                , SRV_AMT, WK_SUPP_FIX, WK_SUPP_RATE
                , CU_NO, CU_MILEAGE, RECOMM_CU_NO, RECOMM_CU_MILEAGE
                , SUPP_AMT, PAY_CARD, PAY_CASH, PAY_MILEAGE
                , DVRY_ADJ_AMT, DVRY_PRCH_AMT
                , DVRY_ST_M_PAY_1, DVRY_ST_M_PAY_2, GOODS_PAY_TYPE, C_DUP_ORDER_CNT, PARTNER_CODE
                , CARD_APPR_NUM, VAN_TERM_KIND, VAT_RATE, C_BR_DIRECT_YN, WK_TAX_RATE, WK_TAX_YN, EMPL_TYPE
                , BR_DVRY_PAY_FLAG, DVRY_FEE_VAT_YN
                , C_BR_VAT_YN, O_BR_VAT_YN, C_HD_BR_VAT_YN, O_HD_BR_VAT_YN
                , PAY_3_VAT_RATE, MATCH_YN, HQ_BL_YN)
    VALUES      (vi_ORD_NO, vi_ORD_TYPE_CD
                , vi_ORD_HD_CODE, vi_ORD_BR_CODE, vi_ORD_ST_CODE
                , vi_PER_HD_CODE, vi_PER_BR_CODE, vi_PER_ST_CODE
                , vi_CTH_HD_CODE, vi_CTH_BR_CODE, vi_CTH_WK_CODE
                , v_O_HD_BR_CODE
                , v_O_HD_DVRY_ST_PAY, v_O_HD_SRV_PAY, v_O_HD_DVRY_PAY, v_O_HD_ST_DVRY_PAY, v_O_HD_ORD_MARGIN
                , v_O_BR_DVRY_ST_PAY, v_O_BR_SRV_PAY, v_O_BR_DVRY_PAY, v_O_BR_ST_DVRY_PAY, v_O_BR_ORD_MARGIN
                , v_O_CAL_RATE, v_O_CAL_WK_RATE, v_O_CAL_ST_RATE, v_O_CAL_SM_RATE
                , v_P_HD_BR_CODE
                , v_P_HD_ORD_ST_PAY, v_P_HD_DVRY_ST_PAY, v_P_HD_DVRY_PAY
                , v_P_BR_ORD_ST_PAY, v_P_BR_DVRY_ST_PAY, v_P_BR_DVRY_PAY
                , v_P_CAL_RATE
                , v_C_HD_BR_CODE
                , v_C_HD_SRV_PAY, v_C_HD_DVRY_PAY
                , v_C_BR_SRV_PAY, v_C_BR_DVRY_PAY
                , vi_DUP_ORDER_CNT, vi_DVRY_PAY_TYPE
                , vi_DVRY_AMT, v_DVRY_ST_PAY_1, v_DVRY_ST_PAY_2
                , v_DVRY_ST_PAY_4_HQ, v_DVRY_ST_PAY_5_HQ
                , v_DVRY_ST_PAY_4_HD, v_DVRY_ST_PAY_5_HD
                , v_DVRY_ST_PAY_4_BR, v_DVRY_ST_PAY_5_BR
                , v_WK_FEE_FIX, v_WK_FEE_RATE, v_DVRY_FEE_FIX
                , vi_ORD_AMT, v_ORD_ST_PAY_1, v_ORD_ST_PAY_2, v_ORD_MARGIN
                , vi_SRV_AMT, v_WK_SUPP_FIX, v_WK_SUPP_RATE
                , NVL(vi_ORD_CU_NO, 0), NVL(v_CU_MILEAGE, 0), NVL(v_RECOMM_CU_NO, 0), NVL(v_RECOMM_CU_MILEAGE, 0)
                , vi_SUPP_AMT, NVL(vi_PAY_CARD, 0), NVL(vi_PAY_CASH, 0), NVL(vi_PAY_MILEAGE, 0)
                , vi_DVRY_ADJ_AMT, vi_DVRY_PRCH_AMT
                , v_DVRY_ST_M_PAY_1, v_DVRY_ST_M_PAY_2, vi_GOODS_PAY_TYPE, v_DUP_ORDER_CNT, vi_PARTNER_CODE
                , vi_CARD_APPR_NUM, v_VAN_TERM_KIND, v_VAT_RATE, v_DIRECT_YN, v_WK_TAX_RATE, v_WK_TAX_YN, v_EMPL_TYPE
                , v_BR_DVRY_PAY_FLAG, v_DVRY_FEE_VAT_YN
                , v_C_BR_VAT_YN, v_O_BR_VAT_YN, v_C_HD_BR_VAT_YN, v_O_HD_BR_VAT_YN
                , v_PAY_3_VAT_RATE, v_MATCH_YN, v_HQ_BL_YN);

    EXCEPTION
        WHEN OTHERS THEN

            SP_SYS_0102_ERROR_LOG_TRG ('SP_SYS_0301_ADJ_ORDER_02', v_STEP ||' ERROR CODE : '||SQLCODE ||', ORD_NO : '||vi_ORD_NO||', ERROR MSG : '||SUBSTR(SQLERRM, 1, 1000));

END SP_SYS_0301_ADJ_ORDER_02;