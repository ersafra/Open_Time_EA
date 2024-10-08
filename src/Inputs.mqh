//+------------------------------------------------------------------+
//|                                                       Inputs.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

    double               InpMaxOrders                  =  10;
    uint                 InpEQ                         =  1;                                   //▶ Distância máxima de pips entre preços iguais
sinput   ENUM_INPUT_YES_NO    InpShowPatternDescript        =  INPUT_YES;                      //▶ Mostrar descrições de padrões
sinput   uint                 InpFontSize                   =  8;                              //▶ Tamanho da fonte 
sinput   color                InpFontColor                  =  clrWhite;                     //▶ Cor do texto
sinput   string               InpFontName                   =  "Calibri";                      //▶ Nome da fonte
input    ENUM_OPENED_MODE     InpModeOpened                 =  OPENED_MODE_ANY;                //▶ Modo de abertura de posições
input    uchar                InpVolume                     =  1;                              //▶ Volume do Lote
input    uint                 InpStopLoss                   =  300;                            //▶ Stop loss (pontos)
input    uint                 InpTakeProfit                 =  300;                            //▶ Take profit (pontos)
input    ushort               InpTrailingStop               =  12;                             //▶ Trailing Stop (pips)
input    ushort               InpTrailingStep               =  5;                              //▶ Trailing Step (pips)
sinput   ulong                InpDeviation                  =  10;                             //▶ Deslizamento de preço
/*sinput*/   uint                 InpSizeSpread                 =  2;                              //▶ Spread multiplicador para paradas
//----------------usado apenas do stoplos automatico
input  bool                   StealthMode                   =  false;                          //▶ Stealh Mode (Yes/No)
enum typets {Simple,MoralExp,None};
input ENUM_TIMEFRAMES         timeframe                     =  PERIOD_M15;                     //▶ Tempo do Trailing stop
input ushort                  Seed                          =  2;                              //▶ Numero para serie
input ulong                   m_slippage                    =  30;                             //▶ Slippage =2
input typets                  TypeTS=Simple;                                                   //▶ Tipo de Trailing Stop
input bool                    UseTakeProfit                 =  false,                          //▶ Use Take Profit ?
                              MultiTS                       =  false;                          //▶ Trailing para todas a posições ?
