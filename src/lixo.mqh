//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
// Desabilita a grade do gráfico
   ChartSetInteger(0, CHART_SHOW_GRID, false);

// Verifica o nome do símbolo
   if(!m_symbol_info.Name(_Symbol))
      return INIT_FAILED;

// Configurações de negociação
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetMarginMode();
   trade.SetTypeFillingBySymbol(m_symbol_info.Name());
   trade.SetDeviationInPoints(m_slippage);
   trade.SetTypeFilling(ORDER_FILLING_FOK);

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

// Inicialização do indicador ZigZag
   ZZ_Handle = iCustom(Symbol(), PERIOD_CURRENT, "Examples\\ZigZag", 12, 5, 3);
   Print("CustomIndicatorHandle ", ZZ_Handle);
   if(ZZ_Handle <= 0)
      Print("Erro ao obter identificador do indicador. Erro #", GetLastError());

   HL[0] = 666;

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

   RefreshRates();

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

   OnInitcurrencyProfits(); // Função adicional
   return INIT_SUCCEEDED;
  }

// Função auxiliar para configurar os horários de abertura e fechamento
bool ConfigureOpenCloseTimes()
  {
// Primeiro intervalo de abertura
   MqlDateTime SOpenStartOne;
   TimeToStruct(OpenStartOne, SOpenStartOne);
   int open_start_one = SOpenStartOne.hour * 3600 + SOpenStartOne.min * 60;

   MqlDateTime SOpenEndOne;
   TimeToStruct(OpenEndOne, SOpenEndOne);
   int open_end_one = SOpenEndOne.hour * 3600 + SOpenEndOne.min * 60;

   if(open_start_one >= open_end_one)
     {
      Print(__FUNCTION__, " erro: ",
            "\"Intervalo de tempo de início de abertura #1\" (", SOpenStartOne.hour, ":", SOpenStartOne.min, ") ",
            "não pode ser >= ",
            "\"Intervalo de tempo de fim de abertura #1\" (", SOpenEndOne.hour, ":", SOpenEndOne.min, ")");
      return false;
     }

// Fechamento no primeiro intervalo
   if(CloseStartOne)
     {
      MqlDateTime SCloseStartOne;
      TimeToStruct(CloseStartOne, SCloseStartOne);
      int close_start_one = SCloseStartOne.hour * 3600 + SCloseStartOne.min * 60;
      if(close_start_one >= open_start_one && close_start_one <= open_end_one)
        {
         Print(__FUNCTION__, " erro: ",
               "\"Intervalo de fechamento #1\" (", SCloseStartOne.hour, ":", SCloseStartOne.min, ") ",
               "não pode estar dentro do intervalo de tempo #1 ",
               "(", SOpenStartOne.hour, ":", SOpenStartOne.min, ") - (", SOpenEndOne.hour, ":", SOpenEndOne.min, ")");
         return false;
        }
     }

// Segundo intervalo de abertura
   MqlDateTime SOpenStartTwo;
   TimeToStruct(OpenStartTwo, SOpenStartTwo);
   int open_start_two = SOpenStartTwo.hour * 3600 + SOpenStartTwo.min * 60;

   MqlDateTime SOpenEndTwo;
   TimeToStruct(OpenEndTwo, SOpenEndTwo);
   int open_end_two = SOpenEndTwo.hour * 3600 + SOpenEndTwo.min * 60;

   if(open_start_two >= open_end_two)
     {
      Print(__FUNCTION__, " erro: ",
            "\"Intervalo de início de abertura #2\" (", SOpenStartTwo.hour, ":", SOpenStartTwo.min, ") ",
            "não pode ser >= ",
            "\"Intervalo de fim de abertura #2\" (", SOpenEndTwo.hour, ":", SOpenEndTwo.min, ")");
      return false;
     }

// Fechamento no segundo intervalo
   if(CloseStartTwo)
     {
      MqlDateTime SCloseStartTwo;
      TimeToStruct(CloseStartTwo, SCloseStartTwo);
      int close_start_two = SCloseStartTwo.hour * 3600 + SCloseStartTwo.min * 60;
      if(close_start_two >= open_start_two && close_start_two <= open_end_two)
        {
         Print(__FUNCTION__, " erro: ",
               "\"Intervalo de fechamento #2\" (", SCloseStartTwo.hour, ":", SCloseStartTwo.min, ") ",
               "não pode estar dentro do intervalo de tempo #2 ",
               "(", SOpenStartTwo.hour, ":", SOpenStartTwo.min, ") - (", SOpenEndTwo.hour, ":", SOpenEndTwo.min, ")");
         return false;
        }
     }

   return true;
  }
