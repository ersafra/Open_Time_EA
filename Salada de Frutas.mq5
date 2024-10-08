//+------------------------------------------------------------------+
//|                                                  Patterns_EA.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link "https://mql5.com"
#property version "1.00"
#property description "versão 01 02/10/24"

//--- includes
#include "src\\Breakeven.mqh";
#include "src\\CheckCorrectStopLoss.mqh";
#include "src\\CheckCorrectTakeProfit.mqh";
#include "src\\CheckFreezeLevel.mqh";
#include "src\\CheckLotForLimitAccount.mqh";
#include "src\\CrossingoftwoiMA.mqh";
#include "src\\CloseBuySell.mqh";
#include "src\\CorrectLots.mqh ";
#include "src\\Cruzamento3x1.mqh";
//#include "src\\Currencyprofits.mqh";
//#include "src\\GreenTrade.mqh";
#include "src\\DateTime.mqh";
#include "src\\FillingArrayDataPatterns.mqh";
#include "src\\FillingListTickets.mqh";
//#include "src\\FiboCreate.mqh";
#include "src\\HasOpenPositionWith.mqh";
#include "src\\Include.mqh";
#include "src\\Inputs.mqh";
#include "src\\IsValidMagic.mqh";
#include "src\\Indicadores.mqh";
#include "src\\NumberBuySell.mqh";
#include "src\\OpenPosition.mqh";
#include "src\\OpenTime.mqh";
#include "src\\Patterns.mqh";
#include "src\\RefreshRates.mqh";
#include "src\\SetTradeParameters.mqh";
#include "src\\StopLevel.mqh";
#include "src\\SuporteResistencia.mqh";
#include "src\\SinalEntrada.mqh";
#include "src\\Trade.mqh";
#include "src\\Temporario.mqh";
#include "src\\UseTrailing.mqh";
#include "src\\VolumeRoundToCorrect.mqh ";
#include "src\\VolumeRoundToSmaller.mqh";
#include "src\\ZeroFillingStop.mqh";

//--- global variables
int _magicNum = GetMagicNumber(Symbol());
int InpMagic = _magicNum * 5678;

string ArrayNames[][2] =
  {
     {"Double inside(3)", "DBLIN"},
     {"Inside Bar(2)", "IN"},
     {"Outside Bar(2)", "OUT"},
     {"Pin Bar up(3)", "PINUP"},
     {"Pin Bar down(3)", "PINDOWN"},
     {"Pivot Point Reversal Up(3)", "PPRUP"},
     {"Pivot Point Reversal Down(3)", "PPRDN"},
     {"Double Bar Low With A Higher Close(2)", "DBLHC"},
     {"Double Bar High With A Lower Close(2)", "DBHLC"},
     {"Close Price Reversal Up(3)", "CPRU"},
     {"Close Price Reversal Down(3)", "CPRD"},
     {"Neutral Bar(1)", "NB"},
     {"Force Bar Up(1)", "FBU"},
     {"Force Bar Down(1)", "FBD"},
     {"Mirror Bar(2)", "MB"},
     {"Hammer(1)", "HAMMER"},
     {"Shooting Star(1)", "SHOOTSTAR"},
     {"Evening Star(3)", "EVSTAR"},
     {"Morning Star(3)", "MORNSTAR"},
     {"Bearish Harami(2)", "BEARHARAMI"},
     {"Bearish Harami Cross(2)", "BEARHARAMICROSS"},
     {"Bullish Harami(2)", "BULLHARAMI"},
     {"Bullish Harami Cross(2)", "BULLHARAMICROSS"},
     {"Dark Cloud Cover(2)", "DARKCLOUD"},
     {"Doji Star(2)", "DOJISTAR"},
     {"Engulfing Bearish Line(2)", "ENGBEARLINE"},
     {"Engulfing Bullish Line(2)", "ENGBULLLINE"},
     {"Evening Doji Star(3)", "EVDJSTAR"},
     {"Morning Doji Star(3)", "MORNDJSTAR"},
     {"Two Neutral Bars(2)", "NB2"},
     {"BuyMM", "BMM"},
     {"SellMM", "SMM"},
     {"CrPrice", "CRP"},
  };
