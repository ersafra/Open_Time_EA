//+------------------------------------------------------------------+
//|                          GreenTrade(barabashkakvn's edition).mq5 |
//|                                   Copyright © 2017, Kozak Andrey |
//|                                                   kozaka@ukr.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2017, Kozak Andrey"
#property link "kozaka@ukr.net"
#property version "1.001"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
// CPositionInfo  m_position;                   // trade position object
// CTrade         m_trade;                      // trading object
// CSymbolInfo    m_symbol;                     // symbol info object
// CAccountInfo   m_account;                    // account info wrapper
//--- input parameters
input int MA_period = 9;            // MA: averaging period
input uchar InpShiftBar = 1;         // Index of the bar #0
input uchar InpShiftBar_1 = 2;       // Index of the bar #1 (shift from bar #0)
input uchar InpShiftBar_2 = 3;       // Index of the bar #2 (shift from bar #1)
input uchar InpShiftBar_3 = 4;       // Index of the bar #3 (shift from bar #2)
input int RSI_period = 21;           // RSI: averaging period
input double InpRSI_Buy_level = 30;  // RSI buy level
input double InpRSI_Sell_level = 70; // RSI sell level
// input double   InpLots           = 0.1;      // Lots
// input ushort   InpStopLoss       = 300;      // Stop Loss (in pips)
// input ushort   InpTakeProfit     = 300;      // Take Profit (in pips)
// input ushort   InpTrailingStop   = 12;       // Trailing Stop (in pips)
// input ushort   InpTrailingStep   = 5;        // Trailing Step (in pips)
input uchar InpMaxPosition = 7; // Max position
// input ulong    m_magic           = 364008764;// magic number
//---
// ulong          m_slippage=10;                // slippage

// double         ExtStopLoss=0;
// double         ExtTakeProfit=0;
// double         ExtTrailingStop=0;
// double         ExtTrailingStep=0;

int handle_iMA;  // variable for storing the handle of the iMA indicator
int handle_iRSI; // variable for storing the handle of the iRSI indicator
// double         m_adjusted_point;             // point value adjusted for 3 or 5 points

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void openGreenTrade()
{
   //--- trabalhamos apenas na hora do nascimento do novo bar

   //---
   double MA_shift_0 = iMAGet(InpShiftBar);
   double MA_shift_1 = iMAGet(InpShiftBar + InpShiftBar_1);
   double MA_shift_2 = iMAGet(InpShiftBar + InpShiftBar_1 + InpShiftBar_2);
   double MA_shift_3 = iMAGet(InpShiftBar + InpShiftBar_1 + InpShiftBar_2 + InpShiftBar_3);
   double RSI = iRSIGet(InpShiftBar);

   if (CalculateAllPositions() >= InpMaxPosition)
      return;

   if (MA_shift_0 > MA_shift_1 && MA_shift_1 > MA_shift_2 && MA_shift_2 > MA_shift_3 &&
       iOpen(InpShiftBar)<MA_shift_0 && iClose(InpShiftBar)>MA_shift_0 &&  RSI > InpRSI_Buy_level)
   {
      Print(__FUNCTION__ " Condição de Compra");
      double sl = 0.0;
      if (InpStopLoss != 0)
         sl = m_symbol_info.Ask() - ExtStopLoss;
      double tp = 0.0;
      if (InpTakeProfit != 0)
         tp = m_symbol_info.Ask() + ExtTakeProfit;
      OpenBuy(sl, tp,"GreenBuy2");
   }

   if (MA_shift_0 < MA_shift_1 && MA_shift_1 < MA_shift_2 && MA_shift_2 < MA_shift_3 &&
       iOpen(InpShiftBar)>MA_shift_0 && iClose(InpShiftBar)<MA_shift_0 &&  RSI < InpRSI_Sell_level)
   {
      Print(__FUNCTION__ "Condição de Venda");
      double sl = 0.0;
      if (InpStopLoss != 0)
         sl = m_symbol_info.Bid() + ExtStopLoss;
      double tp = 0.0;
      if (InpTakeProfit != 0)
         tp = m_symbol_info.Bid() - ExtTakeProfit;
      OpenSell(sl, tp,"GreenSell2");
   }
   //---
   return;
}