//+------------------------------------------------------------------+
// lixo em 12/09 acertando a melhor openBuy/openSell 
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp,const ulong magic)
  {
   sl=m_symbol_info.NormalizePrice(sl);
   tp=m_symbol_info.NormalizePrice(tp);
//--- verifique o volume antes do OrderSend para evitar o erro "dinheiro insuficiente" (CTrade)
   double check_volume_lot=trade.CheckVolume(m_symbol_info.Name(),InpVolume,m_symbol_info.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
      if(check_volume_lot>=InpVolume)
        {
         trade.SetExpertMagicNumber(magic);
         if(trade.Buy(InpVolume,m_symbol_info.Name(),m_symbol_info.Ask(),sl,tp,IntegerToString(magic)))
           {
            if(trade.ResultDeal()==0)
              {
               // Print("Buy -> false. Result Retcode: ",trade.ResultRetcode(),
               //       ", description of result: ",trade.ResultRetcodeDescription());
              }
            else
              {
               // Print("Buy -> true. Result Retcode: ",trade.ResultRetcode(),
               //       ", description of result: ",trade.ResultRetcodeDescription());
              }
           }
         else
           {
            // Print("Buy -> false. Result Retcode: ",trade.ResultRetcode(),
            //       ", description of result: ",trade.ResultRetcodeDescription());
           }
        }
//---
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
void OpenSell(double sl,double tp,const ulong magic)
  {
   sl=m_symbol_info.NormalizePrice(sl);
   tp=m_symbol_info.NormalizePrice(tp);
//--- verifique o volume antes do OrderSend para evitar o erro "dinheiro insuficiente" (CTrade)
   double check_volume_lot=trade.CheckVolume(m_symbol_info.Name(),InpVolume,m_symbol_info.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
      if(check_volume_lot>=InpVolume)
        {
         trade.SetExpertMagicNumber(magic);
         if(trade.Sell(InpVolume,m_symbol_info.Name(),m_symbol_info.Bid(),sl,tp,IntegerToString(magic)))
           {
            if(trade.ResultDeal()==0)
              {
               // Print("Sell -> false. Result Retcode: ",trade.ResultRetcode(),
               //       ", description of result: ",trade.ResultRetcodeDescription());
              }
            else
              {
               // Print("Sell -> true. Result Retcode: ",trade.ResultRetcode(),
               //       ", description of result: ",trade.ResultRetcodeDescription());
              }
           }
         else
           {
            // Print("Sell -> false. Result Retcode: ",trade.ResultRetcode(),
            //       ", description of result: ",trade.ResultRetcodeDescription());
           }
        }
//---
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
/*int OnInit()
  {
//---- apaga a grade
   ChartSetInteger(0, CHART_SHOW_GRID, false);
//-----------------
//teste lição 6 trailing com atr
   if(!m_symbol_info.Name(_Symbol))
      return  INIT_FAILED;
//-----------------

//----------------------------
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetMarginMode();
   trade.SetTypeFillingBySymbol(m_symbol_info.Name());
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
   symb = m_symbol_info.Name();
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
   if(m_symbol_info.Digits() == 2 || m_symbol_info.Digits() == 3 || m_symbol_info.Digits() == 4 || m_symbol_info.Digits() == 5)
      digits_adjust = 10;
   m_adjusted_point = m_symbol_info.Point() * digits_adjust;


//-----------------------
   delete(m_money);
   m_money = new CMoneyFixedRisk;
   if(!m_money.Init(GetPointer(m_symbol_info), Period(), m_symbol_info.Point() * digits_adjust))
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
   if(!m_symbol_info.Name(Symbol())) // sets symbol name
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
   ExtStopLoss       = InpStopLoss        * m_adjusted_point;
//--even break
OnInitcurrencyProfits(); //tree
//--Linha limite para o OnInit---->
   return(INIT_SUCCEEDED);
  }
  */


//--------------------------------fundo duplo
int topFunDuplo()
{
    datetime time = iTime(_Symbol, PERIOD_CURRENT, 1);
    double open = iOpen(_Symbol, PERIOD_CURRENT, 1);
    double high = iHigh(_Symbol, PERIOD_CURRENT, 1);
    double low = iLow(_Symbol, PERIOD_CURRENT, 1);
    double close = iClose(_Symbol, PERIOD_CURRENT, 1);
    double open2 = iOpen(_Symbol, PERIOD_CURRENT, 2);
    double high2 = iHigh(_Symbol, PERIOD_CURRENT, 2);
    double low2 = iLow(_Symbol, PERIOD_CURRENT, 2);
    double close2 = iClose(_Symbol, PERIOD_CURRENT, 2);
    
    if (open < close)
    {
        
        if (open2 > close2 && high == high2 && low == low2)
        {
            createObj(time, high, 233, clrGreen,"Top");
            return 1;
        }
    }
    else if (open > close)
    {
        if (open2 < close2 && high == high2 && low == low2)
        {
            createObj(time, low, 234, clrRed,"Bottom");
            return -1;
        }
    }
    
    return 0;
}

void createObj(datetime time, double price, int arrawCode, color clr, string txt)
{
    string objName = " ";
    StringConcatenate(objName, "Signal@", time, " at ", DoubleToString(price, _Digits), " (", arrawCode, ")");
    if (ObjectCreate(0, objName, OBJ_ARROW, 0, time, price))
    {
        ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, arrawCode);
        ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
        if (clr == clrGreen)
            ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_TOP);
        else if (clr == clrRed)
            ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
    }
    string candleName = objName + txt;
    if (ObjectCreate(0, candleName, OBJ_TEXT, 0, time, price))
    {
        ObjectSetString(0, candleName, OBJPROP_TEXT, " " + txt);
        ObjectSetInteger(0, candleName, OBJPROP_COLOR, clr);
    }
}
/*
Tenho o seguinte cenario , as 17:30 eu tenho um candle com as seguintes posiçoes , open = 1.11294 , close 1.11488 , high 1.11510 e low 1.11243 , no candle de 18:00
 tenho open =1.11488 ,close = 1.11406 ,high = 1.11511, low = 1.11370 , o que configura um topo duplo , correto ?


o candle das 18:30 me tras as seguintes informaçoes open = 1.11407 , high = 1.11411 , low = 1.11369 e close 1.11382 , se mostranto um candle de baixa e consolidando a tendencia de reversão , correto ?





*/

int topFunDuploMargem()
{
    double margem = 1; // Margem de erro de 1 ponto (ajuste conforme necessário)
    datetime time = iTime(_Symbol, PERIOD_CURRENT, 1);
    double open = iOpen(_Symbol, PERIOD_CURRENT, 1);
    double high = iHigh(_Symbol, PERIOD_CURRENT, 1);
    double low = iLow(_Symbol, PERIOD_CURRENT, 1);
    double close = iClose(_Symbol, PERIOD_CURRENT, 1);
    double open2 = iOpen(_Symbol, PERIOD_CURRENT, 2);
    double high2 = iHigh(_Symbol, PERIOD_CURRENT, 2);
    double low2 = iLow(_Symbol, PERIOD_CURRENT, 2);
    double close2 = iClose(_Symbol, PERIOD_CURRENT, 2);
    double open3 = iOpen(_Symbol, PERIOD_CURRENT, 0);
    double close3 = iClose(_Symbol, PERIOD_CURRENT, 0);

    // Detecta topo duplo
    if (open < close)
    {
        // Verifica se os valores de high/low estão dentro da margem de erro e se o padrão de reversão de tendência está presente
        if (open2 > close2 && MathAbs(high - high2) <= margem && MathAbs(low - low2) <= margem)
        {
            // Confirmação da reversão com candle subsequente de baixa
            if (open3 > close3)
            {
                Print("<-------------->Topo Duplo Confirmado");
                createObj(time, high, 234, clrWhite, "Top Confirmado");
                //OpenSell(0, 0, "Sell");
                return 1;
            }
        }
    }
    // Detecta fundo duplo
    else if (open > close)
    {
        // Verifica se os valores de high/low estão dentro da margem de erro e se o padrão de reversão de tendência está presente
        if (open2 < close2 && MathAbs(high - high2) <= margem && MathAbs(low - low2) <= margem)
        {
            // Confirmação da reversão com candle subsequente de alta
            if (open3 < close3)
            {
                Print("<-------------->Fundo Duplo Confirmado");
                createObj(time, low, 233, clrWhite, "Bottom Confirmado");
                //OpenBuy(0, 0, "Buy");
                return -1;
            }
        }
    }

    return 0;
}

int topFunDuploRev()
{
    double margem = 1; // Margem de erro de 1 ponto (ajuste conforme necessário)
    datetime time = iTime(_Symbol, PERIOD_CURRENT, 1);
    double open = iOpen(_Symbol, PERIOD_CURRENT, 1);
    double high = iHigh(_Symbol, PERIOD_CURRENT, 1);
    double low = iLow(_Symbol, PERIOD_CURRENT, 1);
    double close = iClose(_Symbol, PERIOD_CURRENT, 1);
    double open2 = iOpen(_Symbol, PERIOD_CURRENT, 2);
    double high2 = iHigh(_Symbol, PERIOD_CURRENT, 2);
    double low2 = iLow(_Symbol, PERIOD_CURRENT, 2);
    double close2 = iClose(_Symbol, PERIOD_CURRENT, 2);
    double open3 = iOpen(_Symbol, PERIOD_CURRENT, 0);
    double close3 = iClose(_Symbol, PERIOD_CURRENT, 0);

    // Detecta topo duplo
    if (open < close)
    {
        // Verifica se os valores de high/low estão dentro da margem de erro e se o padrão de reversão de tendência está presente
        if (open2 > close2 && MathAbs(high - high2) <= margem && MathAbs(low - low2) <= margem)
        {
            // Confirmação da reversão com candle subsequente de baixa
            if (open3 > close3)
            {
                Print("<-------------->Topo Duplo Confirmado \n",open," < ",close,"\n",open2," > ",close2,"\n",open3," > ",close3);
                createObj(time, high, 234, clrWhite, "Top Confirmado");
               // OpenSell(0, 0, "tfSell");
                return 1;
            }
        }
    }
    // Detecta fundo duplo
    else if (open > close)
    {
        // Verifica se os valores de high/low estão dentro da margem de erro e se o padrão de reversão de tendência está presente
        if (open2 < close2 && MathAbs(high - high2) <= margem && MathAbs(low - low2) <= margem)
        {
            // Confirmação da reversão com candle subsequente de alta
            if (open3 < close3)
            {
                Print("<-------------->Fundo Duplo Confirmado ",open," > ",close);
                createObj(time, low, 233, clrWhite, "Bottom Confirmado");
               // OpenBuy(0, 0, "tfBuy");
                return -1;
            }
        }
    }

    return 0;
}

int topUpDow()
{
     if(rates[0].time == lastBar){
        return;
    } else {
        lastBar = rates[0].time;
    }
    // Detecta topo duplo
    if (rates[].open < rates[].close)
    {
        // Verifica se os valores de high/low estão dentro da margem de erro e se o padrão de reversão de tendência está presente
        if (rates[2].open == rates[2].close && MathAbs(rates[1].high - rates[2].high) <= margem && MathAbs(rates[1].low - rates[2].low) <= margem)
        {
            // Confirmação da reversão com candle subsequente de baixa
            if (rates[0].open > rates[0].close)
            {
                Print("<-------------->Topo Duplo Confirmado");
                createObj(time, high, 234, clrWhite, "Top Confirmado");
                //OpenSell(0, 0, "Sell");
                return 1;
            }
        }
    }
    // Detecta fundo duplo
    else if (rates[].open > rates[].close)
    {
        // Verifica se os valores de high/low estão dentro da margem de erro e se o padrão de reversão de tendência está presente
        if (rates[2].open == rates[2]close && MathAbs(rates[].high - rates[2].high) <= margem && MathAbs(rates[].low - rates[2].low) <= margem)
        {
            // Confirmação da reversão com candle subsequente de alta
            if (rates[0].open < rates[0].close)
            {
                Print("<-------------->Fundo Duplo Confirmado");
                createObj(time, low, 233, clrWhite, "Bottom Confirmado");
                //OpenBuy(0, 0, "Buy");
                return -1;
            }
        }
    }

    return 0;
}


void upDow4()
  {
   if(rates[0].time == lastBar)
     {
      return;
     }
   else
     {
      lastBar = rates[0].time;
     }

// Verifica se há uma tendência de martelo (compra)
   if(rates[2].open < rates[2].close)
     {
         ObjectCreate(0, "Obj", OBJ_ARROW, 0, rates[3].time, rates[3].low);
         ObjectSetInteger(0, "Obj", OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, "Obj", OBJPROP_ARROWCODE, 233);
         
           }
        }
     
  
//+------------------------------------------------------------------+
// Variável global para armazenar a última barra verificada
//datetime lastBar = 0;

// Função para identificar candles de alta e de baixa e plotar o sinal
void upDow3()
{
   // Verifica se já processamos essa barra
   if(rates[0].time == lastBar)
   {
      return;
   }
   else
   {
      lastBar = rates[0].time;
   }

   // Verifica se a vela é de alta (preço de fechamento maior que o preço de abertura)
   if(rates[1].close > rates[1].open)
   {
      // Cria uma seta para cima no nível da mínima (low) da vela de alta
      string objNameUp = "UpArrow_" + IntegerToString(rates[1].time);
      if (!ObjectCreate(0, objNameUp, OBJ_ARROW, 0, rates[1].time, rates[1].low))
      {
         Print("Erro ao criar objeto de seta de alta: ", GetLastError());
      }
      ObjectSetInteger(0, objNameUp, OBJPROP_COLOR, clrGreen);
      ObjectSetInteger(0, objNameUp, OBJPROP_ARROWCODE, 233);  // Código da seta para cima
   }
   
   // Verifica se a vela é de baixa (preço de fechamento menor que o preço de abertura)
   if(rates[1].close < rates[1].open)
   {
      // Cria uma seta para baixo no nível da máxima (high) da vela de baixa
      string objNameDown = "DownArrow_" + IntegerToString(rates[1].time);
      if (!ObjectCreate(0, objNameDown, OBJ_ARROW, 0, rates[1].time, rates[1].high))
      {
         Print("Erro ao criar objeto de seta de baixa: ", GetLastError());
      }
      ObjectSetInteger(0, objNameDown, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, objNameDown, OBJPROP_ARROWCODE, 234);  // Código da seta para baixo
   }
}

//+------------------------------------------------------------------+

// Função para identificar candles de alta e de baixa e plotar o sinal
void dowUp1()
  {
   double margem = 1; // Margem de erro de 1 ponto (ajuste conforme necessário)

// Verifica se já processamos essa barra
   if(rates[0].time == lastBar)
     {
      return;
     }
   else
     {
      lastBar = rates[0].time;
     }

// Verifica se a vela é de alta (preço de fechamento maior que o preço de abertura)
   if(rates[1].close < rates[1].open)
     {
      // Verifica se os valores de high/low estão dentro da margem de erro e se o padrão de reversão de tendência está presente
      if(rates[2].open == rates[1].close && MathAbs(rates[1].high - rates[2].high) <= margem && MathAbs(rates[1].low - rates[2].low) <= margem)
        {
         Print(__FUNCTION__"<------------ Temos algo aqui");

         // Cria uma seta para cima no nível da mínima (low) da vela de alta
         string objNameUp = "UpArrow_" + IntegerToString(rates[1].time);
         if(!ObjectCreate(0, objNameUp, OBJ_ARROW, 0, rates[1].time, rates[1].high))
           {
            Print("Erro ao criar objeto de seta de alta: ", GetLastError());
           }
         ObjectSetInteger(0, objNameUp, OBJPROP_COLOR, clrGreen);
         ObjectSetInteger(0, objNameUp, OBJPROP_ARROWCODE, 234);  // Código da seta para cima


         // Verifica se a vela é de baixa (preço de fechamento menor que o preço de abertura)
         if(rates[2].close > rates[2].open)
           {
            // Cria uma seta para baixo no nível da máxima (high) da vela de baixa
            string objNameDown = "DownArrow_" + IntegerToString(rates[2].time);
            if(!ObjectCreate(0, objNameDown, OBJ_ARROW, 0, rates[2].time, rates[2].low))
              {
               Print("Erro ao criar objeto de seta de baixa: ", GetLastError());
              }
            ObjectSetInteger(0, objNameDown, OBJPROP_COLOR, clrRed);
            ObjectSetInteger(0, objNameDown, OBJPROP_ARROWCODE, 233);  // Código da seta para baixo
            trade.Sell(m_symbol_info.LotsMin());
           }

        }

     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void identifyTop()
  {
   double margem = 1; // Margem de erro de 1 ponto (ajuste conforme necessário)

// Verifica se já processamos essa barra
   if(rates[0].time == lastBar)
     {
      return;
     }
   else
     {
      lastBar = rates[0].time;
     }

// Verifica se a vela 1 é de alta (fechamento > abertura) e a máxima é maior que as máximas anteriores
   if(rates[1].close > rates[1].open && rates[1].high > rates[2].high && rates[1].high > rates[3].high)
     {
      // Verifica se a vela atual é de baixa (sinal de reversão)
      if(rates[0].close < rates[0].open)
        {
         Print(__FUNCTION__" <------------ Topo identificado");

         // Cria uma seta para baixo no nível da máxima (high) da vela de alta (ponto de topo)
         string objNameTop = "DownArrow_" + IntegerToString(rates[1].time);
         if(!ObjectCreate(0, objNameTop, OBJ_ARROW, 0, rates[1].time, rates[1].high))
           {
            Print("Erro ao criar objeto de seta de topo: ", GetLastError());
           }
         ObjectSetInteger(0, objNameTop, OBJPROP_COLOR, clrRed);
         ObjectSetInteger(0, objNameTop, OBJPROP_ARROWCODE, 234);  // Código da seta para baixo

         // Aqui você pode adicionar uma lógica para vender ou sinalizar o topo de outra forma
         trade.Sell(m_symbol_info.LotsMin());  // Exemplo: executa uma operação de venda
        }
     }
  }
//-----------------------------
void upDow2()
  {
   double margem = 1; // Margem de erro de 1 ponto (ajuste conforme necessário)

// Verifica se já processamos essa barra
   if(rates[0].time == lastBar)
     {
      return;
     }
   else
     {
      lastBar = rates[0].time;
     }

// Verifica se a vela 1 é de alta (preço de fechamento maior que o preço de abertura)
   if(rates[1].close > rates[1].open)
     {
      // Verifica se os valores de high/low estão dentro da margem de erro e se o padrão de reversão de tendência está presente
      if(rates[2].open == rates[1].close && MathAbs(rates[1].high - rates[2].high) <= margem && MathAbs(rates[1].low - rates[2].low) <= margem)

        {
         Print(__FUNCTION__" <------------ Temos algo aqui");

         // Cria uma seta para cima no nível da mínima (low) da vela de alta
         string objNameUp = "UpArrow_" + IntegerToString(rates[1].time);
         if(!ObjectCreate(0, objNameUp, OBJ_ARROW, 0, rates[1].time, rates[1].low))
           {
            Print("Erro ao criar objeto de seta de alta: ", GetLastError());
           }
         ObjectSetInteger(0, objNameUp, OBJPROP_COLOR, clrGreen);
         ObjectSetInteger(0, objNameUp, OBJPROP_ARROWCODE, 233);  // Código da seta para cima
        }
     }

// Verifica se a vela 2 é de baixa (preço de fechamento menor que o preço de abertura)
   if(rates[2].close < rates[2].open)
     {
      // Cria uma seta para baixo no nível da máxima (high) da vela de baixa
      string objNameDown = "DownArrow_" + IntegerToString(rates[2].time);
      if(!ObjectCreate(0, objNameDown, OBJ_ARROW, 0, rates[2].time, rates[2].high))
        {
         Print("Erro ao criar objeto de seta de baixa: ", GetLastError());
        }
      ObjectSetInteger(0, objNameDown, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, objNameDown, OBJPROP_ARROWCODE, 234);  // Código da seta para baixo

      // Executa uma operação de compra
      trade.Buy(m_symbol_info.LotsMin());
     }
  }
//-------------------------------------
void identifyBottom()
  {
   double margem = 1; // Margem de erro de 1 ponto (ajuste conforme necessário)

// Verifica se já processamos essa barra
   if(rates[0].time == lastBar)
     {
      return;
     }
   else
     {
      lastBar = rates[0].time;
     }

// Verifica se a vela 1 é de baixa (fechamento < abertura) e a mínima é menor que as mínimas anteriores
   if(rates[1].close < rates[1].open && rates[1].low < rates[2].low && rates[1].low < rates[3].low)
     {
      // Verifica se a vela atual é de alta (sinal de reversão)
      if(rates[0].close > rates[0].open)
        {
         Print(__FUNCTION__" <------------ Fundo identificado");

         // Cria uma seta para cima no nível da mínima (low) da vela de baixa (ponto de fundo)
         string objNameBottom = "UpArrow_" + IntegerToString(rates[1].time);
         if(!ObjectCreate(0, objNameBottom, OBJ_ARROW, 0, rates[1].time, rates[1].low))
           {
            Print("Erro ao criar objeto de seta de fundo: ", GetLastError());
           }
         ObjectSetInteger(0, objNameBottom, OBJPROP_COLOR, clrGreen);
         ObjectSetInteger(0, objNameBottom, OBJPROP_ARROWCODE, 233);  // Código da seta para cima

         // Aqui você pode adicionar uma lógica para comprar ou sinalizar o fundo de outra forma
         trade.Buy(m_symbol_info.LotsMin());  // Exemplo: executa uma operação de compra
        }
     }
  }
//------------------------------------------------
void FundoDuplo()
  {
   double margem = 1; // Margem de erro de 1 ponto (ajuste conforme necessário)

// Verifica se já processamos essa barra
   if(rates[0].time == lastBar)
     {
      return;
     }
   else
     {
      lastBar = rates[0].time;
     }

// Verifica se a vela 1 é de baixa (preço de fechamento menor que o preço de abertura)
   if(rates[1].close > rates[1].open)
     {
      // Verifica se os valores de high/low estão dentro da margem de erro e se o padrão de reversão de tendência está presente
      if(rates[2].open == rates[1].close && MathAbs(rates[1].high - rates[2].high) <= margem && MathAbs(rates[1].low - rates[2].low) <= margem)
        {
         Print(__FUNCTION__"<------------ Temos algo aqui");

         // Cria uma seta para baixo no nível da máxima (high) da vela de baixa
         string objNameDown = "DownArrow_" + IntegerToString(rates[1].time);
         if(!ObjectCreate(0, objNameDown, OBJ_ARROW, 0, rates[1].time, rates[1].high))
           {
            Print("Erro ao criar objeto de seta de baixa: ", GetLastError());
           }
         ObjectSetInteger(0, objNameDown, OBJPROP_COLOR, clrRed);
         ObjectSetInteger(0, objNameDown, OBJPROP_ARROWCODE, 234);  // Código da seta para baixo

         // Verifica se a vela 2 é de alta (preço de fechamento maior que o preço de abertura)
         if(rates[2].close < rates[2].open)
           {
            // Cria uma seta para cima no nível da mínima (low) da vela de alta
            string objNameUp = "UpArrow_" + IntegerToString(rates[2].time);
            if(!ObjectCreate(0, objNameUp, OBJ_ARROW, 0, rates[2].time, rates[2].low))
              {
               Print("Erro ao criar objeto de seta de alta: ", GetLastError());
              }
            ObjectSetInteger(0, objNameUp, OBJPROP_COLOR, clrGreen);
            ObjectSetInteger(0, objNameUp, OBJPROP_ARROWCODE, 233);  // Código da seta para cima
            trade.Buy(m_symbol_info.LotsMin());
           }
        }
     }
  }
//+------------------------------------------------------------------+