/*
 * File: cantx_0x193_private.h
 *
 * Code generated for Simulink model 'cantx_0x193'.
 *
 * Model version                  : 1.2
 * Simulink Coder version         : 9.7 (R2022a) 13-Nov-2021
 * C/C++ source code generated on : Thu Apr 18 18:04:12 2024
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: Infineon->TriCore
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#ifndef RTW_HEADER_cantx_0x193_private_h_
#define RTW_HEADER_cantx_0x193_private_h_
#include "rtwtypes.h"
#include "cantx_0x193.h"
#ifndef UCHAR_MAX
#include <limits.h>
#endif

#if ( UCHAR_MAX != (0xFFU) ) || ( SCHAR_MAX != (0x7F) )
#error Code was generated for compiler with different sized uchar/char. \
Consider adjusting Test hardware word size settings on the \
Hardware Implementation pane to match your compiler word sizes as \
defined in limits.h of the compiler. Alternatively, you can \
select the Test hardware is the same as production hardware option and \
select the Enable portable word sizes option on the Code Generation > \
Verification pane for ERT based targets, which will disable the \
preprocessor word size checks.
#endif

#if ( USHRT_MAX != (0xFFFFU) ) || ( SHRT_MAX != (0x7FFF) )
#error Code was generated for compiler with different sized ushort/short. \
Consider adjusting Test hardware word size settings on the \
Hardware Implementation pane to match your compiler word sizes as \
defined in limits.h of the compiler. Alternatively, you can \
select the Test hardware is the same as production hardware option and \
select the Enable portable word sizes option on the Code Generation > \
Verification pane for ERT based targets, which will disable the \
preprocessor word size checks.
#endif

#if ( UINT_MAX != (0xFFFFFFFFU) ) || ( INT_MAX != (0x7FFFFFFF) )
#error Code was generated for compiler with different sized uint/int. \
Consider adjusting Test hardware word size settings on the \
Hardware Implementation pane to match your compiler word sizes as \
defined in limits.h of the compiler. Alternatively, you can \
select the Test hardware is the same as production hardware option and \
select the Enable portable word sizes option on the Code Generation > \
Verification pane for ERT based targets, which will disable the \
preprocessor word size checks.
#endif

#if ( ULONG_MAX != (0xFFFFFFFFU) ) || ( LONG_MAX != (0x7FFFFFFF) )
#error Code was generated for compiler with different sized ulong/long. \
Consider adjusting Test hardware word size settings on the \
Hardware Implementation pane to match your compiler word sizes as \
defined in limits.h of the compiler. Alternatively, you can \
select the Test hardware is the same as production hardware option and \
select the Enable portable word sizes option on the Code Generation > \
Verification pane for ERT based targets, which will disable the \
preprocessor word size checks.
#endif

extern void cantx_0x193_sig_inf_eng_tra_rdctn_fail_stat(UB
  rtu_inf_eng_tra_rdctn_fail_stat, UB *rty_CanTx_inf_eng_tra_rdctn_fail_stat);
extern void cantx_0x193_cantx_0x193_main_2X(UB rtu_inf_eng_tra_rdctn_fail_stat,
  UB *rty_CanTx_inf_eng_tra_rdctn_fail_stat);
extern void cantx_0x193_sig_inf_eng_trq_tcm_rqst_fail_stat(UB
  rtu_inf_eng_trq_tcm_rqst_fail_stat, UB
  *rty_CanTx_inf_eng_trq_tcm_rqst_fail_stat);
extern void cantx_0x193_sig_inf_trq_crnk_shft(UW rtu_inf_trq_crnk_shft, UB
  *rty_CanTx_inf_trq_crnk_shft);
extern void cantx_0x193_cantx_0x193_main_4X(UB
  rtu_inf_eng_trq_tcm_rqst_fail_stat, UW rtu_inf_trq_crnk_shft, UB
  *rty_CanTx_inf_eng_trq_tcm_rqst_fail_stat, UB *rty_CanTx_inf_trq_crnk_shft);
extern void cantx_0x193_sig_inf_aps_pos_eff(UB rtu_inf_aps_pos_eff, UB
  *rty_CanTx_inf_aps_pos_eff);
extern void cantx_0x193_sig_inf_aps_pos_pt_validity(UB
  rtu_inf_aps_pos_pt_validity, UB *rty_CanTx_inf_aps_pos_pt_validity);
extern void cantx_0x193_sig_inf_tra_non_reg(UW rtu_inf_tra_non_reg, UB
  *rty_CanTx_inf_tra_non_reg);
extern void cantx_0x193_cantx_0x193_main_8X(UB rtu_inf_aps_pos_pt_validity, UW
  rtu_inf_tra_non_reg, UB rtu_inf_aps_pos_eff, UB
  *rty_CanTx_inf_aps_pos_pt_validity, UB *rty_CanTx_inf_tra_non_reg, UB
  *rty_CanTx_inf_aps_pos_eff);

#endif                                 /* RTW_HEADER_cantx_0x193_private_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
