//+------------------------------------------------------------------+
//|                                                    StopLevel.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| "Retorna o nível de Stop calculado."                               |
//+------------------------------------------------------------------+
int StopLevel(const string symbol_name)
{
  int sp = (int)SymbolInfoInteger(symbol_name, SYMBOL_SPREAD);
  int lv = (int)SymbolInfoInteger(symbol_name, SYMBOL_TRADE_STOPS_LEVEL);
  return (lv == 0 ? sp * size_spread : lv);
}

//+------------------------------------------------------------------+
//|                                                     Trailing.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
string ObjectSignature = "";
long chartID = 0;
//string simbolo = Symbol();


bool OnlyCurrentPair = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Trailing()
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
//+------------------------------------------------------------------+
void stopAutomatico()
{
if(hasOpenPositionWith(simbolo, "buyCinq"))
    {
        //Print(__FUNCTION__, " Não se aplica ", InpMagic);
        return;
    }
    if(hasOpenPositionWith(simbolo, "sellCinq"))
    {
        //Print(__FUNCTION__, " Não se aplica ", InpMagic);
        return;
    }

  int posMagic = PositionGetInteger(POSITION_MAGIC);
 // trade.SetExpertMagicNumber(InpMagic);
  for (int i = PositionsTotal() - 1; i >= 0; i--) // returns the number of current positions
  {
    if (m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
    {
      if (!OnlyCurrentPair || m_position.Symbol() == _Symbol && posMagic == InpMagic)
      {
        ulong ticket = m_position.Ticket();
        string symbol = m_position.Symbol();
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        ulong digits = SymbolInfoInteger(symbol, SYMBOL_DIGITS);
        if (digits == 2 || digits == 3 || digits == 4 || digits == 5)
          point *= 10;
        double slCurrentLevel = 0;
        double tpCurrentLevel = 0;
        bool closed = false;
        double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
        double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
        if (StealthMode)
        {
          slCurrentLevel = ObjectGetDouble(chartID, ObjectSignature + "sl" + IntegerToString(ticket), OBJPROP_PRICE);
          tpCurrentLevel = ObjectGetDouble(chartID, ObjectSignature + "tp" + IntegerToString(ticket), OBJPROP_PRICE);

          if (m_position.PositionType() == POSITION_TYPE_BUY)
          {
            if (tpCurrentLevel > 0)
            {
              if (bid >= tpCurrentLevel)
              {
                closed = trade.PositionClose(ticket);
              }
            }
            if (slCurrentLevel > 0)
            {
              if (bid <= slCurrentLevel)
                closed = trade.PositionClose(ticket);
            }
          }
          else if (m_position.PositionType() == POSITION_TYPE_SELL)
          {
            if (tpCurrentLevel > 0)
            {
              if (ask <= tpCurrentLevel)
                closed = trade.PositionClose(ticket);
            }
            if (slCurrentLevel > 0)
            {
              if (ask >= slCurrentLevel)
                closed = trade.PositionClose(ticket);
            }
          }
          if (closed)
          {
            ObjectDelete(chartID, ObjectSignature + "sl" + IntegerToString(ticket));
            ObjectDelete(chartID, ObjectSignature + "tp" + IntegerToString(ticket));
          }
        }
        if (!closed)
        {
          // **************** check SL & TP *********************
          if ((InpStopLoss > 0 || InpTakeProfit > 0) && ((!StealthMode && m_position.StopLoss() == 0 && m_position.TakeProfit() == 0) || (StealthMode && slCurrentLevel == 0 && tpCurrentLevel == 0)))
          {
            double stopLevel = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
            double distTP = MathMax(InpTakeProfit * point, stopLevel);
            double distSL = MathMax(InpStopLoss * point, stopLevel);
            double takeProfit = 0;
            double stopLoss = 0;
            if (m_position.PositionType() == POSITION_TYPE_BUY)
            {
              if (InpTakeProfit > 0)
                takeProfit = m_position.PriceOpen() + distTP;
              if (InpStopLoss > 0)
                stopLoss = m_position.PriceOpen() - distSL;
            }
            else if (m_position.PositionType() == POSITION_TYPE_SELL)
            {
              if (InpTakeProfit > 0)
                takeProfit = m_position.PriceOpen() - distTP;
              if (InpStopLoss > 0)
                stopLoss = m_position.PriceOpen() + distSL;
            }
            if (!StealthMode)
            {
              ResetLastError();
              if (!trade.PositionModify(ticket, NormalizeDouble(stopLoss, digits), NormalizeDouble(takeProfit, digits)))
                ;
               //Print(__FUNCTION__ "  ",ShortName +" (OrderModify Error) "+ IntegerToString(GetLastError()));
              //Print("----->StopLevel ", stopLevel, " TP ", distTP, " SL ", distSL);
            }
            else
            {
              SetLevel(ObjectSignature + "sl" + IntegerToString(ticket), NormalizeDouble(stopLoss, digits), clrRed, STYLE_DASH, 1);
              SetLevel(ObjectSignature + "tp" + IntegerToString(ticket), NormalizeDouble(takeProfit, digits), clrGreen, STYLE_DASH, 1);
            }
          }
        }
      }
    }
  }
}

void SetLevel(string linename, double level, color col1, int linestyle, int thickness)
{
  int digits = _Digits;

  // create or move the horizontal line
  if (ObjectFind(chartID, linename) != 0)
  {
    ObjectCreate(chartID, linename, OBJ_HLINE, 0, 0, level);
    ObjectSetInteger(chartID, linename, OBJPROP_STYLE, linestyle);
    ObjectSetInteger(chartID, linename, OBJPROP_COLOR, col1);
    ObjectSetInteger(chartID, linename, OBJPROP_WIDTH, thickness);

    ObjectSetInteger(chartID, linename, OBJPROP_BACK, true);
  }
  else
  {
    ObjectMove(chartID, linename, 0, Time(PERIOD_CURRENT, 0), level);
  }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime Time(ENUM_TIMEFRAMES tf, int i)
{
  datetime times[1];
  int copied = CopyTime(_Symbol, tf, i, 1, times);
  if (copied < 1)
  {
    return 0;
  }
  return times[0];
}