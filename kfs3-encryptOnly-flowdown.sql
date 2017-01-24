-- taken from https://subversion.uits.arizona.edu/kitt-anon/kitt/financial-system/ops-scripts/environment_flowdowns/trunk/KFS-environment-flow-STG.sql
-- ====================================================================================================================
-- 3)OBFUSCATE SENSITIVE DATA: Set each vendor to have a different randomly assigned number for Tax ID and encrypt it.
--   For the Tax Id Types that are set to NONE, it leaves it as is (so it allows blank values)
-- !!! Note: KULOWNER needs permission to run the DBMS_CRYPTO package for ENCRYPTING the dummy numbers
-- ====================================================================================================================
-- Create/Update the DES Encrypt/Decrypt functions in the DB
CREATE OR REPLACE
FUNCTION          DES_ENCRYPT (p_plainText VARCHAR2) RETURN VARCHAR2
IS
    encryptedValue      VARCHAR2(255);
    encryption_key      RAW (8) := ('EC80BAE30EA40101');
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

CREATE OR REPLACE
FUNCTION          DES_DECRYPT (p_encodedText VARCHAR2) RETURN VARCHAR2
IS
    decryptedValue      RAW(255);
    encryption_key      RAW (8) := ('EC80BAE30EA40101');
    encryption_type     PLS_INTEGER := dbms_crypto.ENCRYPT_DES + DBMS_CRYPTO.CHAIN_ECB + DBMS_CRYPTO.PAD_PKCS5;
    
BEGIN
	decryptedValue:= dbms_crypto.DECRYPT(
    src => UTL_ENCODE.base64_decode( UTL_I18N.STRING_TO_RAW( p_encodedText,'utf8')),
    typ => encryption_type,
    key => encryption_key
  );
  RETURN UTL_I18N.RAW_TO_CHAR( decryptedValue, 'utf8');
END;
/

-- NEW: 9000000000000 + ROW# -  for account numbers 
UPDATE fp_dv_ach_t set dv_payee_acct_nbr = DES_ENCRYPT( ROWNUM + 9000000000000 );
UPDATE fp_dv_wire_trnfr_t set dv_payee_acct_nbr = DES_ENCRYPT( ROWNUM + 9000000000000 );
UPDATE pdp_ach_acct_nbr_t set ach_bnk_acct_nbr = DES_ENCRYPT( ROWNUM + 9000000000000 );
UPDATE pdp_payee_ach_acct_t set bnk_acct_nbr = DES_ENCRYPT( ROWNUM + 9000000000000 );

-- NEW: 900000000 + ROW# - for tax id numbers that are not of type NONE
UPDATE pur_vndr_hdr_t set vndr_tax_nbr = DES_ENCRYPT( ROWNUM + 900000000 ) where vndr_tax_typ_cd != 'NONE';
UPDATE pur_vndr_tax_chg_t set vndr_prev_tax_nbr = DES_ENCRYPT( ROWNUM + 899999999 ) where vndr_prev_tax_typ_cd != 'NONE';
UPDATE tax_payee_t set hdr_vndr_tax_nbr = DES_ENCRYPT( ROWNUM + 900000000 );

--OLD:
-- update fp_dv_ach_t set dv_payee_acct_nbr = 'r+181z6uNTJrgbJPn0ljGA==';
-- update fp_dv_wire_trnfr_t set dv_payee_acct_nbr = 'r+181z6uNTJrgbJPn0ljGA==';
-- update pdp_ach_acct_nbr_t set ach_bnk_acct_nbr = 'r+181z6uNTJrgbJPn0ljGA==';
-- update pdp_payee_ach_acct_t set bnk_acct_nbr = 'r+181z6uNTJrgbJPn0ljGA==';
-- update pur_vndr_hdr_t set vndr_tax_nbr = 'r+181z6uNTIc3lalnjPKpA==';
-- update pur_vndr_tax_chg_t set vndr_prev_tax_nbr = 'r+181z6uNTIc3lalnjPKpA==';
-- update tax_payee_t set hdr_vndr_tax_nbr = 'r+181z6uNTIc3lalnjPKpA==';
