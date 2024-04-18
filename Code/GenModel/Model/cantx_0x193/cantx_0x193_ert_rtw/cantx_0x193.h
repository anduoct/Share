/*
 * File: cantx_0x193.h
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

#ifndef RTW_HEADER_cantx_0x193_h_
#define RTW_HEADER_cantx_0x193_h_
#ifndef cantx_0x193_COMMON_INCLUDES_
#define cantx_0x193_COMMON_INCLUDES_
#include "rtwtypes.h"
#endif                                 /* cantx_0x193_COMMON_INCLUDES_ */

#include "cantx_0x193_types.h"

/* Macros for accessing real-time model data structure */
#ifndef rtmGetErrorStatus
#define rtmGetErrorStatus(rtm)         ((rtm)->errorStatus)
#endif

#ifndef rtmSetErrorStatus
#define rtmSetErrorStatus(rtm, val)    ((rtm)->errorStatus = (val))
#endif

/* Block signals (default storage) */
typedef struct {
  UB Switch2;                          /* '<S16>/Switch2' */
  UB Switch2_b;                        /* '<S15>/Switch2' */
  UB Switch2_d;                        /* '<S14>/Switch2' */
  UB Switch2_n;                        /* '<S10>/Switch2' */
  UB Switch2_c;                        /* '<S9>/Switch2' */
  UB Switch2_g;                        /* '<S6>/Switch2' */
} B_cantx_0x193_T;

/* Real-time Model Data Structure */
struct tag_RTM_cantx_0x193_T {
  const CH * volatile errorStatus;
};

/* Block signals (default storage) */
extern B_cantx_0x193_T cantx_0x193_B;

/*
 * Exported Global Signals
 *
 * Note: Exported global signals are block signals with an exported global
 * storage class designation.  Code generation will declare the memory for
 * these signals and export their symbols.
 *
 */
extern UB inf_eng_tra_rdctn_fail_stat;/* '<Root>/inf_eng_tra_rdctn_fail_stat' */
extern UB inf_eng_trq_tcm_rqst_fail_stat;
                                   /* '<Root>/inf_eng_trq_tcm_rqst_fail_stat' */
extern UW inf_trq_crnk_shft;           /* '<Root>/inf_trq_crnk_shft' */
extern UB inf_aps_pos_pt_validity;     /* '<Root>/inf_aps_pos_pt_validity' */
extern UW inf_tra_non_reg;             /* '<Root>/inf_tra_non_reg' */
extern UB inf_aps_pos_eff;             /* '<Root>/inf_aps_pos_eff' */
extern UB CanTx_inf_eng_tra_rdctn_fail_stat;
                                /* '<Root>/CanTx_inf_eng_tra_rdctn_fail_stat' */
extern UB CanTx_inf_eng_trq_tcm_rqst_fail_stat;
                             /* '<Root>/CanTx_inf_eng_trq_tcm_rqst_fail_stat' */
extern UB CanTx_inf_trq_crnk_shft;     /* '<Root>/CanTx_inf_trq_crnk_shft' */
extern UB CanTx_inf_aps_pos_pt_validity;
                                    /* '<Root>/CanTx_inf_aps_pos_pt_validity' */
extern UB CanTx_inf_tra_non_reg;       /* '<Root>/CanTx_inf_tra_non_reg' */
extern UB CanTx_inf_aps_pos_eff;       /* '<Root>/CanTx_inf_aps_pos_eff' */

/* Model entry point functions */
extern void cantx_0x193_initialize(void);
extern void cantx_0x193_step(void);
extern void cantx_0x193_terminate(void);

/* Real-time Model object */
extern RT_MODEL_cantx_0x193_T *const cantx_0x193_M;

