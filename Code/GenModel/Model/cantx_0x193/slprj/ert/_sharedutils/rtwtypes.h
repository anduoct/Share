/*
 * File: rtwtypes.h
 *
 * Code generated for Simulink model 'cantx_0x193'.
 *
 * Model version                  : 1.2
 * Simulink Coder version         : 9.7 (R2022a) 13-Nov-2021
 * C/C++ source code generated on : Thu Apr 18 18:04:12 2024
 */

#ifndef RTWTYPES_H
#define RTWTYPES_H

/* Logical type definitions */
#if (!defined(__cplusplus))
#ifndef false
#define false                          (0U)
#endif

#ifndef true
#define true                           (1U)
#endif
#endif

/*=======================================================================*
 * Target hardware information
 *   Device type: Infineon->TriCore
 *   Number of bits:     char:   8    short:   16    int:  32
 *                       long:  32
 *                       native word size:  32
 *   Byte ordering: LittleEndian
 *   Signed integer division rounds to: Zero
 *   Shift right on a signed integer as arithmetic shift: on
 *=======================================================================*/

/*=======================================================================*
 * Fixed width word size data types:                                     *
 *   int8_T, int16_T, int32_T     - signed 8, 16, or 32 bit integers     *
 *   uint8_T, uint16_T, uint32_T  - unsigned 8, 16, or 32 bit integers   *
 *   real32_T, real64_T           - 32 and 64 bit floating point numbers *
 *=======================================================================*/
typedef signed char int8_T;
typedef unsigned char uint8_T;
typedef short int16_T;
typedef unsigned short uint16_T;
typedef int int32_T;
typedef unsigned int uint32_T;
typedef float real32_T;
typedef double real64_T;

/*===========================================================================*
 * Generic type definitions: boolean_T, char_T, byte_T, int_T, uint_T,       *
 *                           real_T, time_T, ulong_T.                        *
 *===========================================================================*/
typedef double real_T;
typedef double time_T;
typedef unsigned char boolean_T;
typedef int int_T;
typedef unsigned int uint_T;
typedef unsigned long ulong_T;
typedef char char_T;
typedef unsigned char uchar_T;
typedef char_T byte_T;

/*===========================================================================*
 * Complex number type definitions                                           *
 *===========================================================================*/
#define CREAL_T

typedef struct {
  real32_T re;
  real32_T im;
} creal32_T;

typedef struct {
  real64_T re;
  real64_T im;
} creal64_T;

typedef struct {
  real_T re;
  real_T im;
} creal_T;

#define CINT8_T

typedef struct {
  int8_T re;
  int8_T im;
} cint8_T;

#define CUINT8_T

typedef struct {
  uint8_T re;
  uint8_T im;
} cuint8_T;

#define CINT16_T

typedef struct {
  int16_T re;
  int16_T im;
} cint16_T;

#define CUINT16_T

typedef struct {
  uint16_T re;
  uint16_T im;
} cuint16_T;

#define CINT32_T

typedef struct {
  int32_T re;
  int32_T im;
} cint32_T;

#define CUINT32_T

typedef struct {
  uint32_T re;
  uint32_T im;
} cuint32_T;

/*=======================================================================*
 * Min and Max:                                                          *
 *   int8_T, int16_T, int32_T     - signed 8, 16, or 32 bit integers     *
 *   uint8_T, uint16_T, uint32_T  - unsigned 8, 16, or 32 bit integers   *
 *=======================================================================*/
#define MAX_int8_T                     ((int8_T)(127))
#define MIN_int8_T                     ((int8_T)(-128))
#define MAX_uint8_T                    ((uint8_T)(255U))
#define MAX_int16_T                    ((int16_T)(32767))
#define MIN_int16_T                    ((int16_T)(-32768))
#define MAX_uint16_T                   ((uint16_T)(65535U))
#define MAX_int32_T                    ((int32_T)(2147483647))
#define MIN_int32_T                    ((int32_T)(-2147483647-1))
#define MAX_uint32_T                   ((uint32_T)(0xFFFFFFFFU))

/* Block D-Work pointer type */
typedef void * pointer_T;

/* Define Simulink Coder replacement data types. */
typedef cint8_T cSB;         /* User defined replacement datatype for cint8_T */
typedef cuint8_T cUB;       /* User defined replacement datatype for cuint8_T */
typedef cint16_T cSW;       /* User defined replacement datatype for cint16_T */
typedef cuint16_T cUW;     /* User defined replacement datatype for cuint16_T */
typedef cint32_T cSD;       /* User defined replacement datatype for cint32_T */
typedef cuint32_T cUD;     /* User defined replacement datatype for cuint32_T */
typedef creal32_T cR32;    /* User defined replacement datatype for creal32_T */
typedef creal_T cR64;        /* User defined replacement datatype for creal_T */

/* Define Simulink Coder replacement data types. */
typedef int8_T SB;            /* User defined replacement datatype for int8_T */
typedef uint8_T UB;          /* User defined replacement datatype for uint8_T */
typedef int16_T SW;          /* User defined replacement datatype for int16_T */
typedef uint16_T UW;        /* User defined replacement datatype for uint16_T */
typedef int32_T SD;          /* User defined replacement datatype for int32_T */
typedef uint32_T UD;        /* User defined replacement datatype for uint32_T */
typedef real32_T R32;       /* User defined replacement datatype for real32_T */
typedef real_T R64;           /* User defined replacement datatype for real_T */
typedef boolean_T BOOL;    /* User defined replacement datatype for boolean_T */
typedef int_T SI;              /* User defined replacement datatype for int_T */
typedef uint_T UI;            /* User defined replacement datatype for uint_T */
typedef char_T CH;            /* User defined replacement datatype for char_T */

#endif                                 /* RTWTYPES_H */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
