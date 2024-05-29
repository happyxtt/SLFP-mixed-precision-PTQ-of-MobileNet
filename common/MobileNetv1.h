
#include "./common.h"
#include<stdio.h>
#include<fstream>  //ifstream
#include<iostream>
#include<string>     //包含getline()
#include <cuda_runtime.h>
#include<math.h>

//自定义数据结构
//输入图像数据结构
typedef unsigned char uint8_t;

//浮点转SFP数据结构
typedef struct myfixed
{
  unsigned sign:1;
  unsigned integer:10;
  unsigned fraction:13;
  unsigned fix:23;
}myfixed;

//Kscale浮点转fixed数据结构
typedef struct kfixed
{
  unsigned sign:1;
  unsigned fraction:16;
}kfixed;


//bias浮点转fixed数据结构
typedef struct bfixed
{
  unsigned sign:1;
  unsigned integer:16;
  unsigned fraction:9;
}bfixed;
//输入输出SFP格式的数据格式
typedef struct sfp
{
  unsigned sign:1;  
  unsigned exp:4;   
  unsigned mnt:5;  
}sfp;

//用来计算两个SFP乘法的数据格式
typedef struct lut
{
 unsigned cbMnt:10;
 unsigned carry:1;
 unsigned outMnt:6 ;   
 unsigned outExp:5;
 unsigned outSign:1; 
}lut;

//用来SFP定点化的数据格式
typedef struct sfpFixed
{
 unsigned fixed21:21;  
 unsigned fixed14:14; 
 unsigned fixed24:24;      
}sfpFixed;

//用来存储卷积中间24位加法的数据格式
typedef struct int24
{ 
 unsigned sign:1;
 unsigned out:24;
 unsigned Kscale:16;
}int24;

//用来存储SFP加法的过程数据的数据格式
typedef struct addsfp
{ 
 unsigned mnta:13;//存储a的尾数
 unsigned mntb:13;//存储b的尾数
 unsigned addMnt:13;//存储尾数加法结果
 unsigned sign:1;
 unsigned exp:4;
 unsigned mnt:4;
}addsfp;

typedef struct fileidx
{
  char jpgname[50000*29];
  int idx[50000];
}fileidx; 

typedef struct fileidx_pointer
{
  char jpgname[29];
}fileidx_pointer; 



//conv
__global__ void image(uint8_t *image, sfp *out, int inputRow, float Ka);
__global__ void conv2(sfp *active, sfp *weight, float *bias, sfp *out, float *outint24, int inputRow, int outputRow, int inputChannel, float Ka, float Kw, float Kr, int type_in, int type_out);
__global__ void conv1(sfp *active, sfp *weight, float *bias, sfp *out, float *outint24, int inputRow, int outputRow, int inputChannel, float Ka, float Kw, float Kr, int type_in, int type_out);
__global__ void conv_DW(sfp *active, sfp *weight, float *bias, sfp *out, float *outint24, int inputRow, int outputRow, int stride, float Ka, float Kw, float Kr, int type_in, int type_out);
__global__ void avgpool(sfp *active, sfp *out, int inputRow);
__global__ void fullconnection(sfp *active, sfp *weight, float *bias, sfp *out, float *outint24, float Ka, float Kw, float Kr);
__global__ void BubbleSort(sfp* data, int *rank, int *TOP1, int *TOP5, int *pic_idx, int idx, int maxnum, float Ka);

//readdata
//测试用获取数据函数
void get_parameter(const char* filename, uint8_t* parameter);
//获取图像名以及INDIX
fileidx get_file_idx(const char* filename , int size );
fileidx_pointer *get_file_idx_pointer(const char* filename , int size , int* pic_idx);

//获取权重，偏置，图像像素值
float* get_weight(const char * filename , int size);
float* get_bias(const char * filename , int size);
float* get_Kw(const char* filename , int size);
float* get_Kr(const char* filename , int size);

//datascale
//量化后的weight,bias转化为SFP
void get_weightSfp(float* weight , sfp *out, float Kw, int size, int type);
void get_biasint24(float* bias , int24 *out, float Kr, int size);


//数据格式转换
__device__ sfp float2sfp(float a, int type);
__device__ float sfp2fixed(sfp active, sfp weight, int type);
__device__ float sfp2float(sfp a);
float sfpfloat( sfp a);



