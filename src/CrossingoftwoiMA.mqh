//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

//---
int   ExtHandle=0;
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double tradeSizeOptimized(void)
  {
   double price=0.0;
   double margin=0.0;
//--- select lot size
   if(!SymbolInfoDouble(_Symbol,SYMBOL_ASK,price))
      return(0.0);
   if(!OrderCalcMargin(ORDER_TYPE_BUY,_Symbol,1.0,price,margin))
      return(0.0);
   if(margin<=0.0)
      return(0.0);

   double lot=NormalizeDouble(AccountInfoDouble(ACCOUNT_FREEMARGIN)*MaximumRisk/margin,2);
//--- calculate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      //--- select history for access
      HistorySelect(0,TimeCurrent());
      //---
      int    orders=HistoryDealsTotal();  // total history deals
      int    losses=0;                    // number of losses orders without a break

      for(int i=orders-1;i>=0;i--)
        {
         ulong ticket=HistoryDealGetTicket(i);
         if(ticket==0)
           {
            Print("HistoryDealGetTicket failed, no m_trade history");
            break;
           }
         //--- check symbol
         if(HistoryDealGetString(ticket,DEAL_SYMBOL)!=_Symbol)
            continue;
         //--- check profit
         double profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
         if(profit>0.0)
            break;
         if(profit<0.0)
            losses++;
        }
      //---
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//--- normalize and check limits
   double stepvol=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   lot=stepvol*NormalizeDouble(lot/stepvol,0);

   double minvol=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   if(lot<minvol)
      lot=minvol;

   double maxvol=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   if(lot>maxvol)
      lot=maxvol;
//--- return trading volume
   return(lot);
  }
//+------------------------------------------------------------------+
//| Check for open position conditions                               |
//+------------------------------------------------------------------+
void CheckForOpen(void)
  {
   MqlRates rt[2];
//--- go trading only for first ticks of new bar
   if(CopyRates(_Symbol,_Period,0,2,rt)!=2)
     {
      Print("CopyRates of ",_Symbol," failed, no history");
      return;
     }
   if(rt[1].tick_volume>1)
      return;
//--- get current Moving Average
   double   ma[1];
   if(CopyBuffer(ExtHandle,0,0,1,ma)!=1)
     {
      Print("CopyBuffer from iMA failed, no data");
      return;
     }
//--- check signals
   ENUM_ORDER_TYPE signal=WRONG_VALUE;
   string BuySell ;

   if(rt[0].open>ma[0] && rt[0].close<ma[0])
      {signal=ORDER_TYPE_SELL;    // sell conditions
      BuySell = "crpSell";}
   else
     {
      if(rt[0].open<ma[0] && rt[0].close>ma[0])
         signal=ORDER_TYPE_BUY;  // buy conditions
         BuySell = "crpBuy";
     }
//--- additional checking
   if(signal!=WRONG_VALUE)
      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
         if(Bars(_Symbol,_Period)>100)
           {
            datetime currentCandleTime = iTime(_Symbol, PERIOD_CURRENT, 0); // Obtém o tempo do candle atual

            // Verifica se o tempo do último candle é diferente do atual
            if(openTimeBuy != currentCandleTime)
              {
               trade.SetExpertMagicNumber(InpMagic);
               trade.PositionOpen(_Symbol,signal,(double)(m_symbol_info.LotsMin()*InpVolume),
                                    SymbolInfoDouble(_Symbol,signal==ORDER_TYPE_SELL ? SYMBOL_BID:SYMBOL_ASK),
                                    0,0,BuySell);
              }

           }
//---
  }
//+------------------------------------------------------------------+
//| Check for close position conditions                              |
//+------------------------------------------------------------------+
void CheckForClose(void)
  {
   MqlRates rt[2];
//--- go trading only for first ticks of new bar
   if(CopyRates(_Symbol,_Period,0,2,rt)!=2)
     {
      Print("CopyRates of ",_Symbol," failed, no history");
      return;
     }
   if(rt[1].tick_volume>1)
      return;
//--- get current Moving Average
   double   ma[1];
   if(CopyBuffer(ExtHandle,0,0,1,ma)!=1)
     {
      Print("CopyBuffer from iMA failed, no data");
      return;
     }
//--- positions already selected before
   bool signal=false;
   long type=PositionGetInteger(POSITION_TYPE);

   if(type==(long)POSITION_TYPE_BUY   && rt[0].open>ma[0] && rt[0].close<ma[0])
      signal=true;
   if(type==(long)POSITION_TYPE_SELL  && rt[0].open<ma[0] && rt[0].close>ma[0])
      signal=true;
//--- additional checking
   if(signal)
      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
         if(Bars(_Symbol,_Period)>100)
           {
            trade.PositionClose(_Symbol,3);
           }
//---
  }
