//+------------------------------------------------------------------+
//|                                                      Include.mqh |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link "https://mql5.com"
#property version "1.00"
//+------------------------------------------------------------------+
//| Перечисление разрешённых типов позиций                           |
//+------------------------------------------------------------------+
enum ENUM_OPENED_MODE
{
   OPENED_MODE_ANY,      // Qualquer posição
   OPENED_MODE_SWING,    // Apenas uma posição no mercado(swing)
   OPENED_MODE_BUY_ONE,  // Apenas compras
   OPENED_MODE_BUY_MANY, // Muitas posições(compra)
   OPENED_MODE_SELL_ONE, // Apenas vendas
   OPENED_MODE_SELL_MANY // Muitas pocisões(venda)
};
//+------------------------------------------------------------------+
//| Перечисление типов ордеров для паттернов                         |
//+------------------------------------------------------------------+
enum ENUM_ORDER_TYPE_BY_PATTERN
{
   ENUM_ORDER_TYPE_BY_PATT_BUY,  // Compra
   ENUM_ORDER_TYPE_BY_PATT_SELL, // Venda
   ENUM_ORDER_TYPE_BY_PATT_NONE  // Neutro

};
//+------------------------------------------------------------------+
//| Перечисление "Входной параметр On/Off"                           |
//+------------------------------------------------------------------+
enum ENUM_INPUT_ON_OFF
{
   INPUT_ON = 1, // On
   INPUT_OFF = 0 // Off
};
//+------------------------------------------------------------------+
//| Перечисление "Входной параметр Yes/No"                           |
//+------------------------------------------------------------------+
enum ENUM_INPUT_YES_NO
{
   INPUT_YES = 1, // Yes
   INPUT_NO = 0   // No
};
//+------------------------------------------------------------------+
//| Перечисление типов паттернов                                     |
//+------------------------------------------------------------------+
enum ENUM_PATTERN_TYPE
{
   PATTERN_TYPE_DOUBLE_INSIDE,   // Double inside Bar
   PATTERN_TYPE_INSIDE,          // Inside Bar
   PATTERN_TYPE_OUTSIDE,         // Outside Bar
   PATTERN_TYPE_PINUP,           // Pin up
   PATTERN_TYPE_PINDOWN,         // Pin down
   PATTERN_TYPE_PPRUP,           // Pivot Point Reversal Up
   PATTERN_TYPE_PPRDN,           // Pivot Point Reversal Down
   PATTERN_TYPE_DBLHC,           // Double Bar Low With A Higher Close
   PATTERN_TYPE_DBHLC,           // Double Bar High With A Lower Close
   PATTERN_TYPE_CPRU,            // Close Price Reversal Up
   PATTERN_TYPE_CPRD,            // Close Price Reversal Down
   PATTERN_TYPE_NB,              // Neutral Bar
   PATTERN_TYPE_FBU,             // Force Bar Up
   PATTERN_TYPE_FBD,             // Force Bar Down
   PATTERN_TYPE_MB,              // Mirror Bar
   PATTERN_TYPE_HAMMER,          // Hammer Pattern
   PATTERN_TYPE_SHOOTSTAR,       // Shooting Star
   PATTERN_TYPE_EVSTAR,          // Evening Star
   PATTERN_TYPE_MORNSTAR,        // Morning Star
   PATTERN_TYPE_BEARHARAMI,      // Bearish Harami
   PATTERN_TYPE_BEARHARAMICROSS, // Bearish Harami Cross
   PATTERN_TYPE_BULLHARAMI,      // Bullish Harami
   PATTERN_TYPE_BULLHARAMICROSS, // Bullish Harami Cross
   PATTERN_TYPE_DARKCLOUD,       // Dark Cloud Cover
   PATTERN_TYPE_DOJISTAR,        // Doji Star
   PATTERN_TYPE_ENGBEARLINE,     // Engulfing Bearish Line
   PATTERN_TYPE_ENGBULLLINE,     // Engulfing Bullish Line
   PATTERN_TYPE_EVDJSTAR,        // Evening Doji Star
   PATTERN_TYPE_MORNDJSTAR,      // Morning Doji Star
   PATTERN_TYPE_NB2,             // Two Neutral Bars
   PATTERN_TYPE_BMM,             // BuyMM
   PATTERN_TYPE_SMM,             // SellMM
   PATTERN_TYPE_CRP              // CrPrice
};
#define TOTAL_PATTERNS (30)
//+------------------------------------------------------------------+
//| Структура имён и флагов паттерна                                 |
//+------------------------------------------------------------------+
struct SDataNames
{
   string name_long;           // Nome completo
   string mame_short;          // Nome curto
   bool used_this;             // Flag de uso do padrão
   ENUM_ORDER_TYPE order_type; // Tipo de ordem para o padrão
};
//+------------------------------------------------------------------+
//| Структура входных данных паттерна                                |
//+------------------------------------------------------------------+
struct SDataInput
{
   SDataNames pattern[]; // Nomes e flags
   bool used_group1;     // Flag de uso do grupo 1
   bool used_group2;     // Flag de uso do grupo 2
   bool used_group3;     // Flag de uso do grupo 3
   double equ_min;       // Valor mínimo de comparação
   string font_name;     // Nome da fonte
   uint font_size;       // Tamanho da fonte
   color font_color;     // Cor da fonte
   bool show_descript;   // Exibir descrições
};
//+------------------------------------------------------------------+
int GetMagicNumber(string symbol)
{
   if (symbol == "AUDCAD")
      return 1;
   if (symbol == "AUDCHF")
      return 2;
   if (symbol == "AUDJPY")
      return 3;
   if (symbol == "AUDNZD")
      return 4;
   if (symbol == "AUDUSD")
      return 5;
   if (symbol == "BTCUSD")
      return 6;
   if (symbol == "CADCHF")
      return 7;
   if (symbol == "CADJPY")
      return 8;
   if (symbol == "CHFJPY")
      return 9;
   if (symbol == "EURAUD")
      return 10;
   if (symbol == "EURCAD")
      return 11;
   if (symbol == "EURCHF")
      return 12;
   if (symbol == "EURGBP")
      return 13;
   if (symbol == "EURJPY")
      return 14;
   if (symbol == "EURNZD")
      return 15;
   if (symbol == "EURUSD")
      return 16;
   if (symbol == "GBPJPY")
      return 17;
   if (symbol == "GBPUSD")
      return 18;
   if (symbol == "GOLD")
      return 19;
   if (symbol == "NZDCAD")
      return 20;
   if (symbol == "NZDJPY")
      return 21;
   if (symbol == "USDCAD")
      return 22;
   if (symbol == "USDCHF")
      return 23;
   if (symbol == "USDCNH")
      return 24;
   if (symbol == "USDJPY")
      return 25;
   if (symbol == "GBPAUD")
      return 26;
   if (symbol == "GBPCHF")
      return 27;
   if (symbol == "AUDCADm")
      return 28;
   if (symbol == "AUDCHFm")
      return 29;
   if (symbol == "AUDJPYm")
      return 30;
   if (symbol == "AUDNZDm")
      return 31;
   if (symbol == "AUDUSDm")
      return 32;
   if (symbol == "BTCUSDm")
      return 33;
   if (symbol == "CADCHFm")
      return 34;
   if (symbol == "CADJPYm")
      return 35;
   if (symbol == "CHFJPYm")
      return 36;
   if (symbol == "EURAUDm")
      return 37;
   if (symbol == "EURCADm")
      return 38;
   if (symbol == "EURCHFm")
      return 39;
   if (symbol == "EURGBPm")
      return 40;
   if (symbol == "EURJPYm")
      return 41;
   if (symbol == "EURNZDm")
      return 42;
   if (symbol == "EURUSDm")
      return 43;
   if (symbol == "GBPJPYm")
      return 44;
   if (symbol == "GBPUSDm")
      return 45;
   if (symbol == "GOLDm")
      return 46;
   if (symbol == "NZDCADm")
      return 47;
   if (symbol == "NZDJPYm")
      return 48;
   if (symbol == "USDCADm")
      return 49;
   if (symbol == "USDCHFm")
      return 50;
   if (symbol == "USDCNHm")
      return 51;
   if (symbol == "USDJPYm")
      return 52;
   if (symbol == "GBPAUDm")
      return 53;
   if (symbol == "GBPCHFm")
      return 54;
   if (symbol == "ETHUSDm")
      return 55;
   if (symbol == "ETHUSD")
      return 56;
   if (symbol == "XAUUSD")
      return 57;
   if (symbol == "XAUUSDm")
      return 58;
   if (symbol == "NZDUSDm")
      return 59;

   return 0; // Default value if symbol is not matched
}
