/*
 * File: cantx_0x193.c
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

#include "cantx_0x193.h"
#include "rtwtypes.h"
#include "cantx_0x193_private.h"

/* Exported block signals */
UB inf_eng_tra_rdctn_fail_stat;       /* '<Root>/inf_eng_tra_rdctn_fail_stat' */
UB inf_eng_trq_tcm_rqst_fail_stat; /* '<Root>/inf_eng_trq_tcm_rqst_fail_stat' */
UW inf_trq_crnk_shft;                  /* '<Root>/inf_trq_crnk_shft' */
UB inf_aps_pos_pt_validity;            /* '<Root>/inf_aps_pos_pt_validity' */
UW inf_tra_non_reg;                    /* '<Root>/inf_tra_non_reg' */
UB inf_aps_pos_eff;                    /* '<Root>/inf_aps_pos_eff' */
UB CanTx_inf_eng_tra_rdctn_fail_stat;
                                /* '<Root>/CanTx_inf_eng_tra_rdctn_fail_stat' */
UB CanTx_inf_eng_trq_tcm_rqst_fail_stat;
                             /* '<Root>/CanTx_inf_eng_trq_tcm_rqst_fail_stat' */
UB CanTx_inf_trq_crnk_shft;            /* '<Root>/CanTx_inf_trq_crnk_shft' */
UB CanTx_inf_aps_pos_pt_validity;   /* '<Root>/CanTx_inf_aps_pos_pt_validity' */
UB CanTx_inf_tra_non_reg;              /* '<Root>/CanTx_inf_tra_non_reg' */
UB CanTx_inf_aps_pos_eff;              /* '<Root>/CanTx_inf_aps_pos_eff' */

/* Block signals (default storage) */
B_cantx_0x193_T cantx_0x193_B;

/* Real-time model */
static RT_MODEL_cantx_0x193_T cantx_0x193_M_;
RT_MODEL_cantx_0x193_T *const cantx_0x193_M = &cantx_0x193_M_;

/* Output and update for atomic system: '<S2>/sig_inf_eng_tra_rdctn_fail_stat' */
void cantx_0x193_sig_inf_eng_tra_rdctn_fail_stat(UB
  rtu_inf_eng_tra_rdctn_fail_stat, UB *rty_CanTx_inf_eng_tra_rdctn_fail_stat)
{
  /* Switch: '<S6>/Switch2' incorporates:
   *  Constant: '<S5>/Max'
   *  RelationalOperator: '<S6>/LowerRelop1'
   *  Switch: '<S6>/Switch'
   */
  if (rtu_inf_eng_tra_rdctn_fail_stat > 1) {
    *rty_CanTx_inf_eng_tra_rdctn_fail_stat = 1U;
  } else {
    *rty_CanTx_inf_eng_tra_rdctn_fail_stat = rtu_inf_eng_tra_rdctn_fail_stat;
  }

  /* End of Switch: '<S6>/Switch2' */
}

/* Output and update for action system: '<S1>/cantx_0x193_main_2X' */
void cantx_0x193_cantx_0x193_main_2X(UB rtu_inf_eng_tra_rdctn_fail_stat, UB
  *rty_CanTx_inf_eng_tra_rdctn_fail_stat)
{
  /* Outputs for Atomic SubSystem: '<S2>/sig_inf_eng_tra_rdctn_fail_stat' */
  cantx_0x193_sig_inf_eng_tra_rdctn_fail_stat(rtu_inf_eng_tra_rdctn_fail_stat,
    rty_CanTx_inf_eng_tra_rdctn_fail_stat);

  /* End of Outputs for SubSystem: '<S2>/sig_inf_eng_tra_rdctn_fail_stat' */
}

