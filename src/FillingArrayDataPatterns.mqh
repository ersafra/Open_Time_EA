//+------------------------------------------------------------------+
//|                                     FillingArrayDataPatterns.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Заполнение массива структур данных паттернов                     |
//+------------------------------------------------------------------+
int FillingArrayDataPatterns(void)
  {
   int total=ArrayRange(ArrayNames,0);
   ResetLastError();
   if(ArrayResize(data_inputs.pattern,total)!=total)
     {
      Print(__FUNCTION__,": Error changing s_patterns array size: ",GetLastError());
      return WRONG_VALUE;
     }
   ZeroMemory(data_inputs);
   data_inputs.equ_min=(double)InpEQ;
   data_inputs.font_color=InpFontColor;
   data_inputs.font_name=InpFontName;
   data_inputs.font_size=InpFontSize;
   data_inputs.used_group1=InpEnableOneBarPatterns;
   data_inputs.used_group2=InpEnableTwoBarPatterns;
   data_inputs.used_group3=InpEnableThreeBarPatterns;
   data_inputs.show_descript=InpShowPatternDescript;
   for(int i=0; i<total; i++)
     {
      data_inputs.pattern[i].name_long=ArrayNames[i][0];
      data_inputs.pattern[i].mame_short=ArrayNames[i][1];
      data_inputs.pattern[i].used_this=
         (
            i==0  ?  InpEnablePAT_DOUBLE_INSIDE    :
            i==1  ?  InpEnablePAT_INSIDE           :
            i==2  ?  InpEnablePAT_OUTSIDE          :
            i==3  ?  InpEnablePAT_PINUP            :
            i==4  ?  InpEnablePAT_PINDOWN          :
            i==5  ?  InpEnablePAT_PPRUP            :
            i==6  ?  InpEnablePAT_PPRDN            :
            i==7  ?  InpEnablePAT_DBLHC            :
            i==8  ?  InpEnablePAT_DBHLC            :
            i==9  ?  InpEnablePAT_CPRU             :
            i==10 ?  InpEnablePAT_CPRD             :
            i==11 ?  InpEnablePAT_NB               :
            i==12 ?  InpEnablePAT_FBU              :
            i==13 ?  InpEnablePAT_FBD              :
            i==14 ?  InpEnablePAT_MB               :
            i==15 ?  InpEnablePAT_HAMMER           :
            i==16 ?  InpEnablePAT_SHOOTSTAR        :
            i==17 ?  InpEnablePAT_EVSTAR           :
            i==18 ?  InpEnablePAT_MORNSTAR         :
            i==19 ?  InpEnablePAT_BEARHARAMI       :
            i==20 ?  InpEnablePAT_BEARHARAMICROSS  :
            i==21 ?  InpEnablePAT_BULLHARAMI       :
            i==22 ?  InpEnablePAT_BULLHARAMICROSS  :
            i==23 ?  InpEnablePAT_DARKCLOUD        :
            i==24 ?  InpEnablePAT_DOJISTAR         :
            i==25 ?  InpEnablePAT_ENGBEARLINE      :
            i==26 ?  InpEnablePAT_ENGBULLLINE      :
            i==27 ?  InpEnablePAT_EVDJSTAR         :
            i==28 ?  InpEnablePAT_MORNDJSTAR       :
            i==29 ?  InpEnablePAT_NB2              :
            false
         );
      data_inputs.pattern[i].order_type=ENUM_ORDER_TYPE
                                        (
                                           i==0  ?  InpTypeOrderPAT_DOUBLE_INSIDE    :
                                           i==1  ?  InpTypeOrderPAT_INSIDE           :
                                           i==2  ?  InpTypeOrderPAT_OUTSIDE          :
                                           i==3  ?  InpTypeOrderPAT_PINUP            :
                                           i==4  ?  InpTypeOrderPAT_PINDOWN          :
                                           i==5  ?  InpTypeOrderPAT_PPRUP            :
                                           i==6  ?  InpTypeOrderPAT_PPRDN            :
                                           i==7  ?  InpTypeOrderPAT_DBLHC            :
                                           i==8  ?  InpTypeOrderPAT_DBHLC            :
                                           i==9  ?  InpTypeOrderPAT_CPRU             :
                                           i==10 ?  InpTypeOrderPAT_CPRD             :
                                           i==11 ?  InpTypeOrderPAT_NB               :
                                           i==12 ?  InpTypeOrderPAT_FBU              :
                                           i==13 ?  InpTypeOrderPAT_FBD              :
                                           i==14 ?  InpTypeOrderPAT_MB               :
                                           i==15 ?  InpTypeOrderPAT_HAMMER           :
                                           i==16 ?  InpTypeOrderPAT_SHOOTSTAR        :
                                           i==17 ?  InpTypeOrderPAT_EVSTAR           :
                                           i==18 ?  InpTypeOrderPAT_MORNSTAR         :
                                           i==19 ?  InpTypeOrderPAT_BEARHARAMI       :
                                           i==20 ?  InpTypeOrderPAT_BEARHARAMICROSS  :
                                           i==21 ?  InpTypeOrderPAT_BULLHARAMI       :
                                           i==22 ?  InpTypeOrderPAT_BULLHARAMICROSS  :
                                           i==23 ?  InpTypeOrderPAT_DARKCLOUD        :
                                           i==24 ?  InpTypeOrderPAT_DOJISTAR         :
                                           i==25 ?  InpTypeOrderPAT_ENGBEARLINE      :
                                           i==26 ?  InpTypeOrderPAT_ENGBULLLINE      :
                                           i==27 ?  InpTypeOrderPAT_EVDJSTAR         :
                                           i==28 ?  InpTypeOrderPAT_MORNDJSTAR       :
                                           i==29 ?  InpTypeOrderPAT_NB2              :
                                           WRONG_VALUE
                                        );
     }
   return total;
  }
//+------------------------------------------------------------------+
