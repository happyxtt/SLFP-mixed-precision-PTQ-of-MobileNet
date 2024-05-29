#include "./common/MobileNetv1.h"
//浮点数转定sfp<4,5> or sfp<4,3>
sfp floattosfp(float a , int type) // modified
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

int24 floattofixed(float a)
  {
    bfixed reg;
    int24 out;
    float Mfraction;

    reg.sign = (a >= 0)?0:1;//符号位
    reg.integer = (int)abs(a);//整数部分
    Mfraction = abs(a) - reg.integer;//取小数部分
    // printf("integer:%d\n",reg.integer);
    // printf("Mf:%f\n",Mfraction);
    reg.fraction = 0;
    for(int i = 0; i < 9; ++i)
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
    out.out  = ((reg.fraction&0b1) == 1)?((reg.integer << 8) + (reg.fraction >> 1) + 1):((reg.integer << 8) + (reg.fraction >> 1));
    out.out  = reg.sign?(0xFFFFFF- out.out + 1):out.out;
    return out;
  }

void get_weightSfp(float* weight , sfp *out, float Kw, int size, int type) //modified
  {
      float *weightSfp = (float *)malloc(size*sizeof(float));
      for(int i = 0; i < size; ++i)
      {
        weightSfp[i] = weight[i]/Kw;
        out[i] = floattosfp(weightSfp[i], type);
      }
      free(weightSfp);
  }

void get_biasint24(float* bias , int24 *out, float Kr, int size)  //no change
  {
    float *biasint24 = (float *)malloc(size*sizeof(float));
      for(int i = 0; i < size; ++i)
      {
        biasint24[i] = bias[i]/Kr;
        out[i] = floattofixed(biasint24[i]);
      }
      free(biasint24);
  }