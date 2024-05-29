#include "./common/MobileNetv1.h"
//#include<cmath>
using namespace std;

void get_parameter(const char* filename, uint8_t* parameter) 
{
    FILE* ptr = fopen(filename, "rb");
  
    if (!ptr) {
      printf("Bad file path: %p, %s\n", ptr, strerror(errno));
      exit(0);
    }
    fread(parameter, 224*224*3*1, 1, ptr);
  
    fclose(ptr);
} 

fileidx get_file_idx(const char* filename , int size )
{
    // FILE* ptr = fopen(filename , 'rb');
    string s;
    char idxchar[4];
    fileidx jpgdata;
    ifstream in;
    in.open(filename);

    for(int i=0 ; i<size ; i++)
    {
      getline(in,s);
      for(int k = 0 ; k < 4 ; k++)
      {
        idxchar[k] = '0'; 
      }     
      for(int j=0;j<29;j++)
      {
        jpgdata.jpgname[i*29+j] = s[j] ;
      } 
      for(int k = s.length() ; k>28 ; k--)
      {
        idxchar[k-29] = s[k];
        // printf("%d  " , s.length());
      }       
      jpgdata.idx[i] = atoi(idxchar);
    }
    in.close();
    return jpgdata;
}

fileidx_pointer *get_file_idx_pointer(const char* filename , int size , int* pic_idx)
{
    // FILE* ptr = fopen(filename , 'rb');
    string s;
    char idxchar[4];
    // fileidx_pointer *jpgdata = (fileidx_pointer *)malloc(size*sizeof(fileidx_pointer));
    fileidx_pointer *jpgdata = new fileidx_pointer[size];
    ifstream in;
    in.open(filename);
    // if (!ptr) {
    //   printf("Bad file path: %p, %s\n", ptr, strerror(errno));
    //   exit(0);
    // }
    for(int i=0 ; i<size ; i++)
    {
      getline(in,s);
      s.copy(jpgdata[i].jpgname , 28 , 0);
      jpgdata[i].jpgname[28] = '\0';

      for(int k = 0 ; k < 4 ; k++)
      {
        idxchar[k] = '0'; 
      }     
      
      for(int k = s.length() ; k>28 ; k--)
      {
        idxchar[k-29] = s[k];
        // printf("%d  " , s.length());
      }       
      pic_idx[i] = atoi(idxchar);
    }
    in.close();
    return jpgdata;
}

float* get_weight(const char* filename , int size)
{
    FILE *q = fopen(filename , "r");
    if (!q) {
      printf("Bad file path: %p, %s\n", q, strerror(errno));
      exit(0);
    }
    float *weight = NULL;
    long int j = 0;
    weight = (float *)malloc((size)*sizeof(float));
    while(!feof(q))
    {
        fscanf(q , "%f" , &weight[j]);
        j++;
    }
    fclose(q);
    return weight;
}

float* get_Kw(const char* filename , int size)
{
    FILE *q = fopen(filename , "r");
    if (!q) {
      printf("Bad file path: %p, %s\n", q, strerror(errno));
      exit(0);
    }
    float *Kw = NULL;
    long int j = 0;
    Kw = (float *)malloc((size)*sizeof(float));
    while(!feof(q))
    {
        fscanf(q , "%f" , &Kw[j]);
        j++;
    }
    fclose(q);
    return Kw;
}

float* get_bias(const char * filename , int size)
{
    FILE *p = fopen(filename , "r");
    if (!p) {
      printf("Bad file path: %p, %s\n", p, strerror(errno));
      exit(0);
    }
    float *bias = NULL;
    long int i = 0;
    bias = (float *)malloc(size*sizeof(float));
    while(!feof(p))
    {
        fscanf(p , "%f" , &bias[i]);
        i++;
    }
    fclose(p);
    return bias;
}

float* get_Kr(const char* filename , int size)
{
    FILE *q = fopen(filename , "r");
    if (!q) {
      printf("Bad file path: %p, %s\n", q, strerror(errno));
      exit(0);
    }
    float *Kr = NULL;
    int j = 0;
    Kr = (float *)malloc((size)*sizeof(float));
    while(!feof(q))
    {
        fscanf(q , "%f" , &Kr[j]);
        j++;
    }
    fclose(q);
    return Kr;
}

