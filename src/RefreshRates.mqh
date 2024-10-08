//+------------------------------------------------------------------+
//|                                                 RefreshRates.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Обновление цен                                                   |
//+------------------------------------------------------------------+
bool RefreshRates(void)
  {
   if(!m_symbol_info.RefreshRates()) return false;
   if(m_symbol_info.Ask()==0 || m_symbol_info.Bid()==0) return false;
   return true;
  }
