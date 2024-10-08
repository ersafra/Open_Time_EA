//+------------------------------------------------------------------+
//|                                                  Patterns_EA.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://mql5.com"
#property version   "1.00"
#property description "versão 29/08 as 12:49 ,testando horario de funcionamento/Inclui cruzamento de medias"
#property description "versão 01/09/24 testanto no trialing"
#property description "stopAutomatico ON /1/2/exnexx/3/sem stopautomatico"
#property description "04/09 maxtrades"
#property description "06/09 Operar Mercado / Suporte /Breakeven"
//--- includes
#include "src\\Breakeven.mqh";
#include "src\\CheckCorrectStopLoss.mqh";
#include "src\\CheckCorrectTakeProfit.mqh";
#include "src\\CheckFreezeLevel.mqh";
#include "src\\CheckLotForLimitAccount.mqh";
#include "src\\CrossingoftwoiMA.mqh";
#include "src\\CloseBuySell.mqh";
#include "src\\CorrectLots.mqh ";
#include "src\\DateTime.mqh";
#include "src\\FillingArrayDataPatterns.mqh";
#include "src\\FillingListTickets.mqh";
#include "src\\FiboCreate.mqh";

#include "src\\Include.mqh";
#include "src\\Inputs.mqh";
#include "src\\IsValidMagic.mqh";
#include "src\\Indicadores.mqh";

#include "src\\NumberBuySell.mqh";
#include "src\\OpenPosition.mqh";
#include "src\\OpenTime.mqh";

#include "src\\RefreshRates.mqh";
#include "src\\SetTradeParameters.mqh";
#include "src\\StopLevel.mqh";
#include "src\\SuporteResistencia.mqh";
#include "src\\Trade.mqh";
#include "src\\Temporario.mqh";

#include "src\\UseTrailing.mqh";
#include "src\\VolumeRoundToCorrect.mqh ";
#include "src\\VolumeRoundToSmaller.mqh";

#include "src\\HasOpenPositionWith.mqh";
#include "src\\SinalEntrada.mqh";
#include "src\\ZeroFillingStop.mqh";
#include "src\\Patterns.mqh";

//----max trades

//----max trades
//--- global variables
int _magicNum = GetMagicNumber(Symbol());
int InpMagic = _magicNum * 5678;

string   ArrayNames[][2]=
  {
     {"Double inside(3)","DBLIN"},
     {"Inside Bar(2)","IN"},
     {"Outside Bar(2)","OUT"},
     {"Pin Bar up(3)","PINUP"},
     {"Pin Bar down(3)","PINDOWN"},
     {"Pivot Point Reversal Up(3)","PPRUP"},
     {"Pivot Point Reversal Down(3)","PPRDN"},
     {"Double Bar Low With A Higher Close(2)","DBLHC"},
     {"Double Bar High With A Lower Close(2)","DBHLC"},
     {"Close Price Reversal Up(3)","CPRU"},
     {"Close Price Reversal Down(3)","CPRD"},
     {"Neutral Bar(1)","NB"},
     {"Force Bar Up(1)","FBU"},
     {"Force Bar Down(1)","FBD"},
     {"Mirror Bar(2)","MB"},
     {"Hammer(1)","HAMMER"},
     {"Shooting Star(1)","SHOOTSTAR"},
     {"Evening Star(3)","EVSTAR"},
     {"Morning Star(3)","MORNSTAR"},
     {"Bearish Harami(2)","BEARHARAMI"},
     {"Bearish Harami Cross(2)","BEARHARAMICROSS"},
     {"Bullish Harami(2)","BULLHARAMI"},
     {"Bullish Harami Cross(2)","BULLHARAMICROSS"},
     {"Dark Cloud Cover(2)","DARKCLOUD"},
     {"Doji Star(2)","DOJISTAR"},
     {"Engulfing Bearish Line(2)","ENGBEARLINE"},
     {"Engulfing Bullish Line(2)","ENGBULLLINE"},
     {"Evening Doji Star(3)","EVDJSTAR"},
     {"Morning Doji Star(3)","MORNDJSTAR"},
     {"Two Neutral Bars(2)","NB2"},
     {"BuyMM","BMM"},
     {"SellMM","SMM"},
     {"CrPrice","CRP"},
  };
