//+------------------------------------------------------------------+
//|                                                    Breakeven.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


//--- input parameters
/*input*/ int Delta=100;
//---
bool     UseSound     = true;
bool     gbNoInit     = false;           // Флаг неудачной инициализации
string   SoundSuccess = "ok.wav";        // Звук успеха
string   SoundError   = "timeout.wav";   // Звук ошибки
int      NumberOfTry  = 3;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void breakEven()
  {
//---
   double M=0.0,MM=0.0,Prof=0.0,LL=0.0;
   int total=0;
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol_info.Name())
           {
            Prof+=m_position.Commission()+m_position.Swap()+m_position.Profit();
            total++;
            if(m_position.PositionType()==POSITION_TYPE_BUY)
               LL=LL+m_position.Volume();
            if(m_position.PositionType()==POSITION_TYPE_SELL)
               LL=LL-m_position.Volume();
           }
   if(total==0)
     {
      Comment("");
      return;
     }
   M=BEZ(); // Уровень безубытка для BUY
   if(!RefreshRates())
      return;
   /*Comment("Уровень безубытка ",M,"+",Delta,"\n",
           "Надо пройти  ",DoubleToString(MathAbs(M-m_symbol_info.Bid())/m_symbol_info.Point(),0)," points","\n",
           " Лот=",DoubleToString(LL,2)," лот","\n",
           "Общий профит  ",DoubleToString(Prof,2));*/
   Comment("Nível de break-even: ",M,"+",Delta,"\n",
           "Pontos a percorrer: ",DoubleToString(MathAbs(M-m_symbol_info.Bid())/m_symbol_info.Point(),0)," pontos","\n",
           " Lote: ",DoubleToString(LL,2)," lote","\n",
           "Lucro total: ",DoubleToString(Prof,2));

   if(LL<0) // Если больше SELL То безубыток - Delta ниже Bid и наоборот
     {
      MM=M-Delta*m_symbol_info.Point();  // Если больше SELL
      for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
         if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
            if(m_position.Symbol()==m_symbol_info.Name())
              {
               if(m_position.PositionType()==POSITION_TYPE_BUY && !CompareDoubles(m_position.TakeProfit(),MM,m_symbol_info.Digits()))
                  Modify(-1,MM,-1);
               if(m_position.PositionType()==POSITION_TYPE_SELL && !CompareDoubles(m_position.TakeProfit(),MM,m_symbol_info.Digits()))
                  Modify(-1,-1,MM);
              }
     }
   if(LL>0) // Если больше BUY То безубыток + Delta выше Bid
     {
      MM=M+Delta*m_symbol_info.Point();     // Если больше BUY
      for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
         if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
            if(m_position.Symbol()==m_symbol_info.Name())
              {
               if(m_position.PositionType()==POSITION_TYPE_BUY && !CompareDoubles(m_position.TakeProfit(),MM,m_symbol_info.Digits()))
                  Modify(-1,-1,MM);
               if(m_position.PositionType()==POSITION_TYPE_SELL && !CompareDoubles(m_position.TakeProfit(),MM,m_symbol_info.Digits()))
                  Modify(-1,MM,-1);
              }
     }
  }

//+------------------------------------------------------------------+
//| Функция подсчёта безубытка                                       |
//+------------------------------------------------------------------+
double BEZ()
  {
   double B2_B=0.0,B2_S=0.0,B2_LB=0.0,B2_LS=0.0,BSw=0.0,SSw=0.0;

   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol_info.Name())
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               B2_B=((B2_B*B2_LB)+(m_position.PriceOpen()*m_position.Volume()))/(B2_LB+m_position.Volume());
               B2_LB=B2_LB+m_position.Volume();
               BSw=+m_position.Commission()+m_position.Swap();
              }
            if(m_position.PositionType()==POSITION_TYPE_SELL)
              {
               B2_S=((B2_S*B2_LS)+(m_position.PriceOpen()*m_position.Volume()))/(B2_LS+m_position.Volume());
               B2_LS=B2_LS+m_position.Volume();
               SSw+=m_position.Commission()+m_position.Swap();
              }
           }

   double M2B=0.0,M2S=0.0,M=0.0;
   if(B2_LB>B2_LS) // Идём вверх
     {
      for(int J2=0;J2<10000;J2++)
        {
         M2B=J2*B2_LB*10;
         M2S=((B2_B-B2_S+0*m_symbol_info.Point())/m_symbol_info.Point()+J2)*(B2_LS*(-10));
         if(M2B+M2S+BSw+SSw>=0)
           {
            M=NormalizeDouble(B2_B+J2*m_symbol_info.Point(),m_symbol_info.Digits());
            break;
           }
        }
     }
   if(B2_LS>B2_LB) //  Идём вниз
     {
      for(int J3=0;J3<10000;J3++)
        {
         M2S=J3*B2_LS*10;
         M2B=((B2_B-B2_S+0*m_symbol_info.Point())/m_symbol_info.Point()+J3)*(B2_LB*(-10));
         if(M2S+M2B+BSw+SSw>=0)
           {
            M=NormalizeDouble(B2_S-J3*Point(),m_symbol_info.Digits());
            break;
           }
        }
     }
