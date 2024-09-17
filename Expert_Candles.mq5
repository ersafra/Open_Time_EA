//+------------------------------------------------------------------+
//|                                               Expert_Candles.mq5 |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
#include <Expert\Signal\SignalCandles.mqh>
#include <Expert\Trailing\TrailingNone.mqh>
#include <Expert\Money\MoneyFixedLot.mqh>
#include <Expert\Signal\Signal2EMA-ITF.mqh>


//+------------------------------------------------------------------+
//| Arquivos de Classe MQH                                           |
//+------------------------------------------------------------------+
#include "src\\Inputs.mqh";


//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CExpert ExtExpert;
CExpert ExtExpert2;
//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Initializing expert
   if(!ExtExpert.Init(Symbol(),Period(),Expert_EveryTick,Expert_MagicNumber))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing expert");
      ExtExpert.Deinit();
      return(-1);
     }
//--- Creation of signal object
   CSignalCandles *signal=new CSignalCandles;
   if(signal==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating signal");
      ExtExpert.Deinit();
      return(-2);
     }
//--- Add signal to expert (will be deleted automatically))
   if(!ExtExpert.InitSignal(signal))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing signal");
      ExtExpert.Deinit();
      return(-3);
     }
//--- Set signal parameters
   signal.Range(Inp_Signal_Candles_Range);
   signal.Minimum(Inp_Signal_Candles_Minimum);
   signal.ShadowBig(Inp_Signal_Candles_ShadowBig);
   signal.ShadowSmall(Inp_Signal_Candles_ShadowSmall);
   signal.Limit(Inp_Signal_Candles_Limit);
   signal.StopLoss(Inp_Signal_Candles_StopLoss);
   signal.TakeProfit(Inp_Signal_Candles_TakeProfit);
   signal.Expiration(Inp_Signal_Candles_Expiration);
//--- Check signal parameters
   if(!signal.ValidationSettings())
     {
      //--- failed
      printf(__FUNCTION__+": error signal parameters");
      ExtExpert.Deinit();
      return(-4);
     }
//--- Creation of trailing object
   CTrailingNone *trailing=new CTrailingNone;
   if(trailing==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating trailing");
      ExtExpert.Deinit();
      return(-5);
     }
//--- Add trailing to expert (will be deleted automatically))
   if(!ExtExpert.InitTrailing(trailing))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing trailing");
      ExtExpert.Deinit();
      return(-6);
     }
//--- Set trailing parameters
//--- Check trailing parameters
   if(!trailing.ValidationSettings())
     {
      //--- failed
      printf(__FUNCTION__+": error trailing parameters");
      ExtExpert.Deinit();
      return(-7);
     }
//--- Creation of money object
   CMoneyFixedLot *money=new CMoneyFixedLot;
   if(money==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating money");
      ExtExpert.Deinit();
      return(-8);
     }
//--- Add money to expert (will be deleted automatically))
   if(!ExtExpert.InitMoney(money))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing money");
      ExtExpert.Deinit();
      return(-9);
     }
//--- Set money parameters
   money.Percent(Inp_Money_FixLot_Percent);
   money.Lots(Inp_Money_FixLot_Lots);
//--- Check money parameters
   if(!money.ValidationSettings())
     {
      //--- failed
      printf(__FUNCTION__+": error money parameters");
      ExtExpert.Deinit();
      return(-10);
     }
//--- Tuning of all necessary indicators
   if(!ExtExpert.InitIndicators())
     {
      //--- failed
      printf(__FUNCTION__+": error initializing indicators");
      ExtExpert.Deinit();
      return(-11);
     }
//--- ok do primeiro robo 

//-->inicio do segundo robo usando coisas do primeiro

//--- Initializing expert
   if(!ExtExpert2.Init(Symbol(),Period(),Expert_EveryTick,Expert_MagicNumber2))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing expert");
      ExtExpert2.Deinit();
      return(-1);
     }
//--- Creation of signal object
   CSignal2EMA_ITF *signal2=new CSignal2EMA_ITF;
   if(signal2==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating signal");
      ExtExpert2.Deinit();
      return(-2);
     }
//--- Add signal to expert (will be deleted automatically))
   if(!ExtExpert2.InitSignal(signal2))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing signal");
      ExtExpert2.Deinit();
      return(-3);
     }
