//+------------------------------------------------------------------+
//|                                                        updow.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"

//--- includes

#include <Arrays\ArrayLong.mqh>
#include <Charts\Chart.mqh>
#include <Expert\Money\MoneyFixedMargin.mqh>
#include <Expert\Money\MoneyFixedRisk.mqh>
#include <Strings\String.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\DealInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\TerminalInfo.mqh>
#include <Trade\Trade.mqh>
#include <TradeAlgorithms.mqh>
//--- objects
CSymbolInfo m_symbol_info;   // Objeto-CSymbolInfo
CAccountInfo account_info;   // Objeto-CAccountInfo
CTerminalInfo terminal_info; // Objeto-CTerminalInfo
CTrade trade;                // Objeto-CTrade

CArrayLong list_trade_patt; // Lista de padrões para abertura
CPositionInfo m_position;   // objeto de posição comercial
CDealInfo m_deal;
COrderInfo m_order;
CMoneyFixedRisk *m_money;

ulong lastBar;

MqlRates rates[], ratesTP[], high[], low[];
double alta = 0.0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  // Desabilita a grade do gráfico
  ChartSetInteger(0, CHART_SHOW_GRID, false);
  // Habilita separador de periodo
  ChartSetInteger(0, CHART_SHOW_PERIOD_SEP, true);
  //--
  if (!m_symbol_info.Name(_Symbol))
    return INIT_FAILED;
  //--------
  ArraySetAsSeries(rates, true);
  //--- create timer
  EventSetTimer(60);

  //---
  return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  //--- destroy timer
  EventKillTimer();
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  //--> topos e fundos
  if (CopyRates(Symbol(), Period(), 0, 10, rates) < 0)
  {
    Print("Erro  na funcao CopyRates = ", GetLastError());
    return;
  }
  //--<

  // AbreCompraComFundoDuplo();
  // fundoDuplo();
  topoDuplo();

  //---
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
  //---
}
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
{
  //---
}
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
  //---
}
//+------------------------------------------------------------------+

// Função para identificar candles de alta e de baixa e plotar o sinal
void fundoDuplo()
{
  double margem = 1; // Margem de erro de 1 ponto (ajuste conforme necessário)

  // Verifica se já processamos essa barra
  if (rates[0].time == lastBar)
  {
    return;
  }
  else
  {
    lastBar = rates[0].time;
  }

  // Verifica se a vela é de alta (preço de fechamento maior que o preço de abertura)
  if (rates[1].close > rates[1].open)
  {
    // Verifica se os valores de high/low estão dentro da margem de erro e se o padrão de reversão de tendência está presente
    if (rates[2].open == rates[1].close && MathAbs(rates[1].high - rates[2].high) <= margem && MathAbs(rates[1].low - rates[2].low) <= margem)
    {
      Print(__FUNCTION__ "<------------ Temos algo aqui");

      // Cria uma seta para cima no nível da mínima (low) da vela de alta
      string objNameUp = "UpArrow_" + IntegerToString(rates[1].time);
      if (!ObjectCreate(0, objNameUp, OBJ_ARROW, 0, rates[1].time, rates[1].low))
      {
        Print("Erro ao criar objeto de seta de alta: ", GetLastError());
      }
      ObjectSetInteger(0, objNameUp, OBJPROP_COLOR, clrGreen);
      ObjectSetInteger(0, objNameUp, OBJPROP_ARROWCODE, 233); // Código da seta para cima

      // Verifica se a vela é de baixa (preço de fechamento menor que o preço de abertura)
      if (rates[2].close < rates[2].open)
      {
        // Cria uma seta para baixo no nível da máxima (high) da vela de baixa
        string objNameDown = "DownArrow_" + IntegerToString(rates[2].time);
        if (!ObjectCreate(0, objNameDown, OBJ_ARROW, 0, rates[2].time, rates[2].high))
        {
          Print("Erro ao criar objeto de seta de baixa: ", GetLastError());
        }
        ObjectSetInteger(0, objNameDown, OBJPROP_COLOR, clrRed);
        ObjectSetInteger(0, objNameDown, OBJPROP_ARROWCODE, 234); // Código da seta para baixo
        trade.Sell(m_symbol_info.LotsMin());
      }
    }
  }
}
//-----------------------------------------------------------------------------------------------------

// Função para identificar candles de alta e de baixa e plotar o sinal
void topoDuplo()
{
  double margem = 1; // Margem de erro de 1 ponto (ajuste conforme necessário)

  // Verifica se já processamos essa barra
  if (rates[0].time == lastBar)
  {
    return;
  }
  else
  {
    lastBar = rates[0].time;
  }
  // Verifica se a vela é de alta (preço de fechamento maior que o preço de abertura)
  if (rates[1].close < rates[1].open && rates[2].close > rates[2].open)
  {
    if (rates[1].open == rates[2].close && MathAbs(rates[1].high - rates[2].high) <= margem && MathAbs(rates[1].low - rates[2].low) <= margem)
    {
      // Cria uma seta para baixo no nível da máxima (high) da vela de baixa
      string objNameDown = "DownArrow_" + IntegerToString(rates[1].time);
      if (!ObjectCreate(0, objNameDown, OBJ_ARROW, 0, rates[1].time, rates[1].high))
      {
        Print("Erro ao criar objeto de seta de baixa: ", GetLastError());
      }
      ObjectSetInteger(0, objNameDown, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, objNameDown, OBJPROP_ARROWCODE, 234); // Código da seta para baixo
       trade.Sell(m_symbol_info.LotsMin());
    }
  }
}

//-----------------------------------------------------------------------------------------------------
/*
// Verifica se os valores de high/low estão dentro da margem de erro e se o padrão de reversão de tendência está presente
    if (rates[2].open == rates[1].close && MathAbs(rates[1].high - rates[2].high) <= margem && MathAbs(rates[1].low - rates[2].low) <= margem)
    {
      Print(__FUNCTION__ "<------------ Temos algo aqui");

      // Cria uma seta para cima no nível da mínima (low) da vela de alta
      string objNameUp = "UpArrow_" + IntegerToString(rates[1].time);
      if (!ObjectCreate(0, objNameUp, OBJ_ARROW, 0, rates[1].time, rates[1].low))
      {
        Print("Erro ao criar objeto de seta de alta: ", GetLastError());
      }
      ObjectSetInteger(0, objNameUp, OBJPROP_COLOR, clrGreen);
      ObjectSetInteger(0, objNameUp, OBJPROP_ARROWCODE, 233); // Código da seta para cima

      // Verifica se a vela é de baixa (preço de fechamento menor que o preço de abertura)
      if (rates[2].close < rates[2].open)
      {
        // Cria uma seta para baixo no nível da máxima (high) da vela de baixa
        string objNameDown = "DownArrow_" + IntegerToString(rates[2].time);
        if (!ObjectCreate(0, objNameDown, OBJ_ARROW, 0, rates[2].time, rates[2].high))
        {
          Print("Erro ao criar objeto de seta de baixa: ", GetLastError());
        }
        ObjectSetInteger(0, objNameDown, OBJPROP_COLOR, clrRed);
        ObjectSetInteger(0, objNameDown, OBJPROP_ARROWCODE, 234); // Código da seta para baixo
        trade.Sell(m_symbol_info.LotsMin());
      }
    }
  }
}


*/