//---
   return(M);
  }
//+------------------------------------------------------------------+
//| Compare doubles                                                  |
//+------------------------------------------------------------------+
bool CompareDoubles(double number1,double number2,int digits)
  {
   digits--;
   if(digits<0)
      digits=0;
   if(NormalizeDouble(number1-number2,digits)==0)
      return(true);
   else
      return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Modify(double pp=-1,double sl=0,double tp=0)
  {
   double op=0.0,pa=0.0,pb=0.0,os=0.0,ot=0.0;

   if(pp<=0)
      pp=m_position.PriceOpen();
   if(sl<0)
      sl=m_position.StopLoss();
   if(tp<0)
      tp=m_position.TakeProfit();

   op=m_position.PriceOpen();
   os=m_position.StopLoss();
   ot=m_position.TakeProfit();

   if(!CompareDoubles(pp,op,m_symbol_info.Digits()) ||
      !CompareDoubles(sl,os,m_symbol_info.Digits()) ||
      !CompareDoubles(tp,ot,m_symbol_info.Digits()))
     {
      if(!trade.PositionModify(m_position.Ticket(),
                               m_symbol_info.NormalizePrice(sl),
                               m_symbol_info.NormalizePrice(tp)))
        {
         if(UseSound)
            PlaySound(SoundError);
         Sleep(1000*10);
        }
      else
        {
         if(UseSound)
            PlaySound(SoundSuccess);
        }
     }
  }
//+------------------------------------------------------------------+
void EvenBreakenV4()
  {
/*/---
   if((bool)MQLInfoInteger(MQL_TESTER))
      if(CalculateAllPositions()==0)
        {
         int rez=MathRand()/2;
         if(rez<32767/2)
            trade.Buy(m_symbol_info.LotsMin());
         else
            trade.Sell(m_symbol_info.LotsMin());
        }
//---*/
   static bool selector=false;
   selector=!selector;
   if(selector)
      return;
   else
      TrailingV4();
  }
//+------------------------------------------------------------------+
//| Trailing                                                         |
//+------------------------------------------------------------------+
void TrailingV4()
  {
   if(InpTrailingStop==0)
      return;
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol_info.Name() && m_position.Magic()==InpMagic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(m_position.PriceCurrent()-m_position.PriceOpen()>ExtTrailingStop+ExtTrailingStep)
                  if(m_position.StopLoss()<m_position.PriceCurrent()-(ExtTrailingStop+ExtTrailingStep))
                    {
                     if(!trade.PositionModify(m_position.Ticket(),
                                              m_symbol_info.NormalizePrice(m_position.PriceCurrent()-ExtTrailingStop),
                                              0))//m_position.TakeProfit()
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",trade.ResultRetcode(),
                              ", description of result: ",trade.ResultRetcodeDescription());
                     continue;
                    }
              }
            else
              {
               if(m_position.PriceOpen()-m_position.PriceCurrent()>ExtTrailingStop+ExtTrailingStep)
                  if((m_position.StopLoss()>(m_position.PriceCurrent()+(ExtTrailingStop+ExtTrailingStep))) ||
                     (m_position.StopLoss()==0))
                    {
                     if(!trade.PositionModify(m_position.Ticket(),
                                              m_symbol_info.NormalizePrice(m_position.PriceCurrent()+ExtTrailingStop),
                                              0))//m_position.TakeProfit()
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",trade.ResultRetcode(),
                              ", description of result: ",trade.ResultRetcodeDescription());
                    }
              }

           }
  }
//+------------------------------------------------------------------+
//| Calculate all positions                                          |
//+------------------------------------------------------------------+
int CalculateAllPositions()
  {
   int total=0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol_info.Name() && m_position.Magic()==InpMagic)
            total++;
//---
   return(total);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
