//+------------------------------------------------------------------+
//|                                              Currencyprofits.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property version "1.001"
//---
#define MODE_LOW 1
#define MODE_HIGH 2
//--- input parameters
input int PercentRisk = 14; // % risk from Free Margin
sinput string FirstMA = "Parameters first indicator";
input ENUM_TIMEFRAMES period_first = PERIOD_CURRENT;        // period first MA
input int ma_period_first = 32;                             // averaging period first MA
input int ma_shift_first = 0;                               // horizontal shift first MA
input ENUM_MA_METHOD ma_method_first = MODE_SMA;            // smoothing type first MA
input ENUM_APPLIED_PRICE applied_price_first = PRICE_CLOSE; // type of price or handle first MA
sinput string SecondtMA = "Parameters second indicator";
input ENUM_TIMEFRAMES period_second = PERIOD_CURRENT;        // period second MA
input int ma_period_second = 86;                             // averaging period second MA
input int ma_shift_second = 0;                               // horizontal shift second MA
input ENUM_MA_METHOD ma_method_second = MODE_SMA;            // smoothing type second MA
input ENUM_APPLIED_PRICE applied_price_second = PRICE_CLOSE; // type of price or handle second MA
//----[]
input int ma_period_first_2 = 2;                             
input int ma_shift_first_2 = 0;                              
input int ma_period_first_50 = 50;                             
input int ma_shift_first_50 = 0;                               
input int ma_period_first_9 = 9;                             
input int ma_shift_first_9 = 0;                               
input int ma_period_second_48 = 48;                             
input int ma_shift_second_48 = 0;  
input int ma_period_second_200 = 200;                             
input int ma_shift_second_200 = 0;  
input int ma_period_second_21 = 21;                             
input int ma_shift_second_21 = 0;  

//---
ENUM_ACCOUNT_MARGIN_MODE m_margin_mode;
// double         m_adjusted_point;             // point value adjusted for 3 or 5 points
// double         ExtStopLoss=0.0;
int handle_iMA_first;  // variable for storing the handle of the iMA indicator
int handle_iMA_second; // variable for storing the handle of the iMA indicator

int handle_iMA_first_2;   // variable for storing the handle of the iMA indicator
int handle_iMA_second_48; // variable for storing the handle of the iMA indicator

int handle_iMA_first_50;   // variable for storing the handle of the iMA indicator
int handle_iMA_second_200; // variable for storing the handle of the iMA indicator

