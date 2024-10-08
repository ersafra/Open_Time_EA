//+------------------------------------------------------------------+
//|                                                     OpenTime.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                   OpenTime 2.mq5 |
//|                              Copyright © 2018, Vladimir Karputov |
//|                                           http://wmua.ru/slesar/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018, Vladimir Karputov"
#property link      "http://wmua.ru/slesar/"
#property version   "2.007"

//----OpenTime
#define m_magic_one m_magic
#define m_magic_two m_magic_one+1
//----OPenTime

double ExtStopLossOne   =0.0;
double ExtTakeProfitOne =0.0;
double ExtStopLossTwo   =0.0;
double ExtTakeProfitTwo =0.0;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OpenTime()
  {
//---
   MqlDateTime STimeCurrent;
   TimeToStruct(TimeCurrent(),STimeCurrent);
   int time_current=STimeCurrent.hour*3600+STimeCurrent.min*60+STimeCurrent.sec;
   if(!Monday && STimeCurrent.day_of_week==1)
      return;
   if(!Tuesday && STimeCurrent.day_of_week==2)
      return;
   if(!Wednesday && STimeCurrent.day_of_week==3)
      return;
   if(!Thursday && STimeCurrent.day_of_week==4)
      return;
   if(!Friday && STimeCurrent.day_of_week==5)
      return;
//---
   MqlDateTime SOpenStartOne;
   TimeToStruct(OpenStartOne,SOpenStartOne);
   int open_start_one=SOpenStartOne.hour*3600+SOpenStartOne.min*60;

   MqlDateTime SOpenEndOne;
   TimeToStruct(OpenEndOne,SOpenEndOne);
   int open_end_one=SOpenEndOne.hour*3600+SOpenEndOne.min*60;

   MqlDateTime SOpenStartTwo;
   TimeToStruct(OpenStartTwo,SOpenStartTwo);
   int open_start_two=SOpenStartTwo.hour*3600+SOpenStartTwo.min*60;

   MqlDateTime SOpenEndTwo;
   TimeToStruct(OpenEndTwo,SOpenEndTwo);
   int open_end_two=SOpenEndTwo.hour*3600+SOpenEndTwo.min*60;

//--- abertura no intervalo de tempo #1 ou intervalo de tempo #2

   if((time_current>=open_start_one && time_current<open_end_one+Duration) ||
      (time_current>=open_start_two && time_current<open_end_two+Duration))
     {
      //  CalculatePositions(count_buys_one,count_sells_one,count_buys_two,count_sells_two);
      if(!RefreshRates())
         return;
      //--- opening on time interval #1
      if(time_current>=open_start_one && time_current<open_end_one+Duration)
        {
         CheckForOpen();
         OpenCandleBuySell();
         Print("Operação realizada com sucesso #1!");
        }
      else
        {
         Print("Operação não realizada. Fora do horário permitido #1.");
        }
     }
   if(time_current>=open_start_two && time_current<open_end_two+Duration)
     {
      CheckForOpen();
      OpenCandleBuySell();
      Print("Operação realizada com sucesso #2!");
     }
   else
     {
      Print("Operação não realizada. Fora do horário permitido.#2");
     }
  }//fim

//+------------------------------------------------------------------+
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume,string &error_description)
  {
//--- minimal allowed volume for trade operations
// double min_volume=m_symbol_info.LotsMin();
   double min_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   if(volume<min_volume)
     {
      error_description=StringFormat("O volume é menor que o mínimo permitido SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }

//--- maximal allowed volume of trade operations
// double max_volume=m_symbol_info.LotsMax();
   double max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   if(volume>max_volume)
     {
      error_description=StringFormat("O volume é maior que o máximo permitido SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }

//--- get minimal step of volume changing
// double volume_step=m_symbol_info.LotsStep();
   double volume_step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);

   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      error_description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                                     volume_step,ratio*volume_step);
      return(false);
     }
   error_description="Correct volume value";
   return(true);
  }
//+------------------------------------------------------------------+
//| Verifica se o modo de preenchimento especificado é permitido     |
//+------------------------------------------------------------------+
bool IsFillingTypeAllowed(int fill_type)
  {
//--- Obtenha o valor da propriedade que descreve os modos de preenchimento permitidos
   int filling=m_symbol_info.TradeFillFlags();
//--- Retorna verdadeiro, se o modo fill_type for permitido
   return((filling & fill_type)==fill_type);
  }
//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions(const ulong magic)
  {
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol_info.Name() && m_position.Magic()==magic)
            trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol
  }