//--- Set signal parameters
   signal2.PeriodFastEMA(Inp_Signal_TwoEMAwithITF_PeriodFastEMA);
   signal2.PeriodSlowEMA(Inp_Signal_TwoEMAwithITF_PeriodSlowEMA);
   signal2.PeriodATR(Inp_Signal_TwoEMAwithITF_PeriodATR);
   signal2.Limit(Inp_Signal_TwoEMAwithITF_Limit);
   signal2.StopLoss(Inp_Signal_TwoEMAwithITF_StopLoss);
   signal2.TakeProfit(Inp_Signal_TwoEMAwithITF_TakeProfit);
   signal2.Expiration(Inp_Signal_TwoEMAwithITF_Expiration);
   signal2.GoodMinuteOfHour(Inp_Signal_TwoEMAwithITF_GoodMinuteOfHour);
   signal2.BadMinutesOfHour(Inp_Signal_TwoEMAwithITF_BadMinutesOfHour);
   signal2.GoodHourOfDay(Inp_Signal_TwoEMAwithITF_GoodHourOfDay);
   signal2.BadHoursOfDay(Inp_Signal_TwoEMAwithITF_BadHoursOfDay);
   signal2.GoodDayOfWeek(Inp_Signal_TwoEMAwithITF_GoodDayOfWeek);
   signal2.BadDaysOfWeek(Inp_Signal_TwoEMAwithITF_BadDaysOfWeek);
//--- Check signal parameters
   if(!signal2.ValidationSettings())
     {
      //--- failed
      printf(__FUNCTION__+": error signal parameters");
      ExtExpert2.Deinit();
      return(-4);
     }
//--- Creation of trailing object
//>   CTrailingNone *trailing=new CTrailingNone;
//>   if(trailing==NULL)
//>     {
      //--- failed
 //     printf(__FUNCTION__+": error creating trailing");
  //    ExtExpert.Deinit();
 //     return(-5);
 //    }
//--- Add trailing to expert (will be deleted automatically))
 //  if(!ExtExpert.InitTrailing(trailing))
  //   {
      //--- failed
  //    printf(__FUNCTION__+": error initializing trailing");
  //    ExtExpert.Deinit();
 //     return(-6);
  //   }
//--- Set trailing parameters
//--- Check trailing parameters
   //if(!trailing.ValidationSettings())
  //   {
      //--- failed
 //     printf(__FUNCTION__+": error trailing parameters");
 //     ExtExpert.Deinit();
 //     return(-7);
 //    }
//--- Creation of money object
 //  CMoneyFixedLot *money=new CMoneyFixedLot;
//   if(money==NULL)
 //    {
      //--- failed
 //     printf(__FUNCTION__+": error creating money");
//      ExtExpert.Deinit();
 //     return(-8);
 //    }
//--- Add money to expert (will be deleted automatically))
  // if(!ExtExpert.InitMoney(money))
 //    {
      //--- failed
  //    printf(__FUNCTION__+": error initializing money");
  //    ExtExpert.Deinit();
 //     return(-9);
  //   }
//--- Set money parameters
 //  money.Percent(Inp_Money_FixLot_Percent);
 //  money.Lots(Inp_Money_FixLot_Lots);
//--- Check money parameters
//   if(!money.ValidationSettings())
 //    {
      //--- failed
 //     printf(__FUNCTION__+": error money parameters");
 //     ExtExpert.Deinit();
 //     return(-10);
 //    }
//--- Tuning of all necessary indicators
//   if(!ExtExpert.InitIndicators())
 //    {
      //--- failed
  //    printf(__FUNCTION__+": error initializing indicators");
  //    ExtExpert.Deinit();
  //    return(-11);
    // }
//--- ok

//-----sempre daqui para cima
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ExtExpert.Deinit();
     ExtExpert2.Deinit();
  }
//+------------------------------------------------------------------+
//| Function-event handler "tick"                                    |
//+------------------------------------------------------------------+
void OnTick()
  {
   ExtExpert.OnTick();
   ExtExpert2.OnTick();
  }
//+------------------------------------------------------------------+
//| Function-event handler "trade"                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
   ExtExpert.OnTrade();
   ExtExpert2.OnTrade();
  }
//+------------------------------------------------------------------+
//| Function-event handler "timer"                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   ExtExpert.OnTimer();
   ExtExpert2.OnTimer();
  }
//+------------------------------------------------------------------+