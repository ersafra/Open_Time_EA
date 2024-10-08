//+------------------------------------------------------------------+
//|                                         VolumeRoundToSmaller.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Возвращает ближайший в меньшую сторону корректный лот            |
//+------------------------------------------------------------------+
double VolumeRoundToSmaller(const double volume,const double min,const double max,const double step)
  {
   return(step==0 ? min : fmin(fmax(floor(volume/step)*step,min),max));
  }


