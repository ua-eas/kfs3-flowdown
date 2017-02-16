-- taken from https://subversion.uits.arizona.edu/kitt-anon/kitt/financial-system/ops-scripts/environment_flowdowns/trunk/KFS-environment-flow-STG.sql
-- ====================================================================================================================
-- 3)OBFUSCATE SENSITIVE DATA: Set each vendor to have a different randomly assigned number for Tax ID and encrypt it.
--   For the Tax Id Types that are set to NONE, it leaves it as is (so it allows blank values)
-- !!! Note: KULOWNER needs permission to run the DBMS_CRYPTO package for ENCRYPTING the dummy numbers
-- ====================================================================================================================
-- Create/Update the DES Encrypt/Decrypt functions in the DB
CREATE OR REPLACE
FUNCTION          DES_ENCRYPT (p_plainText VARCHAR2, encryption_key RAW) RETURN VARCHAR2
IS
    encryptedValue      VARCHAR2(255);
    encryption_type     PLS_INTEGER := dbms_crypto.ENCRYPT_DES + DBMS_CRYPTO.CHAIN_ECB + DBMS_CRYPTO.PAD_PKCS5;
    
BEGIN
	encryptedValue:= dbms_crypto.ENCRYPT(
		src => UTL_RAW.cast_to_raw (p_plainText),
        typ => encryption_type,
        key => encryption_key
  );
  RETURN UTL_I18N.RAW_TO_CHAR( UTL_ENCODE.base64_encode(encryptedValue), 'utf8');
END;
/

-- NOTE: It is the responsibility of whatever is running this script (Jenkins job, human user) to hydrate the ${ENCRYPTION_KEY} with some 8-byte hex string value
-- NEW: 9000000000000 + ROW# -  for account numbers 
UPDATE fp_dv_ach_t set dv_payee_acct_nbr = DES_ENCRYPT( ROWNUM + 9000000000000, '${ENCRYPTION_KEY}');
UPDATE fp_dv_wire_trnfr_t set dv_payee_acct_nbr = DES_ENCRYPT( ROWNUM + 9000000000000, '${ENCRYPTION_KEY}');
UPDATE pdp_ach_acct_nbr_t set ach_bnk_acct_nbr = DES_ENCRYPT( ROWNUM + 9000000000000, '${ENCRYPTION_KEY}');
UPDATE pdp_payee_ach_acct_t set bnk_acct_nbr = DES_ENCRYPT( ROWNUM + 9000000000000, '${ENCRYPTION_KEY}');

-- NEW: 900000000 + ROW# - for tax id numbers that are not of type NONE
UPDATE pur_vndr_hdr_t set vndr_tax_nbr = DES_ENCRYPT( ROWNUM + 900000000, '${ENCRYPTION_KEY}') where vndr_tax_typ_cd != 'NONE';
UPDATE pur_vndr_tax_chg_t set vndr_prev_tax_nbr = DES_ENCRYPT( ROWNUM + 899999999, '${ENCRYPTION_KEY}') where vndr_prev_tax_typ_cd != 'NONE';
UPDATE tax_payee_t set hdr_vndr_tax_nbr = DES_ENCRYPT( ROWNUM + 900000000, '${ENCRYPTION_KEY}');
