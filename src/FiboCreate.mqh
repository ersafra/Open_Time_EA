//+------------------------------------------------------------------+
//|                                                   FiboCreate.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
void carregaFibonacci()
  {
//--- Copy indicator buffer
   CopyNumber = CopyBuffer(ZZ_Handle, 0, 0, 200, ZZ_Buffer);
   if(CopyNumber <= 0)
      Print("Buffer do indicador indisponível");
   ArraySetAsSeries(ZZ_Buffer, true);

//--- copying rates
   if(CopyRates(Symbol(), 0, 0, 200, RatesArray) > 0)  ///---- Proceeds in case price data is available
     {
      //--- set array as time series
      ArraySetAsSeries(RatesArray, true);


      //--- Initial high-low points mapping
      if(HL[0] == 666)
        {
         int ZCount = 0;
         for(int i=0; i <= CopyNumber && ZCount <= 3 && !IsStopped(); i++) ///----- ZZ legs maping
           {
            if(ZZ_Buffer[i] != 0)
              {
               HL[ZCount] = ZZ_Buffer[i];
               HL_Time[ZCount] = RatesArray[i].time;
               ZCount++;
              }
           }
         TrendDirection = CheckTrend(HL[0], HL[1], HL[2], HL[3]);
         Fibo00 = HL[0];
         Time00 = HL_Time[0];
         Fibo100 = HL[1];
         Time100 = HL_Time[1];
         FiboBASE = fabs(Fibo100 - Fibo00);
        }

      // high-low points mapping in concequence
      if(ZZ_Buffer[0] != 0 && ZZ_Buffer[0] != HL[0])
        {
         HL[3] = HL[2];
         HL[2] = HL[1];
         HL[1] = HL[0];
         HL[0] = ZZ_Buffer[0];
         HL_Time[3] = HL_Time[2];
         HL_Time[2] = HL_Time[1];
         HL_Time[1] = HL_Time[0];
         HL_Time[0] = RatesArray[0].time;
         TrendDirection = CheckTrend(HL[0], HL[1], HL[2], HL[3]);
        }
      if(!PositionSelect(Symbol()))
        {
         switch(TrendDirection)
           {
            case  1:
               Comment("A tendência está em alta");
               FiboBASE = Fibo00 - Fibo100;
               Fibo23   = Fibo00 - 0.236 * FiboBASE;
               Fibo38   = Fibo00 - 0.382 * FiboBASE;
               Fibo61   = Fibo00 - 0.618 * FiboBASE;
               Fibo76   = Fibo00 - 0.764 * FiboBASE;
               if(HL[0] > Fibo00)
                 {
                  Fibo00 = HL[0];
                  Time00 = HL_Time[0];
                  if(HL[0] - HL[1] > FiboBASE)
                    {
                     Fibo100 = HL[1];
                     Time100 = HL_Time[1];
                    }
                 }
               if(HL[0] < Fibo100)
                 {
                  Fibo00 = HL[0];
                  Time00 = HL_Time[0];
                  Fibo100 = HL[1];
                  Time100 = HL_Time[1];
                  TrendDirection = CheckTrend(HL[0], HL[1], HL[2], HL[3]);
                  break;
                 }
               if(!FiboCreate(Time100, Fibo100, Time00, Fibo00))
                  Print("Falha na criação do metodo fibo !");

               // check if buy conditions are met
               if(((RatesArray[0].close - Fibo76) > Point() * SafetyBuffer && (Fibo76 - RatesArray[1].close) > Point() * SafetyBuffer) ||
                  ((RatesArray[0].close - Fibo61) > Point() * SafetyBuffer && (Fibo61 - RatesArray[1].close) > Point() * SafetyBuffer) ||
                  ((RatesArray[0].close - Fibo38) > Point() * SafetyBuffer && (Fibo38 - RatesArray[1].close) > Point() * SafetyBuffer) ||
                  ((RatesArray[0].close - Fibo23) > Point() * SafetyBuffer && (Fibo23 - RatesArray[1].close) > Point() * SafetyBuffer))
                 {
                //  Print("A condição de compra é verdadeira");
                 }
               break;
            case -1:
               Comment("A tendência está em baixa");
               FiboBASE = Fibo100 - Fibo00;                    ///--- map FIBO levels
               Fibo23   = Fibo00 + 0.236 * FiboBASE;
               Fibo38   = Fibo00 + 0.382 * FiboBASE;
               Fibo61   = Fibo00 + 0.618 * FiboBASE;
               Fibo76   = Fibo00 + 0.764 * FiboBASE;
               if(HL[0] < Fibo00)
                 {
                  Fibo00 = HL[0];
                  Time00 = HL_Time[0];
                  if(HL[1] - HL[0] > FiboBASE)
                    {
                     Fibo100 = HL[1];
                     Time100 = HL_Time[1];
                    }
                 }
               if(HL[0] > Fibo100)
                 {
                  Fibo00 = HL[0];
                  Time00 = HL_Time[0];
                  Fibo100 = HL[1];
                  Time100 = HL_Time[1];
                  TrendDirection = CheckTrend(HL[0], HL[1], HL[2], HL[3]);
                  break;
                 }
               if(!FiboCreate(Time100, Fibo100, Time00, Fibo00))
                  Print("Fibo create method fails");

               // check if sell conditions are met
               if(((Fibo76 - RatesArray[0].close) > Point() * SafetyBuffer && (Fibo76 - RatesArray[1].close) < Point() * SafetyBuffer) ||
                  ((Fibo61 - RatesArray[0].close) > Point() * SafetyBuffer && (Fibo61 - RatesArray[1].close) < Point() * SafetyBuffer) ||
                  ((Fibo38 - RatesArray[0].close) > Point() * SafetyBuffer && (Fibo38 - RatesArray[1].close) < Point() * SafetyBuffer) ||
                  ((Fibo23 - RatesArray[0].close) > Point() * SafetyBuffer && (Fibo23 - RatesArray[1].close) < Point() * SafetyBuffer))
                 {
                 // Print("A condição de compra é verdadeira");
                 }

               break;
            case  0:
               Comment("PLANO");
               FiboBASE = 0;                    ///--- map FIBO levels
               Fibo23   = 0;
               Fibo38   = 0;
               Fibo61   = 0;
               Fibo76   = 0;
               if(!ObjectDelete(0, "MyFIBO"))
                  Print("O método de exclusão FIBO falhou");

               break;
           }
        }

     }
   else
     {
      Print("A série temporal não está disponível ", GetLastError());
     }
  }

