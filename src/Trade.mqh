//+------------------------------------------------------------------+
//|                                                        Trade.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Função de negociação                                             |
//+------------------------------------------------------------------+
int Trade(const ENUM_PATTERN_TYPE &pattern_type,const int index)
  {
   ENUM_POSITION_TYPE type = patt.PositionPattern(pattern_type);
   int number = 0, last_total = list_trade_patt.Total();
//--- Sempre uma posição no mercado: Compra (Buy) ou Venda (Sell)
   if(InpModeOpened == OPENED_MODE_SWING)
     {
      if(type == POSITION_TYPE_BUY && NumberSell() > 0) CloseSell();
      if(type == POSITION_TYPE_SELL && NumberBuy() > 0) CloseBuy();
     }
//--- Apenas uma posição de Compra (Buy)
   if(InpModeOpened == OPENED_MODE_BUY_ONE)
     {
      if(NumberBuy() > 0) return WRONG_VALUE;
      if(type == POSITION_TYPE_SELL) return last_total;
     }
//--- Qualquer quantidade de Compras (Buy)
   if(InpModeOpened == OPENED_MODE_BUY_MANY)
      if(type == POSITION_TYPE_SELL) return last_total;
//--- Apenas uma posição de Venda (Sell)
   if(InpModeOpened == OPENED_MODE_SELL_ONE)
     {
      if(NumberSell() > 0) return WRONG_VALUE;
      if(type == POSITION_TYPE_BUY) return last_total;
     }
//--- Qualquer quantidade de Vendas (Sell)
   if(InpModeOpened == OPENED_MODE_SELL_MANY)
      if(type == POSITION_TYPE_BUY) return last_total;
//--- Todas as verificações foram passadas, ou foi selecionada qualquer quantidade de posições - abrir posição
   if(to_logs)
      Print(__FUNCTION__, ": Para abrir uma posição ", (type == POSITION_TYPE_BUY ? "Compra" : "Venda"), " pelo padrão ", patt.DescriptPattern(pattern_type));
   if(OpenPosition(pattern_type))
      list_trade_patt.Delete(index);
//--- Retorno da quantidade de posições abertas
   return last_total - list_trade_patt.Total();
  }
