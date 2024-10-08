//+------------------------------------------------------------------+
//|                                                 OpenPosition.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
void OpenCandleBuySell() //--- Abertura de posições com base nos sinais
  {
  int total = list_trade_patt.Total();
   if(total > 0)
     {
      for(int i = total - 1; i > WRONG_VALUE; i--)
        {
         ENUM_PATTERN_TYPE type = (ENUM_PATTERN_TYPE)list_trade_patt.At(i);
         if(type == NULL)
            continue;
         int res = Trade(type, i);
         //int res = 0; // usado para deslicar a função de compra e venda das velas
         if(res == WRONG_VALUE)
           {
            list_trade_patt.Clear();
            break;
           }
        }
     }
     }
//+------------------------------------------------------------------+
//| Открытие позиции                                                 |
//+------------------------------------------------------------------+
bool OpenPosition(const ENUM_PATTERN_TYPE &pattern_type)
  {
   string comment=patt.DescriptPattern(pattern_type);
   ENUM_POSITION_TYPE type=patt.PositionPattern(pattern_type);
   double sl=(InpStopLoss==0   ? 0 : CorrectStopLoss(symb,type,InpStopLoss));
   double tp=(InpTakeProfit==0 ? 0 : CorrectTakeProfit(symb,type,InpTakeProfit));
   double ll=trade.CheckVolume(symb,lot,(type==POSITION_TYPE_BUY ? SymbolInfoDouble(symb,SYMBOL_ASK) : SymbolInfoDouble(symb,SYMBOL_BID)),(ENUM_ORDER_TYPE)type);
   if(ll>0 && CheckLotForLimitAccount(type,ll))
     {
      trade.SetExpertMagicNumber(InpMagic);  // Можно сделать для каждого типа паттерна свой магик, но для этого нужен иной учёт позиций
      if(RefreshRates())
        {
         if(type==POSITION_TYPE_BUY  && openTimeBuy != iTime(_Symbol, PERIOD_CURRENT, 0))
           {
            openTimeBuy = iTime(_Symbol, PERIOD_CURRENT, 0);
            // trade.SetExpertMagicNumber(InpMagic);
            if(trade.Buy(ll,symb,m_symbol_info.Ask(),sl,tp,comment))
              {
               FillingListTickets();
               return true;
              }
           }
         if(type==POSITION_TYPE_SELL && openTimeSell != iTime(_Symbol, PERIOD_CURRENT, 0))
           {
            openTimeSell = iTime(_Symbol, PERIOD_CURRENT, 0);
            //  trade.SetExpertMagicNumber(InpMagic);
            if(trade.Sell(ll,symb,m_symbol_info.Bid(),sl,tp,comment))
              {
               FillingListTickets();
               return true;
              }
           }
        }
     }
   return false;
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void OpenBuy(double sl, double tp, string comment)
  {
   sl = m_symbol_info.NormalizePrice(sl);
   tp = m_symbol_info.NormalizePrice(tp);
// comment = m_position.Comment();

   double price = m_symbol_info.Ask();

   double check_open_long_lot = 0.0;
   if(InpMoneyManagement)  // true -> lot is manual, false -> percentage of risk from balance
      check_open_long_lot = (double)(m_symbol_info.LotsMin() * InpVolume);
   else
      check_open_long_lot = m_money.CheckOpenLong(price, sl);
   if(check_open_long_lot == 0.0)
      return;

//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double chek_volime_lot = trade.CheckVolume(m_symbol_info.Name(), check_open_long_lot, price, ORDER_TYPE_BUY);

   if(chek_volime_lot != 0.0)
      if(chek_volime_lot >= check_open_long_lot)
        {
         if(InpPriceLevel == 0 && openTimeBuy != iTime(_Symbol, PERIOD_CURRENT, 0))  // (in pips) < 0 -> Stop orders, = 0 -> Market, > 0 -> Limit orders
           {
            openTimeBuy = iTime(_Symbol, PERIOD_CURRENT, 0);
            trade.SetExpertMagicNumber(InpMagic);
            if(trade.Buy(check_open_long_lot, NULL, price, 0, 0, comment))
              {
               if(trade.ResultDeal() == 0)
                 {
                  Print(InpMagic, " : ", comment, " Compra -> falso. Codigo resultado: ", trade.ResultRetcode(),
                        ", descrição do resultado: ", trade.ResultRetcodeDescription());
                         PrintResult(trade,m_symbol_info);//12/09
                 }
               else
                 {
                  Print(InpMagic, " : ", comment, " Compra -> Verdadeiro. Codigo resultado: ", trade.ResultRetcode(),
                        ", descrição do resultado: ", trade.ResultRetcodeDescription());
                         PrintResult(trade,m_symbol_info);//12/09
                 }
              }
            else
              {
               Print(InpMagic, " : ", comment, " Compra -> falso. Codigo resultado: ", trade.ResultRetcode(),
                     ", descrição do resultado: ", trade.ResultRetcodeDescription());
                      PrintResult(trade,m_symbol_info);//12/09
              }
           }
         else
            if(InpPriceLevel < 0 && openTimeBuy != iTime(_Symbol, PERIOD_CURRENT, 0))  // (in pips) <0 -> Stop orders, =0 -> Market, >0 -> Limit orders
              {
               openTimeBuy = iTime(_Symbol, PERIOD_CURRENT, 0);
               sl = m_symbol_info.NormalizePrice(sl + MathAbs(InpPriceLevel * m_adjusted_point));
               tp = m_symbol_info.NormalizePrice(tp + MathAbs(InpPriceLevel * m_adjusted_point));
               price = m_symbol_info.NormalizePrice(price + MathAbs(InpPriceLevel * m_adjusted_point));

               //CloseAllPositions();

               if(trade.BuyStop(check_open_long_lot, price, m_symbol_info.Name(), 0, 0, 0, comment))
                  Print(InpMagic, " : ", comment, " BuyStop - > true. ticket of order = ", trade.ResultOrder());
                  // PrintResult(trade,m_symbol_info);//12/09
               else
                  Print(InpMagic, " : ", comment, " BuyStop -> false. Result Retcode: ", trade.ResultRetcode(),
                        ", description of Retcode: ", trade.ResultRetcodeDescription(),
                        ", ticket of order: ", trade.ResultOrder());
                         PrintResult(trade,m_symbol_info);//12/09
              }
            else
               if(InpPriceLevel > 0 && openTimeBuy != iTime(_Symbol, PERIOD_CURRENT, 0))  // (in pips) <0 -> Stop orders, =0 -> Market, >0 -> Limit orders
                 {
                  openTimeBuy != iTime(_Symbol, PERIOD_CURRENT, 0);
                  sl = m_symbol_info.NormalizePrice(sl - MathAbs(InpPriceLevel * m_adjusted_point));
                  tp = m_symbol_info.NormalizePrice(tp - MathAbs(InpPriceLevel * m_adjusted_point));
                  price = m_symbol_info.NormalizePrice(price - MathAbs(InpPriceLevel * m_adjusted_point));


                  //CloseAllPositions();

                  if(trade.BuyLimit(check_open_long_lot, price, m_symbol_info.Name(), 0, 0, 0, comment))
                     Print(InpMagic, " : ", comment, " BuyLimit - > true. ticket of order = ", trade.ResultOrder());
                  else
                     Print(InpMagic, " : ", comment, " BuyLimit -> false. Result Retcode: ", trade.ResultRetcode(),
                           ", description of Retcode: ", trade.ResultRetcodeDescription(),
                           ", ticket of order: ", trade.ResultOrder());
                            PrintResult(trade,m_symbol_info);//12/09
                 }
        }
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
void OpenSell(double sl, double tp, string comment)
  {
   sl = m_symbol_info.NormalizePrice(sl);
   tp = m_symbol_info.NormalizePrice(tp);
// comment = m_position.Comment();

   double price = m_symbol_info.Bid();

   double check_open_short_lot = 0.0;
   if(InpMoneyManagement)  // true -> lot is manual, false -> percentage of risk from balance
      check_open_short_lot = (double)(m_symbol_info.LotsMin() * InpVolume);
   else
      check_open_short_lot = m_money.CheckOpenShort(price, sl);
   if(check_open_short_lot == 0.0)
      return;
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double chek_volime_lot = trade.CheckVolume(m_symbol_info.Name(), check_open_short_lot, price, ORDER_TYPE_SELL);

   if(chek_volime_lot != 0.0)
      if(chek_volime_lot >= check_open_short_lot)
        {
         if(InpPriceLevel == 0 && openTimeSell != iTime(_Symbol, PERIOD_CURRENT, 0))  // (in pips) <0 -> Stop orders, =0 -> Market, >0 -> Limit orders
           {
            openTimeSell = iTime(_Symbol, PERIOD_CURRENT, 0);
            trade.SetExpertMagicNumber(InpMagic);
            if(trade.Sell(check_open_short_lot, NULL, price, 0, 0, comment))
              {
               if(trade.ResultDeal() == 0)
                 {
                  Print(InpMagic, " : ", comment, " Venda -> false. Result Retcode: ", trade.ResultRetcode(),
                        ", description of result: ", trade.ResultRetcodeDescription());
                         PrintResult(trade,m_symbol_info);//12/09
                 }
               else
                 {
                  Print(InpMagic, " : ", comment, " Venda -> true. Result Retcode: ", trade.ResultRetcode(),
                        ", description of result: ", trade.ResultRetcodeDescription());
                         PrintResult(trade,m_symbol_info);//12/09
                 }
              }
            else
              {
               Print(InpMagic, " : ", comment, " Venda -> false. Result Retcode: ", trade.ResultRetcode(),
                     ", description of result: ", trade.ResultRetcodeDescription());
                      PrintResult(trade,m_symbol_info);//12/09
              }
           }
         else
            if(InpPriceLevel < 0 && openTimeSell != iTime(_Symbol, PERIOD_CURRENT, 0))  // (in pips) <0 -> Stop orders, =0 -> Market, >0 -> Limit orders
              {
               openTimeSell = iTime(_Symbol, PERIOD_CURRENT, 0);
               sl = m_symbol_info.NormalizePrice(sl - MathAbs(InpPriceLevel * m_adjusted_point));
               tp = m_symbol_info.NormalizePrice(tp - MathAbs(InpPriceLevel * m_adjusted_point));
               price = m_symbol_info.NormalizePrice(price - MathAbs(InpPriceLevel * m_adjusted_point));

               //CloseAllPositions();

               if(trade.SellStop(check_open_short_lot, price, m_symbol_info.Name(), 0, 0, 0, comment))
                  Print(InpMagic, " : ", comment, " SellStop - > true. ticket of order = ", trade.ResultOrder());
                  // PrintResult(trade,m_symbol_info);//12/09
               else
                  Print(InpMagic, " : ", comment, " SellStop -> false. Result Retcode: ", trade.ResultRetcode(),
                        ", description of Retcode: ", trade.ResultRetcodeDescription(),
                        ", ticket of order: ", trade.ResultOrder());
                         PrintResult(trade,m_symbol_info);//12/09
              }
            else
               if(InpPriceLevel > 0 && openTimeSell != iTime(_Symbol, PERIOD_CURRENT, 0))  // (in pips) <0 -> Stop orders, =0 -> Market, >0 -> Limit orders
                 {
                  openTimeSell = iTime(_Symbol, PERIOD_CURRENT, 0);
                  sl = m_symbol_info.NormalizePrice(sl + MathAbs(InpPriceLevel * m_adjusted_point));
                  tp = m_symbol_info.NormalizePrice(tp + MathAbs(InpPriceLevel * m_adjusted_point));
                  price = m_symbol_info.NormalizePrice(price + MathAbs(InpPriceLevel * m_adjusted_point));

                  //CloseAllPositions();

                  if(trade.SellLimit(check_open_short_lot, price, m_symbol_info.Name(), 0, 0, 0, comment))
                     Print(InpMagic, " : ", comment, " SellLimit - > true. ticket of order = ", trade.ResultOrder());
                      //PrintResult(trade,m_symbol_info);//12/09
                  else
                     Print(InpMagic, " : ", comment, " SellLimit -> false. Result Retcode: ", trade.ResultRetcode(),
                           ", description of Retcode: ", trade.ResultRetcodeDescription(),
                           ", ticket of order: ", trade.ResultOrder());
                            PrintResult(trade,m_symbol_info);//12/09
                 }
        }
//---
  }
//+------------------------------------------------------------------+
//| Open Buy position  greentrade                                    |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp)
  {
   sl=m_symbol_info.NormalizePrice(sl);
   tp=m_symbol_info.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=trade.CheckVolume(m_symbol_info.Name(),lot,m_symbol_info.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
      if(check_volume_lot>=lot)
        {
         if(trade.Buy(lot,NULL,m_symbol_info.Ask(),0,0,"GreenBuy"))
           {
            if(trade.ResultDeal()==0)
              {
               Print("#1 Buy -> false. Result Retcode: ",trade.ResultRetcode(),
                     ", description of result: ",trade.ResultRetcodeDescription());
               PrintResult(trade,m_symbol_info);
              }
            else
              {
               Print("#2 Buy -> true. Result Retcode: ",trade.ResultRetcode(),
                     ", description of result: ",trade.ResultRetcodeDescription());
               PrintResult(trade,m_symbol_info);
              }
           }
         else
           {
            Print("#3 Buy -> false. Result Retcode: ",trade.ResultRetcode(),
                  ", description of result: ",trade.ResultRetcodeDescription());
            PrintResult(trade,m_symbol_info);
           }
        }
//---
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
void OpenSell(double sl,double tp)
  {
   sl=m_symbol_info.NormalizePrice(sl);
   tp=m_symbol_info.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=trade.CheckVolume(m_symbol_info.Name(),lot,m_symbol_info.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
      if(check_volume_lot>=lot)
        {
         if(trade.Sell(lot,NULL,m_symbol_info.Bid(),0,0,"GreenSell"))
           {
            if(trade.ResultDeal()==0)
              {
               Print("#1 Sell -> false. Result Retcode: ",trade.ResultRetcode(),
                     ", description of result: ",trade.ResultRetcodeDescription());
               PrintResult(trade,m_symbol_info);
              }
            else
              {
               Print("#2 Sell -> true. Result Retcode: ",trade.ResultRetcode(),
                     ", description of result: ",trade.ResultRetcodeDescription());
               PrintResult(trade,m_symbol_info);
              }
           }
         else
           {
            Print("#3 Sell -> false. Result Retcode: ",trade.ResultRetcode(),
                  ", description of result: ",trade.ResultRetcodeDescription());
            PrintResult(trade,m_symbol_info);
           }
        }
//---
  }