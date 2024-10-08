//+------------------------------------------------------------------+
//|                                         VolumeRoundToCorrect.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Возвращает ближайший корректный лот                              |
//+------------------------------------------------------------------+
double VolumeRoundToCorrect(const double volume,const double min,const double max,const double step)
  {
   return(step==0 ? min : fmin(fmax(round(volume/step)*step,min),max));
  }
