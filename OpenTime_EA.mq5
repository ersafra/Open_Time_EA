//+------------------------------------------------------------------+
//|                                                  Patterns_EA.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://mql5.com"
#property version   "1.00"
#property description "versão 28/08 as 12:49 ,testando horario de funcionamento"
//--- includes
#include "src\\CheckCorrectStopLoss.mqh";
#include "src\\CheckCorrectTakeProfit.mqh";
#include "src\\CheckFreezeLevel.mqh";
#include "src\\CheckLotForLimitAccount.mqh";
#include "src\\CloseBuySell.mqh";
#include "src\\CorrectLots.mqh ";
#include "src\\DateTime.mqh";
#include "src\\FillingArrayDataPatterns.mqh";
#include "src\\FillingListTickets.mqh";
#include "src\\Include.mqh";
#include "src\\Inputs.mqh";
#include "src\\IsValidMagic.mqh";
#include "src\\NumberBuySell.mqh";
#include "src\\OpenPosition.mqh";
#include "src\\RefreshRates.mqh";
#include "src\\SetTradeParameters.mqh";
#include "src\\StopLevel.mqh";
#include "src\\Trade.mqh";
#include "src\\UseTrailing.mqh";
#include "src\\VolumeRoundToCorrect.mqh ";
#include "src\\VolumeRoundToSmaller.mqh";
#include "src\\FiboCreate.mqh";
#include "src\\CrossingoftwoiMA.mqh";
#include "src\\hasOpenPositionWith.mqh";
#include "src\\SinalEntrada.mqh";
#include "src\\ZeroFillingStop.mqh";
#include "src\\OpenTime.mqh";

//----OpenTime
#define m_magic_one m_magic
#define m_magic_two m_magic_one+1
//----OPenTime
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
     {"Two Neutral Bars(2)","NB2"}
  };
SDataInput  data_inputs;
//--- includes
#include "src\\Patterns.mqh"
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
//--fim zzfibo
//-- duas medias
datetime openTimeBuy = 0, openTimeSell = 0;
double m_adjusted_point; // valor do ponto ajustado para 3 ou 5 pontos
//--duas medias
int min_rates_total; //zerofilling
//----------teste
datetime  ts = TimeCurrent(),tm = TimeLocal();
double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- apaga a grade
   ChartSetInteger(0, CHART_SHOW_GRID, false);
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
   for(int i=iBars(_Symbol,TFTS)-1; i>0; i--)
     {
      double open=iOpen(_Symbol,TFTS,i);
      CalcLvl(up,(int)MathRound((iHigh(_Symbol,TFTS,i)-open)/_Point));
      CalcLvl(dn,(int)MathRound((open-iLow(_Symbol,TFTS,i))/_Point));
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
//---Quando o preço cruza a media
   ExtHandle=iMA(_Symbol,_Period,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE);
   if(ExtHandle==INVALID_HANDLE)
     {
      printf("Error creating MA indicator");
      return(INIT_FAILED);
     }
   ChartIndicatorAdd(0, 0, ExtHandle);
//---Quando o preço cruza a media
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetMarginMode();
   trade.SetTypeFillingBySymbol(symbol_info.Name());
//trade.SetTypeFilling(ORDER_FILLING_FOK);
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
  // MqlDateTime SOpenStartTwo;
 //  TimeToStruct(OpenStartTwo,SOpenStartTwo);
 //  int open_start_two=SOpenStartTwo.hour*3600+SOpenStartTwo.min*60;

 //  MqlDateTime SOpenEndTwo;
 //  TimeToStruct(OpenEndTwo,SOpenEndTwo);
 //  int open_end_two=SOpenEndTwo.hour*3600+SOpenEndTwo.min*60;
//---
 //  if(CloseStartTwo)
 //    {
 //     MqlDateTime SCloseStartTwo;
 //     TimeToStruct(CloseStartTwo,SCloseStartTwo);
  //    int close_start_two=SCloseStartTwo.hour*3600+SCloseStartTwo.min*60;
  //    if(close_start_two>=open_start_two && close_start_two<=open_end_two)
  //      {
  //       Print(__FUNCTION__," error: ",
   //            "\"Closing time interval #2\" (",SCloseStartTwo.hour,":",SCloseStartTwo.min,") ",
  //             "can not be inside time interval #2 ",
 //              "(",SOpenStartTwo.hour,":",SOpenStartTwo.min,") - (",SOpenEndTwo.hour,":",SOpenEndTwo.min,")");
  //       return(INIT_PARAMETERS_INCORRECT);
  //      }
   //  }
//---
  // if(open_start_two>=open_end_two)
 //    {
 //     Print(__FUNCTION__," error: ",
   //         "\"Opening start time interval #2\" (",SOpenStartTwo.hour,":",SOpenStartTwo.min,") ",
   //         "can not be >= ",
    //        "\"Opening end time interval #2\" (",SOpenStartTwo.hour,":",SOpenStartTwo.min);
   //   return(INIT_PARAMETERS_INCORRECT);
   //  }
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
               Print("Encontrado padrão de ", pattern.Group(), "-barras ", string(i+1), ": ", patt.DescriptPattern((ENUM_PATTERN_TYPE)pattern_type), ", posição: ", patt.DescriptOrdersPattern((ENUM_PATTERN_TYPE)pattern_type));
           }
        }
     }