SDataInput data_inputs;
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
CSymbolInfo    m_symbol_info;        // Objeto-CSymbolInfo
CAccountInfo   account_info;         // Objeto-CAccountInfo
CTerminalInfo  terminal_info;        // Objeto-CTerminalInfo
CTrade         trade;                // Objeto-CTrade
CPatterns      patt;                 // Objeto-padrões
CArrayLong     list_trade_patt;      // Lista de padrões para abertura
CPositionInfo  m_position;           // objeto de posição comercial
CDealInfo      m_deal;
COrderInfo      m_order;
CMoneyFixedRisk *m_money;
//--- estruturas
struct SDatas
  {
   CArrayLong        list_tickets; // Lista de tickets
   double            total_volume;     // Volume total
  };
//---
struct SDataPositions
  {
   SDatas            Buy;  // Dados das posições de Compra (Buy)
   SDatas            Sell; // Dados das posições de Venda (Sell)
  } Data;

//--- variáveis globais
double lot;      // Volume da posição
string symb;     // Símbolo
int prev_total;  // Quantidade de posições na última verificação
int size_spread; // Multiplicador do spread
bool to_logs;    // Flag de log no visualizador
//-->zzfibo
int ZZ_Handle;
int TrendDirection;
int CopyNumber;
long PositionID;
double ZZ_Buffer[];
double HL[4];
double Fibo00;
double Fibo23;
double Fibo38;
double Fibo61;
double Fibo76;
double Fibo100;
double FiboBASE;
double StopLoss;
double MAXProfit;
double SymbolTickValue;
datetime CloseBarTime;
datetime HL_Time[4];
datetime Time00;
datetime Time100;
bool PositionChangeFlag;

//-------------------------------
MqlRates RatesArray[];
MqlRates rates[];
//--fim zzfibo
//-- duas medias
datetime openTimeBuy = 0, openTimeSell = 0;
double m_adjusted_point;
//--duas medias
int min_rates_total; // zerofilling
// cruzamento 2/48
int Media50;
int Media200;

int Media4;
int Media96;

double ExtTakeProfit   = 0.0;
double ExtTrailingStop = 0.0;
double ExtTrailingStep = 0.0;
double ExtStopLoss     = 0.0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string simbolo = Symbol();
// cruzamento 2/48
//----------teste
datetime ts = TimeCurrent(), tm = TimeLocal();
double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
//---lição 6
int Handle_MA;
double MA_Filter[];
//hhll
int Handle_MAHH;
double MA_FilterHH[];
//hhll

int hand_atr;
double atr[];
//--lição 6
// suporte e resistencia
double pricesHighest[], pricesLowest[];
double resistanceLevels[2], supportLevels[2];
//teste topos e fundos
ulong lastBar;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
// Desabilita a grade do gráfico
   ChartSetInteger(0, CHART_SHOW_GRID, false);
//Habilita separador de periodo
   ChartSetInteger(0,CHART_SHOW_PERIOD_SEP,true);
//3x1
   //OnInit3x1();
//3x1
// Verifica o nome do símbolo
   if(!m_symbol_info.Name(_Symbol))
      return INIT_FAILED;
// Verifica se o símbolo está disponível
   RefreshRates();

// Carrega indicadores
   if(!CarregarIndicadores())
      return INIT_FAILED;

// Configuração dos parâmetros de negociação
   if(!SetTradeParameters())
      return INIT_FAILED;

// Configura os valores das variáveis
   size_spread = int(InpSizeSpread < 1 ? 1 : InpSizeSpread);
   symb = m_symbol_info.Name();
   prev_total = 0;
   to_logs = MQLInfoInteger(MQL_VISUAL_MODE) ? true : false;

// Ordena padrões e preenche dados
   list_trade_patt.Sort();
   int size = FillingArrayDataPatterns();
   if(size == WRONG_VALUE)
      return INIT_FAILED;
   if(!patt.OnInit(data_inputs))
      return INIT_FAILED;
   patt.SearchProcess();

// Inicialização bem-sucedida
   if(Seed > 0)
      MathSrand(Seed);
   else
      MathSrand(GetTickCount());

// Calcula o valor do ponto
   pointvalue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) *
                SymbolInfoDouble(_Symbol, SYMBOL_POINT) /
                SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

