//+------------------------------------------------------------------+
//|                                                  UseTrailing.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
int up[], dn[]; // arrays for storing statistics
int buy_sl, buy_tp, sell_sl, sell_tp;
double pointvalue; // point price
double SLBuy = 0, SLSell = 0, SLNeutral = 0;
//------------------------------------------>

double
dbTickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE),   // Tick size
dbTickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE), // Tick value
dbPointSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT),            // Point size
dbPointValue = dbTickValue * dbPointSize / dbTickSize;            // Point value
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double preco_ativo = PositionGetDouble(POSITION_PRICE_CURRENT);
double preco_abertura = PositionGetDouble(POSITION_PRICE_OPEN);
double preco_stoploss = PositionGetDouble(POSITION_SL);
double preco_takeprofit = PositionGetDouble(POSITION_TP);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NormalizeStop(double price)
  {
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   return NormalizeDouble(price, digits);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void UseTrailing()
  {
   if(hasOpenPositionWith(simbolo, "buyCinq"))
    {
        //Print(__FUNCTION__, " <--> Não Aplicavél ", InpMagic);
        return;
    }
    if(hasOpenPositionWith(simbolo, "sellCinq"))
    {
       // Print(__FUNCTION__, " <--> Não Aplicavél ", InpMagic);
        return;
    }

   if(NewBarTS() == true)  // gather statistics and launch trailing stop
     {

      double open = iOpen(_Symbol, timeframe, 1);
      CalcLvl(up, (int)MathRound((iHigh(_Symbol, timeframe, 1) - open) / _Point));
      CalcLvl(dn, (int)MathRound((open - iLow(_Symbol, timeframe, 1)) / _Point));
      buy_sl = CalcSL(dn);
      buy_tp = CalcTP(up);
      sell_sl = CalcSL(up);
      sell_tp = CalcTP(dn);

      if(TypeTS == Simple)  // simple trailing stop
         SimpleTS();

      if(TypeTS == MoralExp)  // Moral expectation
         METS();
     }

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(bid == SLNeutral || bid <= SLBuy || (SLSell > 0 && bid >= SLSell))
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket) == true)
         Print("<----->"__FUNCTION__"Existe um Trade aqui");
            trade.PositionClose(ticket);
        }
     }
//---
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AllTS()
  {
//---
   double lot_buy = 0, lot_sell = 0, ask_opt = 0, bid_opt = 0, spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
   SLNeutral = 0;
   SLBuy = 0;
   SLSell = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) == true)
        {
         double swap = PositionGetDouble(POSITION_SWAP) - PositionGetDouble(POSITION_COMMISSION),
                lot = PositionGetDouble(POSITION_VOLUME);

         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
           {
            double price = PositionGetDouble(POSITION_PRICE_OPEN) - swap / (lot * pointvalue);
            lot_buy = lot_buy + lot;
            ask_opt = ask_opt + (price + spread) * lot;
            bid_opt = bid_opt + price * lot;
           }
         else
           {
            double price = PositionGetDouble(POSITION_PRICE_OPEN) + swap / (lot * pointvalue);
            lot_sell = lot_sell + lot;
            ask_opt = ask_opt + price * lot;
            bid_opt = bid_opt + (price - spread) * lot;
           }
        }
     }

   if(lot_buy > 0 || lot_sell > 0)  // there are open positions
     {
      ask_opt = ask_opt / (lot_buy + lot_sell);
      bid_opt = bid_opt / (lot_buy + lot_sell);

      bid_opt = NormalizeDouble((ask_opt + bid_opt - spread) / 2, _Digits);

      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      if(lot_buy == lot_sell)
         SLNeutral = bid_opt;

      if(lot_buy > lot_sell)
        {
         double min_sl = NormalizeDouble(bid_opt + m_slippage * _Point, _Digits),
                new_sl = NormalizeDouble(bid - buy_sl * _Point, _Digits);

         if(SLBuy == 0 && new_sl >= min_sl)
            SLBuy = min_sl;

         if(SLBuy > 0 && new_sl > SLBuy)
            SLBuy = new_sl;
        }

      if(lot_buy < lot_sell)
        {
         double min_sl = NormalizeDouble(bid_opt - m_slippage * _Point, _Digits),
                new_sl = NormalizeDouble(bid + sell_sl * _Point, _Digits);

         if(SLSell == 0 && new_sl <= min_sl)
            SLSell = min_sl;

         if(SLSell > 0 && new_sl < SLSell)
            SLSell = new_sl;
        }
     }
