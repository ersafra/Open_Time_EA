//+------------------------------------------------------------------+
//|                     maximus_vX lite(barabashkakvn's edition).mq5 |
//|                                             Evgeny I. SHCHERBINA |
//+------------------------------------------------------------------+
#property copyright "Evgeny I. SHCHERBINA"
#property version   "1.002"
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
CMoneyFixedMargin *m_money;
//--- input parameters
input int               delay_open=2;                 // Trade once in "timeframe of checked elements"
input int               distance=850;                 // Minimum indent from to the consolidation line to open a position
input int               range=500;                    // History: range candle (High - Low)
input int               InpCountToCopy=1000;          // History: data count to copy
input int               InpCountMaxMin=40;            // History: number of checked elements for Max and Min
input ENUM_TIMEFRAMES   InpTimeFrame=PERIOD_M15;      // History: timeframe of checked elements
input double            Risk= 5;                      // Risk in percent for a deal from a free margin
input int               InpStopLoss=1000;             // Stop Loss
input double            InpMinProfit=1.0;             // Min profit (percent)
input ulong             m_magic=47978073;             // magic number
//---
ulong                   m_slippage=10;                // slippage
//---
double ExtDistance=0.0;
double ExtRange=0.0;
double ExtStopLoss=0.0;
double l_max=0,l_min=0,u_max=0,u_min=0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();
//---
   m_trade.SetExpertMagicNumber(m_magic);
//---
   if(IsFillingTypeAllowed(SYMBOL_FILLING_FOK))
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if(IsFillingTypeAllowed(SYMBOL_FILLING_IOC))
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
//---
   m_trade.SetDeviationInPoints(m_slippage);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
//---
   if(m_money!=NULL)
      delete m_money;
   m_money=new CMoneyFixedMargin;
   if(m_money!=NULL)
     {
      if(!m_money.Init(GetPointer(m_symbol),Period(),m_symbol.Point()*digits_adjust))
         return(INIT_FAILED);
      m_money.Percent(Risk);
     }
   else
     {
      Print(__FUNCTION__,", ERROR: Object CMoneyFixedMargin is NULL");
      return(INIT_FAILED);
     }
   ExtDistance=distance*m_symbol.Point();
   ExtRange=range*m_symbol.Point();
   ExtStopLoss=InpStopLoss*m_symbol.Point();
   l_max=0.0;l_min=0.0;u_max=0.0;u_min=0.0;
//---
   FindHighLow();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   if(m_money!=NULL)
      delete m_money;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
//---
   FindHighLow();
//---
   int count_buys=0;
   datetime time_buy=0;
   int count_sells=0;
   datetime time_sell=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               count_buys++;
               time_buy=m_position.Time();
              }

            if(m_position.PositionType()==POSITION_TYPE_SELL)
              {
               count_sells++;
               time_sell=m_position.Time();
              }
           }
   if(count_buys>1 || count_sells>1)
      return;
   if(!RefreshRates())
     {
      PrevBars=iTime(1);
      return;
     }
//--- check open buy
   if(count_buys==0 || (count_buys==1 && time_buy+delay_open*PeriodSeconds(InpTimeFrame)>TimeCurrent()))
     {
      if(l_max!=0.0 && u_min!=0.0 && m_symbol.Ask()-ExtDistance>l_max)
        {
         double sl=(InpStopLoss==0)?0.0:m_symbol.Ask()-ExtStopLoss;
         double temp_tp=(u_min-l_max)/3.0*2.0*m_symbol.Point();
         if(temp_tp<ExtRange)
            temp_tp=ExtRange;
         double tp=m_symbol.Ask()+temp_tp;
         OpenBuy(sl,tp);
        }
      if(u_max!=0 && m_symbol.Ask()-ExtDistance>u_max)
        {
         double sl=(InpStopLoss==0)?0.0:m_symbol.Ask()-ExtStopLoss;
         double tp=m_symbol.Ask()+2.0*ExtRange;
         OpenBuy(sl,tp);
        }
     }
//--- check open sell
   if(count_sells==0 || (count_sells==1 && time_sell+delay_open*PeriodSeconds(InpTimeFrame)>TimeCurrent()))
     {
      if(u_min!=0 && m_symbol.Bid()+ExtDistance<u_min)
        {
         double sl=(InpStopLoss==0)?0.0:m_symbol.Bid()+ExtStopLoss;
         double temp_tp=(u_min-l_max)/3.0*2.0*m_symbol.Point();
         if(temp_tp<ExtRange)
            temp_tp=ExtRange;
         double tp=m_symbol.Bid()-temp_tp;
         OpenSell(sl,tp);
        }
      if(l_min!=0 && m_symbol.Bid()+ExtDistance<l_min)
        {
         double sl=(InpStopLoss==0)?0.0:m_symbol.Bid()+ExtStopLoss;
         double tp=m_symbol.Bid()-2.0*ExtRange;
         OpenSell(sl,tp);
        }
     }
