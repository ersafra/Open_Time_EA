//+------------------------------------------------------------------+
//|                                         CheckCorrectStopLoss.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| "Verifica se o StopLoss está correto em relação ao StopLevel."   |
//+------------------------------------------------------------------+
bool CheckCorrectStopLoss(const string symbol_name,const ENUM_POSITION_TYPE position_type,const double stop_loss)
  {
   if(stop_loss==0) return true;
   double pt=SymbolInfoDouble(symbol_name,SYMBOL_POINT);
   if(pt==0) return false;
   double price=(position_type==POSITION_TYPE_BUY ? SymbolInfoDouble(symbol_name,SYMBOL_ASK) : SymbolInfoDouble(symbol_name,SYMBOL_BID));
   int lv=StopLevel(symbol_name),dg=(int)SymbolInfoInteger(symbol_name,SYMBOL_DIGITS);
   return
   (
    position_type==POSITION_TYPE_BUY ?
    NormalizeDouble(stop_loss-price+lv*pt,dg)<0 :
    NormalizeDouble(stop_loss-price-lv*pt,dg)>0
    );
  }

//+------------------------------------------------------------------+
//|"Retorna o StopLoss correto em relação ao StopLevel."             |
//+------------------------------------------------------------------+
double CorrectStopLoss(const string symbol_name,const ENUM_POSITION_TYPE position_type,const int stop_loss)
  {
   if(stop_loss==0) return 0;
   double pt=SymbolInfoDouble(symbol_name,SYMBOL_POINT);
   if(pt==0) return 0;
   double price=(position_type==POSITION_TYPE_BUY ? SymbolInfoDouble(symbol_name,SYMBOL_BID) : SymbolInfoDouble(symbol_name,SYMBOL_ASK));
   int lv=StopLevel(symbol_name),dg=(int)SymbolInfoInteger(symbol_name,SYMBOL_DIGITS);
   return
   (position_type==POSITION_TYPE_BUY ?
    NormalizeDouble(::fmin(price-lv*pt,price-stop_loss*pt),dg) :
    NormalizeDouble(::fmax(price+lv*pt,price+stop_loss*pt),dg)
    );
  }
  
//+------------------------------------------------------------------+
//| "Retorna o StopLoss correto em relação ao StopLevel."            |
//+------------------------------------------------------------------+
double CorrectStopLoss(const string symbol_name,const ENUM_POSITION_TYPE position_type,const double stop_loss,const double open_price=0)
  {
   if(stop_loss==0) return 0;
   double pt=SymbolInfoDouble(symbol_name,SYMBOL_POINT);
   if(pt==0) return 0;
   double price=(open_price>0 ? open_price : position_type==POSITION_TYPE_BUY ? SymbolInfoDouble(symbol_name,SYMBOL_BID) : SymbolInfoDouble(symbol_name,SYMBOL_ASK));
   int lv=StopLevel(symbol_name),dg=(int)SymbolInfoInteger(symbol_name,SYMBOL_DIGITS);
   return
   (position_type==POSITION_TYPE_BUY ?
    NormalizeDouble(::fmin(price-lv*pt,stop_loss),dg) :
    NormalizeDouble(::fmax(price+lv*pt,stop_loss),dg)
    );
  }