input int                     SafetyBuffer                  =  1;                              //▶ Next bar close distance from level (points)
//input int                     TrendPrecision                =  -5;                             //▶ Next to previous high(low) distance
//input color                   LevelColor                    =  clrYellow;                      //▶ Fibo levels colors
//----------------------------------------
input bool                 InpMoneyManagement               =  true;                           //▶ true -> lot is manual, false -> percentage of risk from balance
input int                  InpPriceLevel                    =  0;                              //▶ (in pips) <0 -> Stop orders, =0 -> Market, >0 -> Limit orders
input double               InpRisk                          =  5;                              //▶ Risk in percent for a deal from balance
//---Quando o preço cruza a media
input double MaximumRisk                                    =  0.01;                           //▶ Risco Máximo em porcentagem
input double DecreaseFactor                                 =  3;                              //▶ Descrease factor
input int    MovingPeriod                                   =  12;                             //▶ Moving Average period
input int    MovingShift                                    =  6;                              //▶ Moving Average shift
//--Quando o preço cruza a media
input uint   InpOnTrailingStop                              =  500;                            //▶ Posicionar lucro em pontos
input uint    Deviation_=10;                                                                   //▶ Máx. desvio de preço em pontos
//--- parâmetros de entrada - OpenTime
sinput string _____1_____="Configurações de Lucro Minimo";
input bool           lucroGarantido                        =   false;
input double         InpLucro                              =   1.00;
input int            MaxTrades                             =   10;
sinput string _____2_____="Habilitar Operações no Mercado";
//----------Operar Mercado
input bool           OperarMercado                         =   true;
//----------------
sinput string _____3_____="Opções de fechamento de posições";                        
input bool           TimeCloseOne                          =   true;                                       //▶ Usar intervalo de tempo de fechamento #1
input datetime       CloseStartOne                         =   D'1970.01.01 19:50:00';                     //▶ Intervalo de tempo de fechamento #1 (SOMENTE hora:minuto!)
input bool           TimeCloseTwo                          =   true;                                       //▶ Usar intervalo de tempo de fechamento #2
input datetime       CloseStartTwo                         =   D'1970.01.01 23:20:00';                     //▶ Intervalo de tempo de fechamento #2 (SOMENTE hora:minuto!)
sinput string _____4_____="Configurações de abertura de posições";                   
input bool           Monday                                =   false;                                      //▶ Operar na segunda-feira
input bool           Tuesday                               =   false;                                      //▶ Operar na terça-feira
input bool           Wednesday                             =   false;                                      //▶ Operar na quarta-feira
input bool           Thursday                              =   true;                                       //▶ Operar na quinta-feira
input bool           Friday                                =   false;                                      //▶ Operar na sexta-feira
input datetime       OpenStartOne                          =   D'1970.01.01 09:30:00';                     //▶ Hora de início do intervalo de abertura #1 (SOMENTE hora:minuto!)
input datetime       OpenEndOne                            =   D'1970.01.01 14:00:00';                     //▶ Hora de término do intervalo de abertura #1 (SOMENTE hora:minuto!)
input datetime       OpenStartTwo                          =   D'1970.01.01 14:30:00';                     //▶ Hora de início do intervalo de abertura #2 (SOMENTE hora:minuto!)
input datetime       OpenEndTwo                            =   D'1970.01.01 19:00:00';                     //▶ Hora de término do intervalo de abertura #2 (SOMENTE hora:minuto!)
input uchar          Duration                              =   30;                                         //▶ Duração em segundos
input bool           BuyOrSellOne                          =   true;                                       //▶ Tipo de operação no intervalo de tempo #1 ("true" -> COMPRA, "false" -> VENDA)
input bool           BuyOrSellTwo                          =   true;                                       //▶ Tipo de operação no intervalo de tempo #2 ("true" -> COMPRA, "false" -> VENDA)
//----------------------
//--- input parameters
input    ENUM_INPUT_ON_OFF    InpEnableOneBarPatterns       =  INPUT_ON;                       //▶ Grupo com uma vela   (on/off)
input    ENUM_INPUT_ON_OFF    InpEnableTwoBarPatterns       =  INPUT_ON;                       //▶ Grupo com duas velas (on/off)
input    ENUM_INPUT_ON_OFF    InpEnableThreeBarPatterns     =  INPUT_ON;                       //▶ Grupo com tres velas (on/off)
//---
input    ENUM_INPUT_ON_OFF    InpEnablePAT_DOUBLE_INSIDE    =  INPUT_ON;                       //▶ Double inside
input    ENUM_INPUT_ON_OFF    InpEnablePAT_INSIDE           =  INPUT_ON;                       //▶ Inside
input    ENUM_INPUT_ON_OFF    InpEnablePAT_OUTSIDE          =  INPUT_ON;                       //▶ Outside
input    ENUM_INPUT_ON_OFF    InpEnablePAT_PINUP            =  INPUT_ON;                       //▶ Pin up
input    ENUM_INPUT_ON_OFF    InpEnablePAT_PINDOWN          =  INPUT_ON;                       //▶ Pin down
input    ENUM_INPUT_ON_OFF    InpEnablePAT_PPRUP            =  INPUT_ON;                       //▶ Pivot Point Reversal Up
input    ENUM_INPUT_ON_OFF    InpEnablePAT_PPRDN            =  INPUT_ON;                       //▶ Pivot Point Reversal Down
input    ENUM_INPUT_ON_OFF    InpEnablePAT_DBLHC            =  INPUT_ON;                       //▶ Double Bar Low With A Higher Close
input    ENUM_INPUT_ON_OFF    InpEnablePAT_DBHLC            =  INPUT_ON;                       //▶ Double Bar High With A Lower Close
input    ENUM_INPUT_ON_OFF    InpEnablePAT_CPRU             =  INPUT_ON;                       //▶ Close Price Reversal Up
input    ENUM_INPUT_ON_OFF    InpEnablePAT_CPRD             =  INPUT_ON;                       //▶ Close Price Reversal Down
input    ENUM_INPUT_ON_OFF    InpEnablePAT_NB               =  INPUT_ON;                       //▶ Neutral Bar
input    ENUM_INPUT_ON_OFF    InpEnablePAT_FBU              =  INPUT_ON;                       //▶ Force Bar Up
input    ENUM_INPUT_ON_OFF    InpEnablePAT_FBD              =  INPUT_ON;                       //▶ Force Bar Down
input    ENUM_INPUT_ON_OFF    InpEnablePAT_MB               =  INPUT_ON;                       //▶ Mirror Bar
input    ENUM_INPUT_ON_OFF    InpEnablePAT_HAMMER           =  INPUT_ON;                       //▶ Hammer Pattern
input    ENUM_INPUT_ON_OFF    InpEnablePAT_SHOOTSTAR        =  INPUT_ON;                       //▶ Shooting Star
input    ENUM_INPUT_ON_OFF    InpEnablePAT_EVSTAR           =  INPUT_ON;                       //▶ Evening Star
input    ENUM_INPUT_ON_OFF    InpEnablePAT_MORNSTAR         =  INPUT_ON;                       //▶ Morning Star
input    ENUM_INPUT_ON_OFF    InpEnablePAT_BEARHARAMI       =  INPUT_ON;                       //▶ Bearish Harami
input    ENUM_INPUT_ON_OFF    InpEnablePAT_BEARHARAMICROSS  =  INPUT_ON;                       //▶ Bearish Harami Cross
input    ENUM_INPUT_ON_OFF    InpEnablePAT_BULLHARAMI       =  INPUT_ON;                       //▶ Bullish Harami
input    ENUM_INPUT_ON_OFF    InpEnablePAT_BULLHARAMICROSS  =  INPUT_ON;                       //▶ Bullish Harami Cross
input    ENUM_INPUT_ON_OFF    InpEnablePAT_DARKCLOUD        =  INPUT_ON;                       //▶ Dark Cloud Cover
input    ENUM_INPUT_ON_OFF    InpEnablePAT_DOJISTAR         =  INPUT_ON;                       //▶ Doji Star
input    ENUM_INPUT_ON_OFF    InpEnablePAT_ENGBEARLINE      =  INPUT_ON;                       //▶ Engulfing Bearish Line
input    ENUM_INPUT_ON_OFF    InpEnablePAT_ENGBULLLINE      =  INPUT_ON;                       //▶ Engulfing Bullish Line
input    ENUM_INPUT_ON_OFF    InpEnablePAT_EVDJSTAR         =  INPUT_ON;                       //▶ Evening Doji Star
input    ENUM_INPUT_ON_OFF    InpEnablePAT_MORNDJSTAR       =  INPUT_ON;                       //▶ Morning Doji Star
input    ENUM_INPUT_ON_OFF    InpEnablePAT_NB2              =  INPUT_ON;                       //▶ Two Neutral Bars
//---
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_DOUBLE_INSIDE    =  ENUM_ORDER_TYPE_BY_PATT_BUY;  //▶ Double inside> 
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_INSIDE           =  ENUM_ORDER_TYPE_BY_PATT_SELL; //▶ Inside
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_OUTSIDE          =  ENUM_ORDER_TYPE_BY_PATT_SELL; //▶ Outside
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_PINUP            =  ENUM_ORDER_TYPE_BY_PATT_BUY;  //▶ Pin up
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_PINDOWN          =  ENUM_ORDER_TYPE_BY_PATT_SELL; //▶ Pin down
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_PPRUP            =  ENUM_ORDER_TYPE_BY_PATT_BUY;  //▶ Pivot Point Reversal Up
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_PPRDN            =  ENUM_ORDER_TYPE_BY_PATT_SELL; //▶ Pivot Point Reversal Down
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_DBLHC            =  ENUM_ORDER_TYPE_BY_PATT_BUY;  //▶ Double Bar Low With A Higher Close
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_DBHLC            =  ENUM_ORDER_TYPE_BY_PATT_SELL; //▶ Double Bar High With A Lower Close
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_CPRU             =  ENUM_ORDER_TYPE_BY_PATT_BUY;  //▶ Close Price Reversal Up
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_CPRD             =  ENUM_ORDER_TYPE_BY_PATT_SELL; //▶ Close Price Reversal Down
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_NB               =  ENUM_ORDER_TYPE_BY_PATT_NONE; //▶ Neutral Bar
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_FBU              =  ENUM_ORDER_TYPE_BY_PATT_BUY;  //▶ Force Bar Up
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_FBD              =  ENUM_ORDER_TYPE_BY_PATT_SELL; //▶ Force Bar Down
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_MB               =  ENUM_ORDER_TYPE_BY_PATT_NONE; //▶ Mirror Bar
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_HAMMER           =  ENUM_ORDER_TYPE_BY_PATT_BUY;  //▶ Hammer Pattern
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_SHOOTSTAR        =  ENUM_ORDER_TYPE_BY_PATT_SELL; //▶ Shooting Star
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_EVSTAR           =  ENUM_ORDER_TYPE_BY_PATT_SELL; //▶ Evening Star
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_MORNSTAR         =  ENUM_ORDER_TYPE_BY_PATT_BUY;  //▶ Morning Star
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_BEARHARAMI       =  ENUM_ORDER_TYPE_BY_PATT_SELL; //▶ Bearish Harami
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_BEARHARAMICROSS  =  ENUM_ORDER_TYPE_BY_PATT_SELL; //▶ Bearish Harami Cross
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_BULLHARAMI       =  ENUM_ORDER_TYPE_BY_PATT_BUY;  //▶ Bullish Harami
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_BULLHARAMICROSS  =  ENUM_ORDER_TYPE_BY_PATT_BUY;  //▶ Bullish Harami Cross
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_DARKCLOUD        =  ENUM_ORDER_TYPE_BY_PATT_SELL; //▶ Dark Cloud Cover
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_DOJISTAR         =  ENUM_ORDER_TYPE_BY_PATT_SELL; //▶ Doji Star
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_ENGBEARLINE      =  ENUM_ORDER_TYPE_BY_PATT_SELL; //▶ Engulfing Bearish Line
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_ENGBULLLINE      =  ENUM_ORDER_TYPE_BY_PATT_BUY;  //▶ Engulfing Bullish Line
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_EVDJSTAR         =  ENUM_ORDER_TYPE_BY_PATT_SELL; //▶ Evening Doji Star
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_MORNDJSTAR       =  ENUM_ORDER_TYPE_BY_PATT_BUY;  //▶ Morning Doji Star
input    ENUM_ORDER_TYPE_BY_PATTERN InpTypeOrderPAT_NB2              =  ENUM_ORDER_TYPE_BY_PATT_NONE; //▶ Two Neutral Bars
//--------------
