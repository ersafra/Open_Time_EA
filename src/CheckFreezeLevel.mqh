//+------------------------------------------------------------------+
//|                                             CheckFreezeLevel.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Проверяет возможность модификации по уровню заморозки            |
//+------------------------------------------------------------------+
bool CheckFreezeLevel(const string symbol_name,const ENUM_ORDER_TYPE order_type,const double price_modified)
  {
   int lv=(int)SymbolInfoInteger(symbol_name,SYMBOL_TRADE_FREEZE_LEVEL);
   if(lv==0) return true;
   double pt=SymbolInfoDouble(symbol_name,SYMBOL_POINT);
   if(pt==0) return false;
   int dg=(int)SymbolInfoInteger(symbol_name,SYMBOL_DIGITS);
   double price=(order_type==ORDER_TYPE_BUY ? SymbolInfoDouble(symbol_name,SYMBOL_BID) :
                 order_type==ORDER_TYPE_SELL ? SymbolInfoDouble(symbol_name,SYMBOL_ASK) : price_modified);
   return(NormalizeDouble(fabs(price-price_modified)-lv*pt,dg)>0);
  }
