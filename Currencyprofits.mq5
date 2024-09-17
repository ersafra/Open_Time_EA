//+------------------------------------------------------------------+
//|                Currencyprofits_01.1(barabashkakvn's edition).mq5 |
//+------------------------------------------------------------------+
#property version   "1.001"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
#include <Expert\Money\MoneyFixedMargin.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
CMoneyFixedMargin m_money;
//---
#define MODE_LOW 1
#define MODE_HIGH 2
//--- input parameters
input int                  InpStopLoss          = 170;            // StopLoss
input ulong                m_magic              = 7815935;        // magic number
input ulong                m_slippage           = 30;             // slippage
input int                  PercentRisk          = 14;             // % risk from Free Margin
sinput string              FirstMA              = "Parameters first indicator";
input ENUM_TIMEFRAMES      period_first         = PERIOD_CURRENT; // period first MA
input int                  ma_period_first      = 32;             // averaging period first MA
input int                  ma_shift_first       = 0;              // horizontal shift first MA
input ENUM_MA_METHOD       ma_method_first      = MODE_SMA;       // smoothing type first MA
input ENUM_APPLIED_PRICE   applied_price_first  = PRICE_CLOSE;    // type of price or handle first MA
sinput string              SecondtMA            = "Parameters second indicator";
input ENUM_TIMEFRAMES      period_second        = PERIOD_CURRENT; // period second MA
input int                  ma_period_second     = 86;             // averaging period second MA
input int                  ma_shift_second      = 0;              // horizontal shift second MA
input ENUM_MA_METHOD       ma_method_second     = MODE_SMA;       // smoothing type second MA
input ENUM_APPLIED_PRICE   applied_price_second = PRICE_CLOSE;    // type of price or handle second MA
//---
ENUM_ACCOUNT_MARGIN_MODE m_margin_mode;
double         m_adjusted_point;             // point value adjusted for 3 or 5 points
double         ExtStopLoss=0.0;
int            handle_iMA_first;             // variable for storing the handle of the iMA indicator
int            handle_iMA_second;            // variable for storing the handle of the iMA indicator
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetMarginMode();
   if(!IsHedging())
     {
      Print("Hedging only!");
      return(INIT_FAILED);
     }
   if(ma_period_first==ma_period_second)
     {
      Print("Parameters incorrect. averaging period first MA == averaging period second MA!");
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   m_symbol.Name(Symbol());                  // sets symbol name
   if(!RefreshRates())
     {
      Print("Error RefreshRates. Bid=",DoubleToString(m_symbol.Bid(),Digits()),
            ", Ask=",DoubleToString(m_symbol.Ask(),Digits()));
      return(INIT_FAILED);
     }
   m_symbol.Refresh();
//---
   m_trade.SetExpertMagicNumber(m_magic);
//---
   m_trade.SetDeviationInPoints(m_slippage);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;
   ExtStopLoss     =InpStopLoss*m_adjusted_point;
//---
   if(!m_money.Init(GetPointer(m_symbol),Period(),m_symbol.Point()*digits_adjust))
      return(INIT_FAILED);
   m_money.Percent(PercentRisk); // 10% risk
//--- create handle of the indicator iMA
   handle_iMA_first=iMA(m_symbol.Name(),period_first,ma_period_first,ma_shift_first,ma_method_first,applied_price_first);
//--- if the handle is not created
   if(handle_iMA_first==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA_second=iMA(m_symbol.Name(),period_second,ma_period_second,ma_shift_second,ma_method_second,applied_price_second);
//--- if the handle is not created
   if(handle_iMA_second==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int total=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            total++;

            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(m_position.PriceCurrent()>=iHighest(m_symbol.Name(),Period(),MODE_HIGH,6,1))
                 {
                  m_trade.PositionClose(m_position.Ticket());
                  return;
                 }
              }

            if(m_position.PositionType()==POSITION_TYPE_SELL)
              {
               if(m_position.PriceCurrent()<=iLowest(m_symbol.Name(),Period(),MODE_LOW,6,1))
                 {
                  m_trade.PositionClose(m_position.Ticket());
                  return;
                 }
              }
           }

   if(total==0)
     {
      //--- Buy
      if(iMAGet(handle_iMA_first,1)>iMAGet(handle_iMA_second,1) &&
         m_symbol.Bid()<=iLowest(m_symbol.Name(),Period(),MODE_LOW,6,1))
        {
         if(!RefreshRates())
            return;

         double sl=m_symbol.Ask()-ExtStopLoss;
         double tp=0.0;

         double check_open_long_lot=m_money.CheckOpenLong(m_symbol.Ask(),sl);
         Print("sl=",DoubleToString(sl,m_symbol.Digits()),
               ", CheckOpenLong: ",DoubleToString(check_open_long_lot,2),
               ", Balance: ",    DoubleToString(m_account.Balance(),2),
               ", Equity: ",     DoubleToString(m_account.Equity(),2),
               ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
         if(check_open_long_lot==0.0)
            return;

         //--- check volume before OrderSend to avoid "not enough money" error (CTrade)
         double chek_volime_lot=m_trade.CheckVolume(m_symbol.Name(),check_open_long_lot,m_symbol.Ask(),ORDER_TYPE_BUY);

         if(chek_volime_lot!=0.0)
            if(chek_volime_lot>=check_open_long_lot)
              {
               if(m_trade.Buy(check_open_long_lot,NULL,m_symbol.Ask(),
                  m_symbol.NormalizePrice(sl),tp))
                 {
                  if(m_trade.ResultDeal()==0)
                    {
                     Print("Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                           ", description of result: ",m_trade.ResultRetcodeDescription());
                    }
                  else
                     Print("Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                           ", description of result: ",m_trade.ResultRetcodeDescription());
                 }
               else
                 {
                  Print("Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                        ", description of result: ",m_trade.ResultRetcodeDescription());
                 }
              }
         return;
        }
      //--- Sell
      if(iMAGet(handle_iMA_first,1)<iMAGet(handle_iMA_second,1) &&
         m_symbol.Bid()>=iHighest(m_symbol.Name(),Period(),MODE_HIGH,6,1))
        {
         if(!RefreshRates())
            return;

         double sl=m_symbol.Bid()+ExtStopLoss;
         double tp=0.0;

         double check_open_short_lot=m_money.CheckOpenShort(m_symbol.Bid(),sl);
         Print("sl=",DoubleToString(sl,m_symbol.Digits()),
               ", CheckOpenLong: ",DoubleToString(check_open_short_lot,2),
               ", Balance: ",    DoubleToString(m_account.Balance(),2),
               ", Equity: ",     DoubleToString(m_account.Equity(),2),
               ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
         if(check_open_short_lot==0.0)
            return;

         //--- check volume before OrderSend to avoid "not enough money" error (CTrade)
         double chek_volime_lot=m_trade.CheckVolume(m_symbol.Name(),check_open_short_lot,m_symbol.Bid(),ORDER_TYPE_SELL);

         if(chek_volime_lot!=0.0)
            if(chek_volime_lot>=check_open_short_lot)
              {
               if(m_trade.Sell(check_open_short_lot,NULL,m_symbol.Bid(),
                  m_symbol.NormalizePrice(sl),tp))
                 {
                  if(m_trade.ResultDeal()==0)
                    {
                     Print("Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                           ", description of result: ",m_trade.ResultRetcodeDescription());
                    }
                  else
                     Print("Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                           ", description of result: ",m_trade.ResultRetcodeDescription());
                 }
               else
                 {
                  Print("Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                        ", description of result: ",m_trade.ResultRetcodeDescription());
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
   m_margin_mode=(ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsHedging(void)
  {
   return(m_margin_mode==ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates()
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
      return(false);
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iMA                                 |
//+------------------------------------------------------------------+
double iMAGet(int handle_iMA,const int index)
  {
   double MA[1];
//--- reset error code
   ResetLastError();
//--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index
   if(CopyBuffer(handle_iMA,0,index,1,MA)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(0.0);
     }
   return(MA[0]);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iHighest(string symbol,
                ENUM_TIMEFRAMES timeframe,
                int type,
                int count=WHOLE_ARRAY,
                int start=0)
  {
   if(start<0)
      return(-1);
   if(count<=0)
      count=Bars(symbol,timeframe);
   if(type==MODE_HIGH)
     {
      double High[];
      ArraySetAsSeries(High,true);
      CopyHigh(symbol,timeframe,start,count,High);
      return(High[ArrayMaximum(High,0,count)]);
     }
//---
   return(0.0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iLowest(string symbol,
               ENUM_TIMEFRAMES timeframe,
               int type,
               int count=WHOLE_ARRAY,
               int start=0)
  {
   if(start<0)
      return(-1);
   if(count<=0)
      count=Bars(symbol,timeframe);
   if(type==MODE_LOW)
     {
      double Low[];
      ArraySetAsSeries(Low,true);
      CopyLow(symbol,timeframe,start,count,Low);
      return(Low[ArrayMinimum(Low,0,count)]);
     }
//---
   return(0.0);
  }
//+------------------------------------------------------------------+