//+------------------------------------------------------------------+
//|                                           FillingListTickets.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| "Preenche os arrays de tickets das posições."                    |
//+------------------------------------------------------------------+
void FillingListTickets(void)
  {
   Data.Buy.list_tickets.Clear();
   Data.Sell.list_tickets.Clear();
   Data.Buy.total_volume=0;
   Data.Sell.total_volume=0;
//---
   int total=PositionsTotal();
   for(int i=total-1; i>=0; i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=InpMagic)   continue;
      if(PositionGetString(POSITION_SYMBOL)!=symb)       continue;
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double volume=PositionGetDouble(POSITION_VOLUME);
      if(type==POSITION_TYPE_BUY)
        {
         Data.Buy.list_tickets.Add(ticket);
         Data.Buy.total_volume+=volume;
        }
      else
        {
         Data.Sell.list_tickets.Add(ticket);
         Data.Sell.total_volume+=volume;
        }
     }
  }