//---
   double balance=m_account.Balance();
   double equity=m_account.Equity();
   if((equity-balance)*100.0/balance>InpMinProfit)
      CloseAllPositions();
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
//---

  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates(void)
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
     {
      Print("RefreshRates error");
      return(false);
     }
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Checks if the specified filling mode is allowed                  |
//+------------------------------------------------------------------+
bool IsFillingTypeAllowed(int fill_type)
  {
//--- Obtain the value of the property that describes allowed filling modes
   int filling=m_symbol.TradeFillFlags();
//--- Return true, if mode fill_type is allowed
   return((filling & fill_type)==fill_type);
  }
//+------------------------------------------------------------------+
//| Get Time for specified bar index                                 |
//+------------------------------------------------------------------+
datetime iTime(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   datetime Time[1];
   datetime time=0; // D'1970.01.01 00:00:00'
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0)
      time=Time[0];
   return(time);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FindHighLow()
  {
   if(!RefreshRates())
      return;
   double High[];    // array for history data of highest bar prices
   double Low[];     // array for history data of minimal bar prices
   double Close[];   // array for history data of close bar prices
   if(ArrayResize(High,InpCountToCopy)==-1 || ArrayResize(Low,InpCountToCopy)==-1 || ArrayResize(Close,InpCountToCopy)==-1)
      return;
//--- ArraySetAsSeries(XXXX,true) -> bar#0 - the most right on the chart
   if(!ArraySetAsSeries(High,true) || !ArraySetAsSeries(Low,true) || !ArraySetAsSeries(Close,true))
      return;
   int copied=-1;
   copied=CopyHigh(m_symbol.Name(),InpTimeFrame,1,InpCountToCopy,High);
   if(copied==-1 || copied!=InpCountToCopy)
      return;
   copied=CopyLow(m_symbol.Name(),InpTimeFrame,1,InpCountToCopy,Low);
   if(copied==-1 || copied!=InpCountToCopy)
      return;
   copied=CopyClose(m_symbol.Name(),InpTimeFrame,1,InpCountToCopy,Close);
   if(copied==-1 || copied!=InpCountToCopy)
      return;
//---
   if(Close[0]-100*m_symbol.Point()>l_max || Close[0]+100*m_symbol.Point()<l_min ||
      Close[0]-100*m_symbol.Point()>u_max || Close[0]+100*m_symbol.Point()<u_min)
     {
      //--- drawing lines "high"
      double max=0.0,min=0.0;
      for(int i=0;i<InpCountToCopy;i++)
        {
         if(Close[0]-ExtRange>High[i])
           {
            max=High[ArrayMaximum(High,i,InpCountMaxMin)];
            min=Low[ArrayMinimum(Low,i,InpCountMaxMin)];
            if(max-min<=ExtRange && Close[0]+ExtRange>max && Close[0]+ExtRange>min)
              {
               u_max=max;
               u_min=min;
               MoveLine(u_max,"u_max",clrLimeGreen);
               MoveLine(u_min,"u_min",clrLimeGreen);
               break;
              }
            else
              {
               max=0.0;
               min=0.0;
              }
           }
        }
      if(max==0 && min==0)
        {
         max = MathFloor(Close[0]+100.0*m_symbol.Point())+range/2.0*m_symbol.Point();
         min = MathFloor(Close[0]+100.0*m_symbol.Point())-range/2.0*m_symbol.Point();
        }
      else
        {
         max = MathFloor((Close[0]+100.0*m_symbol.Point())*100.0)/100.0+range/2.0*m_symbol.Point();
         min = MathFloor((Close[0]+100.0*m_symbol.Point())*100.0)/100.0-range/2.0*m_symbol.Point();
        }
      u_max = max;
      u_min = min;
      MoveLine(u_max,"u_max",clrLimeGreen);
      MoveLine(u_min,"u_min",clrLimeGreen);
      //--- drawing lines "low"
      max=0.0;min=0.0;
      for(int i=0;i<InpCountToCopy;i++)
        {
         if(Close[0]-ExtRange>High[i])
           {
            max=High[ArrayMaximum(High,i,InpCountMaxMin)];
            min=Low[ArrayMinimum(Low,i,InpCountMaxMin)];
            if(max-min<=ExtRange && Close[0]-ExtRange>max && Close[0]-ExtRange>min)
              {
               l_max = max;
               l_min = min;
               MoveLine(l_max,"l_max",clrTomato);
               MoveLine(l_min,"l_min",clrTomato);
               break;
              }
            else
              {
               max=0.0;
               min=0.0;
              }
           }
        }
      if(max==0.0 && min==0.0)
        {
         max = MathFloor((Close[0]-100.0*m_symbol.Point())*100.0)/100.0+range/2.0*m_symbol.Point();
         min = MathFloor((Close[0]-100.0*m_symbol.Point())*100.0)/100.0-range/2.0*m_symbol.Point();
         l_max = max;
         l_min = min;
         MoveLine(l_max,"l_max",clrGreen);
         MoveLine(l_min,"l_min",clrGreen);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MoveLine(double price,string name,color clr)
  {
   if(ObjectFind(0,name)<0)
     {
      //--- reset the error value
      ResetLastError();
      //--- create a horizontal line
      if(!ObjectCreate(0,name,OBJ_HLINE,0,0,price))
        {
         Print(__FUNCTION__,
               ": failed to create a horizontal line! Error code = ",GetLastError());
         return;
        }
      //--- set line color
      ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
      //--- set line display style
      ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_DASHDOTDOT);
     }
//--- reset the error value
   ResetLastError();
//--- move a horizontal line
   if(!ObjectMove(0,name,0,0,price))
     {
      Print(__FUNCTION__,
            ": failed to move the horizontal line! Error code = ",GetLastError());
      return;
     }
   ChartRedraw();
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   double check_open_long_lot=m_money.CheckOpenLong(m_symbol.Ask(),sl);
   Print("sl=",DoubleToString(sl,m_symbol.Digits()),
         ", CheckOpenLong: ",DoubleToString(check_open_long_lot,2),
         ", Balance: ",    DoubleToString(m_account.Balance(),2),
         ", Equity: ",     DoubleToString(m_account.Equity(),2),
         ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
   if(check_open_long_lot==0.0)
     {
      Print(__FUNCTION__,", ERROR: method CheckOpenLong returned the value of \"0.0\"");
      return;
     }

//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),check_open_long_lot,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=check_open_long_lot)
        {
         if(m_trade.Buy(check_open_long_lot,NULL,m_symbol.Ask(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print("#1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
            else
              {
               Print("#2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
           }
         else
           {
            Print("#3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResult(m_trade,m_symbol);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< method CheckOpenLong (",DoubleToString(check_open_long_lot,2),")");
         return;
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
void OpenSell(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   double check_open_short_lot=m_money.CheckOpenShort(m_symbol.Bid(),sl);
   Print("sl=",DoubleToString(sl,m_symbol.Digits()),
         ", CheckOpenLong: ",DoubleToString(check_open_short_lot,2),
         ", Balance: ",    DoubleToString(m_account.Balance(),2),
         ", Equity: ",     DoubleToString(m_account.Equity(),2),
         ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
   if(check_open_short_lot==0.0)
     {
      Print(__FUNCTION__,", ERROR: method CheckOpenShort returned the value of \"0.0\"");
      return;
     }

//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),check_open_short_lot,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=check_open_short_lot)
        {
         if(m_trade.Sell(check_open_short_lot,NULL,m_symbol.Bid(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print("#1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
            else
              {
               Print("#2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
           }
         else
           {
            Print("#3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResult(m_trade,m_symbol);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< method CheckOpenShort (",DoubleToString(check_open_short_lot,2),")");
         return;
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResult(CTrade &trade,CSymbolInfo &symbol)
  {
   Print("Code of request result: "+IntegerToString(trade.ResultRetcode()));
   Print("code of request result: "+trade.ResultRetcodeDescription());
   Print("deal ticket: "+IntegerToString(trade.ResultDeal()));
   Print("order ticket: "+IntegerToString(trade.ResultOrder()));
   Print("volume of deal or order: "+DoubleToString(trade.ResultVolume(),2));
   Print("price, confirmed by broker: "+DoubleToString(trade.ResultPrice(),symbol.Digits()));
   Print("current bid price: "+DoubleToString(trade.ResultBid(),symbol.Digits()));
   Print("current ask price: "+DoubleToString(trade.ResultAsk(),symbol.Digits()));
   Print("broker comment: "+trade.ResultComment());
//DebugBreak();
  }
//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            m_trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol
  }
//+------------------------------------------------------------------+