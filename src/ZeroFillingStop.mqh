//+------------------------------------------------------------------+
//|                                              ZeroFillingStop.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
void  zeroFillingStop()
  {
//---- Verificação da quantidade de barras para a suficiência para cálculo
   if(Bars(Symbol(),PERIOD_CURRENT)<min_rates_total) return;

//---- Declaração de variáveis locais
   double ;
//---- Declaração e reinicialização de variáveis de sinais de trailing stop  
   bool BUY_tral=false;
   bool SELL_tral=false;
   double NewStop=0.0;
//---- Inicialização de sinais de trailing stop e colocação da posição em break-even
   if(PositionSelect(Symbol())) //Verificação da presença de uma posição aberta
     {
      ENUM_POSITION_TYPE PosType=ENUM_POSITION_TYPE(PositionGetInteger(POSITION_TYPE));

      if(PosType==POSITION_TYPE_SELL)
        {
         double LastStop=PositionGetDouble(POSITION_SL);
         double Bid=SymbolInfoDouble(Symbol(),SYMBOL_BID);
         double point=SymbolInfoDouble(Symbol(),SYMBOL_POINT);
         if(!Bid || !point) return; //sem dados para cálculo adicional
         double OpenPrice=PositionGetDouble(POSITION_PRICE_OPEN);
         int point_profit=int((OpenPrice-Bid)/point);

         //---- Obtenção de sinais para mover o stop loss do short para break-even
         if(LastStop>OpenPrice && point_profit>int(InpOnTrailingStop))
           {
            NewStop=OpenPrice;
            SELL_tral=true;
           }
        }

      if(PosType==POSITION_TYPE_BUY)
        {
         double LastStop=PositionGetDouble(POSITION_SL);
         double Ask=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         double point=SymbolInfoDouble(Symbol(),SYMBOL_POINT);
         if(!Ask || !point) return;  //sem dados para cálculo adicional
         double OpenPrice=PositionGetDouble(POSITION_PRICE_OPEN);
         int point_profit=int((Ask-OpenPrice)/point);

         //---- Obtenção de sinais para mover o stop loss do long para break-even
         if(LastStop<OpenPrice && point_profit>int(InpOnTrailingStop))
           {
            NewStop=OpenPrice;
            BUY_tral=true;
           }
        }
     }
//+----------------------------------------------+
//| Execução de operações                        |
//+----------------------------------------------+
//---- Modificamos o long
   dBuyPositionModify(BUY_tral,Symbol(),Deviation_,NewStop,0.0);

//---- Modificamos o short
   dSellPositionModify(SELL_tral,Symbol(),Deviation_,NewStop,0.0);
//----
  }
