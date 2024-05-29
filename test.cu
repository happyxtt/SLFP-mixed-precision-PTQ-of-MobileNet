#include "./common/MobileNetv1.h"
#include <iostream>

using namespace std;
using std::cout;

sfp floatsfp(float a, int type)  //finished
  {
    myfixed reg;
    myfixed regFixed;
    sfp out;
    float Mfraction;
    if(type == 5)
    {
      reg.sign = (a >= 0)?0:1;//符号位
      reg.integer = (int)abs(a);//整数部分
      Mfraction = abs(a) - reg.integer;//取小数部分
      reg.fraction = 0;
      for(int i = 0; i < 13; ++i)
      {
        reg.fraction  = reg.fraction << 1; 
        if( Mfraction*2 >= 1)
        {
          reg.fraction = reg.fraction + 1;
          Mfraction = Mfraction*2 - 1;
        }
        else
        {
          reg.fraction = reg.fraction + 0;
          Mfraction = Mfraction*2;
        }
      }
      regFixed.fix  = ((reg.fraction&0b1) == 1)?((reg.integer << 12) + (reg.fraction>>1) + 1) : ((reg.integer << 12) + (reg.fraction>>1));
      //首先判断符号位
      if(reg.sign == 1)
      {
        out.sign = 1;
      }
      else
      {
        out.sign = 0;
      }

      //判断是否超出SFP表示范围
      if(regFixed.fix >= 0xFE000)//格式为1111 11_1X.XXXX XXXX XXXX
      {
        out.exp = 15;
        out.mnt = 31;
      }
      else if(regFixed.fix <= 0x10)//格式为0.0000 0001 0000 
      {
        out.exp = 0;
        out.mnt = 0;
      }
      else
      {
        if(regFixed.fix >= 0x80000)//格式为1XXX XX_XX.XXXX XXXX XXXX
          {
            if((regFixed.fix&0x3FFF) == 0x2000)//余位为1000...的情况
            {
              if((regFixed.fix&0x4000) == 0x4000)//尾数为奇数+1,偶数不进位
              {
                out.exp = 15;
                out.mnt = ((regFixed.fix&0x7C000)>>14) + 1;
              }
              else
              {
                out.exp = 15;
                out.mnt = ((regFixed.fix&0x7C000)>>14);
              }
            }
            else if((regFixed.fix&0x3FFF) > 0x2000)//不是1000...的情况。大于进位，小于舍去
            {
              out.exp = 15;
              out.mnt = ((regFixed.fix&0x7C000)>>14) + 1;
            }
            else
            {
              out.exp = 15;
              out.mnt = ((regFixed.fix&0x7C000)>>14);
            }
          }
        else if((regFixed.fix >= 0x40000) && (regFixed.fix < 0x80000))//格式为1XX XXX_X.XXXX XXXX XXXX
          {
            if((regFixed.fix&0x1FFF) == 0x1000)//余位为1000...的情况
            {
              if((regFixed.fix&0x2000) == 0x2000)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x3E000)>>13) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 14 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 14;
                  out.mnt = ((regFixed.fix&0x3E000)>>13) + 1;
                }
              }
              else
              {
                out.exp = 14;
                out.mnt = ((regFixed.fix&0x3E000)>>13);
              }
            }
            else if((regFixed.fix&0x1FFF) > 0x1000)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0x3E000)>>13) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 14 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 14;
                  out.mnt = ((regFixed.fix&0x3E000)>>13) + 1;
                }
              }
              else
              {
                out.exp = 14;
                out.mnt = ((regFixed.fix&0x3E000)>>13);
              }
          }
        else if((regFixed.fix >= 0x20000) && (regFixed.fix < 0x40000))//格式为1X XXXX._XXXX XXXX XXXX
          {
            if((regFixed.fix&0xFFF) == 0x800)//余位为1000...的情况
            {
              if((regFixed.fix&0x1000) == 0x1000)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x1F000)>>12) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 13 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 13;
                  out.mnt = ((regFixed.fix&0x1F000)>>12) + 1;
                }
              }
              else
              {
                out.exp = 13;
                out.mnt = ((regFixed.fix&0x1F000)>>12);
              }
            }
            else if((regFixed.fix&0xFFF) > 0x800)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0x1F000)>>12) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 13 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 13;
                  out.mnt = ((regFixed.fix&0x1F000)>>12) + 1;
                }
              }
              else
              {
                out.exp = 13;
                out.mnt = ((regFixed.fix&0x1F000)>>12);
              }
          }
        else if((regFixed.fix >= 0x10000) && (regFixed.fix < 0x20000))//格式为1 XXXX.X_XXX XXXX XXXX
          {
            if((regFixed.fix&0x7FF) == 0x400)//余位为1000...的情况
            {
              if((regFixed.fix&0x800) == 0x800)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0xF800)>>11) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 12 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 12;
                  out.mnt = ((regFixed.fix&0xF800)>>11) + 1;
                }
              }
              else
              {
                out.exp = 12;
                out.mnt = ((regFixed.fix&0xF800)>>11);
              }
            }
            else if((regFixed.fix&0x7FF) > 0x400)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0xF800)>>11) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 12 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 12;
                  out.mnt = ((regFixed.fix&0xF800)>>11) + 1;
                }
              }
              else
              {
                out.exp = 12;
                out.mnt = ((regFixed.fix&0xF800)>>11);
              }
          }
        else if((regFixed.fix >= 0x8000) && (regFixed.fix < 0x10000))//格式为1XXX.XX_XX XXXX XXXX
          {
            if((regFixed.fix&0x3FF) == 0x200)//余位为1000...的情况
            {
              if((regFixed.fix&0x400) == 0x400)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x7C00)>>10) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 11 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 11;
                  out.mnt = ((regFixed.fix&0x7C00)>>10) + 1;
                }
              }
              else
              {
                out.exp = 11;
                out.mnt = ((regFixed.fix&0x7C00)>>10);
              }
            }
            else if((regFixed.fix&0x3FF) > 0x200)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0x7C00)>>10) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 11 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 11;
                  out.mnt = ((regFixed.fix&0x7C00)>>10) + 1;
                }
              }
              else
              {
                out.exp = 11;
                out.mnt = ((regFixed.fix&0x7C00)>>10);
              }
          }
        else if((regFixed.fix >= 0x4000) && (regFixed.fix < 0x8000))//格式为1XX.XXX_X XXXX XXXX
          {
            if((regFixed.fix&0x1FF) == 0x100)//余位为1000...的情况
            {
              if((regFixed.fix&0x200) == 0x200)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x3E00)>>9) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 10 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 10;
                  out.mnt = ((regFixed.fix&0x3E00)>>9) + 1;
                }
              }
              else
              {
                out.exp = 10;
                out.mnt = ((regFixed.fix&0x3E00)>>9);
              }
            }
            else if((regFixed.fix&0x1FF) > 0x100)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0x3E00)>>9) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 10 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 10;
                  out.mnt = ((regFixed.fix&0x3E00)>>9) + 1;
                }
              }
              else
              {
                out.exp = 10;
                out.mnt = ((regFixed.fix&0x3E00)>>9);
              }
          }
        else if((regFixed.fix >= 0x2000) && (regFixed.fix < 0x4000))//格式为1X.XXXX _XXXX XXXX
          {
            if((regFixed.fix&0xFF) == 0x80)//余位为1000...的情况
            {
              if((regFixed.fix&0x100) == 0x100)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x1F00)>>8) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 9 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 9;
                  out.mnt = ((regFixed.fix&0x1F00)>>8) + 1;
                }
              }
              else
              {
                out.exp = 9;
                out.mnt = ((regFixed.fix&0x1F00)>>8);
              }
            }
            else if((regFixed.fix&0xFF) > 0x80)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0x1F00)>>8) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 9 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 9;
                  out.mnt = ((regFixed.fix&0x1F00)>>8) + 1;
                }
              }
              else
              {
                out.exp = 9;
                out.mnt = ((regFixed.fix&0x1F00)>>8);
              }
          }
        else if((regFixed.fix >= 0x1000) && (regFixed.fix < 0x2000))//格式为1.XXXX X_XXX XXXX
          {
            if((regFixed.fix&0x7F) == 0x40)//余位为1000...的情况
            {
              if((regFixed.fix&0x80) == 0x80)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0xF80)>>7) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 8 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 8;
                  out.mnt = ((regFixed.fix&0xF80)>>7) + 1;
                }
              }
              else
              {
                out.exp = 8;
                out.mnt = ((regFixed.fix&0xF80)>>7);
              }
            }
            else if((regFixed.fix&0x7F) > 0x40)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0xF80)>>7) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 8 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 8;
                  out.mnt = ((regFixed.fix&0xF80)>>7) + 1;
                }
              }
              else
              {
                out.exp = 8;
                out.mnt = ((regFixed.fix&0xF80)>>7);
              }
          }
        else if((regFixed.fix >= 0x800) && (regFixed.fix < 0x1000))//格式为0.1XXX XX_XX XXXX
          {
            if((regFixed.fix&0x3F) == 0x20)//余位为1000...的情况
            {
              if((regFixed.fix&0x40) == 0x40)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x7C0)>>6) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 7 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 7;
                  out.mnt = ((regFixed.fix&0x7C0)>>6) + 1;
                }
              }
              else
              {
                out.exp = 7;
                out.mnt = ((regFixed.fix&0x7C0)>>6);
              }
            }
            else if((regFixed.fix&0x3F) > 0x20)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0x7C0)>>6) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 7 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 7;
                  out.mnt = ((regFixed.fix&0x7C0)>>6) + 1;
                }
              }
              else
              {
                out.exp = 7;
                out.mnt = ((regFixed.fix&0x7C0)>>6);
              }
          }
        else if((regFixed.fix >= 0x400) && (regFixed.fix < 0x800))//格式为0.01XX XXX_X XXXX
          {
            if((regFixed.fix&0x1F) == 0x10)//余位为1000...的情况
            {
              if((regFixed.fix&0x20) == 0x20)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x3E0)>>5) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 6 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 6;
                  out.mnt = ((regFixed.fix&0x3E0)>>5) + 1;
                }
              }
              else
              {
                out.exp = 6;
                out.mnt = ((regFixed.fix&0x3E0)>>5);
              }
            }
            else if((regFixed.fix&0x1F) > 0x10)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0x3E0)>>5) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 6 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 6;
                  out.mnt = ((regFixed.fix&0x3E0)>>5) + 1;
                }
              }
              else
              {
                out.exp = 6;
                out.mnt = ((regFixed.fix&0x3E0)>>5);
              }
          }
        else if((regFixed.fix >= 0x200) && (regFixed.fix < 0x400))//格式为0.001X XXXX _XXXX
          {
            if((regFixed.fix&0xF) == 0x8)//余位为1000...的情况
            {
              if((regFixed.fix&0x10) == 0x10)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x1F0)>>4) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 5 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 5;
                  out.mnt = ((regFixed.fix&0x1F0)>>4) + 1;
                }
              }
              else
              {
                out.exp = 5;
                out.mnt = ((regFixed.fix&0x1F0)>>4);
              }
            }
            else if((regFixed.fix&0xF) > 0x8)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0x1F0)>>4) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 5 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 5;
                  out.mnt = ((regFixed.fix&0x1F0)>>4) + 1;
                }
              }
              else
              {
                out.exp = 5;
                out.mnt = ((regFixed.fix&0x1F0)>>4);
              }
          }
        else if((regFixed.fix >= 0x100) && (regFixed.fix < 0x200))//格式为0.0001 XXXX X_XXX
          {
            if((regFixed.fix&0x7) == 0x4)//余位为1000...的情况
            {
              if((regFixed.fix&0x8) == 0x8)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0xF8)>>3) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 4 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 4;
                  out.mnt = ((regFixed.fix&0xF8)>>3) + 1;
                }
              }
              else
              {
                out.exp = 4;
                out.mnt = ((regFixed.fix&0xF8)>>3);
              }
            }
            else if((regFixed.fix&0x7) > 0x4)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0xF8)>>3) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 4 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 4;
                  out.mnt = ((regFixed.fix&0xF8)>>3) + 1;
                }
              }
              else
              {
                out.exp = 4;
                out.mnt = ((regFixed.fix&0xF8)>>3);
              }
          }
        else if((regFixed.fix >= 0x80) && (regFixed.fix < 0x100))//格式为0.0000 1XXX XX_XX
          {
            if((regFixed.fix&0x3) == 0x2)//余位为1000...的情况
            {
              if((regFixed.fix&0x4) == 0x4)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x7C)>>2) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 3 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 3;
                  out.mnt = ((regFixed.fix&0x7C)>>2) + 1;
                }
              }
              else
              {
                out.exp = 3;
                out.mnt = ((regFixed.fix&0x7C)>>2);
              }
            }
            else if((regFixed.fix&0x3) > 0x2)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0x7C)>>2) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 3 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 3;
                  out.mnt = ((regFixed.fix&0x7C)>>2) + 1;
                }
              }
              else
              {
                out.exp = 3;
                out.mnt = ((regFixed.fix&0x7C)>>2);
              }
          }
        else if((regFixed.fix >= 0x40) && (regFixed.fix < 0x80))//格式为0.0000 01XX XXX_X
          {
            if((regFixed.fix&0x1) == 0x1)//余位为1000...的情况
            {
              if((regFixed.fix&0x2) == 0x2)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x3E)>>1) == 31)//处理 mnt = 111的情况
                {
                  out.exp = 2 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 2;
                  out.mnt = ((regFixed.fix&0x3E)>>1) + 1;
                }
              }
              else
              {
                out.exp = 2;
                out.mnt = ((regFixed.fix&0x3E)>>1);
              }
            }
            else
              {
                out.exp = 2;
                out.mnt = ((regFixed.fix&0x3E)>>1);
              }
          }
        else if((regFixed.fix >= 0x20) && (regFixed.fix < 0x40))//格式为0.0000 001X XXXX_
          {
            out.exp = 1;
            out.mnt = (regFixed.fix&0x1F);
          }
        else//格式为0.0000 0001 XXXX
          {
            out.exp = 1;
            out.mnt = 0;
          }
      }
      }

    else if(type == 3)//type == 3
    {
      reg.sign = (a >= 0)?0:1;//符号位
      reg.integer = (int)abs(a);//整数部分
      Mfraction = abs(a) - reg.integer;//取小数部分
      reg.fraction = 0;
      for(int i = 0; i < 11; ++i)
      {
        reg.fraction  = reg.fraction << 1; 
        if( Mfraction*2 >= 1)
        {
          reg.fraction = reg.fraction + 1;
          Mfraction = Mfraction*2 - 1;
        }
        else
        {
          reg.fraction = reg.fraction + 0;
          Mfraction = Mfraction*2;
        }
      }
      regFixed.fix  = ((reg.fraction&0b1) == 1)?((reg.integer << 10) + (reg.fraction>>1) + 1) : ((reg.integer << 10) + (reg.fraction>>1));
      //首先判断符号位
      if( reg.sign == 1 )
      {
        out.sign = 1;
      }
      else
      {
        out.sign = 0;
      }

      //判断是否超出SFP表示范围
      if(regFixed.fix >= 0x3E000)//格式为11 111X XX.XX XXXX XXXX
      {
        out.exp = 15;
        out.mnt = 7;
      }
      else if(regFixed.fix <= 0x4)//格式为0.00 0000 0100 
      {
        out.exp = 0;
        out.mnt = 0;
      }
      else
      {
        if(regFixed.fix >= 0x20000)//格式为1X XX_XX XX.XX XXXX XXXX
          {
            if((regFixed.fix&0x3FFF) == 0x2000)//余位为1000...的情况
            {
              if((regFixed.fix&0x4000) == 0x4000)//尾数为奇数+1,偶数不进位
              {
                out.exp = 15;
                out.mnt = ((regFixed.fix&0x1C000)>>14) + 1;
              }
              else
              {
                out.exp = 15;
                out.mnt = ((regFixed.fix&0x1C000)>>14);
              }
            }
            else if((regFixed.fix&0x3FFF) > 0x2000)//不是1000...的情况。大于进位，小于舍去
            {
              out.exp = 15;
              out.mnt = ((regFixed.fix&0x1C000)>>14) + 1;
            }
            else
            {
              out.exp = 15;
              out.mnt = ((regFixed.fix&0x1C000)>>14);
            }
          }
        else if((regFixed.fix >= 0x10000) && (regFixed.fix < 0x20000))//格式为1 XXX_X XX.XX XXXX XXXX
          {
            if((regFixed.fix&0x1FFF) == 0x1000)//余位为1000...的情况
            {
              if((regFixed.fix&0x2000) == 0x2000)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0xE000)>>13) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 14 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 14;
                  out.mnt = ((regFixed.fix&0xE000)>>13) + 1;
                }
              }
              else
              {
                out.exp = 14;
                out.mnt = ((regFixed.fix&0xE000)>>13);
              }
            }
            else if((regFixed.fix&0x1FFF) > 0x1000)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0xE000)>>13) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 14 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 14;
                  out.mnt = ((regFixed.fix&0xE000)>>13) + 1;
                }
            }
            else
            {
              out.exp = 14;
              out.mnt = ((regFixed.fix&0xE000)>>13);
            }
          }
        else if((regFixed.fix >= 0x8000) && (regFixed.fix < 0x10000))//格式为1XXX _XX.XX XXXX XXXX
          {
            if((regFixed.fix&0xFFF) == 0x800)//余位为1000...的情况
            {
              if((regFixed.fix&0x1000) == 0x1000)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x7000)>>12) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 13 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 13;
                  out.mnt = ((regFixed.fix&0x7000)>>12) + 1;
                }
              }
              else
              {
                out.exp = 13;
                out.mnt = ((regFixed.fix&0x7000)>>12);
              }
            }
            else if((regFixed.fix&0xFFF) > 0x800)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0x7000)>>12) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 13 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 13;
                  out.mnt = ((regFixed.fix&0x7000)>>12) + 1;
                }
              }
            else
            {
              out.exp = 13;
              out.mnt = ((regFixed.fix&0x7000)>>12);
            }
          }
        else if((regFixed.fix >= 0x4000) && (regFixed.fix < 0x8000))//格式为1XX X_X.XX XXXX XXXX
          {
            if((regFixed.fix&0x7FF) == 0x400)//余位为1000...的情况
            {
              if((regFixed.fix&0x800) == 0x800)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x3800)>>11) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 12 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 12;
                  out.mnt = ((regFixed.fix&0x3800)>>11) + 1;
                }
              }
              else
              {
                out.exp = 12;
                out.mnt = ((regFixed.fix&0x3800)>>11);
              }
            }
            else if((regFixed.fix&0x7FF) > 0x400)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0x3800)>>11) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 12 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 12;
                  out.mnt = ((regFixed.fix&0x3800)>>11) + 1;
                }
            }
            else
            {
              out.exp = 12;
              out.mnt = ((regFixed.fix&0x3800)>>11);
            }
          }
        else if((regFixed.fix >= 0x2000) && (regFixed.fix < 0x4000))//格式为1X XX._XX XXXX XXXX
          {
            if((regFixed.fix&0x3FF) == 0x200)//余位为1000...的情况
            {
              if((regFixed.fix&0x400) == 0x400)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x1C00)>>10) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 11 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 11;
                  out.mnt = ((regFixed.fix&0x1C00)>>10) + 1;
                }
              }
              else
              {
                out.exp = 11;
                out.mnt = ((regFixed.fix&0x1C00)>>10);
              }
            }
            else if((regFixed.fix&0x3FF) > 0x200)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0x1C00)>>10) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 11 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 11;
                  out.mnt = ((regFixed.fix&0x1C00)>>10) + 1;
                }
              }
            else
            {
              out.exp = 11;
              out.mnt = ((regFixed.fix&0x1C00)>>10);
            }
          }
        else if((regFixed.fix >= 0x1000) && (regFixed.fix < 0x2000))//格式为1 XX.X_X XXXX XXXX
          {
            if((regFixed.fix&0x1FF) == 0x100)//余位为1000...的情况
            {
              if((regFixed.fix&0x200) == 0x200)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0xE00)>>9) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 10 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 10;
                  out.mnt = ((regFixed.fix&0xE00)>>9) + 1;
                }
              }
              else
              {
                out.exp = 10;
                out.mnt = ((regFixed.fix&0xE00)>>9);
              }
            }
            else if((regFixed.fix&0x1FF) > 0x100)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0xE00)>>9) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 10 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 10;
                  out.mnt = ((regFixed.fix&0xE00)>>9) + 1;
                }
              }
            else
            {
              out.exp = 10;
              out.mnt = ((regFixed.fix&0xE00)>>9);
            }
          }
        else if((regFixed.fix >= 0x800) && (regFixed.fix < 0x1000))//格式为1X.XX _XXXX XXXX
          {
            if((regFixed.fix&0xFF) == 0x80)//余位为1000...的情况
            {
              if((regFixed.fix&0x100) == 0x100)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x700)>>8) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 9 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 9;
                  out.mnt = ((regFixed.fix&0x700)>>8) + 1;
                }
              }
              else
              {
                out.exp = 9;
                out.mnt = ((regFixed.fix&0x700)>>8);
              }
            }
            else if((regFixed.fix&0xFF) > 0x80)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0x700)>>8) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 9 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 9;
                  out.mnt = ((regFixed.fix&0x700)>>8) + 1;
                }
              }
            else
            {
              out.exp = 9;
              out.mnt = ((regFixed.fix&0x700)>>8);
            }
          }
        else if((regFixed.fix >= 0x400) && (regFixed.fix < 0x800))//格式为1.XX X_XXX XXXX
          {
            if((regFixed.fix&0x7F) == 0x40)//余位为1000...的情况
            {
              if((regFixed.fix&0x80) == 0x80)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x380)>>7) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 8 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 8;
                  out.mnt = ((regFixed.fix&0x380)>>7) + 1;
                }
              }
              else
              {
                out.exp = 8;
                out.mnt = ((regFixed.fix&0x380)>>7);
              }
            }
            else if((regFixed.fix&0x7F) > 0x40)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0x380)>>7) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 8 + 1;
                  out.mnt = 0;
                }
              else
                {
                  out.exp = 8;
                  out.mnt = ((regFixed.fix&0x380)>>7) + 1;
                }
            }
            else
            {
              out.exp = 8;
              out.mnt = ((regFixed.fix&0x380)>>7);
            }
          }
        else if((regFixed.fix >= 0x200) && (regFixed.fix < 0x400))//格式为0.1X XX_XX XXXX
          {
            if((regFixed.fix&0x3F) == 0x20)//余位为1000...的情况
            {
              if((regFixed.fix&0x40) == 0x40)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x1C0)>>6) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 7 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 7;
                  out.mnt = ((regFixed.fix&0x1C0)>>6) + 1;
                }
              }
              else
              {
                out.exp = 7;
                out.mnt = ((regFixed.fix&0x1C0)>>6);
              }
            }
            else if((regFixed.fix&0x3F) > 0x20)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0x1C0)>>6) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 7 + 1;
                  out.mnt = 0;
                }
              else
                {
                  out.exp = 7;
                  out.mnt = ((regFixed.fix&0x1C0)>>6) + 1;
                }
            }
            else
            {
              out.exp = 7;
              out.mnt = ((regFixed.fix&0x1C0)>>6);
            }
          }
        else if((regFixed.fix >= 0x100) && (regFixed.fix < 0x200))//格式为0.01 XXX_X XXXX
          {
            if((regFixed.fix&0x1F) == 0x10)//余位为1000...的情况
            {
              if((regFixed.fix&0x20) == 0x20)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0xE0)>>5) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 6 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 6;
                  out.mnt = ((regFixed.fix&0xE0)>>5) + 1;
                }
              }
              else
              {
                out.exp = 6;
                out.mnt = ((regFixed.fix&0xE0)>>5);
              }
            }
            else if((regFixed.fix&0x1F) > 0x10)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0xE0)>>5) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 6 + 1;
                  out.mnt = 0;
                }
              else
                {
                  out.exp = 6;
                  out.mnt = ((regFixed.fix&0xE0)>>5) + 1;
                }
              }
            else
            {
              out.exp = 6;
              out.mnt = ((regFixed.fix&0xE0)>>5);
            }
          }
        else if((regFixed.fix >= 0x80) && (regFixed.fix < 0x100))//格式为0.00 1XXX _XXXX
          {
            if((regFixed.fix&0xF) == 0x8)//余位为1000...的情况
            {
              if((regFixed.fix&0x10) == 0x10)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x70)>>4) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 5 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 5;
                  out.mnt = ((regFixed.fix&0x70)>>4) + 1;
                }
              }
              else
              {
                out.exp = 5;
                out.mnt = ((regFixed.fix&0x70)>>4);
              }
            }
            else if((regFixed.fix&0xF) > 0x8)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0x70)>>4) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 5 + 1;
                  out.mnt = 0;
                }
              else
                {
                  out.exp = 5;
                  out.mnt = ((regFixed.fix&0x70)>>4) + 1;
                }
              }
            else
            {
              out.exp = 5;
              out.mnt = ((regFixed.fix&0x70)>>4);
            }
          }
        else if((regFixed.fix >= 0x40) && (regFixed.fix < 0x80))//格式为0.00 01XX X_XXX
          {
            if((regFixed.fix&0x7) == 0x4)//余位为1000...的情况
            {
              if((regFixed.fix&0x8) == 0x8)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x38)>>3) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 4 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 4;
                  out.mnt = ((regFixed.fix&0x38)>>3) + 1;
                }
              }
              else
              {
                out.exp = 4;
                out.mnt = ((regFixed.fix&0x38)>>3);
              }
            }
            else if((regFixed.fix&0x7) > 0x4)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0x38)>>3) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 4 + 1;
                  out.mnt = 0;
                }
              else
                {
                  out.exp = 4;
                  out.mnt = ((regFixed.fix&0x38)>>3) + 1;
                }
              }
            else
            {
              out.exp = 4;
              out.mnt = ((regFixed.fix&0x38)>>3);
            }
          }
        else if((regFixed.fix >= 0x20) && (regFixed.fix < 0x40))//格式为0.00 001X XX_XX
          {
            if((regFixed.fix&0x3) == 0x2)//余位为1000...的情况
            {
              if((regFixed.fix&0x4) == 0x4)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0x1C)>>2) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 3 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 3;
                  out.mnt = ((regFixed.fix&0x1C)>>2) + 1;
                }
              }
              else
              {
                out.exp = 3;
                out.mnt = ((regFixed.fix&0x1C)>>2);
              }
            }
            else if((regFixed.fix&0x3) > 0x2)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0x1C)>>2) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 3 + 1;
                  out.mnt = 0;
                }
              else
                {
                  out.exp = 3;
                  out.mnt = ((regFixed.fix&0x1C)>>2) + 1;
                }
              }
            else
            {
              out.exp = 3;
              out.mnt = ((regFixed.fix&0x1C)>>2);
            }
          }
        else if((regFixed.fix >= 0x10) && (regFixed.fix < 0x20))//格式为0.00 0001 XXX_X
          {
            if((regFixed.fix&0x1) == 0x1)//余位为1000...的情况
            {
              if((regFixed.fix&0x2) == 0x2)//尾数为奇数+1,偶数不进位
              {
                if(((regFixed.fix&0xE)>>1) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 2 + 1;
                  out.mnt = 0;
                }
                else
                {
                  out.exp = 2;
                  out.mnt = ((regFixed.fix&0xE)>>1) + 1;
                }
              }
              else
              {
                out.exp = 2;
                out.mnt = ((regFixed.fix&0xE)>>1);
              }
            }
            else if((regFixed.fix&0x1) > 0x1)//不是1000...的情况。大于进位，小于舍去
            {
              if(((regFixed.fix&0xE)>>1) == 7)//处理 mnt = 111的情况
                {
                  out.exp = 2 + 1;
                  out.mnt = 0;
                }
              else
                {
                  out.exp = 2;
                  out.mnt = ((regFixed.fix&0xE)>>1) + 1;
                }
              }
            else
            {
              out.exp = 2;
              out.mnt = ((regFixed.fix&0xE)>>1);
            }
          }
        else if((regFixed.fix >= 0x8) && (regFixed.fix < 0x10))//格式为0.00 0000 1XXX
          {
            out.exp = 1;
            out.mnt = (regFixed.fix&0x7);
          }
        else//格式为0.00 0000 01XX
          {
            out.exp = 1;
            out.mnt = 0;
          }
      }
    
    }
    else {
     printf("Wrong Type of float2sfp") ;
    }
    return out;
  }

