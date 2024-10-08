//+------------------------------------------------------------------+
//|                                         Fair Value Gap Indicator |
//|                                       Copyright 2024, Hieu Hoang |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, hieuhoangcntt@gmail.com"
#property indicator_chart_window
#property indicator_buffers 0
double _low, _high;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isGreenCandle(double open, double close)
  {
   return open < close;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isRedCandle(double open, double close)
  {
   return !isGreenCandle(open, close);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBullFVG(int index,
               const double &open[],
               const double &high[],
               const double &low[],
               const double &close[])
  {

   if(isGreenCandle(open[index-1], close[index-1]) &&
      high[index-2] < low[index] && high[index-2] < _low
     )
      return true;
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBearFVG(int index,
               const double &open[],
               const double &high[],
               const double &low[],
               const double &close[])
  {

   if(isRedCandle(open[index-1], close[index-1]) &&
      low[index-2] > high[index] && low[index-2] > _high
     )
      return true;
   return false;
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   ObjectsDeleteAll(0);
   _low = iLow(_Symbol, PERIOD_CURRENT, 0);
   _high = iHigh(_Symbol, PERIOD_CURRENT, 0);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   int end = prev_calculated == 0 ? 2 : prev_calculated - 1;
   string name = "";
   for(int i = rates_total - 1; i >= end; i--)
     {
      _low = _low < low[i] ? _low : low[i];
      _high = _high > high[i] ? _high: high[i];
      if(isBullFVG(i, open, high, low, close))
        {
         name = "Buy range " + high[i-2] + " ↗ " + low[i];
         ObjectCreate(0, name, OBJ_RECTANGLE, 0, time[i-2], low[i], time[rates_total-1], high[i-2]);
         ObjectSetInteger(0, name, OBJPROP_COLOR, clrBlue);
         ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
         ObjectSetInteger(0, name, OBJPROP_FILL, true);
        }
      else
         if(isBearFVG(i, open, high, low, close))
           {
            name = "Sell range " + low[i-2] + " ↘ " + high[i];
            ObjectCreate(0, name, OBJ_RECTANGLE, 0, time[i-2], high[i], time[rates_total-1], low[i-2]);
            ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
            ObjectSetInteger(0, name, OBJPROP_FILL, true);
           }

     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