//+------------------------------------------------------------------+
//| FiboCreate function                                              |
//+------------------------------------------------------------------+
bool FiboCreate(datetime time1, double array1, datetime time0, double array0)
  {
   if(!ObjectDelete(0, "MyFIBO"))
      Print("O método de exclusão FIBO falhou");
   if(ObjectCreate(0, "MyFIBO", OBJ_FIBO, 0, time1, array1, time0, array0))  ///----- FIBO retracement creation based on last ZZ leg
     {
      ObjectSetInteger(0, "MyFIBO", OBJPROP_LEVELCOLOR, LevelColor);
      ObjectSetInteger(0, "MyFIBO", OBJPROP_LEVELSTYLE, STYLE_SOLID);
      ObjectSetInteger(0, "MyFIBO", OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(0, "MyFIBO", OBJPROP_LEVELS, 6);
      ObjectSetDouble(0,  "MyFIBO", OBJPROP_LEVELVALUE, 0, 0.000);
      ObjectSetDouble(0,  "MyFIBO", OBJPROP_LEVELVALUE, 1, 0.236);
      ObjectSetDouble(0,  "MyFIBO", OBJPROP_LEVELVALUE, 2, 0.382);
      ObjectSetDouble(0,  "MyFIBO", OBJPROP_LEVELVALUE, 3, 0.618);
      ObjectSetDouble(0,  "MyFIBO", OBJPROP_LEVELVALUE, 4, 0.764);
      ObjectSetDouble(0,  "MyFIBO", OBJPROP_LEVELVALUE, 5, 1.000);
      ObjectSetString(0,  "MyFIBO", OBJPROP_LEVELTEXT, 0, "0.0% (%$)");
      ObjectSetString(0,  "MyFIBO", OBJPROP_LEVELTEXT, 1, "23.6% (%$)");
      ObjectSetString(0,  "MyFIBO", OBJPROP_LEVELTEXT, 2, "38.2% (%$)");
      ObjectSetString(0,  "MyFIBO", OBJPROP_LEVELTEXT, 3, "61.8% (%$)");
      ObjectSetString(0,  "MyFIBO", OBJPROP_LEVELTEXT, 4, "76.4% (%$)");
      ObjectSetString(0,  "MyFIBO", OBJPROP_LEVELTEXT, 5, "100.0% (%$)");
      return(true);
     }
   else
     {
      Print("A criação do MyFIBO falhou");
      return (false);
     }
  }

//+------------------------------------------------------------------+
//| CheckTrend function                                              |
//+------------------------------------------------------------------+
bool CheckTrend(double hl0,
                double hl1,
                double hl2,
                double hl3)
  {
   int check_trend = 0;
   if(((hl2 - hl0) > Point() * TrendPrecision) && ((hl3 - hl1) > Point() * TrendPrecision))
      check_trend = -1; // trend is down
   if(((hl0 - hl2) > Point() * TrendPrecision) && ((hl1 - hl3) > Point() * TrendPrecision))
      check_trend =  1; // trend is up
   return(check_trend);
  }
//+------------------------------------------------------------------+
