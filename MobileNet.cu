#include "./common/MobileNetv1.h"

int main(void)
{
  //数据读取
    const char *input_pic = "../output_image/";         //存放二进制文件目录
    const char *weight_filename = "./inputdata/mb_new_weight.txt";            //存放权重
    const char *bias_filename = "./inputdata/mb_new_bias.txt";                //存放权重
    const char *Kw_filename = "./inputdata/Kw_e4m3.txt";
    const char *Kr_filename = "./inputdata/Kr_e4m3.txt";
    char filename[] = "./inputdata/val.txt";        //存放标签
    int picnumb = 50000;                                                //读取数量

  //图像信息
    int inputRow = 224;
    int inputCol = 224;
    int inputChannel = 3;
    int weight_size = 3*3*3*32 + 3*3*32 + 32*64 + 3*3*64 + 64*128 + 3*3*128 + \
    128*128 + 3*3*128 + 128*256 + 3*3*256 + 256*256 + 3*3*256 + 256*512 + \
    (3*3*512 + 512*512)*5 + 3*3*512 + 512*1024 + 3*3*1024 + 1024*1024 + 1024*1000;
    int bias_size = 32*2 + 64*2 + 128*4 + 256*4 + 512*12 + 1024*3 + 1000;
    int *pic_idx = (int *)malloc(picnumb * sizeof(int));
    fileidx_pointer *jpg_data = get_file_idx_pointer(filename ,picnumb , pic_idx);
    const char *bin_file_name = ".bin";
    char filelocate[60];

  //开辟主机端内存
    float *h_weight = get_weight(weight_filename , weight_size);
    float *h_bias = get_bias(bias_filename , bias_size);
    float *Kw = get_Kw(Kw_filename , 28);
    float *Kr = get_Kr(Kr_filename , 28);
    int *h_rank = (int *)malloc(5*sizeof(int));
    uint8_t* h_active = (uint8_t*)malloc(224*224*3);
    sfp   *h_weightSfp = (sfp *)malloc(weight_size*sizeof(sfp));
    int24   *h_biasint24 = (int24 *)malloc(bias_size*sizeof(int24));

  //定义type_in数组      1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28
    int Type_in[28] =  {5, 5, 5, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5};
    int Type_out[28] = {5, 5, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 5};

  /////test-5- 全低精度，单独把第二层精度提高---///  602/1000
  //  int Type_in[28] =  {5, 5, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 5};
  //  int Type_out[28] = {5, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 5, 5};

  /////test-4- 全低精度，对照测试---///  395/1000
  //  int Type_in[28] =  {5, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 5};
  //  int Type_out[28] = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 5, 5};

  /////test-3- 全高精度，对照测试---///  679/1000
  //  int Type_in[28] =  {5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5};
  //  int Type_out[28] = {5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5};

  /////test-2- Dw（偶数层）用高精度，普通卷积用低精度---/// 659/1000
  //  int Type_in[28] =  {5, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5};
  //  int Type_out[28] = {5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 5};

  /////test-1- 按权重平均值，平均值小的用sfp43-------////  643/1000
  //  int Type_in[28] =  {5, 5, 5, 5, 5, 3, 5, 3, 5, 3, 5, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5};
  //  int Type_out[28] = {5, 5, 5, 5, 3, 5, 3, 5, 3, 5, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 3, 5, 5};

  //weight,bias量化
    float *h_weight_conv1 = h_weight;
    float *h_bias_conv1 = h_bias;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ;
    sfp *h_weightSfp_conv1 = h_weightSfp;
    int24 *h_biasint24_conv1 = h_biasint24;
    get_weightSfp(h_weight_conv1, h_weightSfp_conv1, Kw[0], 3*3*3*32, Type_in[0]);
    get_biasint24(h_bias_conv1, h_biasint24_conv1, Kr[0], 32);
    float *h_weight_conv2 = h_weight_conv1 + 3*3*3*32;
    float *h_bias_conv2 = h_bias_conv1 + 32;
    sfp *h_weightSfp_conv2 = h_weightSfp_conv1 + 3*3*3*32;
    int24 *h_biasint24_conv2 = h_biasint24_conv1 + 32;
    get_weightSfp(h_weight_conv2, h_weightSfp_conv2, Kw[1], 3*3*32, Type_in[1]);
    get_biasint24(h_bias_conv2, h_biasint24_conv2, Kr[1], 32);
    float *h_weight_conv3 = h_weight_conv2 + 3*3*32;
    float *h_bias_conv3 = h_bias_conv2 + 32;
    sfp *h_weightSfp_conv3 = h_weightSfp_conv2 + 3*3*32;
    int24 *h_biasint24_conv3 = h_biasint24_conv2 + 32;
    get_weightSfp(h_weight_conv3, h_weightSfp_conv3, Kw[2], 32*64, Type_in[2]);
    get_biasint24(h_bias_conv3, h_biasint24_conv3, Kr[2], 64);
    float *h_weight_conv4 = h_weight_conv3 + 32*64;
    float *h_bias_conv4 = h_bias_conv3 + 64;
    sfp *h_weightSfp_conv4 = h_weightSfp_conv3 + 32*64;
    int24 *h_biasint24_conv4 = h_biasint24_conv3 + 64;
    get_weightSfp(h_weight_conv4, h_weightSfp_conv4, Kw[3], 3*3*64, Type_in[3]);
    get_biasint24(h_bias_conv4, h_biasint24_conv4, Kr[3], 64);
    float *h_weight_conv5 = h_weight_conv4 + 3*3*64;
    float *h_bias_conv5 = h_bias_conv4 + 64;
    sfp *h_weightSfp_conv5 = h_weightSfp_conv4 + 3*3*64;
    int24 *h_biasint24_conv5 = h_biasint24_conv4 + 64;
    get_weightSfp(h_weight_conv5, h_weightSfp_conv5, Kw[4], 64*128, Type_in[4]);
    get_biasint24(h_bias_conv5, h_biasint24_conv5, Kr[4], 128);
    float *h_weight_conv6 = h_weight_conv5 + 64*128;
    float *h_bias_conv6 = h_bias_conv5 + 128;
    sfp *h_weightSfp_conv6 = h_weightSfp_conv5 + 64*128;
    int24 *h_biasint24_conv6 = h_biasint24_conv5 + 128;
    get_weightSfp(h_weight_conv6, h_weightSfp_conv6, Kw[5], 3*3*128, Type_in[5]);
    get_biasint24(h_bias_conv6, h_biasint24_conv6, Kr[5], 128);
    float *h_weight_conv7 = h_weight_conv6 + 3*3*128;
    float *h_bias_conv7 = h_bias_conv6 + 128;
    sfp *h_weightSfp_conv7 = h_weightSfp_conv6 + 3*3*128;
    int24 *h_biasint24_conv7 = h_biasint24_conv6 + 128;
    get_weightSfp(h_weight_conv7, h_weightSfp_conv7, Kw[6], 128*128, Type_in[6]);
    get_biasint24(h_bias_conv7, h_biasint24_conv7, Kr[6], 128);
    float *h_weight_conv8 = h_weight_conv7 + 128*128;
    float *h_bias_conv8 = h_bias_conv7 + 128;
    sfp *h_weightSfp_conv8 = h_weightSfp_conv7 + 128*128;
    int24 *h_biasint24_conv8 = h_biasint24_conv7 + 128;
    get_weightSfp(h_weight_conv8, h_weightSfp_conv8, Kw[7], 3*3*128, Type_in[7]);
    get_biasint24(h_bias_conv8, h_biasint24_conv8, Kr[7], 128);
    float *h_weight_conv9 = h_weight_conv8 + 3*3*128;
    float *h_bias_conv9 = h_bias_conv8 + 128;
    sfp *h_weightSfp_conv9 = h_weightSfp_conv8 + 3*3*128;
    int24 *h_biasint24_conv9 = h_biasint24_conv8 + 128;
    get_weightSfp(h_weight_conv9, h_weightSfp_conv9, Kw[8], 128*256, Type_in[8]);
    get_biasint24(h_bias_conv9, h_biasint24_conv9, Kr[8], 256);
    float *h_weight_conv10 = h_weight_conv9 + 128*256;
    float *h_bias_conv10 = h_bias_conv9 + 256;
    sfp *h_weightSfp_conv10 = h_weightSfp_conv9 + 128*256;
    int24 *h_biasint24_conv10 = h_biasint24_conv9 + 256;
    get_weightSfp(h_weight_conv10, h_weightSfp_conv10, Kw[9], 3*3*256, Type_in[9]);
    get_biasint24(h_bias_conv10, h_biasint24_conv10, Kr[9], 256);
    float *h_weight_conv11 = h_weight_conv10 + 3*3*256;
    float *h_bias_conv11 = h_bias_conv10 + 256;
    sfp *h_weightSfp_conv11 = h_weightSfp_conv10 + 3*3*256;
    int24 *h_biasint24_conv11 = h_biasint24_conv10+ 256;
    get_weightSfp(h_weight_conv11, h_weightSfp_conv11, Kw[10], 256*256, Type_in[10]);
    get_biasint24(h_bias_conv11, h_biasint24_conv11, Kr[10], 256);
    float *h_weight_conv12 = h_weight_conv11 + 256*256;
    float *h_bias_conv12 = h_bias_conv11 + 256;
    sfp *h_weightSfp_conv12 = h_weightSfp_conv11 + 256*256;
    int24 *h_biasint24_conv12 = h_biasint24_conv11 + 256;
    get_weightSfp(h_weight_conv12, h_weightSfp_conv12, Kw[11], 3*3*256, Type_in[11]);
    get_biasint24(h_bias_conv12, h_biasint24_conv12, Kr[11], 256);
    float *h_weight_conv13 = h_weight_conv12 + 3*3*256;
    float *h_bias_conv13 = h_bias_conv12 + 256;
    sfp *h_weightSfp_conv13 = h_weightSfp_conv12 + 3*3*256;
    int24 *h_biasint24_conv13 = h_biasint24_conv12 + 256;
    get_weightSfp(h_weight_conv13, h_weightSfp_conv13, Kw[12], 256*512, Type_in[12]);
    get_biasint24(h_bias_conv13, h_biasint24_conv13, Kr[12], 512);
    float *h_weight_conv14 = h_weight_conv13 + 256*512;
    float *h_bias_conv14 = h_bias_conv13 + 512;
    sfp *h_weightSfp_conv14 = h_weightSfp_conv13 + 256*512;
    int24 *h_biasint24_conv14 = h_biasint24_conv13 + 512;
    get_weightSfp(h_weight_conv14, h_weightSfp_conv14, Kw[13], 3*3*512, Type_in[13]);
    get_biasint24(h_bias_conv14, h_biasint24_conv14, Kr[13], 512);
    float *h_weight_conv15 = h_weight_conv14 + 3*3*512;
    float *h_bias_conv15 = h_bias_conv14 + 512;
    sfp *h_weightSfp_conv15 = h_weightSfp_conv14 + 3*3*512;
    int24 *h_biasint24_conv15 = h_biasint24_conv14 + 512;
    get_weightSfp(h_weight_conv15, h_weightSfp_conv15, Kw[14], 512*512, Type_in[14]);
    get_biasint24(h_bias_conv15, h_biasint24_conv15, Kr[14], 512);
    float *h_weight_conv16 = h_weight_conv15 + 512*512;
    float *h_bias_conv16 = h_bias_conv15 + 512;
    sfp *h_weightSfp_conv16 = h_weightSfp_conv15 + 512*512;
    int24 *h_biasint24_conv16 = h_biasint24_conv15 + 512;
    get_weightSfp(h_weight_conv16, h_weightSfp_conv16, Kw[15], 3*3*512, Type_in[15]);
    get_biasint24(h_bias_conv16, h_biasint24_conv16, Kr[15], 512);
    float *h_weight_conv17 = h_weight_conv16 + 3*3*512;
    float *h_bias_conv17 = h_bias_conv16 + 512;
    sfp *h_weightSfp_conv17 = h_weightSfp_conv16 + 3*3*512;
    int24 *h_biasint24_conv17 = h_biasint24_conv16 + 512;
    get_weightSfp(h_weight_conv17, h_weightSfp_conv17, Kw[16], 512*512, Type_in[16]);
    get_biasint24(h_bias_conv17, h_biasint24_conv17, Kr[16], 512);
    float *h_weight_conv18 = h_weight_conv17 + 512*512;
    float *h_bias_conv18 = h_bias_conv17 + 512;
    sfp *h_weightSfp_conv18 = h_weightSfp_conv17 + 512*512;
    int24 *h_biasint24_conv18 = h_biasint24_conv17 + 512;
    get_weightSfp(h_weight_conv18, h_weightSfp_conv18, Kw[17], 3*3*512, Type_in[17]);
    get_biasint24(h_bias_conv18, h_biasint24_conv18, Kr[17], 512);
    float *h_weight_conv19 = h_weight_conv18 + 3*3*512;
    float *h_bias_conv19 = h_bias_conv18 + 512;
    sfp *h_weightSfp_conv19 = h_weightSfp_conv18 + 3*3*512;
    int24 *h_biasint24_conv19 = h_biasint24_conv18 + 512;
    get_weightSfp(h_weight_conv19, h_weightSfp_conv19, Kw[18], 512*512, Type_in[18]);
    get_biasint24(h_bias_conv19, h_biasint24_conv19, Kr[18], 512);
    float *h_weight_conv20 = h_weight_conv19 + 512*512;
    float *h_bias_conv20 = h_bias_conv19 + 512;
    sfp *h_weightSfp_conv20 = h_weightSfp_conv19 + 512*512;
    int24 *h_biasint24_conv20 = h_biasint24_conv19 + 512;
    get_weightSfp(h_weight_conv20, h_weightSfp_conv20, Kw[19], 3*3*512, Type_in[19]);
    get_biasint24(h_bias_conv20, h_biasint24_conv20, Kr[19], 512);
    float *h_weight_conv21 = h_weight_conv20 + 3*3*512;
    float *h_bias_conv21 = h_bias_conv20 + 512;
    sfp *h_weightSfp_conv21 = h_weightSfp_conv20 + 3*3*512;
    int24 *h_biasint24_conv21 = h_biasint24_conv20 + 512;
    get_weightSfp(h_weight_conv21, h_weightSfp_conv21, Kw[20], 512*512, Type_in[20]);
    get_biasint24(h_bias_conv21, h_biasint24_conv21, Kr[20], 512);
    float *h_weight_conv22 = h_weight_conv21 + 512*512;
    float *h_bias_conv22 = h_bias_conv21 + 512;
    sfp *h_weightSfp_conv22 = h_weightSfp_conv21 + 512*512;
    int24 *h_biasint24_conv22 = h_biasint24_conv21 + 512;
    get_weightSfp(h_weight_conv22, h_weightSfp_conv22, Kw[21], 3*3*512, Type_in[21]);
    get_biasint24(h_bias_conv22, h_biasint24_conv22, Kr[21], 512);
    float *h_weight_conv23 = h_weight_conv22 + 3*3*512;
    float *h_bias_conv23 = h_bias_conv22 + 512;
    sfp *h_weightSfp_conv23 = h_weightSfp_conv22 + 3*3*512;
    int24 *h_biasint24_conv23 = h_biasint24_conv22 + 512;
    get_weightSfp(h_weight_conv23, h_weightSfp_conv23, Kw[22], 512*512, Type_in[22]);
    get_biasint24(h_bias_conv23, h_biasint24_conv23, Kr[22], 512);
    float *h_weight_conv24 = h_weight_conv23 + 512*512;
    float *h_bias_conv24 = h_bias_conv23 + 512;
    sfp *h_weightSfp_conv24 = h_weightSfp_conv23 + 512*512;
    int24 *h_biasint24_conv24 = h_biasint24_conv23 + 512;
    get_weightSfp(h_weight_conv24, h_weightSfp_conv24, Kw[23], 3*3*512, Type_in[23]);
    get_biasint24(h_bias_conv24, h_biasint24_conv24, Kr[23], 512);
    float *h_weight_conv25 = h_weight_conv24 + 3*3*512;
    float *h_bias_conv25 = h_bias_conv24 + 512;
    sfp *h_weightSfp_conv25 = h_weightSfp_conv24 + 3*3*512;
    int24 *h_biasint24_conv25 = h_biasint24_conv24 + 512;
    get_weightSfp(h_weight_conv25, h_weightSfp_conv25, Kw[24], 512*1024, Type_in[24]);
    get_biasint24(h_bias_conv25, h_biasint24_conv25, Kr[24], 1024);
    float *h_weight_conv26 = h_weight_conv25 + 512*1024;
    float *h_bias_conv26 = h_bias_conv25 + 1024;
    sfp *h_weightSfp_conv26 = h_weightSfp_conv25 + 512*1024;
    int24 *h_biasint24_conv26 = h_biasint24_conv25 + 1024;
    get_weightSfp(h_weight_conv26, h_weightSfp_conv26, Kw[25], 3*3*1024, Type_in[25]);
    get_biasint24(h_bias_conv26, h_biasint24_conv26, Kr[25], 1024);
    float *h_weight_conv27 = h_weight_conv26 + 3*3*1024;
    float *h_bias_conv27 = h_bias_conv26 + 1024;
    sfp *h_weightSfp_conv27 = h_weightSfp_conv26 + 3*3*1024;
    int24 *h_biasint24_conv27 = h_biasint24_conv26 + 1024;
    get_weightSfp(h_weight_conv27, h_weightSfp_conv27, Kw[26], 1024*1024, Type_in[26]);
    get_biasint24(h_bias_conv27, h_biasint24_conv27, Kr[26], 1024);
    float *h_weight_conv28 = h_weight_conv27 + 1024*1024;
    float *h_bias_conv28 = h_bias_conv27 + 1024;
    sfp *h_weightSfp_conv28 = h_weightSfp_conv27 + 1024*1024;
    int24 *h_biasint24_conv28 = h_biasint24_conv27 + 1024;
    get_weightSfp(h_weight_conv28, h_weightSfp_conv28, Kw[27], 1024*1000, Type_in[27]);
    get_biasint24(h_bias_conv28, h_biasint24_conv28, Kr[27], 1000);
  //开辟设备端内存 
    uint8_t *d_active = NULL;
    (cudaMalloc((void**) &d_active, inputRow*inputCol*inputChannel));
    sfp *d_weight = NULL;
    (cudaMalloc((void**) &d_weight, weight_size*sizeof(sfp)));
    float *d_bias = NULL;
    (cudaMalloc((void**) &d_bias, bias_size*sizeof(int24)));
    int *d_pic_idx = NULL;
    (cudaMalloc((void**) &d_pic_idx, picnumb*sizeof(int)));
    sfp *d_image = NULL;
    (cudaMalloc((void**) &d_image, 224*224*3*sizeof(sfp)));



    (cudaMemcpy(d_weight, h_weightSfp, weight_size*sizeof(sfp), cudaMemcpyHostToDevice));
    (cudaMemcpy(d_bias, h_bias, bias_size*sizeof(float), cudaMemcpyHostToDevice));
    (cudaMemcpy(d_pic_idx , pic_idx , picnumb*sizeof(int) , cudaMemcpyHostToDevice));


    sfp *d_out_net1 = NULL;
    sfp *d_weight_net1 = d_weight;
    float *d_bias_net1 = d_bias;
    (cudaMalloc((void**) &d_out_net1, 112*112*32*sizeof(sfp)));
    sfp *d_out_net2 = NULL;
    sfp *d_weight_net2 = d_weight_net1 + 3*3*3*32;
    float *d_bias_net2 = d_bias_net1 + 32;
    (cudaMalloc((void**) &d_out_net2, 112*112*32*sizeof(sfp)));
    sfp *d_out_net3 = NULL;
    sfp *d_weight_net3 = d_weight_net2 + 3*3*32;
    float *d_bias_net3 = d_bias_net2 + 32;
    (cudaMalloc((void**) &d_out_net3, 112*112*64*sizeof(sfp)));
    sfp *d_out_net4 = NULL;
    sfp *d_weight_net4 = d_weight_net3 + 32*64;
    float *d_bias_net4 = d_bias_net3 + 64;
    (cudaMalloc((void**) &d_out_net4, 56*56*64*sizeof(sfp)));
    sfp *d_out_net5 = NULL;
    sfp *d_weight_net5 = d_weight_net4 + 3*3*64;
    float *d_bias_net5 = d_bias_net4 + 64;
    (cudaMalloc((void**) &d_out_net5, 56*56*128*sizeof(sfp)));
    sfp *d_out_net6 = NULL;
    sfp *d_weight_net6 = d_weight_net5 + 64*128;
    float *d_bias_net6 = d_bias_net5 + 128;
    (cudaMalloc((void**) &d_out_net6, 56*56*128*sizeof(sfp)));
    sfp *d_out_net7 = NULL;
    sfp *d_weight_net7 = d_weight_net6 + 3*3*128;
    float *d_bias_net7 = d_bias_net6 + 128;
    (cudaMalloc((void**) &d_out_net7, 56*56*128*sizeof(sfp)));
    sfp *d_out_net8 = NULL;
    sfp *d_weight_net8 = d_weight_net7 + 128*128;
    float *d_bias_net8 = d_bias_net7 + 128;
    (cudaMalloc((void**) &d_out_net8, 28*28*128*sizeof(sfp)));
    sfp *d_out_net9 = NULL;
    sfp *d_weight_net9 = d_weight_net8 + 3*3*128;
    float *d_bias_net9 = d_bias_net8 + 128;
    (cudaMalloc((void**) &d_out_net9, 28*28*256*sizeof(sfp)));
    sfp *d_out_net10 = NULL;
    sfp *d_weight_net10 = d_weight_net9 + 128*256;
    float *d_bias_net10 = d_bias_net9 + 256;
    (cudaMalloc((void**) &d_out_net10, 28*28*256*sizeof(sfp)));
    sfp *d_out_net11 = NULL;
    sfp *d_weight_net11 = d_weight_net10 + 3*3*256;
    float *d_bias_net11 = d_bias_net10 + 256;
    (cudaMalloc((void**) &d_out_net11, 28*28*256*sizeof(sfp)));
    sfp *d_out_net12 = NULL;
    sfp *d_weight_net12 = d_weight_net11 + 256*256;
    float *d_bias_net12 = d_bias_net11 + 256;
    (cudaMalloc((void**) &d_out_net12, 14*14*256*sizeof(sfp)));
    sfp *d_out_net13 = NULL;
    sfp *d_weight_net13 = d_weight_net12 + 3*3*256;
    float *d_bias_net13 = d_bias_net12 + 256;
    (cudaMalloc((void**) &d_out_net13, 14*14*512*sizeof(sfp)));
    sfp *d_out_net14 = NULL;
    sfp *d_weight_net14 = d_weight_net13 + 256*512;
    float *d_bias_net14 = d_bias_net13 + 512;
    (cudaMalloc((void**) &d_out_net14, 14*14*512*sizeof(sfp)));
    sfp *d_out_net15 = NULL;
    sfp *d_weight_net15 = d_weight_net14 + 3*3*512;
    float *d_bias_net15 = d_bias_net14 + 512;
    (cudaMalloc((void**) &d_out_net15, 14*14*512*sizeof(sfp)));
    sfp *d_out_net16 = NULL;
    sfp *d_weight_net16 = d_weight_net15 + 512*512;
    float *d_bias_net16 = d_bias_net15 + 512;
    (cudaMalloc((void**) &d_out_net16, 14*14*512*sizeof(sfp)));
    sfp *d_out_net17 = NULL;
    sfp *d_weight_net17 = d_weight_net16 + 3*3*512;
    float *d_bias_net17 = d_bias_net16 + 512;
    (cudaMalloc((void**) &d_out_net17, 14*14*512*sizeof(sfp)));
    sfp *d_out_net18 = NULL;
    sfp *d_weight_net18 = d_weight_net17 + 512*512;
    float *d_bias_net18 = d_bias_net17 + 512;
    (cudaMalloc((void**) &d_out_net18, 14*14*512*sizeof(sfp)));
    sfp *d_out_net19 = NULL;
    sfp *d_weight_net19 = d_weight_net18 + 3*3*512;
    float *d_bias_net19 = d_bias_net18 + 512;
    (cudaMalloc((void**) &d_out_net19, 14*14*512*sizeof(sfp)));
    sfp *d_out_net20 = NULL;
    sfp *d_weight_net20 = d_weight_net19 + 512*512;
    float *d_bias_net20 = d_bias_net19 + 512;
    (cudaMalloc((void**) &d_out_net20, 14*14*512*sizeof(sfp)));
    sfp *d_out_net21 = NULL;
    sfp *d_weight_net21 = d_weight_net20 + 3*3*512;
    float *d_bias_net21 = d_bias_net20 + 512;
    (cudaMalloc((void**) &d_out_net21, 14*14*512*sizeof(sfp)));
    sfp *d_out_net22 = NULL;
    sfp *d_weight_net22 = d_weight_net21 + 512*512;
    float *d_bias_net22 = d_bias_net21 + 512;
    (cudaMalloc((void**) &d_out_net22, 14*14*512*sizeof(sfp)));
    sfp *d_out_net23 = NULL;
    sfp *d_weight_net23 = d_weight_net22 + 3*3*512;
    float *d_bias_net23 = d_bias_net22 + 512;
    (cudaMalloc((void**) &d_out_net23, 14*14*512*sizeof(sfp)));
    sfp *d_out_net24 = NULL;
    sfp *d_weight_net24 = d_weight_net23 + 512*512;
    float *d_bias_net24 = d_bias_net23 + 512;
    (cudaMalloc((void**) &d_out_net24, 7*7*512*sizeof(sfp)));
    sfp *d_out_net25 = NULL;
    sfp *d_weight_net25 = d_weight_net24 + 3*3*512;
    float *d_bias_net25 = d_bias_net24 + 512;
    (cudaMalloc((void**) &d_out_net25, 7*7*1024*sizeof(sfp)));
    sfp *d_out_net26 = NULL;
    sfp *d_weight_net26 = d_weight_net25 + 512*1024;
    float *d_bias_net26 = d_bias_net25 + 1024;
    (cudaMalloc((void**) &d_out_net26, 7*7*1024*sizeof(sfp)));
    sfp *d_out_net27 = NULL;
    sfp *d_weight_net27 = d_weight_net26 + 3*3*1024;
    float *d_bias_net27 = d_bias_net26 + 1024;
    (cudaMalloc((void**) &d_out_net27, 7*7*1024*sizeof(sfp)));
    sfp *d_out_avg = NULL;
    (cudaMalloc((void**) &d_out_avg, 1024*sizeof(sfp)));
    sfp *d_out_fc = NULL;
    sfp *d_weight_fc = d_weight_net27 + 1024*1024;
    float *d_bias_fc = d_bias_net27 + 1024;
    (cudaMalloc((void**) &d_out_fc, 1000*sizeof(sfp)));
    int *d_rank = NULL;
    (cudaMalloc((void**) &d_rank , 5*sizeof(int)));
    int *d_TOP1 = NULL;
    (cudaMalloc((void**) &d_TOP1 , sizeof(int)));
    int *d_TOP5 = NULL;
    (cudaMalloc((void**) &d_TOP5 , sizeof(int)));
    float *outint24 = NULL;
    (cudaMalloc((void**) &outint24 , 112*112*64*sizeof(float)));


    sfp *test = (sfp *)malloc(112*112*64*sizeof(sfp));
    float Ka = 0.003960;
  //计算卷积，卷积开始
//  for(int l = 0 ; l < 27; ++l)
//   {
//     printf("[%d]:%d\n", l , Type_in[l]);
//   }

    for (int i = 0 ; i < 1000 ; ++i)
    {
      strcpy(filelocate , input_pic);
      strcat(filelocate , jpg_data[i].jpgname);
      strcat(filelocate , bin_file_name);
      get_parameter(filelocate , h_active);
      (cudaMemcpy(d_active, h_active, inputRow*inputCol*inputChannel*sizeof(uint8_t) , cudaMemcpyHostToDevice));
      image   <<<dim3(224 , 3),dim3(224)>>>(d_active , d_image , 224, Ka);  //sfp45
      conv2   <<<dim3(112 , 32),dim3(112)>>>(d_image , d_weight_net1 , d_bias_net1 , d_out_net1 , outint24 , 224 , 112 , 3, Ka, Kw[0], Kr[0], Type_in[0], Type_out[0]);  //layer-1
      conv_DW <<<dim3(112 , 32),dim3(112)>>>(d_out_net1 , d_weight_net2 , d_bias_net2 , d_out_net2 , outint24 , 112 , 112 , 1, Kr[0], Kw[1], Kr[1], Type_in[1], Type_out[1]);  //2
      conv1   <<<dim3(112 , 64),dim3(112)>>>(d_out_net2 , d_weight_net3 , d_bias_net3 , d_out_net3 , outint24 , 112 , 112 , 32, Kr[1], Kw[2], Kr[2],Type_in[2], Type_out[2]);  //3
      conv_DW <<<dim3(56 , 64),dim3(56)>>>(d_out_net3 , d_weight_net4 , d_bias_net4 , d_out_net4 , outint24 , 112 , 56 , 2, Kr[2], Kw[3], Kr[3],Type_in[3], Type_out[3]);      //4
      conv1   <<<dim3(56 , 128),dim3(56)>>>(d_out_net4 , d_weight_net5 , d_bias_net5 , d_out_net5 , outint24 , 56 , 56 , 64, Kr[3], Kw[4], Kr[4],Type_in[4], Type_out[4]);     //5
      conv_DW <<<dim3(56 , 128),dim3(56)>>>(d_out_net5 , d_weight_net6 , d_bias_net6 , d_out_net6 , outint24 , 56 , 56 , 1, Kr[4], Kw[5], Kr[5],Type_in[5], Type_out[5]);      //6
      conv1   <<<dim3(56 , 128),dim3(56)>>>(d_out_net6 , d_weight_net7 , d_bias_net7 , d_out_net7 , outint24 , 56 , 56 , 128, Kr[5], Kw[6], Kr[6],Type_in[6], Type_out[6]);    //7
      conv_DW <<<dim3(28 , 128),dim3(28)>>>(d_out_net7 , d_weight_net8 , d_bias_net8 , d_out_net8 , outint24 , 56 , 28 , 2, Kr[6], Kw[7], Kr[7],Type_in[7], Type_out[7]);      //8
      conv1   <<<dim3(28 , 256),dim3(28)>>>(d_out_net8 , d_weight_net9 , d_bias_net9 , d_out_net9 , outint24 , 28 , 28 , 128, Kr[7], Kw[8], Kr[8],Type_in[8], Type_out[8]);    //9
      conv_DW <<<dim3(28 , 256),dim3(28)>>>(d_out_net9 , d_weight_net10 , d_bias_net10 , d_out_net10 , outint24 , 28 , 28 , 1, Kr[8], Kw[9], Kr[9],Type_in[9], Type_out[9]);   //10
      conv1   <<<dim3(28 , 256),dim3(28)>>>(d_out_net10 , d_weight_net11 , d_bias_net11 , d_out_net11 , outint24 , 28 , 28 , 256, Kr[9], Kw[10], Kr[10], Type_in[10], Type_out[10]); //11
      conv_DW <<<dim3(14 , 256),dim3(14)>>>(d_out_net11 , d_weight_net12 , d_bias_net12 , d_out_net12 , outint24 , 28 , 14 , 2, Kr[10], Kw[11], Kr[11], Type_in[11], Type_out[11]);  //12
      conv1   <<<dim3(14 , 512),dim3(14)>>>(d_out_net12 , d_weight_net13 , d_bias_net13 , d_out_net13 , outint24 , 14 , 14 , 256, Kr[11], Kw[12], Kr[12], Type_in[12], Type_out[12]);//13
      conv_DW <<<dim3(14 , 512),dim3(14)>>>(d_out_net13 , d_weight_net14 , d_bias_net14 , d_out_net14 , outint24 , 14 , 14 , 1, Kr[12], Kw[13], Kr[13], Type_in[13], Type_out[13]);  //14
      conv1   <<<dim3(14 , 512),dim3(14)>>>(d_out_net14 , d_weight_net15 , d_bias_net15 , d_out_net15 , outint24 , 14 , 14 , 512, Kr[13], Kw[14], Kr[14], Type_in[14], Type_out[14]);//15
      conv_DW <<<dim3(14 , 512),dim3(14)>>>(d_out_net15 , d_weight_net16 , d_bias_net16 , d_out_net16 , outint24 , 14 , 14 , 1, Kr[14], Kw[15], Kr[15], Type_in[15], Type_out[15]);  //16
      conv1   <<<dim3(14 , 512),dim3(14)>>>(d_out_net16 , d_weight_net17 , d_bias_net17 , d_out_net17 , outint24 , 14 , 14 , 512, Kr[15], Kw[16], Kr[16], Type_in[16], Type_out[16]);//17
      conv_DW <<<dim3(14 , 512),dim3(14)>>>(d_out_net17 , d_weight_net18 , d_bias_net18 , d_out_net18 , outint24 , 14 , 14 , 1, Kr[16], Kw[17], Kr[17], Type_in[17], Type_out[17]);  //18
      conv1   <<<dim3(14 , 512),dim3(14)>>>(d_out_net18 , d_weight_net19 , d_bias_net19 , d_out_net19 , outint24 , 14 , 14 , 512, Kr[17], Kw[18], Kr[18], Type_in[18], Type_out[18]);//19
      conv_DW <<<dim3(14 , 512),dim3(14)>>>(d_out_net19 , d_weight_net20 , d_bias_net20 , d_out_net20 , outint24 , 14 , 14 , 1, Kr[18], Kw[19], Kr[19], Type_in[19], Type_out[19]);  //20
      conv1   <<<dim3(14 , 512),dim3(14)>>>(d_out_net20 , d_weight_net21 , d_bias_net21 , d_out_net21 , outint24 , 14 , 14 , 512, Kr[19], Kw[20], Kr[20], Type_in[20], Type_out[20]);//21
      conv_DW <<<dim3(14 , 512),dim3(14)>>>(d_out_net21 , d_weight_net22 , d_bias_net22 , d_out_net22 , outint24 , 14 , 14 , 1, Kr[20], Kw[21], Kr[21], Type_in[21], Type_out[21]);  //22
      conv1   <<<dim3(14 , 512),dim3(14)>>>(d_out_net22 , d_weight_net23 , d_bias_net23 , d_out_net23 , outint24 , 14 , 14 , 512, Kr[21], Kw[22], Kr[22], Type_in[22], Type_out[22]);//23
      conv_DW <<<dim3(7 , 512),dim3(7)>>>(d_out_net23 , d_weight_net24 , d_bias_net24 , d_out_net24 , outint24 , 14 , 7 , 2, Kr[22], Kw[23], Kr[23], Type_in[23], Type_out[23]);     //24
      conv1   <<<dim3(7 , 1024),dim3(7)>>>(d_out_net24 , d_weight_net25 , d_bias_net25 , d_out_net25 , outint24 , 7 , 7 , 512, Kr[23], Kw[24], Kr[24], Type_in[24], Type_out[24]);   //25
      conv_DW <<<dim3(7 , 1024),dim3(7)>>>(d_out_net25 , d_weight_net26 , d_bias_net26 , d_out_net26 , outint24 , 7 , 7 , 1, Kr[24], Kw[25], Kr[25], Type_in[25], Type_out[25]);     //26
      conv1   <<<dim3(7 , 1024),dim3(7)>>>(d_out_net26 , d_weight_net27 , d_bias_net27 , d_out_net27 , outint24 , 7 , 7 , 1024, Kr[25], Kw[26], Kr[26], Type_in[26], Type_out[26]);  //27
      avgpool <<<dim3(1) , dim3(1024)>>>(d_out_net27 , d_out_avg , 7);
      fullconnection <<<dim3(1) , dim3(1024)>>>(d_out_avg , d_weight_fc , d_bias_fc , d_out_fc, outint24 , Kr[26], Kw[27], Kr[27]);              // 第28层
      BubbleSort <<<dim3(1) , dim3(1)>>>(d_out_fc , d_rank , d_TOP1 , d_TOP5 , d_pic_idx , i , picnumb, Kr[27]);
    }
    // cudaMemcpy(test, d_out_net2,112*112*32*sizeof(sfp), cudaMemcpyDeviceToHost);
    // for(int l = 0 ; l < 112*112*32; ++l)
    // {
    //   // printf("[%d]:%f\n",l,Kr[1]*sfpfloat(test[l]));
    // }
    
  // Free device global memory
    (cudaFree(d_out_net1));
    (cudaFree(d_out_net2));
    (cudaFree(d_out_net3));
    (cudaFree(d_out_net4));
    (cudaFree(d_out_net5));
    (cudaFree(d_out_net6));
    (cudaFree(d_out_net7));
    (cudaFree(d_out_net8));
    (cudaFree(d_out_net9));
    (cudaFree(d_out_net10));
    (cudaFree(d_out_net11));
    (cudaFree(d_out_net12));
    (cudaFree(d_out_net13));
    (cudaFree(d_out_net14));
    (cudaFree(d_out_net15));
    (cudaFree(d_out_net16));
    (cudaFree(d_out_net17));
    (cudaFree(d_out_net18));
    (cudaFree(d_out_net19));
    (cudaFree(d_out_net20));
    (cudaFree(d_out_net21));
    (cudaFree(d_out_net22));
    (cudaFree(d_out_net23));
    (cudaFree(d_out_net24));
    (cudaFree(d_out_net25));
    (cudaFree(d_out_net26));
    (cudaFree(d_out_net27));
    (cudaFree(d_out_avg));
    (cudaFree(d_rank));
    (cudaFree(d_active));
    (cudaFree(d_weight));
    (cudaFree(d_pic_idx));
    (cudaFree(d_TOP1));
    (cudaFree(d_TOP5));

    // Free host memory
    free(h_active);
    free(h_weight);
    free(h_rank);
    free(jpg_data);
    free(pic_idx);
    cudaDeviceReset();  
    return 0;
}

