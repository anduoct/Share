/*
 * sfuntmpl_basic.c: Basic 'C' template for a level 2 S-function.
 *
 * Copyright 1990-2018 The MathWorks, Inc.
 */


/*
 * You must specify the S_FUNCTION_NAME as the name of your S-function
 * (i.e. replace sfuntmpl_basic with the name of your S-function).
 */

#define S_FUNCTION_NAME  TimeoutFunc
#define S_FUNCTION_LEVEL 2

/*
 * Need to include simstruc.h for the definition of the SimStruct and
 * its associated macro definitions.
 */
#include "simstruc.h"

enum{
    siggroupIndex = 0,
    canid = 1,
    signalTable = 2,
    numberOfParam
};

#define SIGGROUPINDEX(S) (ssGetSFcnParam(S, siggroupIndex))
#define SIGNALTABLE(S, index) (mxGetCell(ssGetSFcnParam(S, signalTable),index))
#define NUMOFTABLE(S) (mxGetNumberOfElements(ssGetSFcnParam(S, signalTable)))
#define CANID(S) (ssGetSFcnParam(S, canid))

/* Error handling
 * --------------
 *
 * You should use the following technique to report errors encountered within
 * an S-function:
 *
 *       ssSetErrorStatus(S,"Error encountered due to ...");
 *       return;
 *
 * Note that the 2nd argument to ssSetErrorStatus must be persistent memory.
 * It cannot be a local variable. For example the following will cause
 * unpredictable errors:
 *
 *      mdlOutputs()
 *      {
 *         char msg[256];         {ILLEGAL: to fix use "static char msg[256];"}
 *         sprintf(msg,"Error due to %s", string);
 *         ssSetErrorStatus(S,msg);
 *         return;
 *      }
 *
 */

/*====================*
 * S-function methods *
 *====================*/

/* Function: mdlInitializeSizes ===============================================
 * Abstract:
 *    The sizes information is used by Simulink to determine the S-function
 *    block's characteristics (number of inputs, outputs, states, etc.).
 */
static void mdlInitializeSizes(SimStruct *S)
{
    ssSetNumSFcnParams(S, numberOfParam);  /* Number of expected parameters */
    if (ssGetNumSFcnParams(S) != ssGetSFcnParamsCount(S)) {
        /* Return if number of expected != number of actual parameters */
        return;
    }

    ssSetNumContStates(S, 0);
    ssSetNumDiscStates(S, 0);

    /***** Set SFcn Param Untunable *****/
    ssSetSFcnParamNotTunable(S, siggroupIndex);
    ssSetSFcnParamNotTunable(S, canid);
    ssSetSFcnParamNotTunable(S, signalTable);

    if (!ssSetNumInputPorts(S, 0)) return;
    //ssSetInputPortWidth(S, 0, 1);
    //ssSetInputPortRequiredContiguous(S, 0, true); /*direct input signal access*/
    /*
     * Set direct feedthrough flag (1=yes, 0=no).
     * A port has direct feedthrough if the input is used in either
     * the mdlOutputs or mdlGetTimeOfNextVarHit functions.
     */
    //ssSetInputPortDirectFeedThrough(S, 0, 1);

    if (!ssSetNumOutputPorts(S, 0)) return;
    //ssSetOutputPortWidth(S, 0, 1);

    ssSetNumSampleTimes(S, 1);
    ssSetNumRWork(S, 0);
    ssSetNumIWork(S, 0);
    ssSetNumPWork(S, 0);
    ssSetNumModes(S, 0);
    ssSetNumNonsampledZCs(S, 0);

    /* Specify the operating point save/restore compliance to be same as a 
     * built-in block */
    ssSetOperatingPointCompliance(S, USE_DEFAULT_OPERATING_POINT);

    ssSetRuntimeThreadSafetyCompliance(S, RUNTIME_THREAD_SAFETY_COMPLIANCE_TRUE);
    ssSetOptions(S, SS_OPTION_EXCEPTION_FREE_CODE);
}



/* Function: mdlInitializeSampleTimes =========================================
 * Abstract:
 *    This function is used to specify the sample time(s) for your
 *    S-function. You must register the same number of sample times as
 *    specified in ssSetNumSampleTimes.
 */
static void mdlInitializeSampleTimes(SimStruct *S)
{
    ssSetSampleTime(S, 0, INHERITED_SAMPLE_TIME);
    ssSetOffsetTime(S, 0, 0.0);
    ssSetModelReferenceSampleTimeDefaultInheritance(S);

}



#define MDL_INITIALIZE_CONDITIONS   /* Change to #undef to remove function */
#if defined(MDL_INITIALIZE_CONDITIONS)
  /* Function: mdlInitializeConditions ========================================
   * Abstract:
   *    In this function, you should initialize the continuous and discrete
   *    states for your S-function block.  The initial states are placed
   *    in the state vector, ssGetContStates(S) or ssGetRealDiscStates(S).
   *    You can also perform any other initialization activities that your
   *    S-function may require. Note, this routine will be called at the
   *    start of simulation and if it is present in an enabled subsystem
   *    configured to reset states, it will be call when the enabled subsystem
   *    restarts execution to reset the states.
   */
  static void mdlInitializeConditions(SimStruct *S)
  {
  }