// Cálculo de níveis
   for(int i = iBars(_Symbol, timeframe) - 1; i > 0; i--)
     {
      double open = iOpen(_Symbol, timeframe, i);
      CalcLvl(up, (int)MathRound((iHigh(_Symbol, timeframe, i) - open) / _Point));
      CalcLvl(dn, (int)MathRound((open - iLow(_Symbol, timeframe, i)) / _Point));
     }

   ArraySetAsSeries(rates, true); // toopos e fundos

// Ajusta dígitos para pontos
   int digits_adjust = (m_symbol_info.Digits() >= 2 && m_symbol_info.Digits() <= 5) ? 10 : 1;
   m_adjusted_point = m_symbol_info.Point() * digits_adjust;

// Inicializa a classe CMoneyFixedRisk
   delete(m_money);
   m_money = new CMoneyFixedRisk;
   if(!m_money.Init(GetPointer(m_symbol_info), Period(), m_symbol_info.Point() * digits_adjust))
      return INIT_FAILED;

   m_money.Percent(InpRisk);

// Verifica dias de negociação
   if(!Monday && !Tuesday && !Wednesday && !Thursday && !Friday)
     {
      Print(__FUNCTION__, " Erro: você proibiu a negociação durante toda a semana :)");
      return INIT_PARAMETERS_INCORRECT;
     }

// Configura intervalos de abertura e fechamento
   if(!ConfigureOpenCloseTimes())
      return INIT_PARAMETERS_INCORRECT;

// Verifica volume de transação
   if(InpVolume <= 0.0)
     {
      Print(__FUNCTION__, " erro: o \"volume de transação\" não pode ser menor ou igual a zero");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(!m_symbol_info.Name(Symbol()))  // Define o nome do símbolo
      return INIT_FAILED;

// Verifica Trailing Stop
   if(InpTrailingStop != 0 && InpTrailingStep == 0)
     {
      Alert(__FUNCTION__, " ERRO: Não é possível usar trailing: o parâmetro \"Trailing Step\" está zero!");
      return INIT_PARAMETERS_INCORRECT;
     }

// Verifica o valor do volume
   string err_text = "";
   if(!CheckVolumeValue(InpVolume, err_text))
     {
      Print(err_text);
      return INIT_PARAMETERS_INCORRECT;
     }

// Configura o tipo de preenchimento permitido
   if(IsFillingTypeAllowed(SYMBOL_FILLING_FOK))
      trade.SetTypeFilling(ORDER_FILLING_FOK);
   else
      if(IsFillingTypeAllowed(SYMBOL_FILLING_IOC))
         trade.SetTypeFilling(ORDER_FILLING_IOC);
      else
         trade.SetTypeFilling(ORDER_FILLING_RETURN);

   trade.SetDeviationInPoints(m_slippage);

// Configurações adicionais
   EventSetTimer(60);

   ArraySetAsSeries(rates, true);
   ArraySetAsSeries(pricesHighest, true);
   ArrayResize(pricesHighest, 50);
   ArraySetAsSeries(pricesLowest, true);
   ArrayResize(pricesLowest, 50);

   ExtTrailingStop = InpTrailingStop * m_adjusted_point;
   ExtTrailingStep = InpTrailingStep * m_adjusted_point;
   ExtStopLoss = InpStopLoss * m_adjusted_point;
   ExtTakeProfit = InpTakeProfit * m_adjusted_point;
/*/----GreenTrade
   if(InpShiftBar == 0 || InpShiftBar_1 == 0 || InpShiftBar_2 == 0 || InpShiftBar_3 == 0)
     {
      Print("\"Index of the bar #...\" can not be zero");
      return (INIT_PARAMETERS_INCORRECT);
     }
   if(InpMaxPosition == 0)
     {
      Print("\"Max position\" can not be zero");
      return (INIT_PARAMETERS_INCORRECT);
     }
     //-----------*/
     //hhll
     Handle_MAHH = iMA(_Symbol, timeframe, 25, 1, MODE_EMA, PRICE_CLOSE);
  if (Handle_MAHH == INVALID_HANDLE)
  return INIT_FAILED;
  //hhll
//------limite do init
   return INIT_SUCCEEDED;
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function - OnDeinit                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--->zzfibo
   IndicatorRelease(ZZ_Handle);
//--->zzfibo
//----zerofillingstop
   GlobalVariableDel_(Symbol());
//----------------
   EventKillTimer();
//---------------------lição seis
   for(int i = ChartIndicatorsTotal(0, 0) - 1; i >= 0; i--)
      ChartIndicatorDelete(0, 0, ChartIndicatorName(0, 0, i));
//----Suporte
   ArrayFree(pricesHighest); // suport -->
   ArrayFree(pricesLowest);

   ArrayRemove(resistanceLevels, 0, WHOLE_ARRAY);
   ArrayRemove(supportLevels, 0, WHOLE_ARRAY);
//----------------3x1
   if(ma14h!=INVALID_HANDLE)
      IndicatorRelease(ma14h);
   if(ma25h!=INVALID_HANDLE)
      IndicatorRelease(ma25h);
   if(ma36h!=INVALID_HANDLE)
      IndicatorRelease(ma36h);
//------------------> linha limite
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

//--> topos e fundos
   if(CopyRates(Symbol(), Period(), 0, 10, rates) < 0)
     {
      Print("Erro  na funcao CopyRates = ", GetLastError());
      return;
     }
//--<
   static datetime PrevBars = 0;
   datetime time_0 = iTime(0);
   if(time_0 == PrevBars)
      return;
   PrevBars = time_0;
   if(!RefreshRates())
     {
      PrevBars = iTime(1);
      return;
     }

//-----------Auxiliares>
   stopAutomatico();
   EvenBreakenV4();
   HHLL();
//-----------Auxiliares>

//----------------------
   if(lucroGarantido)
      lucro_garantido();
//--------------Compra e Venda>
   if(OperarMercado)
      ManageTradingTime();
//------------------

//------------Linha limite do onTick
  } // Fim onTick

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
//---
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
//--- hora da primeira chamada da OnTimer()
   static datetime start_time = TimeCurrent();