//+------------------------------------------------------------------+
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
bool GreenCheckVolumeValue(double volume, string &error_description)
{
   //--- minimal allowed volume for trade operations
   // double min_volume=m_symbol.LotsMin();
   double min_volume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   if (volume < min_volume)
   {
      error_description = StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f", min_volume);
      return (false);
   }

   //--- maximal allowed volume of trade operations
   // double max_volume=m_symbol.LotsMax();
   double max_volume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   if (volume > max_volume)
   {
      error_description = StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f", max_volume);
      return (false);
   }

   //--- get minimal step of volume changing
   // double volume_step=m_symbol.LotsStep();
   double volume_step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);

   int ratio = (int)MathRound(volume / volume_step);
   if (MathAbs(ratio * volume_step - volume) > 0.0000001)
   {
      error_description = StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                                       volume_step, ratio * volume_step);
      return (false);
   }
   error_description = "Correct volume value";
   return (true);
}
//+------------------------------------------------------------------+
//| Checks if the specified filling mode is allowed                  |
//+------------------------------------------------------------------+
bool GreenIsFillingTypeAllowed(int fill_type)
{
   //--- Obtain the value of the property that describes allowed filling modes
   int filling = m_symbol_info.TradeFillFlags();
   //--- Return true, if mode fill_type is allowed
   return ((filling & fill_type) == fill_type);
}
//+------------------------------------------------------------------+
//| Get Open for specified bar index                                 |
//+------------------------------------------------------------------+
double iOpen(const int index, string symbol = NULL, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT)
{
   if (symbol == NULL)
      symbol = m_symbol_info.Name();
   if (timeframe == 0)
      timeframe = Period();
   double Open[1];
   double open = 0;
   int copied = CopyOpen(symbol, timeframe, index, 1, Open);
   if (copied > 0)
      open = Open[0];
   return (open);
}
//+------------------------------------------------------------------+
//| Get Close for specified bar index                                |
//+------------------------------------------------------------------+
double iClose(const int index, string symbol = NULL, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT)
{
   if (symbol == NULL)
      symbol = m_symbol_info.Name();
   if (timeframe == 0)
      timeframe = Period();
   double Close[1];
   double close = 0;
   int copied = CopyClose(symbol, timeframe, index, 1, Close);
   if (copied > 0)
      close = Close[0];
   return (close);
}

//+------------------------------------------------------------------+
//| Get value of buffers for the iMA                                 |
//+------------------------------------------------------------------+
double iMAGet(const int index)
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
//| Get value of buffers for the iRSI                                |
//+------------------------------------------------------------------+
double iRSIGet(const int index)
{
   double RSI[1];
   //--- reset error code
   ResetLastError();
   //--- fill a part of the iRSI array with values from the indicator buffer that has 0 index
   if (CopyBuffer(handle_iRSI, 0, index, 1, RSI) < 0)
   {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iRSI indicator, error code %d", GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return (0.0);
   }
   return (RSI[0]);
}
//+------------------------------------------------------------------+
//| Calculate all positions                                          |
//+------------------------------------------------------------------+
int GreenCalculateAllPositions()
{
   int total = 0;

   for (int i = PositionsTotal() - 1; i >= 0; i--)
      if (m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if (m_position.Symbol() == m_symbol_info.Name() && m_position.Magic() == InpMagic)
            total++;
   //---
   return (total);
}

//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResult(CTrade &trade, CSymbolInfo &symbol)
{
   Print("Código do resultado da solicitação: " + IntegerToString(trade.ResultRetcode()));
   Print("Descrição do código do resultado da solicitação: " + trade.ResultRetcodeDescription());
   Print("Ticket da negociação: " + IntegerToString(trade.ResultDeal()));
   Print("Ticket da ordem: " + IntegerToString(trade.ResultOrder()));
   Print("Volume da negociação ou ordem: " + DoubleToString(trade.ResultVolume(), 2));
   Print("Preço confirmado pelo corretor: " + DoubleToString(trade.ResultPrice(), symbol.Digits()));
   Print("Preço atual de venda (Bid): " + DoubleToString(trade.ResultBid(), symbol.Digits()));
   Print("Preço atual de compra (Ask): " + DoubleToString(trade.ResultAsk(), symbol.Digits()));
   Print("Comentário do corretor: " + trade.ResultComment());

   // DebugBreak();
}
//+------------------------------------------------------------------+
//| Trailing                                                         |
//+------------------------------------------------------------------+
void GreenTrailing()
{
   if (ExtTrailingStop == 0)
      return;
   for (int i = PositionsTotal() - 1; i >= 0; i--) // returns the number of open positions
      if (m_position.SelectByIndex(i))
         if (m_position.Symbol() == m_symbol_info.Name() && m_position.Magic() == InpMagic)
         {
            if (m_position.PositionType() == POSITION_TYPE_BUY)
            {
               if (m_position.PriceCurrent() - m_position.PriceOpen() > ExtTrailingStop + ExtTrailingStep)
                  if (m_position.StopLoss() < m_position.PriceCurrent() - (ExtTrailingStop + ExtTrailingStep))
                  {
                     if (!trade.PositionModify(m_position.Ticket(),
                                               m_symbol_info.NormalizePrice(m_position.PriceCurrent() - ExtTrailingStop),
                                               m_position.TakeProfit()))
                        Print("Modify ", m_position.Ticket(),
                              " Position -> false. Result Retcode: ", trade.ResultRetcode(),
                              ", description of result: ", trade.ResultRetcodeDescription());
                     continue;
                  }
            }
            else
            {
               if (m_position.PriceOpen() - m_position.PriceCurrent() > ExtTrailingStop + ExtTrailingStep)
                  if ((m_position.StopLoss() > (m_position.PriceCurrent() + (ExtTrailingStop + ExtTrailingStep))) ||
                      (m_position.StopLoss() == 0))
                  {
                     if (!trade.PositionModify(m_position.Ticket(),
                                               m_symbol_info.NormalizePrice(m_position.PriceCurrent() + ExtTrailingStop),
                                               m_position.TakeProfit()))
                        Print("Modify ", m_position.Ticket(),
                              " Position -> false. Result Retcode: ", trade.ResultRetcode(),
                              ", description of result: ", trade.ResultRetcodeDescription());
                     return;
                  }
            }
         }
}
//+------------------------------------------------------------------+