/*-
 * These blocks were eliminated from the model due to optimizations:
 *
 * Block '<S6>/Data Type Duplicate' : Unused code path elimination
 * Block '<S6>/Data Type Propagation' : Unused code path elimination
 * Block '<S9>/Data Type Duplicate' : Unused code path elimination
 * Block '<S9>/Data Type Propagation' : Unused code path elimination
 * Block '<S10>/Data Type Duplicate' : Unused code path elimination
 * Block '<S10>/Data Type Propagation' : Unused code path elimination
 * Block '<S14>/Data Type Duplicate' : Unused code path elimination
 * Block '<S14>/Data Type Propagation' : Unused code path elimination
 * Block '<S15>/Data Type Duplicate' : Unused code path elimination
 * Block '<S15>/Data Type Propagation' : Unused code path elimination
 * Block '<S16>/Data Type Duplicate' : Unused code path elimination
 * Block '<S16>/Data Type Propagation' : Unused code path elimination
 * Block '<S5>/Data Type Conversion' : Eliminate redundant data type conversion
 * Block '<S7>/Data Type Conversion' : Eliminate redundant data type conversion
 * Block '<S11>/Data Type Conversion' : Eliminate redundant data type conversion
 * Block '<S12>/Data Type Conversion' : Eliminate redundant data type conversion
 */

/*-
 * The generated code includes comments that allow you to trace directly
 * back to the appropriate location in the model.  The basic format
 * is <system>/block_name, where system is the system number (uniquely
 * assigned by Simulink) and block_name is the name of the block.
 *
 * Use the MATLAB hilite_system command to trace the generated code back
 * to the model.  For example,
 *
 * hilite_system('<S3>')    - opens system 3
 * hilite_system('<S3>/Kp') - opens and selects block Kp which resides in S3
 *
 * Here is the system hierarchy for this model
 *
 * '<Root>' : 'cantx_0x193'
 * '<S1>'   : 'cantx_0x193/cantx_0x193_main'
 * '<S2>'   : 'cantx_0x193/cantx_0x193_main/cantx_0x193_main_2X'
 * '<S3>'   : 'cantx_0x193/cantx_0x193_main/cantx_0x193_main_4X'
 * '<S4>'   : 'cantx_0x193/cantx_0x193_main/cantx_0x193_main_8X'
 * '<S5>'   : 'cantx_0x193/cantx_0x193_main/cantx_0x193_main_2X/sig_inf_eng_tra_rdctn_fail_stat'
 * '<S6>'   : 'cantx_0x193/cantx_0x193_main/cantx_0x193_main_2X/sig_inf_eng_tra_rdctn_fail_stat/Saturation Dynamic'
 * '<S7>'   : 'cantx_0x193/cantx_0x193_main/cantx_0x193_main_4X/sig_inf_eng_trq_tcm_rqst_fail_stat'
 * '<S8>'   : 'cantx_0x193/cantx_0x193_main/cantx_0x193_main_4X/sig_inf_trq_crnk_shft'
 * '<S9>'   : 'cantx_0x193/cantx_0x193_main/cantx_0x193_main_4X/sig_inf_eng_trq_tcm_rqst_fail_stat/Saturation Dynamic'
 * '<S10>'  : 'cantx_0x193/cantx_0x193_main/cantx_0x193_main_4X/sig_inf_trq_crnk_shft/Saturation Dynamic'
 * '<S11>'  : 'cantx_0x193/cantx_0x193_main/cantx_0x193_main_8X/sig_inf_aps_pos_eff'
 * '<S12>'  : 'cantx_0x193/cantx_0x193_main/cantx_0x193_main_8X/sig_inf_aps_pos_pt_validity'
 * '<S13>'  : 'cantx_0x193/cantx_0x193_main/cantx_0x193_main_8X/sig_inf_tra_non_reg'
 * '<S14>'  : 'cantx_0x193/cantx_0x193_main/cantx_0x193_main_8X/sig_inf_aps_pos_eff/Saturation Dynamic'
 * '<S15>'  : 'cantx_0x193/cantx_0x193_main/cantx_0x193_main_8X/sig_inf_aps_pos_pt_validity/Saturation Dynamic'
 * '<S16>'  : 'cantx_0x193/cantx_0x193_main/cantx_0x193_main_8X/sig_inf_tra_non_reg/Saturation Dynamic'
 */
#endif                                 /* RTW_HEADER_cantx_0x193_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
