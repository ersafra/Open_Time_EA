//+------------------------------------------------------------------+
//|                                       CheckCorrectTakeProfit.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| "Verifica se o TakeProfit está correto em relação ao StopLevel." |
//+------------------------------------------------------------------+
bool CheckCorrectTakeProfit(const string symbol_name,const ENUM_POSITION_TYPE position_type,const double take_profit)
  {
   if(take_profit==0) return true;
   double pt=SymbolInfoDouble(symbol_name,SYMBOL_POINT);
   if(pt==0) return false;
   double price=(position_type==POSITION_TYPE_BUY ? SymbolInfoDouble(symbol_name,SYMBOL_ASK) : SymbolInfoDouble(symbol_name,SYMBOL_BID));
   int lv=StopLevel(symbol_name),dg=(int)SymbolInfoInteger(symbol_name,SYMBOL_DIGITS);
   return
   (
    position_type==POSITION_TYPE_BUY ?
    NormalizeDouble(take_profit-price-lv*pt,dg)>0 :
    NormalizeDouble(take_profit-price+lv*pt,dg)<0
    );
  }
  
  //+------------------------------------------------------------------+
//| "Retorna o TakeProfit correto em relação ao StopLevel."          |
//+------------------------------------------------------------------+
double CorrectTakeProfit(const string symbol_name,const ENUM_POSITION_TYPE position_type,const double take_profit,const double open_price=0)
  {
   if(take_profit==0) return 0;
   double pt=SymbolInfoDouble(symbol_name,SYMBOL_POINT);
   if(pt==0) return 0;
   double price=(open_price>0 ? open_price : position_type==POSITION_TYPE_BUY ? SymbolInfoDouble(symbol_name,SYMBOL_BID) : SymbolInfoDouble(symbol_name,SYMBOL_ASK));
   int lv=StopLevel(symbol_name),dg=(int)SymbolInfoInteger(symbol_name,SYMBOL_DIGITS);
   return
   (position_type==POSITION_TYPE_BUY ?
    NormalizeDouble(::fmax(price+lv*pt,take_profit),dg) :
    NormalizeDouble(::fmin(price-lv*pt,take_profit),dg)
    );
  }
  
//+------------------------------------------------------------------+
//| "Retorna o TakeProfit correto em relação ao StopLevel."          |
//+------------------------------------------------------------------+
double CorrectTakeProfit(const string symbol_name,const ENUM_POSITION_TYPE position_type,const int take_profit)
  {
   if(take_profit==0) return 0;
   double pt=SymbolInfoDouble(symbol_name,SYMBOL_POINT);
   if(pt==0) return 0;
   double price=(position_type==POSITION_TYPE_BUY ? SymbolInfoDouble(symbol_name,SYMBOL_BID) : SymbolInfoDouble(symbol_name,SYMBOL_ASK));
   int lv=StopLevel(symbol_name),dg=(int)SymbolInfoInteger(symbol_name,SYMBOL_DIGITS);
   return
   (position_type==POSITION_TYPE_BUY ?
    NormalizeDouble(fmax(price+lv*pt,price+take_profit*pt),dg) :
    NormalizeDouble(fmin(price-lv*pt,price-take_profit*pt),dg)
    );
  }