int handle_iMA_first_9;   // variable for storing the handle of the iMA indicator
int handle_iMA_second_21; // variable for storing the handle of the iMA indicator
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInitcurrencyProfits()
{
   SetMarginMode();
   if (!IsHedging())
   {
      Print("Hedging only!");
      return (INIT_FAILED);
   }
   if (ma_period_first == ma_period_second)
   {
      Print("Parameters incorrect. averaging period first MA == averaging period second MA!");
      return (INIT_PARAMETERS_INCORRECT);
   }
   if (ma_period_first_2 == ma_period_second_48)
   {
      Print("Parameters incorrect. averaging period first MA == averaging period second MA!");
      return (INIT_PARAMETERS_INCORRECT);
   }
   if (ma_period_first_50 == ma_period_second_200)
   {
      Print("Parameters incorrect. averaging period first MA == averaging period second MA!");
      return (INIT_PARAMETERS_INCORRECT);
   }
   if (ma_period_first_9 == ma_period_second_21)
   {
      Print("Parameters incorrect. averaging period first MA == averaging period second MA!");
      return (INIT_PARAMETERS_INCORRECT);
   }
   //---
   m_symbol_info.Name(Symbol()); // sets symbol name
   if (!RefreshRates())
   {
      Print("Error RefreshRates. Bid=", DoubleToString(m_symbol_info.Bid(), Digits()),
            ", Ask=", DoubleToString(m_symbol_info.Ask(), Digits()));
      return (INIT_FAILED);
   }
   m_symbol_info.Refresh();
   //---
   //  trade.SetExpertMagicNumber(InpMagic);
   //---
   // trade.SetDeviationInPoints(m_slippage);
   //--- tuning for 3 or 5 digits
   //  int digits_adjust=1;
   //   if(m_symbol_info.Digits()==3 || m_symbol_info.Digits()==5)
   //    digits_adjust=10;
   //  m_adjusted_point=m_symbol_info.Point()*digits_adjust;
   //  ExtStopLoss     =InpStopLoss*m_adjusted_point;
   //---
   //if (!m_money.Init(GetPointer(m_symbol_info), Period(), m_symbol_info.Point() * digits_adjust))
   //   return (INIT_FAILED);
 //  m_money.Percent(PercentRisk); // 10% risk
                                 //--- create handle of the indicator iMA
   handle_iMA_first = iMA(m_symbol_info.Name(), period_first, ma_period_first, ma_shift_first, ma_method_first, applied_price_first);
   //--- if the handle is not created
   if (handle_iMA_first == INVALID_HANDLE)
   {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol_info.Name(),EnumToString(Period()),GetLastError());
      //--- the indicator is stopped early
      return (INIT_FAILED);
   }
   //--- create handle of the indicator iMA
   handle_iMA_second = iMA(m_symbol_info.Name(), period_second, ma_period_second, ma_shift_second, ma_method_second, applied_price_second);
   //--- if the handle is not created
   if (handle_iMA_second == INVALID_HANDLE)
   {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol_info.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return (INIT_FAILED);
   }
   //+------------------------------------------------------------------+
   handle_iMA_first_2 = iMA(m_symbol_info.Name(), period_first, ma_period_first_2, ma_shift_first_2, ma_method_first, applied_price_first);
   if (handle_iMA_first == INVALID_HANDLE)
   {
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol_info.Name(),
                  EnumToString(Period()),
                  GetLastError());
      return (INIT_FAILED);
   }
   handle_iMA_second_48 = iMA(m_symbol_info.Name(), period_second, ma_period_second_48, ma_shift_second_48, ma_method_second, applied_price_second);
   if (handle_iMA_second == INVALID_HANDLE)
   {
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol_info.Name(),
                  EnumToString(Period()),
                  GetLastError());
      return (INIT_FAILED);
   }
   handle_iMA_first_50 = iMA(m_symbol_info.Name(), period_first, ma_period_first_50, ma_shift_first_50, ma_method_first, applied_price_first);
   if (handle_iMA_first == INVALID_HANDLE)
   {
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol_info.Name(),
                  EnumToString(Period()),
                  GetLastError());
      return (INIT_FAILED);
   }
   handle_iMA_second_200 = iMA(m_symbol_info.Name(), period_second, ma_period_second_200, ma_shift_second_200, ma_method_second, applied_price_second);
   if (handle_iMA_second == INVALID_HANDLE)
   {
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol_info.Name(),
                  EnumToString(Period()),
                  GetLastError());
      return (INIT_FAILED);
   }
   handle_iMA_first_9 = iMA(m_symbol_info.Name(), period_first, ma_period_first_9, ma_shift_first_9, ma_method_first, applied_price_first);
   if (handle_iMA_first == INVALID_HANDLE)
   {
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol_info.Name(),
                  EnumToString(Period()),
                  GetLastError());
      return (INIT_FAILED);
   }
   handle_iMA_second_21 = iMA(m_symbol_info.Name(), period_second, ma_period_second_21, ma_shift_second_21, ma_method_second, applied_price_second);
   if (handle_iMA_second == INVALID_HANDLE)
   {
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol_info.Name(),
                  EnumToString(Period()),
                  GetLastError());
      return (INIT_FAILED);
   }

   //---
   return (INIT_SUCCEEDED);
}

