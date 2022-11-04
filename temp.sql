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
    IF v_HQ_BL_YN IN('Y','Z') AND v_DVRY_ST_PAY_OB_VAT <> 0 THEN -- 본사귀속정산인 경우 본사로 귀속
        v_DVRY_ST_PAY_HQ_VAT := v_DVRY_ST_PAY_HQ_VAT + v_DVRY_ST_PAY_OB_VAT;
        v_DVRY_ST_PAY_OB_VAT := 0;
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