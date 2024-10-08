//+------------------------------------------------------------------+
//|                                           SetTradeParameters.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Configuração dos parâmetros de negociação                        |
//+------------------------------------------------------------------+
bool SetTradeParameters()
{
   //--- Configuração do símbolo
   ResetLastError();
   if (!m_symbol_info.Name(Symbol()))
   {
      Print(__FUNCTION__, ": Erro ao definir o símbolo ", Symbol(), ": ", GetLastError());
      return false;
   }
   //--- Obtenção de preços
   ResetLastError();
   if (!m_symbol_info.RefreshRates())
   {
      Print(__FUNCTION__, ": Erro ao obter dados de ", m_symbol_info.Name(), ": ", GetLastError());
      return false;
   }
   if (account_info.MarginMode() == ACCOUNT_MARGIN_MODE_RETAIL_NETTING)
   {
      Print(__FUNCTION__, ": Conta ", account_info.MarginModeDescription(), " - O EA deve ser executado em uma conta de hedge.");
      return false;
   }
   //--- Configuração automática do tipo de preenchimento
   trade.SetTypeFilling(GetTypeFilling());
   //--- Definição do número mágico
   trade.SetExpertMagicNumber(InpMagic);
   //--- Definição do desvio (slippage)
   trade.SetDeviationInPoints(InpDeviation);
   //--- Definição do número de ordens
   // trade.SetMaxOrders(InpMaxOrders);
   //--
   trade.SetMarginMode();
   //---
   trade.SetTypeFillingBySymbol(m_symbol_info.Name());
   //--
   //--- Definição do lote com ajuste do valor inserido
   // lot = CorrectLots(InpVolume); // original
   lot = CorrectLots((double)(m_symbol_info.LotsMin() * InpVolume));
   //--- Modo assíncrono de envio de ordens desativado
   trade.SetAsyncMode(false);
   //---

   return true;
}