//+------------------------------------------------------------------+
void buyCrz496()
  {
   if(hasOpenPositionWith(simbolo,"buyCrz496"))
     {
      return;
     }

   static datetime PrevBars=0;
   datetime time_0=iTime(m_symbol_info.Name(),Period(),0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
   RefreshRates();

//--- We look for crossing of two indicators
   double   Fast[];
   double   Low[];

   ArraySetAsSeries(Fast,true);    // index [0] - the most right bar on a charts
   ArraySetAsSeries(Low,true);     // index [0] - the most right bar on a charts

   int      buffer_num=0;           // indicator buffer number
   int      start_pos=0;            // start position
   int      count=3;                // amount to copy

   if(!iMAGet(Media4,buffer_num,start_pos,count,Fast))
      return;
   if(!iMAGet(Media96,buffer_num,start_pos,count,Low))
      return;
//-------------------Compra
   if(Fast[0]>Low[0] && Fast[1]<Low[1]) // buy
     {
      if(!RefreshRates())
        {
         PrevBars=iTime(m_symbol_info.Name(),Period(),1);
         return;
        }
      double sl=(InpStopLoss==0)?0.0:m_symbol_info.Ask()-ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:m_symbol_info.Ask()+ExtTakeProfit;
      OpenBuy(0,0,"buyCrz496");
      return;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sellCrz496()
  {
   if(hasOpenPositionWith(simbolo,"sellCrz496"))
     {
      return;
     }
   static datetime PrevBars=0;
   datetime time_0=iTime(m_symbol_info.Name(),Period(),0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
   RefreshRates();
//--- We look for crossing of two indicators
   double   Fast[];
   double   Low[];

   ArraySetAsSeries(Fast,true);    // index [0] - the most right bar on a charts
   ArraySetAsSeries(Low,true);   // index [0] - the most right bar on a charts

   int      buffer_num=0;           // indicator buffer number
   int      start_pos=0;            // start position
   int      count=3;                // amount to copy

   if(!iMAGet(Media4,buffer_num,start_pos,count,Fast))
      return;
   if(!iMAGet(Media96,buffer_num,start_pos,count,Low))
      return;
//-------------------Venda
   if(Fast[0]<Low[0] && Fast[1]>Low[1]) // sell
     {
      if(!RefreshRates())
        {
         PrevBars=iTime(m_symbol_info.Name(),Period(),1);
         return;
        }
      double sl=(InpStopLoss==0)?0.0:m_symbol_info.Bid()+ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:m_symbol_info.Bid()-ExtTakeProfit;
      OpenSell(0,0,"sellCrz496");
      return;
     }

  }
//+------------------------------------------------------------------+
//|   Cruzamento 50/200                                              |
//+------------------------------------------------------------------+
void buyCrz50200()
  {
   if(hasOpenPositionWith(simbolo,"buyCrz50200"))
     {
      return;
     }
   static datetime PrevBars=0;
   datetime time_0=iTime(m_symbol_info.Name(),Period(),0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
   RefreshRates();

//--- We look for crossing of two indicators
   double   Cinquenta[];
   double   Duzentos[];
//  double   Filter[];
   ArraySetAsSeries(Cinquenta,true);    // index [0] - the most right bar on a charts
   ArraySetAsSeries(Duzentos,true);   // index [0] - the most right bar on a charts

   int      buffer_num=0;           // indicator buffer number
   int      start_pos=0;            // start position
   int      count=3;                // amount to copy

   if(!iMAGet(Media50,buffer_num,start_pos,count,Cinquenta))
      return;
   if(!iMAGet(Media200,buffer_num,start_pos,count,Duzentos))
      return;
//-------------------Compra
   if(Cinquenta[0]>Duzentos[0] && Cinquenta[1]<Duzentos[1]) // buy
     {
      if(hasOpenPositionWith(simbolo,"buyCrz50200"))
        {
         return;
        }
      if(!RefreshRates())
        {
         PrevBars=iTime(m_symbol_info.Name(),Period(),1);
         return;
        }
      double sl=(InpStopLoss==0)?0.0:m_symbol_info.Ask()-ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:m_symbol_info.Ask()+ExtTakeProfit;
      OpenBuy(0,0,"buyCrz50200");
      return;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sellCinq()
  {
   if(hasOpenPositionWith(simbolo,"sellCrz50200"))
     {
      return;
     }
   static datetime PrevBars=0;
   datetime time_0=iTime(m_symbol_info.Name(),Period(),0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
   RefreshRates();

//--- We look for crossing of two indicators
   double   Cinquenta[];
   double   Duzentos[];
//  double   Filter[];
   ArraySetAsSeries(Cinquenta,true);    // index [0] - the most right bar on a charts
   ArraySetAsSeries(Duzentos,true);   // index [0] - the most right bar on a charts

   int      buffer_num=0;           // indicator buffer number
   int      start_pos=0;            // start position
   int      count=3;                // amount to copy

   if(!iMAGet(Media50,buffer_num,start_pos,count,Cinquenta))
      return;
   if(!iMAGet(Media200,buffer_num,start_pos,count,Duzentos))
      return;
//-------------------Venda
   if(Cinquenta[0]<Duzentos[0] && Cinquenta[1]>Duzentos[1]) // sell
     {
      if(hasOpenPositionWith(simbolo,"sellCrz50200"))
        {
         return;
        }
      if(!RefreshRates())
        {
         PrevBars=iTime(m_symbol_info.Name(),Period(),1);
         return;
        }
      double sl=(InpStopLoss==0)?0.0:m_symbol_info.Bid()+ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:m_symbol_info.Bid()-ExtTakeProfit;

      OpenSell(0,0,"sellCrz50200");
      return;
     }
  }
//+------------------------------------------------------------------+
