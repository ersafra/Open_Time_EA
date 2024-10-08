//+------------------------------------------------------------------+
//|                                                 SinalEntrada.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// Função para verificar se está dentro do horário de operação e executar as ações apropriadas
void ManageTradingTime()
  {
   if(IsOpenTimeBard())
     {
      CheckForOpen();// crpSell e crpBuy
      //OpenCandleBuySell();
      openPattern();
     }
   else
     {
      buyCrz50200();
      //buyCrz496();
      sellCrz496();
     }
  }
//--Gatilho de entrada para os candles pattern
  void openPattern()
  {
//--- Verificação de preços nulos
   if(!RefreshRates()) return;
//--- Preenchimento das listas de tickets de posições
   int positions_total=PositionsTotal();
   if(prev_total!=positions_total)
     {
      FillingListTickets();
      prev_total=positions_total;
     }
   int num_b=NumberBuy();
   int num_s=NumberSell();
   long magic=InpMagic;
//--- Busca de padrões e preenchimento da lista de sinais
   list_trade_patt.Clear();
   if(patt.SearchProcess())
     {
      CArrayObj *list=patt.ListPattern();
      if(list!=NULL)
        {
         int total=list.Total();
         for(int i=0; i<total; i++)
           {
            CPattern *pattern=list.At(i);
            if(pattern==NULL) continue;
            long pattern_type=(long)pattern.TypePattern();
            if(list_trade_patt.Search(pattern_type)==WRONG_VALUE)
               list_trade_patt.Add(pattern_type);
            if(to_logs)
               Print("Encontrado padrão de ",pattern.Group(),"- barras ",string(i+1),": ",patt.DescriptPattern((ENUM_PATTERN_TYPE)pattern_type),", posição: ",patt.DescriptOrdersPattern((ENUM_PATTERN_TYPE)pattern_type));
           }
        }
     }
//--- Abertura de posições com base nos sinais
   int total=list_trade_patt.Total();
   if(total>0)
     {
      for(int i=total-1; i>WRONG_VALUE; i--)
        {
         ENUM_PATTERN_TYPE type=(ENUM_PATTERN_TYPE)list_trade_patt.At(i);
         if(type==NULL) continue;
         int res=Trade(type,i);
         if(res==WRONG_VALUE)
           {
            list_trade_patt.Clear();
            break;
           }
        }
     }
  }// fim gatilho pattern