SDataInput  data_inputs;
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
CSymbolInfo    symbol_info;         // Objeto-CSymbolInfo
CAccountInfo   account_info;        // Objeto-CAccountInfo
CTerminalInfo  terminal_info;       // Objeto-CTerminalInfo
CTrade         trade;               // Objeto-CTrade
CPatterns      patt;                // Objeto-padrões
CArrayLong     list_trade_patt;     // Lista de padrões para abertura
CPositionInfo  m_position;          // objeto de posição comercial
CDealInfo      m_deal;
COrderInfo     m_order;
CMoneyFixedRisk *m_money;
//--- estruturas
struct SDatas
  {
   CArrayLong        list_tickets;  // Lista de tickets
   double            total_volume;  // Volume total
  };
//---
struct SDataPositions
  {
   SDatas            Buy;           // Dados das posições de Compra (Buy)
   SDatas            Sell;          // Dados das posições de Venda (Sell)
  }
Data;

//--- variáveis globais
double         lot;                 // Volume da posição
string         symb;                // Símbolo
int            prev_total;          // Quantidade de posições na última verificação
int            size_spread;         // Multiplicador do spread
bool           to_logs;             // Flag de log no visualizador
//-->zzfibo
int            ZZ_Handle;
int            TrendDirection;
int            CopyNumber;
long           PositionID;
double         ZZ_Buffer[];
double         HL[4];
double         Fibo00;
double         Fibo23;
double         Fibo38;
double         Fibo61;
double         Fibo76;
double         Fibo100;
double         FiboBASE;
double         StopLoss;
double         MAXProfit;
double         SymbolTickValue;
datetime       CloseBarTime;
datetime       HL_Time[4];
datetime       Time00;
datetime       Time100;
bool           PositionChangeFlag;

//-------------------------------
MqlRates RatesArray[];
MqlRates        rates[];
//--fim zzfibo
//-- duas medias
datetime openTimeBuy = 0, openTimeSell = 0;
double m_adjusted_point; // valor do ponto ajustado para 3 ou 5 pontos
//--duas medias
int min_rates_total; //zerofilling
//cruzamento 2/48
int                  Media50;                    // variable for storing the handle of the iMA indicator
int                  Media200;                   // variable for storing the handle of the iMA indicator

int                  Media2;
int                  Media48;


double               ExtTakeProfit=0.0;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string simbolo   = Symbol();
//cruzamento 2/48
//----------teste
datetime  ts = TimeCurrent(),tm = TimeLocal();
double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
//---lição 6
int                               Handle_MA;
double                            MA_Filter[];

int                               hand_atr;
double                            atr[];
//--lição 6
//suporte e resistencia
double pricesHighest[], pricesLowest[];

double resistanceLevels[2], supportLevels[2];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- apaga a grade
   ChartSetInteger(0, CHART_SHOW_GRID, false);
//-----------------
//teste lição 6 trailing com atr
   if(!symbol_info.Name(_Symbol))
      return  INIT_FAILED;
//-----------------

//----------------------------
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetMarginMode();
   trade.SetTypeFillingBySymbol(symbol_info.Name());
   trade.SetDeviationInPoints(m_slippage);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
//--------------------------
   if(!CarregarIndicadores())
      return INIT_FAILED;
//-----
//--- Configuração dos parâmetros de negociação
   if(!SetTradeParameters())
      return INIT_FAILED;
//--- Configuração dos valores das variáveis
   size_spread = int(InpSizeSpread < 1 ? 1 : InpSizeSpread);
   symb = symbol_info.Name();
   prev_total = 0;
   to_logs = (MQLInfoInteger(MQL_VISUAL_MODE) ? true : false);
