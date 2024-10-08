//+------------------------------------------------------------------+
//|                                                 IsValidMagic.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                  Patterns_EA.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Retorna a bandeira de um mágico válido                           |
//+------------------------------------------------------------------+
bool IsValidMagic(const ulong magic_number)
  {
   for(int i=0; i<TOTAL_PATTERNS; i++)
     {
      ulong mn=InpMagic+(ulong)i;
      if(mn==magic_number) return true;
     }
   return false;
  }
//+------------------------------------------------------------------+