float sfpfixed(sfp active, sfp weight, int type)
  {
    lut regMult;
    float out;   //output float
    if( ((active.exp == 0) || (weight.exp == 0) ) && (type == 3 || type == 5))
    {
      out = 0;
    } 
    else if(type == 5)
    {
      regMult.cbMnt = (active.mnt << 5) + weight.mnt;  
      switch (regMult.cbMnt)
      {
        case 0:    {regMult.outMnt = 0b000000; regMult.carry = 0;}; break;
        case 1:    {regMult.outMnt = 0b000010; regMult.carry = 0;}; break;
        case 2:    {regMult.outMnt = 0b000100; regMult.carry = 0;}; break;
        case 3:    {regMult.outMnt = 0b000110; regMult.carry = 0;}; break;
        case 4:    {regMult.outMnt = 0b001000; regMult.carry = 0;}; break;
        case 5:    {regMult.outMnt = 0b001010; regMult.carry = 0;}; break;
        case 6:    {regMult.outMnt = 0b001100; regMult.carry = 0;}; break;
        case 7:    {regMult.outMnt = 0b001110; regMult.carry = 0;}; break;
        case 8:    {regMult.outMnt = 0b010000; regMult.carry = 0;}; break;
        case 9:    {regMult.outMnt = 0b010010; regMult.carry = 0;}; break;
        case 10:    {regMult.outMnt = 0b010100; regMult.carry = 0;}; break;
        case 11:    {regMult.outMnt = 0b010110; regMult.carry = 0;}; break;
        case 12:    {regMult.outMnt = 0b011000; regMult.carry = 0;}; break;
        case 13:    {regMult.outMnt = 0b011010; regMult.carry = 0;}; break;
        case 14:    {regMult.outMnt = 0b011100; regMult.carry = 0;}; break;
        case 15:    {regMult.outMnt = 0b011110; regMult.carry = 0;}; break;
        case 16:    {regMult.outMnt = 0b100000; regMult.carry = 0;}; break;
        case 17:    {regMult.outMnt = 0b100010; regMult.carry = 0;}; break;
        case 18:    {regMult.outMnt = 0b100100; regMult.carry = 0;}; break;
        case 19:    {regMult.outMnt = 0b100110; regMult.carry = 0;}; break;
        case 20:    {regMult.outMnt = 0b101000; regMult.carry = 0;}; break;
        case 21:    {regMult.outMnt = 0b101010; regMult.carry = 0;}; break;
        case 22:    {regMult.outMnt = 0b101100; regMult.carry = 0;}; break;
        case 23:    {regMult.outMnt = 0b101110; regMult.carry = 0;}; break;
        case 24:    {regMult.outMnt = 0b110000; regMult.carry = 0;}; break;
        case 25:    {regMult.outMnt = 0b110010; regMult.carry = 0;}; break;
        case 26:    {regMult.outMnt = 0b110100; regMult.carry = 0;}; break;
        case 27:    {regMult.outMnt = 0b110110; regMult.carry = 0;}; break;
        case 28:    {regMult.outMnt = 0b111000; regMult.carry = 0;}; break;
        case 29:    {regMult.outMnt = 0b111010; regMult.carry = 0;}; break;
        case 30:    {regMult.outMnt = 0b111100; regMult.carry = 0;}; break;
        case 31:    {regMult.outMnt = 0b111110; regMult.carry = 0;}; break;
        case 32:    {regMult.outMnt = 0b000010; regMult.carry = 0;}; break;
        case 33:    {regMult.outMnt = 0b000100; regMult.carry = 0;}; break;
        case 34:    {regMult.outMnt = 0b000110; regMult.carry = 0;}; break;
        case 35:    {regMult.outMnt = 0b001000; regMult.carry = 0;}; break;
        case 36:    {regMult.outMnt = 0b001010; regMult.carry = 0;}; break;
        case 37:    {regMult.outMnt = 0b001100; regMult.carry = 0;}; break;
        case 38:    {regMult.outMnt = 0b001110; regMult.carry = 0;}; break;
        case 39:    {regMult.outMnt = 0b010000; regMult.carry = 0;}; break;
        case 40:    {regMult.outMnt = 0b010010; regMult.carry = 0;}; break;
        case 41:    {regMult.outMnt = 0b010101; regMult.carry = 0;}; break;
        case 42:    {regMult.outMnt = 0b010111; regMult.carry = 0;}; break;
        case 43:    {regMult.outMnt = 0b011001; regMult.carry = 0;}; break;
        case 44:    {regMult.outMnt = 0b011011; regMult.carry = 0;}; break;
        case 45:    {regMult.outMnt = 0b011101; regMult.carry = 0;}; break;
        case 46:    {regMult.outMnt = 0b011111; regMult.carry = 0;}; break;
        case 47:    {regMult.outMnt = 0b100001; regMult.carry = 0;}; break;
        case 48:    {regMult.outMnt = 0b100011; regMult.carry = 0;}; break;
        case 49:    {regMult.outMnt = 0b100101; regMult.carry = 0;}; break;
        case 50:    {regMult.outMnt = 0b100111; regMult.carry = 0;}; break;
        case 51:    {regMult.outMnt = 0b101001; regMult.carry = 0;}; break;
        case 52:    {regMult.outMnt = 0b101011; regMult.carry = 0;}; break;
        case 53:    {regMult.outMnt = 0b101101; regMult.carry = 0;}; break;
        case 54:    {regMult.outMnt = 0b101111; regMult.carry = 0;}; break;
        case 55:    {regMult.outMnt = 0b110001; regMult.carry = 0;}; break;
        case 56:    {regMult.outMnt = 0b110100; regMult.carry = 0;}; break;
        case 57:    {regMult.outMnt = 0b110110; regMult.carry = 0;}; break;
        case 58:    {regMult.outMnt = 0b111000; regMult.carry = 0;}; break;
        case 59:    {regMult.outMnt = 0b111010; regMult.carry = 0;}; break;
        case 60:    {regMult.outMnt = 0b111100; regMult.carry = 0;}; break;
        case 61:    {regMult.outMnt = 0b111110; regMult.carry = 0;}; break;
        case 62:    {regMult.outMnt = 0b000000; regMult.carry = 1;}; break;
        case 63:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 64:    {regMult.outMnt = 0b000100; regMult.carry = 0;}; break;
        case 65:    {regMult.outMnt = 0b000110; regMult.carry = 0;}; break;
        case 66:    {regMult.outMnt = 0b001000; regMult.carry = 0;}; break;
        case 67:    {regMult.outMnt = 0b001010; regMult.carry = 0;}; break;
        case 68:    {regMult.outMnt = 0b001100; regMult.carry = 0;}; break;
        case 69:    {regMult.outMnt = 0b001111; regMult.carry = 0;}; break;
        case 70:    {regMult.outMnt = 0b010001; regMult.carry = 0;}; break;
        case 71:    {regMult.outMnt = 0b010011; regMult.carry = 0;}; break;
        case 72:    {regMult.outMnt = 0b010101; regMult.carry = 0;}; break;
        case 73:    {regMult.outMnt = 0b010111; regMult.carry = 0;}; break;
        case 74:    {regMult.outMnt = 0b011001; regMult.carry = 0;}; break;
        case 75:    {regMult.outMnt = 0b011011; regMult.carry = 0;}; break;
        case 76:    {regMult.outMnt = 0b011110; regMult.carry = 0;}; break;
        case 77:    {regMult.outMnt = 0b100000; regMult.carry = 0;}; break;
        case 78:    {regMult.outMnt = 0b100010; regMult.carry = 0;}; break;
        case 79:    {regMult.outMnt = 0b100100; regMult.carry = 0;}; break;
        case 80:    {regMult.outMnt = 0b100110; regMult.carry = 0;}; break;
        case 81:    {regMult.outMnt = 0b101000; regMult.carry = 0;}; break;
        case 82:    {regMult.outMnt = 0b101010; regMult.carry = 0;}; break;
        case 83:    {regMult.outMnt = 0b101100; regMult.carry = 0;}; break;
        case 84:    {regMult.outMnt = 0b101110; regMult.carry = 0;}; break;
        case 85:    {regMult.outMnt = 0b110001; regMult.carry = 0;}; break;
        case 86:    {regMult.outMnt = 0b110011; regMult.carry = 0;}; break;
        case 87:    {regMult.outMnt = 0b110101; regMult.carry = 0;}; break;
        case 88:    {regMult.outMnt = 0b110111; regMult.carry = 0;}; break;
        case 89:    {regMult.outMnt = 0b111001; regMult.carry = 0;}; break;
        case 90:    {regMult.outMnt = 0b111011; regMult.carry = 0;}; break;
        case 91:    {regMult.outMnt = 0b111101; regMult.carry = 0;}; break;
        case 92:    {regMult.outMnt = 0b000000; regMult.carry = 1;}; break;
        case 93:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 94:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 95:    {regMult.outMnt = 0b000011; regMult.carry = 1;}; break;
        case 96:    {regMult.outMnt = 0b000110; regMult.carry = 0;}; break;
        case 97:    {regMult.outMnt = 0b001000; regMult.carry = 0;}; break;
        case 98:    {regMult.outMnt = 0b001010; regMult.carry = 0;}; break;
        case 99:    {regMult.outMnt = 0b001101; regMult.carry = 0;}; break;
        case 100:    {regMult.outMnt = 0b001111; regMult.carry = 0;}; break;
        case 101:    {regMult.outMnt = 0b010001; regMult.carry = 0;}; break;
        case 102:    {regMult.outMnt = 0b010011; regMult.carry = 0;}; break;
        case 103:    {regMult.outMnt = 0b010101; regMult.carry = 0;}; break;
        case 104:    {regMult.outMnt = 0b011000; regMult.carry = 0;}; break;
        case 105:    {regMult.outMnt = 0b011010; regMult.carry = 0;}; break;
        case 106:    {regMult.outMnt = 0b011100; regMult.carry = 0;}; break;
        case 107:    {regMult.outMnt = 0b011110; regMult.carry = 0;}; break;
        case 108:    {regMult.outMnt = 0b100000; regMult.carry = 0;}; break;
        case 109:    {regMult.outMnt = 0b100010; regMult.carry = 0;}; break;
        case 110:    {regMult.outMnt = 0b100101; regMult.carry = 0;}; break;
        case 111:    {regMult.outMnt = 0b100111; regMult.carry = 0;}; break;
        case 112:    {regMult.outMnt = 0b101001; regMult.carry = 0;}; break;
        case 113:    {regMult.outMnt = 0b101011; regMult.carry = 0;}; break;
        case 114:    {regMult.outMnt = 0b101101; regMult.carry = 0;}; break;
        case 115:    {regMult.outMnt = 0b110000; regMult.carry = 0;}; break;
        case 116:    {regMult.outMnt = 0b110010; regMult.carry = 0;}; break;
        case 117:    {regMult.outMnt = 0b110100; regMult.carry = 0;}; break;
        case 118:    {regMult.outMnt = 0b110110; regMult.carry = 0;}; break;
        case 119:    {regMult.outMnt = 0b111000; regMult.carry = 0;}; break;
        case 120:    {regMult.outMnt = 0b111010; regMult.carry = 0;}; break;
        case 121:    {regMult.outMnt = 0b111101; regMult.carry = 0;}; break;
        case 122:    {regMult.outMnt = 0b111111; regMult.carry = 0;}; break;
        case 123:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 124:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 125:    {regMult.outMnt = 0b000011; regMult.carry = 1;}; break;
        case 126:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 127:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 128:    {regMult.outMnt = 0b001000; regMult.carry = 0;}; break;
        case 129:    {regMult.outMnt = 0b001010; regMult.carry = 0;}; break;
        case 130:    {regMult.outMnt = 0b001100; regMult.carry = 0;}; break;
        case 131:    {regMult.outMnt = 0b001111; regMult.carry = 0;}; break;
        case 132:    {regMult.outMnt = 0b010001; regMult.carry = 0;}; break;
        case 133:    {regMult.outMnt = 0b010011; regMult.carry = 0;}; break;
        case 134:    {regMult.outMnt = 0b010110; regMult.carry = 0;}; break;
        case 135:    {regMult.outMnt = 0b011000; regMult.carry = 0;}; break;
        case 136:    {regMult.outMnt = 0b011010; regMult.carry = 0;}; break;
        case 137:    {regMult.outMnt = 0b011100; regMult.carry = 0;}; break;
        case 138:    {regMult.outMnt = 0b011110; regMult.carry = 0;}; break;
        case 139:    {regMult.outMnt = 0b100001; regMult.carry = 0;}; break;
        case 140:    {regMult.outMnt = 0b100011; regMult.carry = 0;}; break;
        case 141:    {regMult.outMnt = 0b100101; regMult.carry = 0;}; break;
        case 142:    {regMult.outMnt = 0b101000; regMult.carry = 0;}; break;
        case 143:    {regMult.outMnt = 0b101010; regMult.carry = 0;}; break;
        case 144:    {regMult.outMnt = 0b101100; regMult.carry = 0;}; break;
        case 145:    {regMult.outMnt = 0b101110; regMult.carry = 0;}; break;
        case 146:    {regMult.outMnt = 0b110000; regMult.carry = 0;}; break;
        case 147:    {regMult.outMnt = 0b110011; regMult.carry = 0;}; break;
        case 148:    {regMult.outMnt = 0b110101; regMult.carry = 0;}; break;
        case 149:    {regMult.outMnt = 0b110111; regMult.carry = 0;}; break;
        case 150:    {regMult.outMnt = 0b111010; regMult.carry = 0;}; break;
        case 151:    {regMult.outMnt = 0b111100; regMult.carry = 0;}; break;
        case 152:    {regMult.outMnt = 0b111110; regMult.carry = 0;}; break;
        case 153:    {regMult.outMnt = 0b000000; regMult.carry = 1;}; break;
        case 154:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 155:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 156:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 157:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 158:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 159:    {regMult.outMnt = 0b000111; regMult.carry = 1;}; break;
        case 160:    {regMult.outMnt = 0b001010; regMult.carry = 0;}; break;
        case 161:    {regMult.outMnt = 0b001100; regMult.carry = 0;}; break;
        case 162:    {regMult.outMnt = 0b001111; regMult.carry = 0;}; break;
        case 163:    {regMult.outMnt = 0b010001; regMult.carry = 0;}; break;
        case 164:    {regMult.outMnt = 0b010011; regMult.carry = 0;}; break;
        case 165:    {regMult.outMnt = 0b010110; regMult.carry = 0;}; break;
        case 166:    {regMult.outMnt = 0b011000; regMult.carry = 0;}; break;
        case 167:    {regMult.outMnt = 0b011010; regMult.carry = 0;}; break;
        case 168:    {regMult.outMnt = 0b011100; regMult.carry = 0;}; break;
        case 169:    {regMult.outMnt = 0b011111; regMult.carry = 0;}; break;
        case 170:    {regMult.outMnt = 0b100001; regMult.carry = 0;}; break;
        case 171:    {regMult.outMnt = 0b100011; regMult.carry = 0;}; break;
        case 172:    {regMult.outMnt = 0b100110; regMult.carry = 0;}; break;
        case 173:    {regMult.outMnt = 0b101000; regMult.carry = 0;}; break;
        case 174:    {regMult.outMnt = 0b101010; regMult.carry = 0;}; break;
        case 175:    {regMult.outMnt = 0b101101; regMult.carry = 0;}; break;
        case 176:    {regMult.outMnt = 0b101111; regMult.carry = 0;}; break;
        case 177:    {regMult.outMnt = 0b110001; regMult.carry = 0;}; break;
        case 178:    {regMult.outMnt = 0b110100; regMult.carry = 0;}; break;
        case 179:    {regMult.outMnt = 0b110110; regMult.carry = 0;}; break;
        case 180:    {regMult.outMnt = 0b111000; regMult.carry = 0;}; break;
        case 181:    {regMult.outMnt = 0b111011; regMult.carry = 0;}; break;
        case 182:    {regMult.outMnt = 0b111101; regMult.carry = 0;}; break;
        case 183:    {regMult.outMnt = 0b111111; regMult.carry = 0;}; break;
        case 184:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 185:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 186:    {regMult.outMnt = 0b000011; regMult.carry = 1;}; break;
        case 187:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 188:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 189:    {regMult.outMnt = 0b000111; regMult.carry = 1;}; break;
        case 190:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 191:    {regMult.outMnt = 0b001001; regMult.carry = 1;}; break;
        case 192:    {regMult.outMnt = 0b001100; regMult.carry = 0;}; break;
        case 193:    {regMult.outMnt = 0b001110; regMult.carry = 0;}; break;
        case 194:    {regMult.outMnt = 0b010001; regMult.carry = 0;}; break;
        case 195:    {regMult.outMnt = 0b010011; regMult.carry = 0;}; break;
        case 196:    {regMult.outMnt = 0b010110; regMult.carry = 0;}; break;
        case 197:    {regMult.outMnt = 0b011000; regMult.carry = 0;}; break;
        case 198:    {regMult.outMnt = 0b011010; regMult.carry = 0;}; break;
        case 199:    {regMult.outMnt = 0b011101; regMult.carry = 0;}; break;
        case 200:    {regMult.outMnt = 0b011111; regMult.carry = 0;}; break;
        case 201:    {regMult.outMnt = 0b100001; regMult.carry = 0;}; break;
        case 202:    {regMult.outMnt = 0b100100; regMult.carry = 0;}; break;
        case 203:    {regMult.outMnt = 0b100110; regMult.carry = 0;}; break;
        case 204:    {regMult.outMnt = 0b101000; regMult.carry = 0;}; break;
        case 205:    {regMult.outMnt = 0b101011; regMult.carry = 0;}; break;
        case 206:    {regMult.outMnt = 0b101101; regMult.carry = 0;}; break;
        case 207:    {regMult.outMnt = 0b110000; regMult.carry = 0;}; break;
        case 208:    {regMult.outMnt = 0b110010; regMult.carry = 0;}; break;
        case 209:    {regMult.outMnt = 0b110100; regMult.carry = 0;}; break;
        case 210:    {regMult.outMnt = 0b110111; regMult.carry = 0;}; break;
        case 211:    {regMult.outMnt = 0b111001; regMult.carry = 0;}; break;
        case 212:    {regMult.outMnt = 0b111100; regMult.carry = 0;}; break;
        case 213:    {regMult.outMnt = 0b111110; regMult.carry = 0;}; break;
        case 214:    {regMult.outMnt = 0b000000; regMult.carry = 1;}; break;
        case 215:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 216:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 217:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 218:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 219:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 220:    {regMult.outMnt = 0b000111; regMult.carry = 1;}; break;
        case 221:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 222:    {regMult.outMnt = 0b001010; regMult.carry = 1;}; break;
        case 223:    {regMult.outMnt = 0b001011; regMult.carry = 1;}; break;
        case 224:    {regMult.outMnt = 0b001110; regMult.carry = 0;}; break;
        case 225:    {regMult.outMnt = 0b010000; regMult.carry = 0;}; break;
        case 226:    {regMult.outMnt = 0b010011; regMult.carry = 0;}; break;
        case 227:    {regMult.outMnt = 0b010101; regMult.carry = 0;}; break;
        case 228:    {regMult.outMnt = 0b011000; regMult.carry = 0;}; break;
        case 229:    {regMult.outMnt = 0b011010; regMult.carry = 0;}; break;
        case 230:    {regMult.outMnt = 0b011101; regMult.carry = 0;}; break;
        case 231:    {regMult.outMnt = 0b011111; regMult.carry = 0;}; break;
        case 232:    {regMult.outMnt = 0b100010; regMult.carry = 0;}; break;
        case 233:    {regMult.outMnt = 0b100100; regMult.carry = 0;}; break;
        case 234:    {regMult.outMnt = 0b100110; regMult.carry = 0;}; break;
        case 235:    {regMult.outMnt = 0b101001; regMult.carry = 0;}; break;
        case 236:    {regMult.outMnt = 0b101011; regMult.carry = 0;}; break;
        case 237:    {regMult.outMnt = 0b101110; regMult.carry = 0;}; break;
        case 238:    {regMult.outMnt = 0b110000; regMult.carry = 0;}; break;
        case 239:    {regMult.outMnt = 0b110011; regMult.carry = 0;}; break;
        case 240:    {regMult.outMnt = 0b110101; regMult.carry = 0;}; break;
        case 241:    {regMult.outMnt = 0b110111; regMult.carry = 0;}; break;
        case 242:    {regMult.outMnt = 0b111010; regMult.carry = 0;}; break;
        case 243:    {regMult.outMnt = 0b111100; regMult.carry = 0;}; break;
        case 244:    {regMult.outMnt = 0b111111; regMult.carry = 0;}; break;
        case 245:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 246:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 247:    {regMult.outMnt = 0b000011; regMult.carry = 1;}; break;
        case 248:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 249:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 250:    {regMult.outMnt = 0b000111; regMult.carry = 1;}; break;
        case 251:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 252:    {regMult.outMnt = 0b001001; regMult.carry = 1;}; break;
        case 253:    {regMult.outMnt = 0b001010; regMult.carry = 1;}; break;
        case 254:    {regMult.outMnt = 0b001100; regMult.carry = 1;}; break;
        case 255:    {regMult.outMnt = 0b001101; regMult.carry = 1;}; break;
        case 256:    {regMult.outMnt = 0b010000; regMult.carry = 0;}; break;
        case 257:    {regMult.outMnt = 0b010010; regMult.carry = 0;}; break;
        case 258:    {regMult.outMnt = 0b010101; regMult.carry = 0;}; break;
        case 259:    {regMult.outMnt = 0b011000; regMult.carry = 0;}; break;
        case 260:    {regMult.outMnt = 0b011010; regMult.carry = 0;}; break;
        case 261:    {regMult.outMnt = 0b011100; regMult.carry = 0;}; break;
        case 262:    {regMult.outMnt = 0b011111; regMult.carry = 0;}; break;
        case 263:    {regMult.outMnt = 0b100010; regMult.carry = 0;}; break;
        case 264:    {regMult.outMnt = 0b100100; regMult.carry = 0;}; break;
        case 265:    {regMult.outMnt = 0b100110; regMult.carry = 0;}; break;
        case 266:    {regMult.outMnt = 0b101001; regMult.carry = 0;}; break;
        case 267:    {regMult.outMnt = 0b101100; regMult.carry = 0;}; break;
        case 268:    {regMult.outMnt = 0b101110; regMult.carry = 0;}; break;
        case 269:    {regMult.outMnt = 0b110000; regMult.carry = 0;}; break;
        case 270:    {regMult.outMnt = 0b110011; regMult.carry = 0;}; break;
        case 271:    {regMult.outMnt = 0b110110; regMult.carry = 0;}; break;
        case 272:    {regMult.outMnt = 0b111000; regMult.carry = 0;}; break;
        case 273:    {regMult.outMnt = 0b111010; regMult.carry = 0;}; break;
        case 274:    {regMult.outMnt = 0b111101; regMult.carry = 0;}; break;
        case 275:    {regMult.outMnt = 0b000000; regMult.carry = 1;}; break;
        case 276:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 277:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 278:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 279:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 280:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 281:    {regMult.outMnt = 0b000111; regMult.carry = 1;}; break;
        case 282:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 283:    {regMult.outMnt = 0b001010; regMult.carry = 1;}; break;
        case 284:    {regMult.outMnt = 0b001011; regMult.carry = 1;}; break;
        case 285:    {regMult.outMnt = 0b001100; regMult.carry = 1;}; break;
        case 286:    {regMult.outMnt = 0b001110; regMult.carry = 1;}; break;
        case 287:    {regMult.outMnt = 0b001111; regMult.carry = 1;}; break;
        case 288:    {regMult.outMnt = 0b010010; regMult.carry = 0;}; break;
        case 289:    {regMult.outMnt = 0b010101; regMult.carry = 0;}; break;
        case 290:    {regMult.outMnt = 0b010111; regMult.carry = 0;}; break;
        case 291:    {regMult.outMnt = 0b011010; regMult.carry = 0;}; break;
        case 292:    {regMult.outMnt = 0b011100; regMult.carry = 0;}; break;
        case 293:    {regMult.outMnt = 0b011111; regMult.carry = 0;}; break;
        case 294:    {regMult.outMnt = 0b100001; regMult.carry = 0;}; break;
        case 295:    {regMult.outMnt = 0b100100; regMult.carry = 0;}; break;
        case 296:    {regMult.outMnt = 0b100110; regMult.carry = 0;}; break;
        case 297:    {regMult.outMnt = 0b101001; regMult.carry = 0;}; break;
        case 298:    {regMult.outMnt = 0b101100; regMult.carry = 0;}; break;
        case 299:    {regMult.outMnt = 0b101110; regMult.carry = 0;}; break;
        case 300:    {regMult.outMnt = 0b110001; regMult.carry = 0;}; break;
        case 301:    {regMult.outMnt = 0b110011; regMult.carry = 0;}; break;
        case 302:    {regMult.outMnt = 0b110110; regMult.carry = 0;}; break;
        case 303:    {regMult.outMnt = 0b111000; regMult.carry = 0;}; break;
        case 304:    {regMult.outMnt = 0b111011; regMult.carry = 0;}; break;
        case 305:    {regMult.outMnt = 0b111110; regMult.carry = 0;}; break;
        case 306:    {regMult.outMnt = 0b000000; regMult.carry = 1;}; break;
        case 307:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 308:    {regMult.outMnt = 0b000011; regMult.carry = 1;}; break;
        case 309:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 310:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 311:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 312:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 313:    {regMult.outMnt = 0b001001; regMult.carry = 1;}; break;
        case 314:    {regMult.outMnt = 0b001010; regMult.carry = 1;}; break;
        case 315:    {regMult.outMnt = 0b001100; regMult.carry = 1;}; break;
        case 316:    {regMult.outMnt = 0b001101; regMult.carry = 1;}; break;
        case 317:    {regMult.outMnt = 0b001110; regMult.carry = 1;}; break;
        case 318:    {regMult.outMnt = 0b001111; regMult.carry = 1;}; break;
        case 319:    {regMult.outMnt = 0b010001; regMult.carry = 1;}; break;
        case 320:    {regMult.outMnt = 0b010100; regMult.carry = 0;}; break;
        case 321:    {regMult.outMnt = 0b010111; regMult.carry = 0;}; break;
        case 322:    {regMult.outMnt = 0b011001; regMult.carry = 0;}; break;
        case 323:    {regMult.outMnt = 0b011100; regMult.carry = 0;}; break;
        case 324:    {regMult.outMnt = 0b011110; regMult.carry = 0;}; break;
        case 325:    {regMult.outMnt = 0b100001; regMult.carry = 0;}; break;
        case 326:    {regMult.outMnt = 0b100100; regMult.carry = 0;}; break;
        case 327:    {regMult.outMnt = 0b100110; regMult.carry = 0;}; break;
        case 328:    {regMult.outMnt = 0b101001; regMult.carry = 0;}; break;
        case 329:    {regMult.outMnt = 0b101100; regMult.carry = 0;}; break;
        case 330:    {regMult.outMnt = 0b101110; regMult.carry = 0;}; break;
        case 331:    {regMult.outMnt = 0b110001; regMult.carry = 0;}; break;
        case 332:    {regMult.outMnt = 0b110100; regMult.carry = 0;}; break;
        case 333:    {regMult.outMnt = 0b110110; regMult.carry = 0;}; break;
        case 334:    {regMult.outMnt = 0b111001; regMult.carry = 0;}; break;
        case 335:    {regMult.outMnt = 0b111011; regMult.carry = 0;}; break;
        case 336:    {regMult.outMnt = 0b111110; regMult.carry = 0;}; break;
        case 337:    {regMult.outMnt = 0b000000; regMult.carry = 1;}; break;
        case 338:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 339:    {regMult.outMnt = 0b000011; regMult.carry = 1;}; break;
        case 340:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 341:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 342:    {regMult.outMnt = 0b000111; regMult.carry = 1;}; break;
        case 343:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 344:    {regMult.outMnt = 0b001010; regMult.carry = 1;}; break;
        case 345:    {regMult.outMnt = 0b001011; regMult.carry = 1;}; break;
        case 346:    {regMult.outMnt = 0b001100; regMult.carry = 1;}; break;
        case 347:    {regMult.outMnt = 0b001101; regMult.carry = 1;}; break;
        case 348:    {regMult.outMnt = 0b001111; regMult.carry = 1;}; break;
        case 349:    {regMult.outMnt = 0b010000; regMult.carry = 1;}; break;
        case 350:    {regMult.outMnt = 0b010001; regMult.carry = 1;}; break;
        case 351:    {regMult.outMnt = 0b010011; regMult.carry = 1;}; break;
        case 352:    {regMult.outMnt = 0b010110; regMult.carry = 0;}; break;
        case 353:    {regMult.outMnt = 0b011001; regMult.carry = 0;}; break;
        case 354:    {regMult.outMnt = 0b011011; regMult.carry = 0;}; break;
        case 355:    {regMult.outMnt = 0b011110; regMult.carry = 0;}; break;
        case 356:    {regMult.outMnt = 0b100001; regMult.carry = 0;}; break;
        case 357:    {regMult.outMnt = 0b100011; regMult.carry = 0;}; break;
        case 358:    {regMult.outMnt = 0b100110; regMult.carry = 0;}; break;
        case 359:    {regMult.outMnt = 0b101001; regMult.carry = 0;}; break;
        case 360:    {regMult.outMnt = 0b101100; regMult.carry = 0;}; break;
        case 361:    {regMult.outMnt = 0b101110; regMult.carry = 0;}; break;
        case 362:    {regMult.outMnt = 0b110001; regMult.carry = 0;}; break;
        case 363:    {regMult.outMnt = 0b110100; regMult.carry = 0;}; break;
        case 364:    {regMult.outMnt = 0b110110; regMult.carry = 0;}; break;
        case 365:    {regMult.outMnt = 0b111001; regMult.carry = 0;}; break;
        case 366:    {regMult.outMnt = 0b111100; regMult.carry = 0;}; break;
        case 367:    {regMult.outMnt = 0b111110; regMult.carry = 0;}; break;
        case 368:    {regMult.outMnt = 0b000000; regMult.carry = 1;}; break;
        case 369:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 370:    {regMult.outMnt = 0b000011; regMult.carry = 1;}; break;
        case 371:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 372:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 373:    {regMult.outMnt = 0b000111; regMult.carry = 1;}; break;
        case 374:    {regMult.outMnt = 0b001001; regMult.carry = 1;}; break;
        case 375:    {regMult.outMnt = 0b001010; regMult.carry = 1;}; break;
        case 376:    {regMult.outMnt = 0b001011; regMult.carry = 1;}; break;
        case 377:    {regMult.outMnt = 0b001101; regMult.carry = 1;}; break;
        case 378:    {regMult.outMnt = 0b001110; regMult.carry = 1;}; break;
        case 379:    {regMult.outMnt = 0b001111; regMult.carry = 1;}; break;
        case 380:    {regMult.outMnt = 0b010001; regMult.carry = 1;}; break;
        case 381:    {regMult.outMnt = 0b010010; regMult.carry = 1;}; break;
        case 382:    {regMult.outMnt = 0b010011; regMult.carry = 1;}; break;
        case 383:    {regMult.outMnt = 0b010101; regMult.carry = 1;}; break;
        case 384:    {regMult.outMnt = 0b011000; regMult.carry = 0;}; break;
        case 385:    {regMult.outMnt = 0b011011; regMult.carry = 0;}; break;
        case 386:    {regMult.outMnt = 0b011110; regMult.carry = 0;}; break;
        case 387:    {regMult.outMnt = 0b100000; regMult.carry = 0;}; break;
        case 388:    {regMult.outMnt = 0b100011; regMult.carry = 0;}; break;
        case 389:    {regMult.outMnt = 0b100110; regMult.carry = 0;}; break;
        case 390:    {regMult.outMnt = 0b101000; regMult.carry = 0;}; break;
        case 391:    {regMult.outMnt = 0b101011; regMult.carry = 0;}; break;
        case 392:    {regMult.outMnt = 0b101110; regMult.carry = 0;}; break;
        case 393:    {regMult.outMnt = 0b110001; regMult.carry = 0;}; break;
        case 394:    {regMult.outMnt = 0b110100; regMult.carry = 0;}; break;
        case 395:    {regMult.outMnt = 0b110110; regMult.carry = 0;}; break;
        case 396:    {regMult.outMnt = 0b111001; regMult.carry = 0;}; break;
        case 397:    {regMult.outMnt = 0b111100; regMult.carry = 0;}; break;
        case 398:    {regMult.outMnt = 0b111110; regMult.carry = 0;}; break;
        case 399:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 400:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 401:    {regMult.outMnt = 0b000011; regMult.carry = 1;}; break;
        case 402:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 403:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 404:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 405:    {regMult.outMnt = 0b001001; regMult.carry = 1;}; break;
        case 406:    {regMult.outMnt = 0b001010; regMult.carry = 1;}; break;
        case 407:    {regMult.outMnt = 0b001100; regMult.carry = 1;}; break;
        case 408:    {regMult.outMnt = 0b001101; regMult.carry = 1;}; break;
        case 409:    {regMult.outMnt = 0b001110; regMult.carry = 1;}; break;
        case 410:    {regMult.outMnt = 0b010000; regMult.carry = 1;}; break;
        case 411:    {regMult.outMnt = 0b010001; regMult.carry = 1;}; break;
        case 412:    {regMult.outMnt = 0b010010; regMult.carry = 1;}; break;
        case 413:    {regMult.outMnt = 0b010100; regMult.carry = 1;}; break;
        case 414:    {regMult.outMnt = 0b010101; regMult.carry = 1;}; break;
        case 415:    {regMult.outMnt = 0b010111; regMult.carry = 1;}; break;
        case 416:    {regMult.outMnt = 0b011010; regMult.carry = 0;}; break;
        case 417:    {regMult.outMnt = 0b011101; regMult.carry = 0;}; break;
        case 418:    {regMult.outMnt = 0b100000; regMult.carry = 0;}; break;
        case 419:    {regMult.outMnt = 0b100010; regMult.carry = 0;}; break;
        case 420:    {regMult.outMnt = 0b100101; regMult.carry = 0;}; break;
        case 421:    {regMult.outMnt = 0b101000; regMult.carry = 0;}; break;
        case 422:    {regMult.outMnt = 0b101011; regMult.carry = 0;}; break;
        case 423:    {regMult.outMnt = 0b101110; regMult.carry = 0;}; break;
        case 424:    {regMult.outMnt = 0b110000; regMult.carry = 0;}; break;
        case 425:    {regMult.outMnt = 0b110011; regMult.carry = 0;}; break;
        case 426:    {regMult.outMnt = 0b110110; regMult.carry = 0;}; break;
        case 427:    {regMult.outMnt = 0b111001; regMult.carry = 0;}; break;
        case 428:    {regMult.outMnt = 0b111100; regMult.carry = 0;}; break;
        case 429:    {regMult.outMnt = 0b111111; regMult.carry = 0;}; break;
        case 430:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 431:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 432:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 433:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 434:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 435:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 436:    {regMult.outMnt = 0b001001; regMult.carry = 1;}; break;
        case 437:    {regMult.outMnt = 0b001011; regMult.carry = 1;}; break;
        case 438:    {regMult.outMnt = 0b001100; regMult.carry = 1;}; break;
        case 439:    {regMult.outMnt = 0b001101; regMult.carry = 1;}; break;
        case 440:    {regMult.outMnt = 0b001111; regMult.carry = 1;}; break;
        case 441:    {regMult.outMnt = 0b010000; regMult.carry = 1;}; break;
        case 442:    {regMult.outMnt = 0b010010; regMult.carry = 1;}; break;
        case 443:    {regMult.outMnt = 0b010011; regMult.carry = 1;}; break;
        case 444:    {regMult.outMnt = 0b010100; regMult.carry = 1;}; break;
        case 445:    {regMult.outMnt = 0b010110; regMult.carry = 1;}; break;
        case 446:    {regMult.outMnt = 0b010111; regMult.carry = 1;}; break;
        case 447:    {regMult.outMnt = 0b011001; regMult.carry = 1;}; break;
        case 448:    {regMult.outMnt = 0b011100; regMult.carry = 0;}; break;
        case 449:    {regMult.outMnt = 0b011111; regMult.carry = 0;}; break;
        case 450:    {regMult.outMnt = 0b100010; regMult.carry = 0;}; break;
        case 451:    {regMult.outMnt = 0b100101; regMult.carry = 0;}; break;
        case 452:    {regMult.outMnt = 0b101000; regMult.carry = 0;}; break;
        case 453:    {regMult.outMnt = 0b101010; regMult.carry = 0;}; break;
        case 454:    {regMult.outMnt = 0b101101; regMult.carry = 0;}; break;
        case 455:    {regMult.outMnt = 0b110000; regMult.carry = 0;}; break;
        case 456:    {regMult.outMnt = 0b110011; regMult.carry = 0;}; break;
        case 457:    {regMult.outMnt = 0b110110; regMult.carry = 0;}; break;
        case 458:    {regMult.outMnt = 0b111001; regMult.carry = 0;}; break;
        case 459:    {regMult.outMnt = 0b111100; regMult.carry = 0;}; break;
        case 460:    {regMult.outMnt = 0b111110; regMult.carry = 0;}; break;
        case 461:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 462:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 463:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 464:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 465:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 466:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 467:    {regMult.outMnt = 0b001001; regMult.carry = 1;}; break;
        case 468:    {regMult.outMnt = 0b001011; regMult.carry = 1;}; break;
        case 469:    {regMult.outMnt = 0b001100; regMult.carry = 1;}; break;
        case 470:    {regMult.outMnt = 0b001110; regMult.carry = 1;}; break;
        case 471:    {regMult.outMnt = 0b001111; regMult.carry = 1;}; break;
        case 472:    {regMult.outMnt = 0b010000; regMult.carry = 1;}; break;
        case 473:    {regMult.outMnt = 0b010010; regMult.carry = 1;}; break;
        case 474:    {regMult.outMnt = 0b010011; regMult.carry = 1;}; break;
        case 475:    {regMult.outMnt = 0b010101; regMult.carry = 1;}; break;
        case 476:    {regMult.outMnt = 0b010110; regMult.carry = 1;}; break;
        case 477:    {regMult.outMnt = 0b011000; regMult.carry = 1;}; break;
        case 478:    {regMult.outMnt = 0b011001; regMult.carry = 1;}; break;
        case 479:    {regMult.outMnt = 0b011011; regMult.carry = 1;}; break;
        case 480:    {regMult.outMnt = 0b011110; regMult.carry = 0;}; break;
        case 481:    {regMult.outMnt = 0b100001; regMult.carry = 0;}; break;
        case 482:    {regMult.outMnt = 0b100100; regMult.carry = 0;}; break;
        case 483:    {regMult.outMnt = 0b100111; regMult.carry = 0;}; break;
        case 484:    {regMult.outMnt = 0b101010; regMult.carry = 0;}; break;
        case 485:    {regMult.outMnt = 0b101101; regMult.carry = 0;}; break;
        case 486:    {regMult.outMnt = 0b110000; regMult.carry = 0;}; break;
        case 487:    {regMult.outMnt = 0b110011; regMult.carry = 0;}; break;
        case 488:    {regMult.outMnt = 0b110110; regMult.carry = 0;}; break;
        case 489:    {regMult.outMnt = 0b111000; regMult.carry = 0;}; break;
        case 490:    {regMult.outMnt = 0b111011; regMult.carry = 0;}; break;
        case 491:    {regMult.outMnt = 0b111110; regMult.carry = 0;}; break;
        case 492:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 493:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 494:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 495:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 496:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 497:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 498:    {regMult.outMnt = 0b001001; regMult.carry = 1;}; break;
        case 499:    {regMult.outMnt = 0b001011; regMult.carry = 1;}; break;
        case 500:    {regMult.outMnt = 0b001100; regMult.carry = 1;}; break;
        case 501:    {regMult.outMnt = 0b001110; regMult.carry = 1;}; break;
        case 502:    {regMult.outMnt = 0b001111; regMult.carry = 1;}; break;
        case 503:    {regMult.outMnt = 0b010001; regMult.carry = 1;}; break;
        case 504:    {regMult.outMnt = 0b010010; regMult.carry = 1;}; break;
        case 505:    {regMult.outMnt = 0b010100; regMult.carry = 1;}; break;
        case 506:    {regMult.outMnt = 0b010101; regMult.carry = 1;}; break;
        case 507:    {regMult.outMnt = 0b010111; regMult.carry = 1;}; break;
        case 508:    {regMult.outMnt = 0b011000; regMult.carry = 1;}; break;
        case 509:    {regMult.outMnt = 0b011010; regMult.carry = 1;}; break;
        case 510:    {regMult.outMnt = 0b011011; regMult.carry = 1;}; break;
        case 511:    {regMult.outMnt = 0b011101; regMult.carry = 1;}; break;
        case 512:    {regMult.outMnt = 0b100000; regMult.carry = 0;}; break;
        case 513:    {regMult.outMnt = 0b100011; regMult.carry = 0;}; break;
        case 514:    {regMult.outMnt = 0b100110; regMult.carry = 0;}; break;
        case 515:    {regMult.outMnt = 0b101001; regMult.carry = 0;}; break;
        case 516:    {regMult.outMnt = 0b101100; regMult.carry = 0;}; break;
        case 517:    {regMult.outMnt = 0b101111; regMult.carry = 0;}; break;
        case 518:    {regMult.outMnt = 0b110010; regMult.carry = 0;}; break;
        case 519:    {regMult.outMnt = 0b110101; regMult.carry = 0;}; break;
        case 520:    {regMult.outMnt = 0b111000; regMult.carry = 0;}; break;
        case 521:    {regMult.outMnt = 0b111011; regMult.carry = 0;}; break;
        case 522:    {regMult.outMnt = 0b111110; regMult.carry = 0;}; break;
        case 523:    {regMult.outMnt = 0b000000; regMult.carry = 1;}; break;
        case 524:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 525:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 526:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 527:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 528:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 529:    {regMult.outMnt = 0b001010; regMult.carry = 1;}; break;
        case 530:    {regMult.outMnt = 0b001011; regMult.carry = 1;}; break;
        case 531:    {regMult.outMnt = 0b001100; regMult.carry = 1;}; break;
        case 532:    {regMult.outMnt = 0b001110; regMult.carry = 1;}; break;
        case 533:    {regMult.outMnt = 0b010000; regMult.carry = 1;}; break;
        case 534:    {regMult.outMnt = 0b010001; regMult.carry = 1;}; break;
        case 535:    {regMult.outMnt = 0b010010; regMult.carry = 1;}; break;
        case 536:    {regMult.outMnt = 0b010100; regMult.carry = 1;}; break;
        case 537:    {regMult.outMnt = 0b010110; regMult.carry = 1;}; break;
        case 538:    {regMult.outMnt = 0b010111; regMult.carry = 1;}; break;
        case 539:    {regMult.outMnt = 0b011000; regMult.carry = 1;}; break;
        case 540:    {regMult.outMnt = 0b011010; regMult.carry = 1;}; break;
        case 541:    {regMult.outMnt = 0b011100; regMult.carry = 1;}; break;
        case 542:    {regMult.outMnt = 0b011101; regMult.carry = 1;}; break;
        case 543:    {regMult.outMnt = 0b011110; regMult.carry = 1;}; break;
        case 544:    {regMult.outMnt = 0b100010; regMult.carry = 0;}; break;
        case 545:    {regMult.outMnt = 0b100101; regMult.carry = 0;}; break;
        case 546:    {regMult.outMnt = 0b101000; regMult.carry = 0;}; break;
        case 547:    {regMult.outMnt = 0b101011; regMult.carry = 0;}; break;
        case 548:    {regMult.outMnt = 0b101110; regMult.carry = 0;}; break;
        case 549:    {regMult.outMnt = 0b110001; regMult.carry = 0;}; break;
        case 550:    {regMult.outMnt = 0b110100; regMult.carry = 0;}; break;
        case 551:    {regMult.outMnt = 0b110111; regMult.carry = 0;}; break;
        case 552:    {regMult.outMnt = 0b111010; regMult.carry = 0;}; break;
        case 553:    {regMult.outMnt = 0b111110; regMult.carry = 0;}; break;
        case 554:    {regMult.outMnt = 0b000000; regMult.carry = 1;}; break;
        case 555:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 556:    {regMult.outMnt = 0b000011; regMult.carry = 1;}; break;
        case 557:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 558:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 559:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 560:    {regMult.outMnt = 0b001010; regMult.carry = 1;}; break;
        case 561:    {regMult.outMnt = 0b001011; regMult.carry = 1;}; break;
        case 562:    {regMult.outMnt = 0b001101; regMult.carry = 1;}; break;
        case 563:    {regMult.outMnt = 0b001110; regMult.carry = 1;}; break;
        case 564:    {regMult.outMnt = 0b010000; regMult.carry = 1;}; break;
        case 565:    {regMult.outMnt = 0b010001; regMult.carry = 1;}; break;
        case 566:    {regMult.outMnt = 0b010011; regMult.carry = 1;}; break;
        case 567:    {regMult.outMnt = 0b010100; regMult.carry = 1;}; break;
        case 568:    {regMult.outMnt = 0b010110; regMult.carry = 1;}; break;
        case 569:    {regMult.outMnt = 0b010111; regMult.carry = 1;}; break;
        case 570:    {regMult.outMnt = 0b011001; regMult.carry = 1;}; break;
        case 571:    {regMult.outMnt = 0b011010; regMult.carry = 1;}; break;
        case 572:    {regMult.outMnt = 0b011100; regMult.carry = 1;}; break;
        case 573:    {regMult.outMnt = 0b011101; regMult.carry = 1;}; break;
        case 574:    {regMult.outMnt = 0b011111; regMult.carry = 1;}; break;
        case 575:    {regMult.outMnt = 0b100000; regMult.carry = 1;}; break;
        case 576:    {regMult.outMnt = 0b100100; regMult.carry = 0;}; break;
        case 577:    {regMult.outMnt = 0b100111; regMult.carry = 0;}; break;
        case 578:    {regMult.outMnt = 0b101010; regMult.carry = 0;}; break;
        case 579:    {regMult.outMnt = 0b101101; regMult.carry = 0;}; break;
        case 580:    {regMult.outMnt = 0b110000; regMult.carry = 0;}; break;
        case 581:    {regMult.outMnt = 0b110100; regMult.carry = 0;}; break;
        case 582:    {regMult.outMnt = 0b110111; regMult.carry = 0;}; break;
        case 583:    {regMult.outMnt = 0b111010; regMult.carry = 0;}; break;
        case 584:    {regMult.outMnt = 0b111101; regMult.carry = 0;}; break;
        case 585:    {regMult.outMnt = 0b000000; regMult.carry = 1;}; break;
        case 586:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 587:    {regMult.outMnt = 0b000011; regMult.carry = 1;}; break;
        case 588:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 589:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 590:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 591:    {regMult.outMnt = 0b001001; regMult.carry = 1;}; break;
        case 592:    {regMult.outMnt = 0b001011; regMult.carry = 1;}; break;
        case 593:    {regMult.outMnt = 0b001101; regMult.carry = 1;}; break;
        case 594:    {regMult.outMnt = 0b001110; regMult.carry = 1;}; break;
        case 595:    {regMult.outMnt = 0b010000; regMult.carry = 1;}; break;
        case 596:    {regMult.outMnt = 0b010001; regMult.carry = 1;}; break;
        case 597:    {regMult.outMnt = 0b010011; regMult.carry = 1;}; break;
        case 598:    {regMult.outMnt = 0b010100; regMult.carry = 1;}; break;
        case 599:    {regMult.outMnt = 0b010110; regMult.carry = 1;}; break;
        case 600:    {regMult.outMnt = 0b011000; regMult.carry = 1;}; break;
        case 601:    {regMult.outMnt = 0b011001; regMult.carry = 1;}; break;
        case 602:    {regMult.outMnt = 0b011011; regMult.carry = 1;}; break;
        case 603:    {regMult.outMnt = 0b011100; regMult.carry = 1;}; break;
        case 604:    {regMult.outMnt = 0b011110; regMult.carry = 1;}; break;
        case 605:    {regMult.outMnt = 0b011111; regMult.carry = 1;}; break;
        case 606:    {regMult.outMnt = 0b100001; regMult.carry = 1;}; break;
        case 607:    {regMult.outMnt = 0b100010; regMult.carry = 1;}; break;
        case 608:    {regMult.outMnt = 0b100110; regMult.carry = 0;}; break;
        case 609:    {regMult.outMnt = 0b101001; regMult.carry = 0;}; break;
        case 610:    {regMult.outMnt = 0b101100; regMult.carry = 0;}; break;
        case 611:    {regMult.outMnt = 0b110000; regMult.carry = 0;}; break;
        case 612:    {regMult.outMnt = 0b110011; regMult.carry = 0;}; break;
        case 613:    {regMult.outMnt = 0b110110; regMult.carry = 0;}; break;
        case 614:    {regMult.outMnt = 0b111001; regMult.carry = 0;}; break;
        case 615:    {regMult.outMnt = 0b111100; regMult.carry = 0;}; break;
        case 616:    {regMult.outMnt = 0b000000; regMult.carry = 1;}; break;
        case 617:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 618:    {regMult.outMnt = 0b000011; regMult.carry = 1;}; break;
        case 619:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 620:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 621:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 622:    {regMult.outMnt = 0b001001; regMult.carry = 1;}; break;
        case 623:    {regMult.outMnt = 0b001011; regMult.carry = 1;}; break;
        case 624:    {regMult.outMnt = 0b001100; regMult.carry = 1;}; break;
        case 625:    {regMult.outMnt = 0b001110; regMult.carry = 1;}; break;
        case 626:    {regMult.outMnt = 0b010000; regMult.carry = 1;}; break;
        case 627:    {regMult.outMnt = 0b010001; regMult.carry = 1;}; break;
        case 628:    {regMult.outMnt = 0b010011; regMult.carry = 1;}; break;
        case 629:    {regMult.outMnt = 0b010100; regMult.carry = 1;}; break;
        case 630:    {regMult.outMnt = 0b010110; regMult.carry = 1;}; break;
        case 631:    {regMult.outMnt = 0b011000; regMult.carry = 1;}; break;
        case 632:    {regMult.outMnt = 0b011001; regMult.carry = 1;}; break;
        case 633:    {regMult.outMnt = 0b011011; regMult.carry = 1;}; break;
        case 634:    {regMult.outMnt = 0b011100; regMult.carry = 1;}; break;
        case 635:    {regMult.outMnt = 0b011110; regMult.carry = 1;}; break;
        case 636:    {regMult.outMnt = 0b100000; regMult.carry = 1;}; break;
        case 637:    {regMult.outMnt = 0b100001; regMult.carry = 1;}; break;
        case 638:    {regMult.outMnt = 0b100011; regMult.carry = 1;}; break;
        case 639:    {regMult.outMnt = 0b100100; regMult.carry = 1;}; break;
        case 640:    {regMult.outMnt = 0b101000; regMult.carry = 0;}; break;
        case 641:    {regMult.outMnt = 0b101011; regMult.carry = 0;}; break;
        case 642:    {regMult.outMnt = 0b101110; regMult.carry = 0;}; break;
        case 643:    {regMult.outMnt = 0b110010; regMult.carry = 0;}; break;
        case 644:    {regMult.outMnt = 0b110101; regMult.carry = 0;}; break;
        case 645:    {regMult.outMnt = 0b111000; regMult.carry = 0;}; break;
        case 646:    {regMult.outMnt = 0b111100; regMult.carry = 0;}; break;
        case 647:    {regMult.outMnt = 0b111111; regMult.carry = 0;}; break;
        case 648:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 649:    {regMult.outMnt = 0b000011; regMult.carry = 1;}; break;
        case 650:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 651:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 652:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 653:    {regMult.outMnt = 0b001001; regMult.carry = 1;}; break;
        case 654:    {regMult.outMnt = 0b001011; regMult.carry = 1;}; break;
        case 655:    {regMult.outMnt = 0b001100; regMult.carry = 1;}; break;
        case 656:    {regMult.outMnt = 0b001110; regMult.carry = 1;}; break;
        case 657:    {regMult.outMnt = 0b010000; regMult.carry = 1;}; break;
        case 658:    {regMult.outMnt = 0b010001; regMult.carry = 1;}; break;
        case 659:    {regMult.outMnt = 0b010011; regMult.carry = 1;}; break;
        case 660:    {regMult.outMnt = 0b010100; regMult.carry = 1;}; break;
        case 661:    {regMult.outMnt = 0b010110; regMult.carry = 1;}; break;
        case 662:    {regMult.outMnt = 0b011000; regMult.carry = 1;}; break;
        case 663:    {regMult.outMnt = 0b011001; regMult.carry = 1;}; break;
        case 664:    {regMult.outMnt = 0b011011; regMult.carry = 1;}; break;
        case 665:    {regMult.outMnt = 0b011101; regMult.carry = 1;}; break;
        case 666:    {regMult.outMnt = 0b011110; regMult.carry = 1;}; break;
        case 667:    {regMult.outMnt = 0b100000; regMult.carry = 1;}; break;
        case 668:    {regMult.outMnt = 0b100010; regMult.carry = 1;}; break;
        case 669:    {regMult.outMnt = 0b100011; regMult.carry = 1;}; break;
        case 670:    {regMult.outMnt = 0b100101; regMult.carry = 1;}; break;
        case 671:    {regMult.outMnt = 0b100110; regMult.carry = 1;}; break;
        case 672:    {regMult.outMnt = 0b101010; regMult.carry = 0;}; break;
        case 673:    {regMult.outMnt = 0b101101; regMult.carry = 0;}; break;
        case 674:    {regMult.outMnt = 0b110001; regMult.carry = 0;}; break;
        case 675:    {regMult.outMnt = 0b110100; regMult.carry = 0;}; break;
        case 676:    {regMult.outMnt = 0b110111; regMult.carry = 0;}; break;
        case 677:    {regMult.outMnt = 0b111011; regMult.carry = 0;}; break;
        case 678:    {regMult.outMnt = 0b111110; regMult.carry = 0;}; break;
        case 679:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 680:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 681:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 682:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 683:    {regMult.outMnt = 0b000111; regMult.carry = 1;}; break;
        case 684:    {regMult.outMnt = 0b001001; regMult.carry = 1;}; break;
        case 685:    {regMult.outMnt = 0b001011; regMult.carry = 1;}; break;
        case 686:    {regMult.outMnt = 0b001100; regMult.carry = 1;}; break;
        case 687:    {regMult.outMnt = 0b001110; regMult.carry = 1;}; break;
        case 688:    {regMult.outMnt = 0b010000; regMult.carry = 1;}; break;
        case 689:    {regMult.outMnt = 0b010001; regMult.carry = 1;}; break;
        case 690:    {regMult.outMnt = 0b010011; regMult.carry = 1;}; break;
        case 691:    {regMult.outMnt = 0b010100; regMult.carry = 1;}; break;
        case 692:    {regMult.outMnt = 0b010110; regMult.carry = 1;}; break;
        case 693:    {regMult.outMnt = 0b011000; regMult.carry = 1;}; break;
        case 694:    {regMult.outMnt = 0b011001; regMult.carry = 1;}; break;
        case 695:    {regMult.outMnt = 0b011011; regMult.carry = 1;}; break;
        case 696:    {regMult.outMnt = 0b011101; regMult.carry = 1;}; break;
        case 697:    {regMult.outMnt = 0b011110; regMult.carry = 1;}; break;
        case 698:    {regMult.outMnt = 0b100000; regMult.carry = 1;}; break;
        case 699:    {regMult.outMnt = 0b100010; regMult.carry = 1;}; break;
        case 700:    {regMult.outMnt = 0b100011; regMult.carry = 1;}; break;
        case 701:    {regMult.outMnt = 0b100101; regMult.carry = 1;}; break;
        case 702:    {regMult.outMnt = 0b100111; regMult.carry = 1;}; break;
        case 703:    {regMult.outMnt = 0b101000; regMult.carry = 1;}; break;
        case 704:    {regMult.outMnt = 0b101100; regMult.carry = 0;}; break;
        case 705:    {regMult.outMnt = 0b101111; regMult.carry = 0;}; break;
        case 706:    {regMult.outMnt = 0b110011; regMult.carry = 0;}; break;
        case 707:    {regMult.outMnt = 0b110110; regMult.carry = 0;}; break;
        case 708:    {regMult.outMnt = 0b111010; regMult.carry = 0;}; break;
        case 709:    {regMult.outMnt = 0b111101; regMult.carry = 0;}; break;
        case 710:    {regMult.outMnt = 0b000000; regMult.carry = 1;}; break;
        case 711:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 712:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 713:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 714:    {regMult.outMnt = 0b000111; regMult.carry = 1;}; break;
        case 715:    {regMult.outMnt = 0b001001; regMult.carry = 1;}; break;
        case 716:    {regMult.outMnt = 0b001010; regMult.carry = 1;}; break;
        case 717:    {regMult.outMnt = 0b001100; regMult.carry = 1;}; break;
        case 718:    {regMult.outMnt = 0b001110; regMult.carry = 1;}; break;
        case 719:    {regMult.outMnt = 0b001111; regMult.carry = 1;}; break;
        case 720:    {regMult.outMnt = 0b010001; regMult.carry = 1;}; break;
        case 721:    {regMult.outMnt = 0b010011; regMult.carry = 1;}; break;
        case 722:    {regMult.outMnt = 0b010100; regMult.carry = 1;}; break;
        case 723:    {regMult.outMnt = 0b010110; regMult.carry = 1;}; break;
        case 724:    {regMult.outMnt = 0b011000; regMult.carry = 1;}; break;
        case 725:    {regMult.outMnt = 0b011001; regMult.carry = 1;}; break;
        case 726:    {regMult.outMnt = 0b011011; regMult.carry = 1;}; break;
        case 727:    {regMult.outMnt = 0b011101; regMult.carry = 1;}; break;
        case 728:    {regMult.outMnt = 0b011110; regMult.carry = 1;}; break;
        case 729:    {regMult.outMnt = 0b100000; regMult.carry = 1;}; break;
        case 730:    {regMult.outMnt = 0b100010; regMult.carry = 1;}; break;
        case 731:    {regMult.outMnt = 0b100100; regMult.carry = 1;}; break;
        case 732:    {regMult.outMnt = 0b100101; regMult.carry = 1;}; break;
        case 733:    {regMult.outMnt = 0b100111; regMult.carry = 1;}; break;
        case 734:    {regMult.outMnt = 0b101001; regMult.carry = 1;}; break;
        case 735:    {regMult.outMnt = 0b101010; regMult.carry = 1;}; break;
        case 736:    {regMult.outMnt = 0b101110; regMult.carry = 0;}; break;
        case 737:    {regMult.outMnt = 0b110001; regMult.carry = 0;}; break;
        case 738:    {regMult.outMnt = 0b110101; regMult.carry = 0;}; break;
        case 739:    {regMult.outMnt = 0b111000; regMult.carry = 0;}; break;
        case 740:    {regMult.outMnt = 0b111100; regMult.carry = 0;}; break;
        case 741:    {regMult.outMnt = 0b111111; regMult.carry = 0;}; break;
        case 742:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 743:    {regMult.outMnt = 0b000011; regMult.carry = 1;}; break;
        case 744:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 745:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 746:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 747:    {regMult.outMnt = 0b001010; regMult.carry = 1;}; break;
        case 748:    {regMult.outMnt = 0b001100; regMult.carry = 1;}; break;
        case 749:    {regMult.outMnt = 0b001101; regMult.carry = 1;}; break;
        case 750:    {regMult.outMnt = 0b001111; regMult.carry = 1;}; break;
        case 751:    {regMult.outMnt = 0b010001; regMult.carry = 1;}; break;
        case 752:    {regMult.outMnt = 0b010010; regMult.carry = 1;}; break;
        case 753:    {regMult.outMnt = 0b010100; regMult.carry = 1;}; break;
        case 754:    {regMult.outMnt = 0b010110; regMult.carry = 1;}; break;
        case 755:    {regMult.outMnt = 0b011000; regMult.carry = 1;}; break;
        case 756:    {regMult.outMnt = 0b011001; regMult.carry = 1;}; break;
        case 757:    {regMult.outMnt = 0b011011; regMult.carry = 1;}; break;
        case 758:    {regMult.outMnt = 0b011101; regMult.carry = 1;}; break;
        case 759:    {regMult.outMnt = 0b011111; regMult.carry = 1;}; break;
        case 760:    {regMult.outMnt = 0b100000; regMult.carry = 1;}; break;
        case 761:    {regMult.outMnt = 0b100010; regMult.carry = 1;}; break;
        case 762:    {regMult.outMnt = 0b100100; regMult.carry = 1;}; break;
        case 763:    {regMult.outMnt = 0b100101; regMult.carry = 1;}; break;
        case 764:    {regMult.outMnt = 0b100111; regMult.carry = 1;}; break;
        case 765:    {regMult.outMnt = 0b101001; regMult.carry = 1;}; break;
        case 766:    {regMult.outMnt = 0b101011; regMult.carry = 1;}; break;
        case 767:    {regMult.outMnt = 0b101100; regMult.carry = 1;}; break;
        case 768:    {regMult.outMnt = 0b110000; regMult.carry = 0;}; break;
        case 769:    {regMult.outMnt = 0b110100; regMult.carry = 0;}; break;
        case 770:    {regMult.outMnt = 0b110111; regMult.carry = 0;}; break;
        case 771:    {regMult.outMnt = 0b111010; regMult.carry = 0;}; break;
        case 772:    {regMult.outMnt = 0b111110; regMult.carry = 0;}; break;
        case 773:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 774:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 775:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 776:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 777:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 778:    {regMult.outMnt = 0b001010; regMult.carry = 1;}; break;
        case 779:    {regMult.outMnt = 0b001011; regMult.carry = 1;}; break;
        case 780:    {regMult.outMnt = 0b001101; regMult.carry = 1;}; break;
        case 781:    {regMult.outMnt = 0b001111; regMult.carry = 1;}; break;
        case 782:    {regMult.outMnt = 0b010000; regMult.carry = 1;}; break;
        case 783:    {regMult.outMnt = 0b010010; regMult.carry = 1;}; break;
        case 784:    {regMult.outMnt = 0b010100; regMult.carry = 1;}; break;
        case 785:    {regMult.outMnt = 0b010110; regMult.carry = 1;}; break;
        case 786:    {regMult.outMnt = 0b011000; regMult.carry = 1;}; break;
        case 787:    {regMult.outMnt = 0b011001; regMult.carry = 1;}; break;
        case 788:    {regMult.outMnt = 0b011011; regMult.carry = 1;}; break;
        case 789:    {regMult.outMnt = 0b011101; regMult.carry = 1;}; break;
        case 790:    {regMult.outMnt = 0b011110; regMult.carry = 1;}; break;
        case 791:    {regMult.outMnt = 0b100000; regMult.carry = 1;}; break;
        case 792:    {regMult.outMnt = 0b100010; regMult.carry = 1;}; break;
        case 793:    {regMult.outMnt = 0b100100; regMult.carry = 1;}; break;
        case 794:    {regMult.outMnt = 0b100110; regMult.carry = 1;}; break;
        case 795:    {regMult.outMnt = 0b100111; regMult.carry = 1;}; break;
        case 796:    {regMult.outMnt = 0b101001; regMult.carry = 1;}; break;
        case 797:    {regMult.outMnt = 0b101011; regMult.carry = 1;}; break;
        case 798:    {regMult.outMnt = 0b101100; regMult.carry = 1;}; break;
        case 799:    {regMult.outMnt = 0b101110; regMult.carry = 1;}; break;
        case 800:    {regMult.outMnt = 0b110010; regMult.carry = 0;}; break;
        case 801:    {regMult.outMnt = 0b110110; regMult.carry = 0;}; break;
        case 802:    {regMult.outMnt = 0b111001; regMult.carry = 0;}; break;
        case 803:    {regMult.outMnt = 0b111101; regMult.carry = 0;}; break;
        case 804:    {regMult.outMnt = 0b000000; regMult.carry = 1;}; break;
        case 805:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 806:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 807:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 808:    {regMult.outMnt = 0b000111; regMult.carry = 1;}; break;
        case 809:    {regMult.outMnt = 0b001001; regMult.carry = 1;}; break;
        case 810:    {regMult.outMnt = 0b001011; regMult.carry = 1;}; break;
        case 811:    {regMult.outMnt = 0b001101; regMult.carry = 1;}; break;
        case 812:    {regMult.outMnt = 0b001110; regMult.carry = 1;}; break;
        case 813:    {regMult.outMnt = 0b010000; regMult.carry = 1;}; break;
        case 814:    {regMult.outMnt = 0b010010; regMult.carry = 1;}; break;
        case 815:    {regMult.outMnt = 0b010100; regMult.carry = 1;}; break;
        case 816:    {regMult.outMnt = 0b010110; regMult.carry = 1;}; break;
        case 817:    {regMult.outMnt = 0b010111; regMult.carry = 1;}; break;
        case 818:    {regMult.outMnt = 0b011001; regMult.carry = 1;}; break;
        case 819:    {regMult.outMnt = 0b011011; regMult.carry = 1;}; break;
        case 820:    {regMult.outMnt = 0b011101; regMult.carry = 1;}; break;
        case 821:    {regMult.outMnt = 0b011110; regMult.carry = 1;}; break;
        case 822:    {regMult.outMnt = 0b100000; regMult.carry = 1;}; break;
        case 823:    {regMult.outMnt = 0b100010; regMult.carry = 1;}; break;
        case 824:    {regMult.outMnt = 0b100100; regMult.carry = 1;}; break;
        case 825:    {regMult.outMnt = 0b100110; regMult.carry = 1;}; break;
        case 826:    {regMult.outMnt = 0b100111; regMult.carry = 1;}; break;
        case 827:    {regMult.outMnt = 0b101001; regMult.carry = 1;}; break;
        case 828:    {regMult.outMnt = 0b101011; regMult.carry = 1;}; break;
        case 829:    {regMult.outMnt = 0b101101; regMult.carry = 1;}; break;
        case 830:    {regMult.outMnt = 0b101110; regMult.carry = 1;}; break;
        case 831:    {regMult.outMnt = 0b110000; regMult.carry = 1;}; break;
        case 832:    {regMult.outMnt = 0b110100; regMult.carry = 0;}; break;
        case 833:    {regMult.outMnt = 0b111000; regMult.carry = 0;}; break;
        case 834:    {regMult.outMnt = 0b111011; regMult.carry = 0;}; break;
        case 835:    {regMult.outMnt = 0b111111; regMult.carry = 0;}; break;
        case 836:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 837:    {regMult.outMnt = 0b000011; regMult.carry = 1;}; break;
        case 838:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 839:    {regMult.outMnt = 0b000111; regMult.carry = 1;}; break;
        case 840:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 841:    {regMult.outMnt = 0b001010; regMult.carry = 1;}; break;
        case 842:    {regMult.outMnt = 0b001100; regMult.carry = 1;}; break;
        case 843:    {regMult.outMnt = 0b001110; regMult.carry = 1;}; break;
        case 844:    {regMult.outMnt = 0b010000; regMult.carry = 1;}; break;
        case 845:    {regMult.outMnt = 0b010010; regMult.carry = 1;}; break;
        case 846:    {regMult.outMnt = 0b010011; regMult.carry = 1;}; break;
        case 847:    {regMult.outMnt = 0b010101; regMult.carry = 1;}; break;
        case 848:    {regMult.outMnt = 0b010111; regMult.carry = 1;}; break;
        case 849:    {regMult.outMnt = 0b011001; regMult.carry = 1;}; break;
        case 850:    {regMult.outMnt = 0b011011; regMult.carry = 1;}; break;
        case 851:    {regMult.outMnt = 0b011100; regMult.carry = 1;}; break;
        case 852:    {regMult.outMnt = 0b011110; regMult.carry = 1;}; break;
        case 853:    {regMult.outMnt = 0b100000; regMult.carry = 1;}; break;
        case 854:    {regMult.outMnt = 0b100010; regMult.carry = 1;}; break;
        case 855:    {regMult.outMnt = 0b100100; regMult.carry = 1;}; break;
        case 856:    {regMult.outMnt = 0b100110; regMult.carry = 1;}; break;
        case 857:    {regMult.outMnt = 0b100111; regMult.carry = 1;}; break;
        case 858:    {regMult.outMnt = 0b101001; regMult.carry = 1;}; break;
        case 859:    {regMult.outMnt = 0b101011; regMult.carry = 1;}; break;
        case 860:    {regMult.outMnt = 0b101101; regMult.carry = 1;}; break;
        case 861:    {regMult.outMnt = 0b101111; regMult.carry = 1;}; break;
        case 862:    {regMult.outMnt = 0b110000; regMult.carry = 1;}; break;
        case 863:    {regMult.outMnt = 0b110010; regMult.carry = 1;}; break;
        case 864:    {regMult.outMnt = 0b110110; regMult.carry = 0;}; break;
        case 865:    {regMult.outMnt = 0b111010; regMult.carry = 0;}; break;
        case 866:    {regMult.outMnt = 0b111101; regMult.carry = 0;}; break;
        case 867:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 868:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 869:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 870:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 871:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 872:    {regMult.outMnt = 0b001010; regMult.carry = 1;}; break;
        case 873:    {regMult.outMnt = 0b001100; regMult.carry = 1;}; break;
        case 874:    {regMult.outMnt = 0b001101; regMult.carry = 1;}; break;
        case 875:    {regMult.outMnt = 0b001111; regMult.carry = 1;}; break;
        case 876:    {regMult.outMnt = 0b010001; regMult.carry = 1;}; break;
        case 877:    {regMult.outMnt = 0b010011; regMult.carry = 1;}; break;
        case 878:    {regMult.outMnt = 0b010101; regMult.carry = 1;}; break;
        case 879:    {regMult.outMnt = 0b010111; regMult.carry = 1;}; break;
        case 880:    {regMult.outMnt = 0b011000; regMult.carry = 1;}; break;
        case 881:    {regMult.outMnt = 0b011010; regMult.carry = 1;}; break;
        case 882:    {regMult.outMnt = 0b011100; regMult.carry = 1;}; break;
        case 883:    {regMult.outMnt = 0b011110; regMult.carry = 1;}; break;
        case 884:    {regMult.outMnt = 0b100000; regMult.carry = 1;}; break;
        case 885:    {regMult.outMnt = 0b100010; regMult.carry = 1;}; break;
        case 886:    {regMult.outMnt = 0b100100; regMult.carry = 1;}; break;
        case 887:    {regMult.outMnt = 0b100101; regMult.carry = 1;}; break;
        case 888:    {regMult.outMnt = 0b100111; regMult.carry = 1;}; break;
        case 889:    {regMult.outMnt = 0b101001; regMult.carry = 1;}; break;
        case 890:    {regMult.outMnt = 0b101011; regMult.carry = 1;}; break;
        case 891:    {regMult.outMnt = 0b101101; regMult.carry = 1;}; break;
        case 892:    {regMult.outMnt = 0b101111; regMult.carry = 1;}; break;
        case 893:    {regMult.outMnt = 0b110000; regMult.carry = 1;}; break;
        case 894:    {regMult.outMnt = 0b110010; regMult.carry = 1;}; break;
        case 895:    {regMult.outMnt = 0b110100; regMult.carry = 1;}; break;
        case 896:    {regMult.outMnt = 0b111000; regMult.carry = 0;}; break;
        case 897:    {regMult.outMnt = 0b111100; regMult.carry = 0;}; break;
        case 898:    {regMult.outMnt = 0b000000; regMult.carry = 1;}; break;
        case 899:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 900:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 901:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 902:    {regMult.outMnt = 0b000111; regMult.carry = 1;}; break;
        case 903:    {regMult.outMnt = 0b001001; regMult.carry = 1;}; break;
        case 904:    {regMult.outMnt = 0b001011; regMult.carry = 1;}; break;
        case 905:    {regMult.outMnt = 0b001101; regMult.carry = 1;}; break;
        case 906:    {regMult.outMnt = 0b001111; regMult.carry = 1;}; break;
        case 907:    {regMult.outMnt = 0b010001; regMult.carry = 1;}; break;
        case 908:    {regMult.outMnt = 0b010010; regMult.carry = 1;}; break;
        case 909:    {regMult.outMnt = 0b010100; regMult.carry = 1;}; break;
        case 910:    {regMult.outMnt = 0b010110; regMult.carry = 1;}; break;
        case 911:    {regMult.outMnt = 0b011000; regMult.carry = 1;}; break;
        case 912:    {regMult.outMnt = 0b011010; regMult.carry = 1;}; break;
        case 913:    {regMult.outMnt = 0b011100; regMult.carry = 1;}; break;
        case 914:    {regMult.outMnt = 0b011110; regMult.carry = 1;}; break;
        case 915:    {regMult.outMnt = 0b100000; regMult.carry = 1;}; break;
        case 916:    {regMult.outMnt = 0b100010; regMult.carry = 1;}; break;
        case 917:    {regMult.outMnt = 0b100011; regMult.carry = 1;}; break;
        case 918:    {regMult.outMnt = 0b100101; regMult.carry = 1;}; break;
        case 919:    {regMult.outMnt = 0b100111; regMult.carry = 1;}; break;
        case 920:    {regMult.outMnt = 0b101001; regMult.carry = 1;}; break;
        case 921:    {regMult.outMnt = 0b101011; regMult.carry = 1;}; break;
        case 922:    {regMult.outMnt = 0b101101; regMult.carry = 1;}; break;
        case 923:    {regMult.outMnt = 0b101111; regMult.carry = 1;}; break;
        case 924:    {regMult.outMnt = 0b110000; regMult.carry = 1;}; break;
        case 925:    {regMult.outMnt = 0b110010; regMult.carry = 1;}; break;
        case 926:    {regMult.outMnt = 0b110100; regMult.carry = 1;}; break;
        case 927:    {regMult.outMnt = 0b110110; regMult.carry = 1;}; break;
        case 928:    {regMult.outMnt = 0b111010; regMult.carry = 0;}; break;
        case 929:    {regMult.outMnt = 0b111110; regMult.carry = 0;}; break;
        case 930:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 931:    {regMult.outMnt = 0b000011; regMult.carry = 1;}; break;
        case 932:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 933:    {regMult.outMnt = 0b000111; regMult.carry = 1;}; break;
        case 934:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 935:    {regMult.outMnt = 0b001010; regMult.carry = 1;}; break;
        case 936:    {regMult.outMnt = 0b001100; regMult.carry = 1;}; break;
        case 937:    {regMult.outMnt = 0b001110; regMult.carry = 1;}; break;
        case 938:    {regMult.outMnt = 0b010000; regMult.carry = 1;}; break;
        case 939:    {regMult.outMnt = 0b010010; regMult.carry = 1;}; break;
        case 940:    {regMult.outMnt = 0b010100; regMult.carry = 1;}; break;
        case 941:    {regMult.outMnt = 0b010110; regMult.carry = 1;}; break;
        case 942:    {regMult.outMnt = 0b011000; regMult.carry = 1;}; break;
        case 943:    {regMult.outMnt = 0b011010; regMult.carry = 1;}; break;
        case 944:    {regMult.outMnt = 0b011100; regMult.carry = 1;}; break;
        case 945:    {regMult.outMnt = 0b011101; regMult.carry = 1;}; break;
        case 946:    {regMult.outMnt = 0b011111; regMult.carry = 1;}; break;
        case 947:    {regMult.outMnt = 0b100001; regMult.carry = 1;}; break;
        case 948:    {regMult.outMnt = 0b100011; regMult.carry = 1;}; break;
        case 949:    {regMult.outMnt = 0b100101; regMult.carry = 1;}; break;
        case 950:    {regMult.outMnt = 0b100111; regMult.carry = 1;}; break;
        case 951:    {regMult.outMnt = 0b101001; regMult.carry = 1;}; break;
        case 952:    {regMult.outMnt = 0b101011; regMult.carry = 1;}; break;
        case 953:    {regMult.outMnt = 0b101101; regMult.carry = 1;}; break;
        case 954:    {regMult.outMnt = 0b101111; regMult.carry = 1;}; break;
        case 955:    {regMult.outMnt = 0b110000; regMult.carry = 1;}; break;
        case 956:    {regMult.outMnt = 0b110010; regMult.carry = 1;}; break;
        case 957:    {regMult.outMnt = 0b110100; regMult.carry = 1;}; break;
        case 958:    {regMult.outMnt = 0b110110; regMult.carry = 1;}; break;
        case 959:    {regMult.outMnt = 0b111000; regMult.carry = 1;}; break;
        case 960:    {regMult.outMnt = 0b111100; regMult.carry = 0;}; break;
        case 961:    {regMult.outMnt = 0b000000; regMult.carry = 1;}; break;
        case 962:    {regMult.outMnt = 0b000010; regMult.carry = 1;}; break;
        case 963:    {regMult.outMnt = 0b000100; regMult.carry = 1;}; break;
        case 964:    {regMult.outMnt = 0b000110; regMult.carry = 1;}; break;
        case 965:    {regMult.outMnt = 0b001000; regMult.carry = 1;}; break;
        case 966:    {regMult.outMnt = 0b001010; regMult.carry = 1;}; break;
        case 967:    {regMult.outMnt = 0b001100; regMult.carry = 1;}; break;
        case 968:    {regMult.outMnt = 0b001110; regMult.carry = 1;}; break;
        case 969:    {regMult.outMnt = 0b001111; regMult.carry = 1;}; break;
        case 970:    {regMult.outMnt = 0b010001; regMult.carry = 1;}; break;
        case 971:    {regMult.outMnt = 0b010011; regMult.carry = 1;}; break;
        case 972:    {regMult.outMnt = 0b010101; regMult.carry = 1;}; break;
        case 973:    {regMult.outMnt = 0b010111; regMult.carry = 1;}; break;
        case 974:    {regMult.outMnt = 0b011001; regMult.carry = 1;}; break;
        case 975:    {regMult.outMnt = 0b011011; regMult.carry = 1;}; break;
        case 976:    {regMult.outMnt = 0b011101; regMult.carry = 1;}; break;
        case 977:    {regMult.outMnt = 0b011111; regMult.carry = 1;}; break;
        case 978:    {regMult.outMnt = 0b100001; regMult.carry = 1;}; break;
        case 979:    {regMult.outMnt = 0b100011; regMult.carry = 1;}; break;
        case 980:    {regMult.outMnt = 0b100101; regMult.carry = 1;}; break;
        case 981:    {regMult.outMnt = 0b100111; regMult.carry = 1;}; break;
        case 982:    {regMult.outMnt = 0b101001; regMult.carry = 1;}; break;
        case 983:    {regMult.outMnt = 0b101011; regMult.carry = 1;}; break;
        case 984:    {regMult.outMnt = 0b101100; regMult.carry = 1;}; break;
        case 985:    {regMult.outMnt = 0b101110; regMult.carry = 1;}; break;
        case 986:    {regMult.outMnt = 0b110000; regMult.carry = 1;}; break;
        case 987:    {regMult.outMnt = 0b110010; regMult.carry = 1;}; break;
        case 988:    {regMult.outMnt = 0b110100; regMult.carry = 1;}; break;
        case 989:    {regMult.outMnt = 0b110110; regMult.carry = 1;}; break;
        case 990:    {regMult.outMnt = 0b111000; regMult.carry = 1;}; break;
        case 991:    {regMult.outMnt = 0b111010; regMult.carry = 1;}; break;
        case 992:    {regMult.outMnt = 0b111110; regMult.carry = 0;}; break;
        case 993:    {regMult.outMnt = 0b000001; regMult.carry = 1;}; break;
        case 994:    {regMult.outMnt = 0b000011; regMult.carry = 1;}; break;
        case 995:    {regMult.outMnt = 0b000101; regMult.carry = 1;}; break;
        case 996:    {regMult.outMnt = 0b000111; regMult.carry = 1;}; break;
        case 997:    {regMult.outMnt = 0b001001; regMult.carry = 1;}; break;
        case 998:    {regMult.outMnt = 0b001011; regMult.carry = 1;}; break;
        case 999:    {regMult.outMnt = 0b001101; regMult.carry = 1;}; break;
        case 1000:    {regMult.outMnt = 0b001111; regMult.carry = 1;}; break;
        case 1001:    {regMult.outMnt = 0b010001; regMult.carry = 1;}; break;
        case 1002:    {regMult.outMnt = 0b010011; regMult.carry = 1;}; break;
        case 1003:    {regMult.outMnt = 0b010101; regMult.carry = 1;}; break;
        case 1004:    {regMult.outMnt = 0b010111; regMult.carry = 1;}; break;
        case 1005:    {regMult.outMnt = 0b011001; regMult.carry = 1;}; break;
        case 1006:    {regMult.outMnt = 0b011011; regMult.carry = 1;}; break;
        case 1007:    {regMult.outMnt = 0b011101; regMult.carry = 1;}; break;
        case 1008:    {regMult.outMnt = 0b011110; regMult.carry = 1;}; break;
        case 1009:    {regMult.outMnt = 0b100000; regMult.carry = 1;}; break;
        case 1010:    {regMult.outMnt = 0b100010; regMult.carry = 1;}; break;
        case 1011:    {regMult.outMnt = 0b100100; regMult.carry = 1;}; break;
        case 1012:    {regMult.outMnt = 0b100110; regMult.carry = 1;}; break;
        case 1013:    {regMult.outMnt = 0b101000; regMult.carry = 1;}; break;
        case 1014:    {regMult.outMnt = 0b101010; regMult.carry = 1;}; break;
        case 1015:    {regMult.outMnt = 0b101100; regMult.carry = 1;}; break;
        case 1016:    {regMult.outMnt = 0b101110; regMult.carry = 1;}; break;
        case 1017:    {regMult.outMnt = 0b110000; regMult.carry = 1;}; break;
        case 1018:    {regMult.outMnt = 0b110010; regMult.carry = 1;}; break;
        case 1019:    {regMult.outMnt = 0b110100; regMult.carry = 1;}; break;
        case 1020:    {regMult.outMnt = 0b110110; regMult.carry = 1;}; break;
        case 1021:    {regMult.outMnt = 0b111000; regMult.carry = 1;}; break;
        case 1022:    {regMult.outMnt = 0b111010; regMult.carry = 1;}; break;
        case 1023:    {regMult.outMnt = 0b111100; regMult.carry = 1;}; break;   
        default:    printf("error\n");
      }

      regMult.outSign = active.sign ^ weight.sign;
      if( (active.exp == 0) || (weight.exp == 0) )
      {
        regMult.outExp = 0;
      }
      else
      {
        regMult.outExp = active.exp + weight.exp + regMult.carry;
        switch (regMult.outMnt)
          {
            case 0:      out = 1.000000;  break;
            case 1:      out = 1.015625;  break;
            case 2:      out = 1.031250;  break;
            case 3:      out = 1.046875;  break;
            case 4:      out = 1.062500;  break;
            case 5:      out = 1.078125;  break;
            case 6:      out = 1.093750;  break;
            case 7:      out = 1.109375;  break;
            case 8:      out = 1.125000;  break;
            case 9:      out = 1.140625;  break;
            case 10:      out = 1.156250;  break;
            case 11:      out = 1.171875;  break;
            case 12:      out = 1.187500;  break;
            case 13:      out = 1.203125;  break;
            case 14:      out = 1.218750;  break;
            case 15:      out = 1.234375;  break;
            case 16:      out = 1.250000;  break;
            case 17:      out = 1.265625;  break;
            case 18:      out = 1.281250;  break;
            case 19:      out = 1.296875;  break;
            case 20:      out = 1.312500;  break;
            case 21:      out = 1.328125;  break;
            case 22:      out = 1.343750;  break;
            case 23:      out = 1.359375;  break;
            case 24:      out = 1.375000;  break;
            case 25:      out = 1.390625;  break;
            case 26:      out = 1.406250;  break;
            case 27:      out = 1.421875;  break;
            case 28:      out = 1.437500;  break;
            case 29:      out = 1.453125;  break;
            case 30:      out = 1.468750;  break;
            case 31:      out = 1.484375;  break;
            case 32:      out = 1.500000;  break;
            case 33:      out = 1.515625;  break;
            case 34:      out = 1.531250;  break;
            case 35:      out = 1.546875;  break;
            case 36:      out = 1.562500;  break;
            case 37:      out = 1.578125;  break;
            case 38:      out = 1.593750;  break;
            case 39:      out = 1.609375;  break;
            case 40:      out = 1.625000;  break;
            case 41:      out = 1.640625;  break;
            case 42:      out = 1.656250;  break;
            case 43:      out = 1.671875;  break;
            case 44:      out = 1.687500;  break;
            case 45:      out = 1.703125;  break;
            case 46:      out = 1.718750;  break;
            case 47:      out = 1.734375;  break;
            case 48:      out = 1.750000;  break;
            case 49:      out = 1.765625;  break;
            case 50:      out = 1.781250;  break;
            case 51:      out = 1.796875;  break;
            case 52:      out = 1.812500;  break;
            case 53:      out = 1.828125;  break;
            case 54:      out = 1.843750;  break;
            case 55:      out = 1.859375;  break;
            case 56:      out = 1.875000;  break;
            case 57:      out = 1.890625;  break;
            case 58:      out = 1.906250;  break;
            case 59:      out = 1.921875;  break;
            case 60:      out = 1.937500;  break;
            case 61:      out = 1.953125;  break;
            case 62:      out = 1.968750;  break;
            case 63:      out = 1.984375;  break;
          }
          
        //指数移位
        if(regMult.outExp == 0)
        {
          out = 0;
        }
        else
        {
          switch (regMult.outExp)
          {
            case 1:     out = out * 3.0517578125e-05;      break;
            case 2:     out = out * 6.103515625e-05;      break;
            case 3:     out = out * 0.0001220703125;      break;
            case 4:     out = out * 0.000244140625;      break;
            case 5:     out = out * 0.00048828125;      break;
            case 6:     out = out * 0.0009765625;      break;
            case 7:     out = out * 0.001953125;      break;
            case 8:     out = out * 0.00390625;      break;
            case 9:     out = out * 0.0078125;      break;
            case 10:    out = out * 0.015625;      break;
            case 11:    out = out * 0.03125;      break;
            case 12:    out = out * 0.0625;      break;
            case 13:    out = out * 0.125;      break;
            case 14:    out = out * 0.25;      break;
            case 15:    out = out * 0.5;      break;
            case 16:    out = out * 1;      break;
            case 17:    out = out * 2;      break;
            case 18:    out = out * 4;      break;
            case 19:    out = out * 8;      break;
            case 20:    out = out * 16;      break;
            case 21:    out = out * 32;      break;
            case 22:    out = out * 64;      break;
            case 23:    out = out * 128;      break;
            case 24:    out = out * 256;      break;
            case 25:    out = out * 512;      break;
            case 26:    out = out * 1024;      break;
            case 27:    out = out * 2048;      break;
            case 28:    out = out * 4096;      break;
            case 29:    out = out * 8192;      break;
            case 30:    out = out * 16384;      break;
            case 31:    out = out * 32768;      break;
          }
        }
      
        //根据符号位判断正负
        out = (regMult.outSign == 1)?(-out):out;
      }
    }
    else if(type == 3)
    {
      regMult.cbMnt = (active.mnt << 3) + weight.mnt;  
      //printf("位数为查找表输入:%d\n",regMult.cbMnt);
      //尾数位lut
      switch (regMult.cbMnt)
      {
        case 0:    {regMult.outMnt = 0b0000; regMult.carry = 0;}; break;
        case 1:    {regMult.outMnt = 0b0010; regMult.carry = 0;}; break;
        case 2:    {regMult.outMnt = 0b0100; regMult.carry = 0;}; break;
        case 3:    {regMult.outMnt = 0b0110; regMult.carry = 0;}; break;
        case 4:    {regMult.outMnt = 0b1000; regMult.carry = 0;}; break;
        case 5:    {regMult.outMnt = 0b1010; regMult.carry = 0;}; break;
        case 6:    {regMult.outMnt = 0b1100; regMult.carry = 0;}; break;
        case 7:    {regMult.outMnt = 0b1110; regMult.carry = 0;}; break;
        case 8:    {regMult.outMnt = 0b0010; regMult.carry = 0;}; break;
        case 9:    {regMult.outMnt = 0b0100; regMult.carry = 0;}; break;
        case 10:   {regMult.outMnt = 0b0110; regMult.carry = 0;}; break;
        case 11:   {regMult.outMnt = 0b1001; regMult.carry = 0;}; break;
        case 12:   {regMult.outMnt = 0b1011; regMult.carry = 0;}; break;
        case 13:   {regMult.outMnt = 0b1101; regMult.carry = 0;}; break;
        case 14:   {regMult.outMnt = 0b0000; regMult.carry = 1;}; break;
        case 15:   {regMult.outMnt = 0b0001; regMult.carry = 1;}; break;
        case 16:   {regMult.outMnt = 0b0100; regMult.carry = 0;}; break;
        case 17:   {regMult.outMnt = 0b0110; regMult.carry = 0;}; break;
        case 18:   {regMult.outMnt = 0b1001; regMult.carry = 0;}; break;
        case 19:   {regMult.outMnt = 0b1100; regMult.carry = 0;}; break;
        case 20:   {regMult.outMnt = 0b1110; regMult.carry = 0;}; break;
        case 21:   {regMult.outMnt = 0b0000; regMult.carry = 1;}; break;
        case 22:   {regMult.outMnt = 0b0010; regMult.carry = 1;}; break;
        case 23:   {regMult.outMnt = 0b0011; regMult.carry = 1;}; break;
        case 24:   {regMult.outMnt = 0b0110; regMult.carry = 0;}; break;
        case 25:   {regMult.outMnt = 0b1001; regMult.carry = 0;}; break;
        case 26:   {regMult.outMnt = 0b1100; regMult.carry = 0;}; break;
        case 27:   {regMult.outMnt = 0b1110; regMult.carry = 0;}; break;
        case 28:   {regMult.outMnt = 0b0000; regMult.carry = 1;}; break;
        case 29:   {regMult.outMnt = 0b0010; regMult.carry = 1;}; break;
        case 30:   {regMult.outMnt = 0b0011; regMult.carry = 1;}; break;
        case 31:   {regMult.outMnt = 0b0101; regMult.carry = 1;}; break;
        case 32:   {regMult.outMnt = 0b1000; regMult.carry = 0;}; break;
        case 33:   {regMult.outMnt = 0b1011; regMult.carry = 0;}; break;
        case 34:   {regMult.outMnt = 0b1110; regMult.carry = 0;}; break;
        case 35:   {regMult.outMnt = 0b0000; regMult.carry = 1;}; break;
        case 36:   {regMult.outMnt = 0b0010; regMult.carry = 1;}; break;
        case 37:   {regMult.outMnt = 0b0100; regMult.carry = 1;}; break;
        case 38:   {regMult.outMnt = 0b0101; regMult.carry = 1;}; break;
        case 39:   {regMult.outMnt = 0b0110; regMult.carry = 1;}; break;
        case 40:   {regMult.outMnt = 0b1010; regMult.carry = 0;}; break;
        case 41:   {regMult.outMnt = 0b1101; regMult.carry = 0;}; break;
        case 42:   {regMult.outMnt = 0b0000; regMult.carry = 1;}; break;
        case 43:   {regMult.outMnt = 0b0010; regMult.carry = 1;}; break;
        case 44:   {regMult.outMnt = 0b0100; regMult.carry = 1;}; break;
        case 45:   {regMult.outMnt = 0b0101; regMult.carry = 1;}; break;
        case 46:   {regMult.outMnt = 0b0111; regMult.carry = 1;}; break;
        case 47:   {regMult.outMnt = 0b1000; regMult.carry = 1;}; break;
        case 48:   {regMult.outMnt = 0b1100; regMult.carry = 0;}; break;
        case 49:   {regMult.outMnt = 0b0000; regMult.carry = 1;}; break;
        case 50:   {regMult.outMnt = 0b0010; regMult.carry = 1;}; break;
        case 51:   {regMult.outMnt = 0b0011; regMult.carry = 1;}; break;
        case 52:   {regMult.outMnt = 0b0101; regMult.carry = 1;}; break;
        case 53:   {regMult.outMnt = 0b0111; regMult.carry = 1;}; break;
        case 54:   {regMult.outMnt = 0b1000; regMult.carry = 1;}; break;
        case 55:   {regMult.outMnt = 0b1010; regMult.carry = 1;}; break;
        case 56:   {regMult.outMnt = 0b1110; regMult.carry = 0;}; break;
        case 57:   {regMult.outMnt = 0b0001; regMult.carry = 1;}; break;
        case 58:   {regMult.outMnt = 0b0011; regMult.carry = 1;}; break;
        case 59:   {regMult.outMnt = 0b0101; regMult.carry = 1;}; break;
        case 60:   {regMult.outMnt = 0b0110; regMult.carry = 1;}; break;
        case 61:   {regMult.outMnt = 0b1000; regMult.carry = 1;}; break;
        case 62:   {regMult.outMnt = 0b1010; regMult.carry = 1;}; break;
        case 63:   {regMult.outMnt = 0b1100; regMult.carry = 1;}; break;     
        default:    printf("error\n");
      }
      regMult.outSign = active.sign ^ weight.sign;
      if((active.exp == 0) || (weight.exp == 0))
      {
        regMult.outExp = 0;
      }
      else
      {
        regMult.outExp = active.exp + weight.exp + regMult.carry;
        //求尾数
        switch (regMult.outMnt)
          {
            case 0:     out = 1 +     0     +     0     +     0     +     0     ;  break;
            case 1:     out = 1 +     0     +     0     +     0     +   0.0625  ;  break;
            case 2:     out = 1 +     0     +     0     +   0.125   +     0     ;  break;
            case 3:     out = 1 +     0     +     0     +   0.125   +   0.0625  ;  break;
            case 4:     out = 1 +     0     +    0.25   +     0     +     0     ;  break;
            case 5:     out = 1 +     0     +    0.25   +     0     +   0.0625  ;  break;
            case 6:     out = 1 +     0     +    0.25   +   0.125   +     0     ;  break; 
            case 7:     out = 1 +     0     +    0.25   +   0.125   +   0.0625  ;  break;
            case 8:     out = 1 +    0.5    +     0     +     0     +     0     ;  break;
            case 9:     out = 1 +    0.5    +     0     +     0     +   0.0625  ;  break;
            case 10:    out = 1 +    0.5    +     0     +   0.125   +     0     ;  break;
            case 11:    out = 1 +    0.5    +     0     +   0.125   +   0.0625  ;  break;
            case 12:    out = 1 +    0.5    +    0.25   +     0     +     0     ;  break; 
            case 13:    out = 1 +    0.5    +    0.25   +     0     +   0.0625  ;  break;
            case 14:    out = 1 +    0.5    +    0.25   +   0.125   +     0     ;  break;
            case 15:    out = 1 +    0.5    +    0.25   +   0.125   +   0.0625  ;  break;   
          }
          
        //指数移位
        if(regMult.outExp == 0)
        {
          out = 0;
        }
        else
        {
          switch (regMult.outExp)
          {
            case 1:     out = out * 3.0517578125e-05;      break;
            case 2:     out = out * 6.103515625e-05;      break;
            case 3:     out = out * 0.0001220703125;      break;
            case 4:     out = out * 0.000244140625;      break;
            case 5:     out = out * 0.00048828125;      break;
            case 6:     out = out * 0.0009765625;      break;
            case 7:     out = out * 0.001953125;      break;
            case 8:     out = out * 0.00390625;      break;
            case 9:     out = out * 0.0078125;      break;
            case 10:    out = out * 0.015625;      break;
            case 11:    out = out * 0.03125;      break;
            case 12:    out = out * 0.0625;      break;
            case 13:    out = out * 0.125;      break;
            case 14:    out = out * 0.25;      break;
            case 15:    out = out * 0.5;      break;
            case 16:    out = out * 1;      break;
            case 17:    out = out * 2;      break;
            case 18:    out = out * 4;      break;
            case 19:    out = out * 8;      break;
            case 20:    out = out * 16;      break;
            case 21:    out = out * 32;      break;
            case 22:    out = out * 64;      break;
            case 23:    out = out * 128;      break;
            case 24:    out = out * 256;      break;
            case 25:    out = out * 512;      break;
            case 26:    out = out * 1024;      break;
            case 27:    out = out * 2048;      break;
            case 28:    out = out * 4096;      break;
            case 29:    out = out * 8192;      break;
            case 30:    out = out * 16384;      break;
            case 31:    out = out * 32768;      break;
          }
        }
      
        //根据符号位判断正负
        out = (regMult.outSign == 1)?(-out):out;
      }
    }
    return out;
  }


int main()
{
    float A = 6.5855;
    int type1 = 3;
    int type2 = 5;
    float out1, out2;
    sfp A_sfp, B_sfp;
    A_sfp = floatsfp(A ,type1);
    B_sfp = floatsfp(A, type2);
    cout << oct << A_sfp.sign <<"\n"<< oct << A_sfp.exp << "\n"<< oct << A_sfp.mnt <<"\n"<< endl;
    cout << oct << B_sfp.sign <<"\n"<< oct << B_sfp.exp << "\n"<< oct << B_sfp.mnt <<"\n"<< endl;

    out1 = sfpfixed(A_sfp, A_sfp, type1);
    out2 = sfpfixed(B_sfp, B_sfp, type2);
    cout << out1 << endl;
    cout << out2 << endl;
}