//--- Preenchimento da estrutura de dados dos padrões
   list_trade_patt.Sort();
   int size = FillingArrayDataPatterns();
   if(size == WRONG_VALUE)
      return INIT_FAILED;
   if(!patt.OnInit(data_inputs))
      return INIT_FAILED;
   patt.SearchProcess();
//--- Inicialização bem-sucedida
//--UseTrailing--->
   if(Seed>0)//initialize random number generator
      MathSrand(Seed);
   else
      MathSrand(GetTickCount());
   trade.SetDeviationInPoints(m_slippage);
   pointvalue=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE)*SymbolInfoDouble(_Symbol,SYMBOL_POINT)/SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   for(int i=iBars(_Symbol,timeframe)-1; i>0; i--)
     {
      double open=iOpen(_Symbol,timeframe,i);
      CalcLvl(up,(int)MathRound((iHigh(_Symbol,timeframe,i)-open)/_Point));
      CalcLvl(dn,(int)MathRound((open-iLow(_Symbol,timeframe,i))/_Point));
     }
//---UseTrainling---x
//--- get indicator handle -- zzfibo
   ZZ_Handle = iCustom(Symbol(), PERIOD_CURRENT, "Examples\\ZigZag", 12, 5, 3);
   Print("CustomIndicatorHandle ",ZZ_Handle);
   if(ZZ_Handle <= 0)
      Print("Identificador do indicador sem sucesso. Erro #", GetLastError());
   HL[0] = 666;
//---fim zzfibo
//-- duas medias
   int digits_adjust = 1;
   if(symbol_info.Digits() == 2 || symbol_info.Digits() == 3 || symbol_info.Digits() == 4 || symbol_info.Digits() == 5)
      digits_adjust = 10;
   m_adjusted_point = symbol_info.Point() * digits_adjust;
//-----------------------
   delete(m_money);
   m_money = new CMoneyFixedRisk;
   if(!m_money.Init(GetPointer(symbol_info), Period(), symbol_info.Point() * digits_adjust))
      return (INIT_FAILED);
   m_money.Percent(InpRisk);
//--duas medias

//---- ZeroFillingStop
   min_rates_total=2;