//-----
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void METS()
  {
//---
   int arrup[], sizeup = ArrayCopy(arrup, up);
   int arrdn[], sizedn = ArrayCopy(arrdn, dn);
   int stoplvl = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double freezelvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point, mintp = stoplvl * _Point;

   for(int i = sizeup - 2; i >= 0; i--)
      arrup[i] = arrup[i] + arrup[i + 1];

   for(int i = sizedn - 2; i >= 0; i--)
      arrdn[i] = arrdn[i] + arrdn[i + 1];

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) == true)
        {
         double lot = PositionGetDouble(POSITION_VOLUME) * pointvalue,
                profitpoint = (PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) - PositionGetDouble(POSITION_COMMISSION)) / lot;

         int indx = (int)MathFloor(profitpoint);

         if(indx > stoplvl)
           {
            bool modify = false;
            int _sl = 0, _tp = 0;
            double open = PositionGetDouble(POSITION_PRICE_OPEN),
                   price = PositionGetDouble(POSITION_PRICE_CURRENT),
                   sl = PositionGetDouble(POSITION_SL),
                   tp = PositionGetDouble(POSITION_TP),
                   mr = -DBL_MAX;

            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
              {
               indx = MathMin(indx, sizedn - 1);
               for(int i = stoplvl; i < sizeup; i++)
                  for(int j = stoplvl; j <= indx; j++)
                    {
                     double prob = arrup[i] * (arrdn[0] - arrdn[j]);
                     prob = prob / (prob + arrdn[j] * (arrup[0] - arrup[i]));
                     double curmr = MathPow(profitpoint + i, prob) * MathPow(profitpoint - j, 1 - prob) - profitpoint;
                     if(curmr > profitpoint && curmr > mr)
                       {
                        mr = curmr;
                        _tp = i;
                        _sl = j;
                       }
                    }

               if(mr > 0 && profitpoint > _sl + m_slippage)
                 {
                  double new_sl = NormalizeDouble(price - _sl * _Point, _Digits);

                  if(sl == 0)
                     sl = open;

                  if(price - sl > freezelvl && new_sl > sl)
                    {
                     modify = true;
                     sl = new_sl;
                    }

                  if(UseTakeProfit == true && sl > open)
                    {
                     double new_tp = NormalizeDouble(price + _tp * _Point, _Digits);

                     if(tp == 0)
                        tp = NormalizeDouble(price + mintp, _Digits);

                     if(tp - price > freezelvl && new_tp > tp)
                       {
                        modify = true;
                        tp = new_tp;
                       }
                    }
                 }
              }
            else
              {
               indx = MathMin(indx, sizeup - 1);
               for(int i = stoplvl; i < sizedn; i++)
                  for(int j = stoplvl; j <= indx; j++)
                    {
                     double prob = arrdn[i] * (arrup[0] - arrup[j]);
                     prob = prob / (prob + arrup[j] * (arrdn[0] - arrdn[i]));
                     double curmr = MathPow(profitpoint + i, prob) * MathPow(profitpoint - j, 1 - prob) - profitpoint;
                     if(curmr > profitpoint && curmr > mr)
                       {
                        mr = curmr;
                        _tp = i;
                        _sl = j;
                       }
                    }

               if(mr > 0 && profitpoint > _sl + m_slippage)
                 {
                  double new_sl = NormalizeDouble(price + _sl * _Point, _Digits);

                  if(sl == 0)
                     sl = open;

                  if(sl - price > freezelvl && new_sl < sl)
                    {
                     modify = true;
                     sl = new_sl;
                    }

                  if(UseTakeProfit == true && sl < open)
                    {
                     double new_tp = NormalizeDouble(price - _tp * _Point, _Digits);

                     if(tp == 0)
                        tp = NormalizeDouble(price - mintp, _Digits);

                     if(price - tp > freezelvl && new_tp < tp)
                       {
                        modify = true;
                        tp = new_tp;
                       }
                    }
                 }
              }
            Print("<----->"__FUNCTION__"Existe um Trade aqui");
            if(modify == true && trade.PositionModify(ticket, sl, tp) == false)
               Print("Modification error ", GetLastError());
           }
        }
     }
