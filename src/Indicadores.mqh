//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+


bool CarregarIndicadores()
{
   //---Quando o preço cruza a media
   ExtHandle=iMA(_Symbol,_Period,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE);
   if(ExtHandle==INVALID_HANDLE)
     {
      printf("Error creating MA indicator");
      return false;
     }
  // ChartIndicatorAdd(0, 0, ExtHandle);
//---Quando o preço cruza a media 50
    Media50 = iCustom(m_symbol_info.Name(),Period(), "Custom Moving Average Input Color",
                             50, 3, MODE_EMA, clrBlue, PRICE_CLOSE);
   if (Media50 == INVALID_HANDLE)
   {
      PrintFormat("MAFast: Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      return false;
   }
ChartIndicatorAdd(0, 0, Media50);
//---Quando o preço cruza a media 200
    Media200 = iCustom(m_symbol_info.Name(),Period(), "Custom Moving Average Input Color",
                             200, 3, MODE_EMA, clrWhite, PRICE_CLOSE);
   if (Media200 == INVALID_HANDLE)
   {
      PrintFormat("MAFast: Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      return false;
   }
ChartIndicatorAdd(0, 0, Media200);
//---Quando o preço cruza a media 2
    Media4 = iCustom(m_symbol_info.Name(),Period(), "Custom Moving Average Input Color",
                             4, 0, MODE_EMA, clrBlue, PRICE_CLOSE);
   if (Media4 == INVALID_HANDLE)
   {
      PrintFormat("MAFast: Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      return false;
   }
ChartIndicatorAdd(0, 0, Media4);
//---Quando o preço cruza a media 48
    Media96 = iCustom(m_symbol_info.Name(),Period(), "Custom Moving Average Input Color",
                             96, 0, MODE_EMA, clrYellow, PRICE_CLOSE);
   if (Media96 == INVALID_HANDLE)
   {
      PrintFormat("MAFast: Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      return false;
   }
ChartIndicatorAdd(0, 0,Media96);

// Indicator RSI declaration lição 6

Handle_MA= iMA(_Symbol,PERIOD_M30,50,1,MODE_EMA,PRICE_CLOSE);
if(Handle_MA==INVALID_HANDLE)
return  false;

// Indicator RSI declaration

hand_atr= iATR(_Symbol,PERIOD_M30,14);
if(hand_atr==INVALID_HANDLE)
return  false;
//--- lição 6
//--- create handle of the indicator iMA
   //handle_iMA=iMA(m_symbol_info.Name(),Period(),MA_period,0,MODE_SMMA,PRICE_MEDIAN);
//--- if the handle is not created
  // if(handle_iMA==INVALID_HANDLE)
   //  {
      //--- tell about the failure and output the error code
    //  PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
       //           m_symbol_info.Name(),
      //            EnumToString(Period()),
     //             GetLastError());
      //--- the indicator is stopped early
    //  return false;
    // }
   //  ChartIndicatorAdd(0, 0, handle_iMA);
//--- create handle of the indicator iRSI
   //handle_iRSI=iRSI(m_symbol_info.Name(),Period(),RSI_period,PRICE_CLOSE);
//--- if the handle is not created
  // if(handle_iRSI==INVALID_HANDLE)
   //  {
      //--- tell about the failure and output the error code
     // PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
    //              m_symbol_info.Name(),
    //              EnumToString(Period()),
    //              GetLastError());
      //--- the indicator is stopped early
     // return false;
   //  }

   //--- sempre carrega acima dessa linha
   return true;
}

//+------------------------------------------------------------------+