#endif /* MDL_INITIALIZE_CONDITIONS */



#define MDL_START  /* Change to #undef to remove function */
#if defined(MDL_START) 
  /* Function: mdlStart =======================================================
   * Abstract:
   *    This function is called once at start of model execution. If you
   *    have states that should be initialized once, this is the place
   *    to do it.
   */
  static void mdlStart(SimStruct *S)
  {
  }
#endif /*  MDL_START */



/* Function: mdlOutputs =======================================================
 * Abstract:
 *    In this function, you compute the outputs of your S-function
 *    block.
 */
static void mdlOutputs(SimStruct *S, int_T tid)
{
    //const real_T *u = (const real_T*) ssGetInputPortSignal(S,0);
    //real_T       *y = ssGetOutputPortSignal(S,0);
    //y[0] = u[0];
}



#define MDL_UPDATE  /* Change to #undef to remove function */
#if defined(MDL_UPDATE)
  /* Function: mdlUpdate ======================================================
   * Abstract:
   *    This function is called once for every major integration time step.
   *    Discrete states are typically updated here, but this function is useful
   *    for performing any tasks that should only take place once per
   *    integration step.
   */
  static void mdlUpdate(SimStruct *S, int_T tid)
  {
  }
#endif /* MDL_UPDATE */



#define MDL_DERIVATIVES  /* Change to #undef to remove function */
#if defined(MDL_DERIVATIVES)
  /* Function: mdlDerivatives =================================================
   * Abstract:
   *    In this function, you compute the S-function block's derivatives.
   *    The derivatives are placed in the derivative vector, ssGetdX(S).
   */
  static void mdlDerivatives(SimStruct *S)
  {
  }
#endif /* MDL_DERIVATIVES */



/* Function: mdlTerminate =====================================================
 * Abstract:
 *    In this function, you should perform any actions that are necessary
 *    at the termination of a simulation.  For example, if memory was
 *    allocated in mdlStart, this is the place to free it.
 */
static void mdlTerminate(SimStruct *S)
{
}

#define MDL_RTW
#if defined(MDL_RTW) && (defined(MATLAB_MEX_FILE) || defined(NRT))
static void mdlRTW(SimStruct *S)
{   
    /**** s_function parameters define ****/
    char *c_siggroupIndex;
    char *c_canid;
    char *c_signalTable;
 
    int8_T c_signalTableNum;
    int8_T i;

    size_t buflen_name1;
    size_t buflen_name2;
    size_t buflen_namen;
    
    buflen_name1 = mxGetN(SIGGROUPINDEX(S))*sizeof(mxChar)+1;
    c_siggroupIndex = mxMalloc(buflen_name1);
    mxGetString(SIGGROUPINDEX(S),c_siggroupIndex,(mwSize)buflen_name1);

    buflen_name2 = mxGetN(CANID(S))*sizeof(mxChar)+1;
    c_canid = mxMalloc(buflen_name2);
    mxGetString(CANID(S),c_canid,(mwSize)buflen_name2);

    c_signalTableNum = (int8_T)NUMOFTABLE(S);

    for ( i = 0; i < c_signalTableNum; i++)
    {
        size_t buflen_name4;
        buflen_name4 = mxGetN(SIGNALTABLE(S,i))*sizeof(mxChar)+1;
        buflen_namen += buflen_name4;
    }
    c_signalTable = mxMalloc(buflen_namen + c_signalTableNum - 1);

    for ( i = 0; i < c_signalTableNum; i++)
    {
        char *tableTmp;
        size_t buflen_name4;
        if ( i != (c_signalTableNum - 1))
        {
            buflen_name4 = mxGetN(SIGNALTABLE(S,i))*sizeof(mxChar)+2;
        }
        else
        {
            buflen_name4 = mxGetN(SIGNALTABLE(S,i))*sizeof(mxChar)+1;
        }
        tableTmp = mxMalloc(buflen_name4);
        mxGetString(SIGNALTABLE(S,i),tableTmp,(mwSize)buflen_name4);
        if ( i != (c_signalTableNum - 1))
        {
            strcat(tableTmp,",");
        }
        else
        {
            ;
        }
        strcat(c_signalTable, tableTmp);
    }

    /**** write out rtw parameters ****/
    if (!ssWriteRTWParamSettings(S, numberOfParam,
                                SSWRITE_VALUE_STR,"r_siggroupIndex",c_siggroupIndex,
                                SSWRITE_VALUE_STR,"r_canid",c_canid,
                                SSWRITE_VALUE_STR,"r_signalTable",c_signalTable
                               ))
								
    {
        return; /* An error occurred which will be reported by SL */
    }
	
}
#endif

/*=============================*
 * Required S-function trailer *
 *=============================*/

#ifdef  MATLAB_MEX_FILE    /* Is this file being compiled as a MEX-file? */
#include "simulink.c"      /* MEX-file interface mechanism */
#else
#include "cg_sfun.h"       /* Code generation registration function */
#endif