void OnTickcurrencyProfits()
{
   //---
   int total = 0;
   for (int i = PositionsTotal() - 1; i >= 0; i--)
      if (m_position.SelectByIndex(i)) // seleciona a posição por índice para posterior acesso às suas propriedades
         if (m_position.Symbol() == m_symbol_info.Name() && m_position.Magic() == InpMagic)
         {
            total++;

            if (m_position.PositionType() == POSITION_TYPE_BUY)
            {
               if (m_position.PriceCurrent() >= iHighest(m_symbol_info.Name(), Period(), MODE_HIGH, 6, 1))
               {
                 //Print("<----- Aqui teria fechado uma compra");
                  trade.PositionClose(m_position.Ticket());
                  return;
               }
            }

            if (m_position.PositionType() == POSITION_TYPE_SELL)
            {
               if (m_position.PriceCurrent() <= iLowest(m_symbol_info.Name(), Period(), MODE_LOW, 6, 1))
               {
                 // Print("<----- Aqui teria fechado uma venda");
                  trade.PositionClose(m_position.Ticket());
                  return;
               }
            }
         }

   if (total == 0)
   {
      //--- Buy
      if (iMAGet(handle_iMA_first, 1) > iMAGet(handle_iMA_second, 1) &&
          m_symbol_info.Bid() <= iLowest(m_symbol_info.Name(), Period(), MODE_LOW, 6, 1))
      { 
         if (!RefreshRates())
            return;

         double sl = m_symbol_info.Ask() - ExtStopLoss;
         double tp = 0.0;

         double check_open_long_lot = m_money.CheckOpenLong(m_symbol_info.Ask(), sl);
         Print("sl=", DoubleToString(sl, m_symbol_info.Digits()),
               ", CheckOpenLong: ", DoubleToString(check_open_long_lot, 2),
               ", Balance: ", DoubleToString(account_info.Balance(), 2),
               ", Equity: ", DoubleToString(account_info.Equity(), 2),
               ", FreeMargin: ", DoubleToString(account_info.FreeMargin(), 2));
         if (check_open_long_lot == 0.0)
            return;

         //--- verifique o volume antes do OrderSend para evitar o erro "dinheiro insuficiente" (CTrade)
         double chek_volime_lot = trade.CheckVolume(m_symbol_info.Name(), check_open_long_lot, m_symbol_info.Ask(), ORDER_TYPE_BUY);

         if (chek_volime_lot != 0.0)
            if (chek_volime_lot >= check_open_long_lot)
            {
               if (trade.Buy(check_open_long_lot, NULL, m_symbol_info.Ask(),
                             m_symbol_info.NormalizePrice(sl), tp,"BuyNew"))
               {
                  if (trade.ResultDeal() == 0)
                  {
                     Print("Buy -> false. Result Retcode: ", trade.ResultRetcode(),
                           ", description of result: ", trade.ResultRetcodeDescription());
                  }
                  else
                     Print("Buy -> true. Result Retcode: ", trade.ResultRetcode(),
                           ", description of result: ", trade.ResultRetcodeDescription());
               }
               else
               {
                  Print("Buy -> false. Result Retcode: ", trade.ResultRetcode(),
                        ", description of result: ", trade.ResultRetcodeDescription());
               }
            }
         return;
      }
      //--- Sell
      if (iMAGet(handle_iMA_first, 1) < iMAGet(handle_iMA_second, 1) &&
          m_symbol_info.Bid() >= iHighest(m_symbol_info.Name(), Period(), MODE_HIGH, 6, 1))
      {
         if (!RefreshRates())
            return;

         double sl = m_symbol_info.Bid() + ExtStopLoss;
         double tp = 0.0;

         double check_open_short_lot = m_money.CheckOpenShort(m_symbol_info.Bid(), sl);
         Print("sl=", DoubleToString(sl, m_symbol_info.Digits()),
               ", CheckOpenLong: ", DoubleToString(check_open_short_lot, 2),
               ", Balance: ", DoubleToString(account_info.Balance(), 2),
               ", Equity: ", DoubleToString(account_info.Equity(), 2),
               ", FreeMargin: ", DoubleToString(account_info.FreeMargin(), 2));
         if (check_open_short_lot == 0.0)
            return;

         //--- check volume before OrderSend to avoid "not enough money" error (CTrade)
         double chek_volime_lot = trade.CheckVolume(m_symbol_info.Name(), check_open_short_lot, m_symbol_info.Bid(), ORDER_TYPE_SELL);

         if (chek_volime_lot != 0.0)
            if (chek_volime_lot >= check_open_short_lot)
            {
               if (trade.Sell(check_open_short_lot, NULL, m_symbol_info.Bid(),
                              m_symbol_info.NormalizePrice(sl), tp,"SellNew"))
               {
                  if (trade.ResultDeal() == 0)
                  {
                     Print("Sell -> false. Result Retcode: ", trade.ResultRetcode(),
                           ", description of result: ", trade.ResultRetcodeDescription());
                  }
                  else
                     Print("Sell -> true. Result Retcode: ", trade.ResultRetcode(),
                           ", description of result: ", trade.ResultRetcodeDescription());
               }
               else
               {
                  Print("Sell -> false. Result Retcode: ", trade.ResultRetcode(),
                        ", description of result: ", trade.ResultRetcodeDescription());
               }
            }
         return;
      }
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetMarginMode(void)
{
   m_margin_mode = (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsHedging(void)
{
   return (m_margin_mode == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
}
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool bbbbbRefreshRates()
{
   //--- refresh rates
   if (!m_symbol_info.RefreshRates())
      return (false);
   //--- protection against the return value of "zero"
   if (m_symbol_info.Ask() == 0 || m_symbol_info.Bid() == 0)
      return (false);
   //---
   return (true);
}
//+------------------------------------------------------------------+
//| Get value of buffers for the iMA                                 |
//+------------------------------------------------------------------+
double iMAGet(int handle_iMA, const int index)
{
   double MA[1];
   //--- reset error code
   ResetLastError();
   //--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index
   if (CopyBuffer(handle_iMA, 0, index, 1, MA) < 0)
   {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iMA indicator, error code %d", GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return (0.0);
   }
   return (MA[0]);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iHighest(string symbol,
                ENUM_TIMEFRAMES timeframe,
                int type,
                int count = WHOLE_ARRAY,
                int start = 0)
{
   if (start < 0)
      return (-1);
   if (count <= 0)
      count = Bars(symbol, timeframe);
   if (type == MODE_HIGH)
   {
      double High[];
      ArraySetAsSeries(High, true);
      CopyHigh(symbol, timeframe, start, count, High);
      return (High[ArrayMaximum(High, 0, count)]);
   }
   //---
   return (0.0);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iLowest(string symbol,
               ENUM_TIMEFRAMES timeframe,
               int type,
               int count = WHOLE_ARRAY,
               int start = 0)
{
   if (start < 0)
      return (-1);
   if (count <= 0)
      count = Bars(symbol, timeframe);
   if (type == MODE_LOW)
   {
      double Low[];
      ArraySetAsSeries(Low, true);
      CopyLow(symbol, timeframe, start, count, Low);
      return (Low[ArrayMinimum(Low, 0, count)]);
   }
   //---
   return (0.0);
}
