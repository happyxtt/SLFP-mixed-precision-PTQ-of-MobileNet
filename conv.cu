#include "./common/MobileNetv1.h"
//输入图像归一化
  __global__ void image(uint8_t *image, sfp *out, int inputRow, float Ka)  
  {
    const int idx = blockDim.x*blockIdx.x + threadIdx.x;
    const int i = blockIdx.y;
    float temp[224*224*3];
    temp[i*inputRow*inputRow + idx] = float(image[i*inputRow*inputRow + idx])/255;
    temp[i*inputRow*inputRow + idx] = 2*(temp[i*inputRow*inputRow + idx] - 0.5);
    temp[i*inputRow*inputRow + idx] = temp[i*inputRow*inputRow + idx]/Ka;
    out[i*inputRow*inputRow + idx] = float2sfp(temp[i*inputRow*inputRow + idx], 5);
  }
//3*3普通卷积，步长2
    __global__ void conv2(sfp *active, sfp *weight, float *bias, sfp *out, float *outint24,  int inputRow, int outputRow, int inputChannel, float Ka, float Kw, float Kr, int type_in, int type_out) //modified
    {
      const int idx = blockDim.x*blockIdx.x + threadIdx.x;
      int row = blockIdx.x;
      int col = threadIdx.x;
      int kernelSize = 3;
      int i = blockIdx.y;
      outint24[i*outputRow*outputRow + idx] = 0;
      for(int l = 0; l < inputChannel; ++l)
      {
        for(int j = 0; j < kernelSize; ++j)
        {
          for(int k = 0; k < kernelSize; ++k)
          {
              sfp imgValue;
              int curRow = row*2 - kernelSize / 2 + j;
              int curCol = col*2 - kernelSize / 2 + k;
              if(curRow < 0 || curCol < 0 || curRow >= inputRow || curCol >= inputRow)
              {
                imgValue.sign = 0;
                imgValue.exp = 0;
                imgValue.mnt = 0;
              }
              else
              {
                imgValue = active[l*inputRow*inputRow + curRow*inputRow  + curCol];
              }
              outint24[i*outputRow*outputRow + idx] += sfp2fixed(imgValue, weight[i*inputChannel*kernelSize*kernelSize + l*kernelSize*kernelSize + j*kernelSize + k], type_in);
          }
        }
      }
      outint24[i*outputRow*outputRow + idx] = outint24[i*outputRow*outputRow + idx] * (Kw*Ka);
      outint24[i*outputRow*outputRow + idx] = (outint24[i*outputRow*outputRow + idx] + bias[i])/Kr;
      outint24[i*outputRow*outputRow + idx] = (outint24[i*outputRow*outputRow + idx] > 0) ? outint24[i*outputRow*outputRow + idx] : 0;   
      outint24[i*outputRow*outputRow + idx] = (outint24[i*outputRow*outputRow + idx] < 252) ? outint24[i*outputRow*outputRow + idx] : 252;
      out[i*outputRow*outputRow + idx] = float2sfp(outint24[i*outputRow*outputRow + idx], type_out);
    }

//1*1普通卷积，步长1
    __global__ void conv1(sfp *active, sfp *weight, float *bias, sfp *out, float *outint24 , int inputRow, int outputRow, int inputChannel, float Ka, float Kw, float Kr, int type_in, int type_out)
    {
      const int idx = blockDim.x*blockIdx.x + threadIdx.x;
      int i = blockIdx.y;
      outint24[i*outputRow*outputRow + idx] = 0;
      for(int j = 0; j < inputChannel; ++j)//遍历输入的每个通道
      {
        outint24[i*outputRow*outputRow + idx] += sfp2fixed(active[j*inputRow*inputRow + idx ] , weight[i*inputChannel + j], type_in);
      }
      outint24[i*outputRow*outputRow + idx] = outint24[i*outputRow*outputRow + idx] * (Kw*Ka);
      outint24[i*outputRow*outputRow + idx] = (outint24[i*outputRow*outputRow + idx] + bias[i])/Kr;
      outint24[i*outputRow*outputRow + idx] = (outint24[i*outputRow*outputRow + idx] > 0) ? outint24[i*outputRow*outputRow + idx] : 0;   
      outint24[i*outputRow*outputRow + idx] = (outint24[i*outputRow*outputRow + idx] < 252) ? outint24[i*outputRow*outputRow + idx] : 252;
      out[i*outputRow*outputRow + idx] = float2sfp(outint24[i*outputRow*outputRow + idx], type_out);
    } 