//---
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SimpleTS()
  {
  if(hasOpenPositionWith(simbolo,"buyCinq"))
     {
      return;
     }
//---
   double freezelvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point,
          mintp = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) == true)
        {
         bool modify = false;
         double open = PositionGetDouble(POSITION_PRICE_OPEN),
                price = PositionGetDouble(POSITION_PRICE_CURRENT),
                sl = PositionGetDouble(POSITION_SL),
                tp = PositionGetDouble(POSITION_TP),
                swap = PositionGetDouble(POSITION_SWAP) - PositionGetDouble(POSITION_COMMISSION),
                lot = PositionGetDouble(POSITION_VOLUME) * pointvalue;

         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
           {
            double min_sl = NormalizeDouble(open - MathFloor(swap / lot + m_slippage) * _Point, _Digits),
                   new_sl = NormalizeDouble(price - buy_sl * _Point, _Digits);

            if(sl == 0)
               sl = min_sl;

            sl = MathMax(sl, min_sl);

            if(price - sl > freezelvl && new_sl > sl)
              {
               modify = true;
               sl = new_sl;
              }

            if(UseTakeProfit == true && sl > min_sl)  // take profit can be modified
              {
               double new_tp = NormalizeDouble(price + buy_tp * _Point, _Digits);

               if(tp == 0)
                  tp = NormalizeDouble(price + mintp, _Digits);

               if(tp - price > freezelvl && new_tp > tp)
                 {
                  modify = true;
                  tp = new_tp;
                 }
              }
           }
         else
           {
            double min_sl = NormalizeDouble(open + MathCeil(swap / lot - m_slippage) * _Point, _Digits),
                   new_sl = NormalizeDouble(price + sell_sl * _Point, _Digits);

            if(sl == 0)
               sl = min_sl;

            sl = MathMin(sl, min_sl);

            if(sl - price > freezelvl && new_sl < sl)
              {
               modify = true;
               sl = new_sl;
              }

            if(UseTakeProfit == true && sl < min_sl)
              {
               double new_tp = NormalizeDouble(price - sell_tp * _Point, _Digits);

               if(tp == 0)
                  tp = NormalizeDouble(price - mintp, _Digits);

               if(price - tp > freezelvl && new_tp < tp)
                 {
                  modify = true;
                  tp = new_tp;
                 }
              }
           }

         if(modify == true && trade.PositionModify(ticket, sl, tp) == false)
            Print("Modification error ", GetLastError());
        }
     }
//---
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalcLvl(int &array[], int value)
  {
//---
   int s = ArraySize(array);
   if(s > value)
      array[value]++;
   else
     {
      int a[];
      ArrayResize(a, value + 1);
      ArrayInitialize(a, 0);
      for(int i = 0; i < s; i++)
         a[i] = array[i];
      a[value] = value;
      ArrayCopy(array, a);
     }
//---
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CalcSL(int &array[])
  {
//---
   int a[], s = ArrayCopy(a, array), sl = 0;
   ulong max = 0;

   for(int i = s - 2; i >= 0; i--)
      a[i] = a[i] + a[i + 1];

   for(int i = 0; i < s; i++)
     {
      ulong res = (s - i) * (a[0] - a[i]);
      if(max < res)
        {
         max = res;
         sl = i;
        }
     }
   return ((int)MathMax(sl, SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL)));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CalcTP(int &array[])
  {
//---
   int a[], s = ArrayCopy(a, array), tp = 0;
   ulong max = 0;

   for(int i = s - 2; i >= 0; i--)
      a[i] = a[i] + a[i + 1];

   for(int i = 0; i < s; i++)
     {
      ulong res = i * a[i];
      if(max < res)
        {
         max = res;
         tp = i;
        }
     }
   return ((int)MathMax(tp, SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL)));
//---
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NewBarTS()
  {
// Variável estática para armazenar o timestamp da última barra verificada
   static long lastbar;

// Obtém o timestamp da última barra
   long curbar = SeriesInfoInteger(_Symbol, timeframe, SERIES_LASTBAR_DATE);

// Verifica se a barra atual é mais recente que a última barra registrada
   if(lastbar < curbar)
     {
      // Atualiza lastbar para o timestamp da barra atual
      lastbar = curbar;
      // Retorna true indicando que uma nova barra apareceu
      return (true);
     }
// Retorna false indicando que nenhuma nova barra apareceu
   return (false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NewBar()
  {
//---
   static long lastbar;
   long curbar = SeriesInfoInteger(_Symbol, PERIOD_CURRENT, SERIES_LASTBAR_DATE);

   if(lastbar < curbar)
     {
      lastbar = curbar;
      return (true);
     }
   return (false);
//---
  }
//+------------------------------------------------------------------+
