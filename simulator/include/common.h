
#ifndef _COMMON_HEAD
#define _COMMON_HEAD
#include <stdint.h>
#define InstNum 42
#define REG_NUM 32
#define ROM_NUM 1024
#define RAM_NUM (2 * 1024 * 1024)

enum InstSet {
NOP,MOV,MVHI,MVLO,ADD,SUB,MUL,DIV,ADDI,SUBI,MULI,DIVI,INPUT,OUTPUT,AND,OR,NOT,SLL,SLLI,SRL,B,JMP,JEQ,JNE,JLT,JLE,CALL,RETURN,LD,ST,FADD,FSUB,FMUL,FDIV,FMOV,FNEG,FJEQ,FJLT,FLD,FST,HALT,SETL,CALLR
};


#endif