//+------------------------------------------------------------------+
//| Calculate positions Buy and Sell                                 |
//+------------------------------------------------------------------+
void CalculatePositions(int &count_buys_one,int &count_sells_one,int &count_buys_two,int &count_sells_two)
  {
   count_buys_one=0;
   count_sells_one=0;
   count_buys_two=0;
   count_sells_two=0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // seleciona a posição por índice para posterior acesso às suas propriedades
         if(m_position.Symbol()==m_symbol_info.Name())
           {
            if(m_position.Magic()==InpMagic)
              {
               if(m_position.PositionType()==POSITION_TYPE_BUY)
                  count_buys_one++;
               if(m_position.PositionType()==POSITION_TYPE_SELL)
                  count_sells_one++;
              }
            else
               if(m_position.Magic()==InpMagic)
                 {
                  if(m_position.PositionType()==POSITION_TYPE_BUY)
                     count_buys_two++;
                  if(m_position.PositionType()==POSITION_TYPE_SELL)
                     count_sells_two++;
                 }
           }
//---
   return;
  }

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsOpenTime()
  {
   MqlDateTime STimeCurrent;
   TimeToStruct(TimeCurrent(), STimeCurrent);
   int time_current = STimeCurrent.hour * 3600 + STimeCurrent.min * 60 + STimeCurrent.sec;

   if(!Monday &&    STimeCurrent.day_of_week == 1)
      return false;
   if(!Tuesday &&   STimeCurrent.day_of_week == 2)
      return false;
   if(!Wednesday && STimeCurrent.day_of_week == 3)
      return false;
   if(!Thursday &&  STimeCurrent.day_of_week == 4)
      return false;
   if(!Friday &&   STimeCurrent.day_of_week == 5)
      return false;

   MqlDateTime SOpenStartOne;
   TimeToStruct(OpenStartOne, SOpenStartOne);
   int open_start_one = SOpenStartOne.hour * 3600 + SOpenStartOne.min * 60;

   MqlDateTime SOpenEndOne;
   TimeToStruct(OpenEndOne, SOpenEndOne);
   int open_end_one = SOpenEndOne.hour * 3600 + SOpenEndOne.min * 60;

   MqlDateTime SOpenStartTwo;
   TimeToStruct(OpenStartTwo, SOpenStartTwo);
   int open_start_two = SOpenStartTwo.hour * 3600 + SOpenStartTwo.min * 60;

   MqlDateTime SOpenEndTwo;
   TimeToStruct(OpenEndTwo, SOpenEndTwo);
   int open_end_two = SOpenEndTwo.hour * 3600 + SOpenEndTwo.min * 60;

// Verifica se a operação pode ser realizada no intervalo de tempo #1 ou #2
   bool within_time_interval_one = (time_current >= open_start_one && time_current < open_end_one + Duration);
   bool within_time_interval_two = (time_current >= open_start_two && time_current < open_end_two + Duration);

   if(within_time_interval_one || within_time_interval_two)
     {
      if(!RefreshRates())
         return false;

      if(within_time_interval_one)
        {
         Print(__FUNCTION__" Operação realizada com sucesso #1! ",ts," Local ",tm);
         return true;
        }
      else
        {
         Print(__FUNCTION__" Operação não realizada. Fora do horário permitido #1 Current. ",ts," Local ",tm);
         return false;
        }

      if(within_time_interval_two)
        {
         Print(__FUNCTION__" Operação realizada com sucesso #2! ",ts," Local ",tm);
         return true;
        }
      else
        {
         Print(__FUNCTION__" Operação não realizada. Fora do horário permitido #2 Current. ",ts," Local ",tm);
         return false;
        }
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsOpenTimeBard()
  {
   MqlDateTime STimeCurrent;
   TimeToStruct(TimeCurrent(), STimeCurrent);
   int time_current = STimeCurrent.hour * 3600 + STimeCurrent.min * 60 + STimeCurrent.sec;

// Check if the current day is within the allowed trading days
   if(!Monday    && STimeCurrent.day_of_week == 1 ||
      !Tuesday   && STimeCurrent.day_of_week == 2 ||
      !Wednesday && STimeCurrent.day_of_week == 3 ||
      !Thursday  && STimeCurrent.day_of_week == 4 ||
      !Friday    && STimeCurrent.day_of_week == 5)
     {
      return false;
     }

// Calculate the start and end times for both time intervals
   MqlDateTime SOpenStartOne, SOpenEndOne, SOpenStartTwo, SOpenEndTwo;
   TimeToStruct(OpenStartOne, SOpenStartOne);
   TimeToStruct(OpenEndOne, SOpenEndOne);
   TimeToStruct(OpenStartTwo, SOpenStartTwo);
   TimeToStruct(OpenEndTwo, SOpenEndTwo);

   int open_start_one = SOpenStartOne.hour * 3600 + SOpenStartOne.min * 60;
   int open_end_one = SOpenEndOne.hour * 3600 + SOpenEndOne.min * 60;
   int open_start_two = SOpenStartTwo.hour * 3600 + SOpenStartTwo.min * 60;
   int open_end_two = SOpenEndTwo.hour * 3600 + SOpenEndTwo.min * 60;

// Check if the current time is within either time interval
   bool within_time_interval_one = (time_current >= open_start_one && time_current < open_end_one + Duration);
   bool within_time_interval_two = (time_current >= open_start_two && time_current < open_end_two + Duration);

   if(within_time_interval_one || within_time_interval_two)
     {
      if(!RefreshRates())
        {
         return false;
        }

      if(within_time_interval_one)
        {
         return true;
        }
      else
         if(within_time_interval_two)
           {
            return true;
           }
     }
   return false;
  }


//+------------------------------------------------------------------+
// Função auxiliar para configurar os horários de abertura e fechamento
bool ConfigureOpenCloseTimes()
  {
// Primeiro intervalo de abertura
   MqlDateTime SOpenStartOne;
   TimeToStruct(OpenStartOne, SOpenStartOne);
   int open_start_one = SOpenStartOne.hour * 3600 + SOpenStartOne.min * 60;

   MqlDateTime SOpenEndOne;
   TimeToStruct(OpenEndOne, SOpenEndOne);
   int open_end_one = SOpenEndOne.hour * 3600 + SOpenEndOne.min * 60;

   if(open_start_one >= open_end_one)
     {
      Print(__FUNCTION__, " erro: ",
            "\"Intervalo de tempo de início de abertura #1\" (", SOpenStartOne.hour, ":", SOpenStartOne.min, ") ",
            "não pode ser >= ",
            "\"Intervalo de tempo de fim de abertura #1\" (", SOpenEndOne.hour, ":", SOpenEndOne.min, ")");
      return false;
     }

// Fechamento no primeiro intervalo
   if(CloseStartOne)
     {
      MqlDateTime SCloseStartOne;
      TimeToStruct(CloseStartOne, SCloseStartOne);
      int close_start_one = SCloseStartOne.hour * 3600 + SCloseStartOne.min * 60;
      if(close_start_one >= open_start_one && close_start_one <= open_end_one)
        {
         Print(__FUNCTION__, " erro: ",
               "\"Intervalo de fechamento #1\" (", SCloseStartOne.hour, ":", SCloseStartOne.min, ") ",
               "não pode estar dentro do intervalo de tempo #1 ",
               "(", SOpenStartOne.hour, ":", SOpenStartOne.min, ") - (", SOpenEndOne.hour, ":", SOpenEndOne.min, ")");
         return false;
        }
     }

// Segundo intervalo de abertura
   MqlDateTime SOpenStartTwo;
   TimeToStruct(OpenStartTwo, SOpenStartTwo);
   int open_start_two = SOpenStartTwo.hour * 3600 + SOpenStartTwo.min * 60;

   MqlDateTime SOpenEndTwo;
   TimeToStruct(OpenEndTwo, SOpenEndTwo);
   int open_end_two = SOpenEndTwo.hour * 3600 + SOpenEndTwo.min * 60;

   if(open_start_two >= open_end_two)
     {
      Print(__FUNCTION__, " erro: ",
            "\"Intervalo de início de abertura #2\" (", SOpenStartTwo.hour, ":", SOpenStartTwo.min, ") ",
            "não pode ser >= ",
            "\"Intervalo de fim de abertura #2\" (", SOpenEndTwo.hour, ":", SOpenEndTwo.min, ")");
      return false;
     }

// Fechamento no segundo intervalo
   if(CloseStartTwo)
     {
      MqlDateTime SCloseStartTwo;
      TimeToStruct(CloseStartTwo, SCloseStartTwo);
      int close_start_two = SCloseStartTwo.hour * 3600 + SCloseStartTwo.min * 60;
      if(close_start_two >= open_start_two && close_start_two <= open_end_two)
        {
         Print(__FUNCTION__, " erro: ",
               "\"Intervalo de fechamento #2\" (", SCloseStartTwo.hour, ":", SCloseStartTwo.min, ") ",
               "não pode estar dentro do intervalo de tempo #2 ",
               "(", SOpenStartTwo.hour, ":", SOpenStartTwo.min, ") - (", SOpenEndTwo.hour, ":", SOpenEndTwo.min, ")");
         return false;
        }
     }

   return true;
  }
//+------------------------------------------------------------------+