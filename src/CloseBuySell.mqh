//+------------------------------------------------------------------+
//|                                                 CloseBuySell.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Fecha posiçoes de compra = Buy                                   |
//+------------------------------------------------------------------+
void CloseBuy(void)
  {
   int total=Data.Buy.list_tickets.Total();
   for(int i=total-1; i>=0; i--)
     {
      ulong ticket=Data.Buy.list_tickets.At(i);
      if(ticket==NULL) continue;
      trade.PositionClose(ticket,InpDeviation);
     }
   FillingListTickets();
  }
//+------------------------------------------------------------------+
//| Fecha posiçoes de venda =  Sell                                  |
//+------------------------------------------------------------------+
void CloseSell(void)
  {
   int total=Data.Sell.list_tickets.Total();
   for(int i=total-1; i>=0; i--)
     {
      ulong ticket=Data.Sell.list_tickets.At(i);
      if(ticket==NULL) continue;
      trade.PositionClose(ticket,InpDeviation);
     }
   FillingListTickets();
  }