//----INicio do OpenTime
//-------------------OpenTime------------------//
   if(!Monday && !Tuesday && !Wednesday && !Thursday && !Friday)
     {
      Print(__FUNCTION__," Erro: você proibiu a negociação durante toda a semana:)");
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   MqlDateTime SOpenStartOne;
   TimeToStruct(OpenStartOne,SOpenStartOne);
   int open_start_one=SOpenStartOne.hour*3600+SOpenStartOne.min*60;

   MqlDateTime SOpenEndOne;
   TimeToStruct(OpenEndOne,SOpenEndOne);
   int open_end_one=SOpenEndOne.hour*3600+SOpenEndOne.min*60;

   if(open_start_one>=open_end_one)
     {
      Print(__FUNCTION__," erro: ",
            "\"Intervalo de tempo de início de abertura #1\" (",SOpenStartOne.hour,":",SOpenStartOne.min,") ",
            "can not be >= ",
            "\"Intervalo de tempo de fim de abertura #1\" (",SOpenEndOne.hour,":",SOpenEndOne.min);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   if(CloseStartOne)
     {
      MqlDateTime SCloseStartOne;
      TimeToStruct(CloseStartOne,SCloseStartOne);
      int close_start_one=SCloseStartOne.hour*3600+SCloseStartOne.min*60;
      if(close_start_one>=open_start_one && close_start_one<=open_end_one)
        {
         Print(__FUNCTION__," error: ",
               "\"Intervalo de fechamento #1\" (",SCloseStartOne.hour,":",SCloseStartOne.min,") ",
               "não pode estar dentro do intervalo de tempo #1 ",
               "(",SOpenStartOne.hour,":",SOpenStartOne.min,") - (",SOpenEndOne.hour,":",SOpenEndOne.min,")");
         return(INIT_PARAMETERS_INCORRECT);
        }
     }
//---
   MqlDateTime SOpenStartTwo;
   TimeToStruct(OpenStartTwo,SOpenStartTwo);
   int open_start_two=SOpenStartTwo.hour*3600+SOpenStartTwo.min*60;

   MqlDateTime SOpenEndTwo;
   TimeToStruct(OpenEndTwo,SOpenEndTwo);
   int open_end_two=SOpenEndTwo.hour*3600+SOpenEndTwo.min*60;
//---
   if(CloseStartTwo)
     {
      MqlDateTime SCloseStartTwo;
      TimeToStruct(CloseStartTwo,SCloseStartTwo);
      int close_start_two=SCloseStartTwo.hour*3600+SCloseStartTwo.min*60;
      if(close_start_two>=open_start_two && close_start_two<=open_end_two)
        {
         Print(__FUNCTION__," error: ",
               "\"Closing time interval #2\" (",SCloseStartTwo.hour,":",SCloseStartTwo.min,") ",
               "can not be inside time interval #2 ",
               "(",SOpenStartTwo.hour,":",SOpenStartTwo.min,") - (",SOpenEndTwo.hour,":",SOpenEndTwo.min,")");
         return(INIT_PARAMETERS_INCORRECT);
        }
     }
//---
   if(open_start_two>=open_end_two)
     {
      Print(__FUNCTION__," error: ",
            "\"Opening start time interval #2\" (",SOpenStartTwo.hour,":",SOpenStartTwo.min,") ",
            "can not be >= ",
            "\"Opening end time interval #2\" (",SOpenStartTwo.hour,":",SOpenStartTwo.min);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   if(InpVolume<=0.0)
     {
      Print(__FUNCTION__," error: the \"volume transaction\" can't be smaller or equal to zero");
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   if(!symbol_info.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();

   string err_text="";
   if(!CheckVolumeValue(InpVolume,err_text))
     {
      Print(err_text);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   if(IsFillingTypeAllowed(SYMBOL_FILLING_FOK))
      trade.SetTypeFilling(ORDER_FILLING_FOK);
   else
      if(IsFillingTypeAllowed(SYMBOL_FILLING_IOC))
         trade.SetTypeFilling(ORDER_FILLING_IOC);
      else
         trade.SetTypeFilling(ORDER_FILLING_RETURN);
//---
   trade.SetDeviationInPoints(m_slippage);
//-------------------OpenTime------------------//
   EventSetTimer(60);
//---Suporte
   ArraySetAsSeries(rates,        true);
   ArraySetAsSeries(pricesHighest,true); //suporte
   ArrayResize(pricesHighest,50);
   ArraySetAsSeries(pricesLowest,true); //suporte
   ArrayResize(pricesLowest,50);
//---Suporte
//-- even break
//--- initialize the generator of random numbers
   if((bool)MQLInfoInteger(MQL_TESTER))
      MathSrand(GetTickCount());
//---
   if(InpTrailingStop!=0 && InpTrailingStep==0)
     {
      Alert(__FUNCTION__," ERROR: Trailing is not possible: the parameter \"Trailing Step\" is zero!");
      return(INIT_PARAMETERS_INCORRECT);
     }

   ExtTrailingStop   = InpTrailingStop    * m_adjusted_point;
   ExtTrailingStep   = InpTrailingStep    * m_adjusted_point;
//--even break
//--Linha limite para o OnInit---->
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
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
   ArrayFree(pricesHighest);//suport -->
   ArrayFree(pricesLowest);

   ArrayRemove(resistanceLevels,0,WHOLE_ARRAY);
   ArrayRemove(supportLevels,0,WHOLE_ARRAY);//<-- suport
//---Suporte


////------------------> linha limite
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- Verificando preços zero - Candle
   if(!RefreshRates())
      return;
//--- Preenchendo listas de tickets das posições
   int positions_total = PositionsTotal();
   if(prev_total != positions_total)
     {
      FillingListTickets();
      prev_total = positions_total;
     }
   int num_b = NumberBuy();
   int num_s = NumberSell();
   long magic = InpMagic;

//--- Busca de padrões e preenchimento da lista de sinais
   list_trade_patt.Clear();
   if(patt.SearchProcess())
     {
      CArrayObj *list = patt.ListPattern();
      if(list != NULL)
        {
         int total = list.Total();
         for(int i = 0; i < total; i++)
           {
            CPattern *pattern = list.At(i);
            if(pattern == NULL)
               continue;
            long pattern_type = (long)pattern.TypePattern();
            if(list_trade_patt.Search(pattern_type) == WRONG_VALUE)
               list_trade_patt.Add(pattern_type);
            if(to_logs)
               Print("<-->");
               //Print(__FUNCTION__" Encontrado padrão de ", pattern.Group(), "-barras ", string(i+1), ": ", patt.DescriptPattern((ENUM_PATTERN_TYPE)pattern_type), ", posição: ", patt.DescriptOrdersPattern((ENUM_PATTERN_TYPE)pattern_type));
           }
        }
     }
// -----Final Candle - Inicio do OpenTime
//-----------Auxiliares>
   stopAutomatico();
   //UseTrailing();
   //breakEven();
   //carregaFibonacci();
   suporteResistencia();
   //DoBreakeven();
   EvenBreakenV4();
   //Trailing();
   if(lucroGarantido)
      lucro_garantido();
//--------------Compra e Venda>
   if(OperarMercado)
      ManageTradingTime();
// CheckForOpen();          // Verifica condições de abertura
//OpenCandleBuySell();      // Ação baseada na abertura do candle
// buyCinq();
// buyMM();
// sellCinq();
// sellMM();
   ;
//------------Linha limite do onTick
  }//Fim onTick

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
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
//--- hora da primeira chamada da OnTimer()
   static datetime start_time=TimeCurrent();
//--- hora do servidor de negociação na primeira chamada da OnTimer();
   static datetime start_tradeserver_time=0;
//--- hora do servidor de negociação calculada
   static datetime calculated_server_time=0;
//--- hora local no computador
   datetime local_time=TimeLocal();
//--- hora estimada atual do servidor de negociação
   datetime trade_server_time=TimeTradeServer();
//--- se por algum motivo a hora do servidor for desconhecida, sairemos antecipadamente
   if(trade_server_time==0)
      return;
//--- se o valor inicial do servidor de negociação ainda não estiver definido
   if(start_tradeserver_time==0)
     {
      start_tradeserver_time=trade_server_time;
      //--- definimos a hora calculada do servidor de negociação
      Print(trade_server_time);
      calculated_server_time=trade_server_time;
     }
   else
     {
      //--- aumentamos o tempo da primeira chamada da OnTimer()
      if(start_tradeserver_time!=0)
         calculated_server_time=calculated_server_time+1;;
     }
//---
   string com=StringFormat("                  Hora Inicio: %s\r\n",TimeToString(start_time,TIME_MINUTES|TIME_SECONDS));
   com=com+StringFormat("                  Hora local: %s\r\n",TimeToString(local_time,TIME_MINUTES|TIME_SECONDS));
   com=com+StringFormat(" TimeTradeServer time: %s\r\n",TimeToString(trade_server_time,TIME_MINUTES|TIME_SECONDS));
   com=com+StringFormat(" EstimatedServer  time: %s\r\n",TimeToString(calculated_server_time,TIME_MINUTES|TIME_SECONDS));
//--- exibimos no gráfico os valores de todos os contadores
   Comment(com);
//------------------->

//------------+
  }
//+------------------------------------------------------------------+