/* Output and update for atomic system: '<S3>/sig_inf_eng_trq_tcm_rqst_fail_stat' */
void cantx_0x193_sig_inf_eng_trq_tcm_rqst_fail_stat(UB
  rtu_inf_eng_trq_tcm_rqst_fail_stat, UB
  *rty_CanTx_inf_eng_trq_tcm_rqst_fail_stat)
{
  /* Switch: '<S9>/Switch2' incorporates:
   *  Constant: '<S7>/Max'
   *  RelationalOperator: '<S9>/LowerRelop1'
   *  Switch: '<S9>/Switch'
   */
  if (rtu_inf_eng_trq_tcm_rqst_fail_stat > 1) {
    *rty_CanTx_inf_eng_trq_tcm_rqst_fail_stat = 1U;
  } else {
    *rty_CanTx_inf_eng_trq_tcm_rqst_fail_stat =
      rtu_inf_eng_trq_tcm_rqst_fail_stat;
  }

  /* End of Switch: '<S9>/Switch2' */
}

/* Output and update for atomic system: '<S3>/sig_inf_trq_crnk_shft' */
void cantx_0x193_sig_inf_trq_crnk_shft(UW rtu_inf_trq_crnk_shft, UB
  *rty_CanTx_inf_trq_crnk_shft)
{
  /* Switch: '<S10>/Switch2' incorporates:
   *  DataTypeConversion: '<S8>/Data Type Conversion'
   */
  *rty_CanTx_inf_trq_crnk_shft = (UB)((UD)rtu_inf_trq_crnk_shft >> 1);
}

/* Output and update for action system: '<S1>/cantx_0x193_main_4X' */
void cantx_0x193_cantx_0x193_main_4X(UB rtu_inf_eng_trq_tcm_rqst_fail_stat, UW
  rtu_inf_trq_crnk_shft, UB *rty_CanTx_inf_eng_trq_tcm_rqst_fail_stat, UB
  *rty_CanTx_inf_trq_crnk_shft)
{
  /* Outputs for Atomic SubSystem: '<S3>/sig_inf_eng_trq_tcm_rqst_fail_stat' */
  cantx_0x193_sig_inf_eng_trq_tcm_rqst_fail_stat
    (rtu_inf_eng_trq_tcm_rqst_fail_stat,
     rty_CanTx_inf_eng_trq_tcm_rqst_fail_stat);

  /* End of Outputs for SubSystem: '<S3>/sig_inf_eng_trq_tcm_rqst_fail_stat' */

  /* Outputs for Atomic SubSystem: '<S3>/sig_inf_trq_crnk_shft' */
  cantx_0x193_sig_inf_trq_crnk_shft(rtu_inf_trq_crnk_shft,
    rty_CanTx_inf_trq_crnk_shft);

  /* End of Outputs for SubSystem: '<S3>/sig_inf_trq_crnk_shft' */
}

/* Output and update for atomic system: '<S4>/sig_inf_aps_pos_eff' */
void cantx_0x193_sig_inf_aps_pos_eff(UB rtu_inf_aps_pos_eff, UB
  *rty_CanTx_inf_aps_pos_eff)
{
  /* Switch: '<S14>/Switch2' incorporates:
   *  Constant: '<S11>/Max'
   *  RelationalOperator: '<S14>/LowerRelop1'
   *  Switch: '<S14>/Switch'
   */
  if (rtu_inf_aps_pos_eff > 100) {
    *rty_CanTx_inf_aps_pos_eff = 100U;
  } else {
    *rty_CanTx_inf_aps_pos_eff = rtu_inf_aps_pos_eff;
  }

  /* End of Switch: '<S14>/Switch2' */
}

/* Output and update for atomic system: '<S4>/sig_inf_aps_pos_pt_validity' */
void cantx_0x193_sig_inf_aps_pos_pt_validity(UB rtu_inf_aps_pos_pt_validity, UB *
  rty_CanTx_inf_aps_pos_pt_validity)
{
  /* Switch: '<S15>/Switch2' incorporates:
   *  Constant: '<S12>/Max'
   *  RelationalOperator: '<S15>/LowerRelop1'
   *  Switch: '<S15>/Switch'
   */
  if (rtu_inf_aps_pos_pt_validity > 1) {
    *rty_CanTx_inf_aps_pos_pt_validity = 1U;
  } else {
    *rty_CanTx_inf_aps_pos_pt_validity = rtu_inf_aps_pos_pt_validity;
  }

  /* End of Switch: '<S15>/Switch2' */
}