//--- hora do servidor de negociação na primeira chamada da OnTimer();
   static datetime start_tradeserver_time = 0;
//--- hora do servidor de negociação calculada
   static datetime calculated_server_time = 0;
//--- hora local no computador
   datetime local_time = TimeLocal();
//--- hora estimada atual do servidor de negociação
   datetime trade_server_time = TimeTradeServer();
//--- se por algum motivo a hora do servidor for desconhecida, sairemos antecipadamente
   if(trade_server_time == 0)
      return;
//--- se o valor inicial do servidor de negociação ainda não estiver definido
   if(start_tradeserver_time == 0)
     {
      start_tradeserver_time = trade_server_time;
      //--- definimos a hora calculada do servidor de negociação
      // Print(trade_server_time);
      calculated_server_time = trade_server_time;
     }
   else
     {
      //--- aumentamos o tempo da primeira chamada da OnTimer()
      if(start_tradeserver_time != 0)
         calculated_server_time = calculated_server_time + 1;
      ;
     }
//---
   string com = StringFormat("                Hora Inicio: %s\r\n", TimeToString(start_time, TIME_MINUTES | TIME_SECONDS));
   com = com + StringFormat("                  Hora local: %s\r\n", TimeToString(local_time, TIME_MINUTES | TIME_SECONDS));
   com = com + StringFormat(" TimeTradeServer time: %s\r\n", TimeToString(trade_server_time, TIME_MINUTES | TIME_SECONDS));
   com = com + StringFormat(" EstimatedServer  time: %s\r\n", TimeToString(calculated_server_time, TIME_MINUTES | TIME_SECONDS));
//--- exibimos no gráfico os valores de todos os contadores
   Comment(com);
//------------+
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResult(CTrade &trade, CSymbolInfo &symbol)
{
   Print("Código do resultado da solicitação: " + IntegerToString(trade.ResultRetcode()));
   Print("Descrição do código do resultado da solicitação: " + trade.ResultRetcodeDescription());
   Print("Ticket da negociação: " + IntegerToString(trade.ResultDeal()));
   Print("Ticket da ordem: " + IntegerToString(trade.ResultOrder()));
   Print("Volume da negociação ou ordem: " + DoubleToString(trade.ResultVolume(), 2));
   Print("Preço confirmado pelo corretor: " + DoubleToString(trade.ResultPrice(), symbol.Digits()));
   Print("Preço atual de venda (Bid): " + DoubleToString(trade.ResultBid(), symbol.Digits()));
   Print("Preço atual de compra (Ask): " + DoubleToString(trade.ResultAsk(), symbol.Digits()));
   Print("Comentário do corretor: " + trade.ResultComment());

   // DebugBreak();
}