//3*3DW卷积，步长1或2
	__global__ void conv_DW(sfp *active, sfp *weight, float *bias, sfp *out, float *outint24 , int inputRow, int outputRow, int stride, float Ka, float Kw, float Kr, int type_in, int type_out)
	{
    const int idx = blockDim.x*blockIdx.x + threadIdx.x;
    int row = blockIdx.x;
    int col = threadIdx.x;
    int kernelSize = 3;
    int i = blockIdx.y;
    outint24[i*outputRow*outputRow + idx] = 0; 
    for(int j = 0; j < kernelSize; ++j)
    {
      for(int k = 0; k < kernelSize; ++k)
      {
        sfp imgValue;
        int curRow;
        int curCol;
        if(stride == 1)
        {
          curRow = stride*row - kernelSize / 2 + j;
          curCol = stride*col - kernelSize / 2 + k;
        }
        else
        {
          curRow = stride*row - kernelSize / 2 + j + 1;
          curCol = stride*col - kernelSize / 2 + k + 1;
        }
        if(curRow < 0 || curCol < 0 || curRow >= inputRow || curCol >= inputRow)
        {
          imgValue.sign = 0;
          imgValue.exp = 0;
          imgValue.mnt = 0;
        }
        else
        {
          imgValue = active[i*inputRow*inputRow + curRow * inputRow + curCol];
        }
        outint24[i*outputRow*outputRow + idx] += sfp2fixed(weight[i*kernelSize*kernelSize + j * kernelSize + k] , imgValue, type_in);
      }
    }
    outint24[i*outputRow*outputRow + idx] = outint24[i*outputRow*outputRow + idx] * (Kw*Ka);
    outint24[i*outputRow*outputRow + idx] = (outint24[i*outputRow*outputRow + idx] + bias[i])/Kr;
    outint24[i*outputRow*outputRow + idx] = (outint24[i*outputRow*outputRow + idx] > 0) ? outint24[i*outputRow*outputRow + idx] : 0; 
    outint24[i*outputRow*outputRow + idx] = (outint24[i*outputRow*outputRow + idx] < 252) ? outint24[i*outputRow*outputRow + idx] : 252;
    out[i*outputRow*outputRow + idx] = float2sfp(outint24[i*outputRow*outputRow + idx], type_out);
	}
//Avgpool
  __global__ void avgpool(sfp *active, sfp *out, int inputRow)
  {
    const int idx = blockDim.x*blockIdx.x + threadIdx.x;
    float sumadd[1024];
    sumadd[idx] = 0;
    for(int j = 0; j < inputRow*inputRow; ++j)//遍历输入的每个像素点
    {
      sumadd[idx] += sfp2float(active[idx*inputRow*inputRow + j])/(inputRow*inputRow);
    }
    out[idx] = float2sfp(sumadd[idx], 5);
  }

//fullconnection
  __global__ void fullconnection(sfp *active , sfp *weight , float *bias , sfp *out ,  float *outint24, float Ka, float Kw, float Kr)
  {
    int idx = threadIdx.x;
    outint24[idx] = 0;
    if(idx < 1000)
    {
      for(int i = 0; i < 1024 ; i++)
      {
        outint24[idx] += sfp2fixed(active[i],weight[idx*1024 + i], 5);
      }
      outint24[idx] = outint24[idx] * (Kw*Ka);
      outint24[idx] = (outint24[idx] + bias[idx])/Kr;
      out[idx] = float2sfp(outint24[idx], 5);
    }
  }

//排序
  __global__ void BubbleSort(sfp* data , int *rank , int *TOP1 , int *TOP5 , int *pic_idx , int idx , int maxnum,float Ka)
  {
      int i = 0;
      int j = 0;
      int position[1000];
      float a[1000];
      float tmp = 0;
      for(i = 0; i<1000 ; ++i)
      {
        position[i] = i;
        a[i] = sfp2float(data[i]);
      }
      for (i = 0; i < 1000 - 1; ++i)
      {
          for (j = 1; j < 1000 - i; ++j)
          {
              if (a[j] > a[j-1])    /* 从大到小排序，把较小的交换到后面来 */
              {
                  tmp = a[j-1];
                  a[j-1] = a[j];
                  a[j] = tmp;
                  /* 记录位置 */
                  tmp = position[j-1];
                  position[j-1] = position[j];
                  position[j] = tmp;
              }
          }
      }
      for(int j = 0; j < 5; ++j)
      {
        rank[j] = position[j];
        //  printf("rank[%d]:%d\n",j,rank[j]);
        //  printf("a[%d]:%f\n",j,a[j]*Ka);
      }
      //  printf("%d\n",pic_idx[idx]);
      if(rank[0] == pic_idx[idx])
      {
        TOP1[0]++;
        printf("Top1:%d\n",TOP1[0]);
      }
      if(rank[0] == pic_idx[idx] || rank[1] == pic_idx[idx] || rank[2] == pic_idx[idx] || rank[3] == pic_idx[idx] || rank[4] == pic_idx[idx])
      {
        TOP5[0]++;
        printf("Top5:%d\n",TOP5[0]);
      }
      if(idx == maxnum-1)
      {
        // printf("d_top1 = %f , d_top5 = %f\n" , float(TOP1[0]) , float(TOP5[0]));
        //printf("d_top1 = %f%% , d_top5 = %f%%\n" , float(TOP1[0]/maxnum*100) , float(TOP5[0]/maxnum*100));
      }
  }