/* Output and update for atomic system: '<S4>/sig_inf_tra_non_reg' */
void cantx_0x193_sig_inf_tra_non_reg(UW rtu_inf_tra_non_reg, UB
  *rty_CanTx_inf_tra_non_reg)
{
  /* Switch: '<S16>/Switch2' incorporates:
   *  DataTypeConversion: '<S13>/Data Type Conversion'
   */
  *rty_CanTx_inf_tra_non_reg = (UB)((UD)rtu_inf_tra_non_reg >> 1);
}

/* Output and update for action system: '<S1>/cantx_0x193_main_8X' */
void cantx_0x193_cantx_0x193_main_8X(UB rtu_inf_aps_pos_pt_validity, UW
  rtu_inf_tra_non_reg, UB rtu_inf_aps_pos_eff, UB
  *rty_CanTx_inf_aps_pos_pt_validity, UB *rty_CanTx_inf_tra_non_reg, UB
  *rty_CanTx_inf_aps_pos_eff)
{
  /* Outputs for Atomic SubSystem: '<S4>/sig_inf_aps_pos_pt_validity' */
  cantx_0x193_sig_inf_aps_pos_pt_validity(rtu_inf_aps_pos_pt_validity,
    rty_CanTx_inf_aps_pos_pt_validity);

  /* End of Outputs for SubSystem: '<S4>/sig_inf_aps_pos_pt_validity' */

  /* Outputs for Atomic SubSystem: '<S4>/sig_inf_tra_non_reg' */
  cantx_0x193_sig_inf_tra_non_reg(rtu_inf_tra_non_reg, rty_CanTx_inf_tra_non_reg);

  /* End of Outputs for SubSystem: '<S4>/sig_inf_tra_non_reg' */

  /* Outputs for Atomic SubSystem: '<S4>/sig_inf_aps_pos_eff' */
  cantx_0x193_sig_inf_aps_pos_eff(rtu_inf_aps_pos_eff, rty_CanTx_inf_aps_pos_eff);

  /* End of Outputs for SubSystem: '<S4>/sig_inf_aps_pos_eff' */
}

/* Model step function */
void cantx_0x193_step(void)
{
  /* (no output/update code required) */
}

/* Model initialize function */
void cantx_0x193_initialize(void)
{
  /* ConstCode for Outport: '<Root>/CanTx_inf_eng_tra_rdctn_fail_stat' */
  CanTx_inf_eng_tra_rdctn_fail_stat = cantx_0x193_B.Switch2_g;

  /* ConstCode for Outport: '<Root>/CanTx_inf_eng_trq_tcm_rqst_fail_stat' */
  CanTx_inf_eng_trq_tcm_rqst_fail_stat = cantx_0x193_B.Switch2_c;

  /* ConstCode for Outport: '<Root>/CanTx_inf_trq_crnk_shft' */
  CanTx_inf_trq_crnk_shft = cantx_0x193_B.Switch2_n;

  /* ConstCode for Outport: '<Root>/CanTx_inf_aps_pos_pt_validity' */
  CanTx_inf_aps_pos_pt_validity = cantx_0x193_B.Switch2_b;

  /* ConstCode for Outport: '<Root>/CanTx_inf_tra_non_reg' */
  CanTx_inf_tra_non_reg = cantx_0x193_B.Switch2;

  /* ConstCode for Outport: '<Root>/CanTx_inf_aps_pos_eff' */
  CanTx_inf_aps_pos_eff = cantx_0x193_B.Switch2_d;
}

/* Model terminate function */
void cantx_0x193_terminate(void)
{
  /* (no terminate code required) */
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