// -----Final Candle - Inicio do OpenTime
//-----------Auxiliares>
   stopAutomatico();
   UseTrailing();
   carregaFibonacci();
//--------------Compra e Venda>
   
ManageTradingTime();

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
//---
  }
//+------------------------------------------------------------------+
//| Возвращает тип исполнения ордера, равный type,                   |
//| если он доступен на символе, иначе - корректный вариант          |
//| https://www.mql5.com/ru/forum/170952/page4#comment_4128864       |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetTypeFilling(const ENUM_ORDER_TYPE_FILLING type=ORDER_FILLING_RETURN)
  {
   const ENUM_SYMBOL_TRADE_EXECUTION exe_mode=symbol_info.TradeExecution();
   const int filling_mode=symbol_info.TradeFillFlags();

   return(
            (filling_mode==0 || (type>=ORDER_FILLING_RETURN) || ((filling_mode &(type+1))!=type+1)) ?
            (((exe_mode==SYMBOL_TRADE_EXECUTION_EXCHANGE) || (exe_mode==SYMBOL_TRADE_EXECUTION_INSTANT)) ?
             ORDER_FILLING_RETURN :((filling_mode==SYMBOL_FILLING_IOC) ? ORDER_FILLING_IOC : ORDER_FILLING_FOK)) : type
         );
  }

//+------------------------------------------------------------------+
// Função para verificar se está dentro do horário de operação e executar as ações apropriadas
void ManageTradingTime()
{
    if (IsOpenTime()) // Verifica se está dentro do horário de operação
    {
        CheckForOpen();          // Verifica condições de abertura
        OpenCandleBuySell();      // Ação baseada na abertura do candle

        datetime currentCandleTime = iTime(_Symbol, PERIOD_CURRENT, 0); // Obtém o tempo do candle atual

        // Verifica se o tempo do último candle é diferente do atual
        if (openTimeBuy != currentCandleTime)
        {
           //Trailing();
            openTimeBuy = currentCandleTime; // Atualiza o tempo do último candle
           // trade.Buy(0.01, _Symbol, Ask, 0, 0, "time_buy_time"); // Executa a compra
            // trade.Sell(0.01, _Symbol, Bid, 0, 0, "time_sell"); // (Comentado) Executa a venda se necessário
        }
    }
    else
    {
        //Print("Fora do Horario #1 ", ts); // Mensagem de fora do horário
        Trailing();
    }
}