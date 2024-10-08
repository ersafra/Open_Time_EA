//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"

//+------------------------------------------------------------------+
//| Checks if the specified filling mode is allowed                  |
//+------------------------------------------------------------------+
bool IsFillingTypeAllowed(string symbol, int fill_type)
  {
//--- Obtain the value of the property that describes allowed filling modes
   int filling = (int)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
//--- Return true, if mode fill_type is allowed
   return ((filling & fill_type) == fill_type);
  }
//+------------------------------------------------------------------+
//| Get Time for specified bar index                                 |
//+------------------------------------------------------------------+


//- New bar   -------------------------------------------------------+
bool IsNewbar()
  {
   static datetime previousTime = 0;
   datetime currentTime = iTime(_Symbol, _Period, 0);
   if(previousTime!=currentTime)
     {
      previousTime=currentTime;
      return true;
     }
   return false;
  }

/*/ Função para desbloquear o envio de ordem day trade
void VerificarSeNovoDia()
  {
   string hoje = TimeToString(TimeTradeServer(), TIME_DATE);
   datetime dia = StringToTime(hoje);

   if(dia_atual != dia)
     {
      dia_atual = dia;
      bloquear_envio_ordem_por_horario_encerrar = false; // reset da variável.
     }
  }
*/

//+------------------------------------------------------------------+
//| Custon functions                                                 |
//+------------------------------------------------------------------+

// normalize price
bool NormalizePrice(double &price)
  {
   double tickSize = 0;
   if(!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, tickSize))
     {
      Print("Erro ao normalizar valores");
      return false;
     }
   price = NormalizeDouble((price / tickSize) * tickSize, _Digits);
   return true;
  }

//+------------------------------------------------------------------+
//|    contar posiçoes abertas                                       |
//+------------------------------------------------------------------+
void CountOpenPositions(int &cntBuy, int &cntSell)
  {
   cntBuy = 0;
   cntSell = 0;
   int total = PositionsTotal();
   for(int i = total - 1; i > 0; i--)
     {
      m_position.SelectByIndex(i);
      if(m_position.Magic() == InpMagic)
        {
         if(m_position.PositionType() == POSITION_TYPE_BUY)
           {
            cntBuy++;
           }
         if(m_position.PositionType() == POSITION_TYPE_SELL)
           {
            cntSell++;
           }
        }
     }
  }
// close positions
void ClosePositions(bool buy_sell)
  {
   int total = PositionsTotal();
   for(int i = total - 1; i > 0; i--)
     {
      m_position.SelectByIndex(i);
      if(m_position.Magic() == InpMagic)
        {
         if(buy_sell && m_position.PositionType() == POSITION_TYPE_SELL)
           {
            continue;
           }
         if(!buy_sell && m_position.PositionType() == POSITION_TYPE_BUY)
           {
            continue;
           }
         trade.PositionClose(m_position.Ticket());
        }
     }
  }



//+------------------------------------------------------------------+
void DeleteAllOrders()
  {
   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol_info.Name() && m_order.Magic()==InpMagic)
            trade.OrderDelete(m_order.Ticket());
  }
//+------------------------------------------------------------------+

//--------------------------
bool SearchPositions(const datetime start_time,const datetime stop_time)
  {
//--- request trade history
   HistorySelect(start_time,stop_time);
//--- for all deals
   for(int i=HistoryDealsTotal()-1;i>=0;i--)
      if(m_deal.SelectByIndex(i)) // selects the deals by index for further access to its properties
         if(m_deal.Symbol()==m_symbol_info.Name() && m_deal.Magic()==InpMagic)
           {
            if(m_deal.Entry()==DEAL_ENTRY_IN)
               if(m_deal.Time()>=start_time && m_deal.Time()<stop_time)
                  return(true);
           }
//---
   return(false);
  }
//---------------------------------
bool iMAGet(int    handle_iMA,   // indicator handle
            int    buffer_num,   // indicator buffer number
            int    start_pos,    // start position
            int    count,        // amount to copy
            double &buffer[]     // target array to copy
           )
  {
//--- reset error code
   ResetLastError();
//--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index
   if(CopyBuffer(handle_iMA,buffer_num,start_pos,count,buffer)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat(__FUNCTION__" Failed to copy data from the iMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(false);
     }
   return(true);
  }


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Comentario(const string &comment)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         string posSymbol = PositionGetString(POSITION_SYMBOL);
         int posType = PositionGetInteger(POSITION_TYPE);
         int posMagic = PositionGetInteger(POSITION_MAGIC);

         if(Symbol() == m_position.Symbol() && InpMagic == m_position.Magic() &&
            (m_position.PositionType() == POSITION_TYPE_BUY || m_position.PositionType() == POSITION_TYPE_SELL))
           {
            if(m_position.Comment() == comment)

               return true;
           }
        }
     }
   return false;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OpenBuyTest()
  {

   datetime currentCandleTime = iTime(_Symbol, PERIOD_CURRENT, 0); // Obtém o tempo do candle atual
   if(openTimeBuy != currentCandleTime)
     {
      openTimeBuy = currentCandleTime; // Atualiza o tempo do último candle
      bool sucesso = trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,0.01,Ask,0,0,"time_Buy");  // Executa a compra

      if(sucesso)
        {
         Print("<------> Compra executada com sucesso");
        }
      else
        {
         Print("<----> Erro ao executar compra em ", __FUNCTION__);
        }

     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OpenSellTest()
  {
// Obtém o tempo do candle atual
   datetime currentCandleTime = iTime(_Symbol, PERIOD_CURRENT, 0);

// Verifica se o tempo do candle atual é diferente do último tempo registrado
   if(openTimeSell != currentCandleTime)
     {
      // Atualiza o tempo do último candle
      openTimeSell = currentCandleTime;

      // Tenta abrir uma posição de venda
      bool sucesso = trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, 0.01, Bid, 0, 0, "time_Sell");

      // Verifica se a venda foi executada com sucesso
      if(sucesso)
        {
         Print("<------> Venda executada com sucesso");
        }
      else
        {
         Print("<----> Erro ao executar venda em ", __FUNCTION__);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void licaoSeis()
  {
   if(OpenBar(Symbol()))
     {
      // Candle declaration
      double High[],Low[],open[],close[];
      ArraySetAsSeries(High,true);
      ArraySetAsSeries(Low,true);
      ArraySetAsSeries(close,true);
      ArraySetAsSeries(open,true);
      CopyHigh(Symbol(),timeframe,0,1000,High);
      CopyLow(Symbol(),timeframe,0,1000,Low);
      CopyOpen(_Symbol,timeframe,0,100,open);
      CopyClose(_Symbol,timeframe,0,100,close);
      // Highest high and lowest low declaration
      int highest= ArrayMaximum(High,2,20);
      int lowest= ArrayMinimum(Low,2,20);

      double  HH= High[highest];
      //Drawline(" Kháng Cự ", clrRed,HH);
      double  LL= Low[lowest];
      //Drawline(" hỗ trợ ", clrBlue,LL);

      // Moving average declaration
      CopyBuffer(Handle_MA,0,0,100,MA_Filter);
      ArraySetAsSeries(MA_Filter,true);
      // Atr declaration
      ArraySetAsSeries(atr,true);
      CopyBuffer(hand_atr,0,0,50,atr);

      //   Broker parameter
      double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
      double ask= SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double bid= SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double spread=ask-bid;
      double stoplevel= (int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
      int freezerlevel= (int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL);


      // Count bjuy and count sell
      int count_buy=0;
      int count_sell=0;
      count_position(count_buy,count_sell,atr);

      // Main condition for buy and sell

      if(count_buy==0)
        {
         if(ask>(HH) && High[highest] > MA_Filter[highest])
           {
            double  entryprice= ask;
            double  sl        = LL;
            double  tp        = entryprice   +4*atr[1];
            double lotsize    = calculate_lotsize(sl,entryprice);
            if(bid-sl>stoplevel && tp-bid>stoplevel&& CheckVolumeValue(lotsize))
              {
               //trade.Buy(lotsize,_Symbol,entryprice,sl,tp, " Comprar Sr. Tan ? ");
               Print("Teriamos uma compra aqui");

              }
           }
        }
      if(count_sell==0)
        {
         if(bid<(LL) && Low[lowest] < MA_Filter[lowest])
           {
            double  entryprice= bid;
            double  sl        = HH;
            double  tp        = entryprice   -4*atr[1];
            double lotsize    = calculate_lotsize(sl,entryprice);
            if(sl-ask>stoplevel && ask-tp>stoplevel&& CheckVolumeValue(lotsize))
              {
               //trade.Sell(lotsize,_Symbol,entryprice,sl,tp, " Vender Sr. Tan ? ");
               Print("Teriamos uma venda aqui");
              }
           }
        }

     }

  }

void  count_position(int &count_buy, int &count_sell, double &_atr[])

  {

   count_buy=0;
   count_sell=0;
   int total_postion=PositionsTotal();
   double cp=0.0, op=0.0, sl=0.0,tp=0.0;
   ulong ticket=0.0;
   for(int i=total_postion-1; i>=0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Symbol()==_Symbol && m_position.Magic()== InpMagic)
            cp=m_position.PriceCurrent();
         op=m_position.PriceOpen();
         sl=m_position.StopLoss();
         tp=m_position.TakeProfit();
         ticket=m_position.Ticket();
           {
            if(m_position.PositionType()== POSITION_TYPE_BUY)
              {
               count_buy++;
               double Traill= cp-2*_atr[1];
               if(cp>sl+0.1*_atr[1] && Traill>sl&& PositionModifyCheck(ticket,Traill,tp,_Symbol))
                 {
                  trade.PositionModify(ticket,Traill,tp);//alterei tp para 0
                 }
              }

            if(m_position.PositionType()== POSITION_TYPE_SELL)
              {
               count_sell++;
               double Traill= cp+2*_atr[1];
               if(cp<sl-0.1*_atr[1] && Traill < sl && PositionModifyCheck(ticket,Traill,tp,_Symbol))

                 {
                  trade.PositionModify(ticket,Traill,tp);
                 }
              }

           }
        }

     }
  }

// Only buy or sell at new candle
datetime    mprevBar;
bool    OpenBar(string  symbol)

  {
   datetime     CurBar=iTime(symbol,timeframe,0);
   if(CurBar==mprevBar)
     {
      return   false;
     }
   mprevBar=CurBar;
   return  true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Drawline(string name, color  Color, double  price)
  {
   if(ObjectFind(0,name)<0)
     {
      ResetLastError();;
     }
   if(!ObjectCreate(0,name,OBJ_HLINE,0,0,price))
     {
      return;
     }
// Setup color for object
   ObjectSetInteger(0,name,OBJPROP_COLOR,Color);
// Setup color for object
   ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_DASHDOT);
// Setup color for object
   ObjectSetInteger(0,name,OBJPROP_WIDTH,2);

   if(!ObjectMove(0,name,0,0,price))
     {
      return;
     }
   ChartRedraw();
  }
//+------------------------------------------------------------------+
//| Checking the new values of levels before order modification      |
//+------------------------------------------------------------------+
bool PositionModifyCheck(ulong ticket, double sl, double tp, string symbol)
  {
   CPositionInfo pos;
   COrderInfo    order;
   if(PositionGetString(POSITION_SYMBOL) == symbol)
     {
      //--- selecionar ordem pelo ticket
      if(pos.SelectByTicket(ticket))
        {
         //--- tamanho do ponto e nome do símbolo, para o qual uma ordem pendente foi colocada
         double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
         //--- verificar se há alterações no nível de StopLoss
         bool StopLossChanged = (MathAbs(pos.StopLoss() - sl) > point);
         //--- se houver alterações nos níveis
         if(StopLossChanged) // || TakeProfitChanged)
            return(true);  // posição pode ser modificada
         //--- não há alterações nos níveis de StopLoss e TakeProfit
         else
            //--- notificar sobre o erro
            PrintFormat("O pedido #%d já possui níveis de Aberto=%.5f SL=%.5f TP=%.5f",
                        ticket, order.StopLoss(), order.TakeProfit());
        }
     }
//--- chegou ao fim, nenhuma alteração para a ordem
   return(false);       // não há necessidade de modificar
  } // fim PositionModifyCheck


double calculate_lotsize(double sl, double price)

  {
   double lots=0.,margin ;
   double lotstep= SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   double ticksize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickvalue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double balance= AccountInfoDouble(ACCOUNT_BALANCE);
   double point= SymbolInfoDouble(_Symbol,SYMBOL_POINT);
//double  loss=MathRound((MathAbs(price-sl)/ ticksize) * ticksize );
   double  loss=MathAbs(price-sl)/point;
   m_symbol_info.NormalizePrice(loss);
   double Risk= 0.01*balance;
   if(loss!=0)
     {
      lots=MathAbs(Risk/loss);
      lots=MathFloor(lots/lotstep)*lotstep;
     }
   if(OrderCalcMargin(ORDER_TYPE_BUY,_Symbol,lots,price,margin))
     {
      double free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if(free_margin<0)
        {
         lots=0;
        }
      else
         if(free_margin<margin)
           {
            lots=lots*free_margin/margin;
            lots=MathFloor(lots/lotstep-1)*lotstep;
           }
     }
   lots=MathMax(lots,SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN));
   lots=MathMin(lots,SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX));
   return lots;
  }

//+------------------------------------------------------------------+
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume)
  {

//--- minimal allowed volume for trade operations
   double min_volume=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(volume < min_volume)
     {
      //description = StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }

//--- maximal allowed volume of trade operations
   double max_volume=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(volume>max_volume)
     {
      //description = StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }

//--- get minimal step of volume changing
   double volume_step=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   int ratio = (int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      //description = StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f", volume_step,ratio*volume_step);
      return(false);
     }

   return(true);
  }

//+------------------------------------------------------------------+
void lucroPontos()
  {
   double lucro_garantido_pontos = 100; // pontos de lucro para fechar a posição
   double prejuizo_pontos = -100; // pontos de prejuízo para fechar a posição

//if(Comentario("compra_MM_50_200"))
// {
//   Print(__FUNCTION__ "==> No podemos fazer nada aqui");
//  return;
// }

   if(PositionsTotal() > 0)
     {
      for(int i = 0; i < PositionsTotal(); i++)
        {
         if(m_position.SelectByIndex(i))
           {
            if(m_position.Symbol() == Symbol() && m_position.Magic() == InpMagic)
              {
               if(m_position.PositionType() == POSITION_TYPE_BUY || m_position.PositionType() == POSITION_TYPE_SELL)
                 {
                  double positionPriceOpen = m_position.PriceOpen();
                  double positionPriceCurrent = m_position.PriceCurrent();
                  double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
                  double positionProfitPoints = (positionPriceCurrent - positionPriceOpen) / point;

                  // Ajusta o sinal dependendo do tipo de posição
                  if(m_position.PositionType() == POSITION_TYPE_SELL)
                    {
                     positionProfitPoints = -positionProfitPoints;
                    }

                  if(positionProfitPoints >= lucro_garantido_pontos) //|| positionProfitPoints <= prejuizo_pontos)
                    {
                     bool sucesso = trade.PositionClose(m_position.Ticket());
                     if(sucesso)
                       {
                        Print("==> " __FUNCTION__ " ==> Profit em ", positionProfitPoints, " pontos, lucrinho no bolso !!!");
                       }
                     else
                       {
                        Print("==> " __FUNCTION__ " ==> Ainda não atingimos os pontos desejados, estamos em ", positionProfitPoints);
                       }
                    }
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void lucro_garantido()
  {
   double lucro_garantido = InpLucro;
//  double prejuizo = -10.00;


   if(hasOpenPositionWith(simbolo, "buyCinq"))
     {
      //Print(__FUNCTION__, " <--> Não Aplicavél ", InpMagic);
      return;
     }
   if(hasOpenPositionWith(simbolo, "sellCinq"))
     {
      // Print(__FUNCTION__, " <--> Não Aplicavél ", InpMagic);
      return;
     }

   if(PositionsTotal() > 0)
     {
      for(int i = 0; i < PositionsTotal(); i++)
        {
         if(m_position.SelectByIndex(i))
           {
            if(m_position.Symbol() == Symbol() && m_position.Magic() == InpMagic)
              {
               if(m_position.PositionType() == POSITION_TYPE_BUY || m_position.PositionType() == POSITION_TYPE_SELL)
                 {
                  double positionProfit = PositionGetDouble(POSITION_PROFIT);

                  if(positionProfit > lucro_garantido) //|| positionProfit <= prejuizo)
                    {
                     bool sucesso = trade.PositionClose(m_position.Ticket());
                     if(sucesso)
                       {
                        Print("==> "__FUNCTION__ "==> Profit em ", positionProfit, " lucrinho no bolso !!!");
                       }
                     else
                       {
                        Print("==> "__FUNCTION__"==> Ainda não atingimos os ",InpLucro," estamos em ",positionProfit);
                       }
                    }
                 }
              }
           }
        }
     }
  }

//---------------------------------- teste de cruzamento de medias
//+------------------------------------------------------------------+
/*/|                                             MovingAverages.mq5   |
//|                        Copyright 2024, MetaQuotes Software Corp. |
//|                                        https://www.mql5.com    |
//+------------------------------------------------------------------+
#property strict

// Parâmetros para médias móveis
input int maPeriod50 = 50;     // Período da média móvel rápida
input int maPeriod200 = 200;   // Período da média móvel lenta
input ENUM_MA_METHOD maMethod = MODE_SMA; // Método da média móvel (SMA, EMA, etc.)
input ENUM_APPLIED_PRICE appliedPrice = PRICE_CLOSE; // Tipo de preço utilizado

// Buffers para armazenar os valores das médias móveis
double ma50Previous, ma50Current;
double ma200Previous, ma200Current;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit50()
  {
   // Inicializa buffers
   ma50Previous = 0.0;
   ma50Current = 0.0;
   ma200Previous = 0.0;
   ma200Current = 0.0;

   // Expert inicializado com sucesso
   Print("Expert iniciado com sucesso.");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit50(const int reason)
  {
   // Função chamada quando o Expert é removido
   Print("Expert removido.");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick50()
  {
   // Calcula os valores das médias móveis

   //ma50Previous =  iMA(_Symbol,_Period,NULL, 0, maPeriod50,  0, maMethod, appliedPrice, 1);
   //ma50Current =   iMA(NULL, 0, maPeriod50,  0, maMethod, appliedPrice, 0);
  // ma200Previous = iMA(NULL, 0, maPeriod200, 0, maMethod, appliedPrice, 1);
  // ma200Current =  iMA(NULL, 0, maPeriod200, 0, maMethod, appliedPrice, 0);

   // Verifica cruzamento
   string crossoverType = CheckCrossOver(ma50Previous, ma50Current, ma200Previous, ma200Current);

   // Imprime resultado no log
   if (StringLen(crossoverType) > 0)
     {
      PrintFormat("Cruzamento detectado: %s", crossoverType);
     }
  }
//+------------------------------------------------------------------+
//| Função para verificar o cruzamento das médias móveis            |
//+------------------------------------------------------------------+
string CheckCrossOver(double ma50Prev, double ma50Curr, double ma200Prev, double ma200Curr)
  {
   if (ma50Prev < ma200Prev && ma50Curr > ma200Curr)
     {
      return "ACIMA";
     }
   else if (ma50Prev > ma200Prev && ma50Curr < ma200Curr)
     {
      return "ABAIXO";
     }
   else
     {
      return "";
     }
  }
  */
//+------------------------------------------------------------------+
bool patternsOpen()
  {
   string patterns[] =
     {
      "Double inside(3)",
      "Inside Bar(2)",
      "Outside Bar(2)",
      "Pin Bar up(3)",
      "Pin Bar down(3)",
      "Pivot Point Reversal Up(3)",
      "Pivot Point Reversal Down(3)",
      "Double Bar Low With A Higher Close(2)",
      "Double Bar High With A Lower Close(2)",
      "Close Price Reversal Up(3)",
      "Close Price Reversal Down(3)",
      "Neutral Bar(1)",
      "Force Bar Up(1)",
      "Force Bar Down(1)",
      "Mirror Bar(2)",
      "Hammer(1)",
      "Shooting Star(1)",
      "Evening Star(3)",
      "Morning Star(3)",
      "Bearish Harami(2)",
      "Bearish Harami Cross(2)",
      "Bullish Harami(2)",
      "Bullish Harami Cross(2)",
      "Dark Cloud Cover(2)",
      "Doji Star(2)",
      "Engulfing Bearish Line(2)",
      "Engulfing Bullish Line(2)",
      "Evening Doji Star(3)",
      "Morning Doji Star(3)",
      "Two Neutral Bars(2)",
      "BuyMM",
      "SellMM",
      "CrPrice",
     };

   for(int i = 0; i < ArraySize(patterns); i++)
     {
      if(Comentario(patterns[i]))
        {
         Print("Vela já comprada/Vendida ", patterns[i]);
         return true;
        }
     }
   return false;
  }
//+------------------------------------------------------------------+

 
//---------------------------------
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
            Print("<-------------->Topo Duplo");
            createObj(time, high, 233, clrWhite,"Top");
            OpenSell(0,0,"Sell");
            return 1;
        }
    }
    else if (open > close)
    {
        if (open2 < close2 && high == high2 && low == low2)
        {
          Print("<-------------->Fundo Duplo");
            createObj(time, low, 234, clrWhite,"Bottom");
            OpenBuy(0,0,"Buy");
            return -1;
        }
    }
    
    return 0;
}
//--------------------------
int topFunDuploMargem()
{
    double margem = 1; // Margem de erro de 2 pontos, você pode ajustar para 3 se quiser
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
        // Verifica se os valores estão dentro da margem de erro
        if (open2 > close2 && MathAbs(high - high2) <= margem && MathAbs(low - low2) <= margem)
        {
            Print("<-------------->Topo Duplo");
            createObj(time, high, 234, clrWhite, "Top");
            //OpenSell(0, 0, "Sell");
            return 1;
        }
    }
    else if (open > close)
    {
        // Verifica se os valores estão dentro da margem de erro
        if (open2 < close2 && MathAbs(high - high2) <= margem && MathAbs(low - low2) <= margem)
        {
            Print("<-------------->Fundo Duplo");
            createObj(time, low, 233, clrWhite, "Bottom");
            //OpenBuy(0, 0, "Buy");
            return -1;
        }
    }
    
    return 0;
}


int topFunDuploRev()
{
    double margem = 1; // Margem de erro de 1 ponto (ajuste conforme necessário)
    datetime time = iTime(_Symbol, PERIOD_CURRENT, 1);
    
    double open   =  iOpen  (_Symbol, PERIOD_CURRENT, 1);
    double high   =  iHigh  (_Symbol, PERIOD_CURRENT, 1);
    double low    =  iLow   (_Symbol, PERIOD_CURRENT, 1);
    double close  =  iClose (_Symbol, PERIOD_CURRENT, 1);
    
    double open2  =  iOpen  (_Symbol, PERIOD_CURRENT, 2);
    double high2  =  iHigh  (_Symbol, PERIOD_CURRENT, 2);
    double low2   =  iLow   (_Symbol, PERIOD_CURRENT, 2);
    double close2 =  iClose (_Symbol, PERIOD_CURRENT, 2);
    
    double open3  =  iOpen  (_Symbol, PERIOD_CURRENT, 0);
    double close3 =  iClose (_Symbol, PERIOD_CURRENT, 0);

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


void createObj(datetime time, double price, int arrawCode, color clr, string txt)
{
    string objName = " ";
    StringConcatenate(objName, "Signal@", time, " at ", DoubleToString(price, _Digits), " (", arrawCode, ")");
    if (ObjectCreate(0, objName, OBJ_ARROW, 0, time, price))
    {
        ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, arrawCode);
        ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
        if (clr == clrWhite)
            ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_TOP);
        else if (clr == clrWhite)
            ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
    }
    string candleName = objName + txt;
    if (ObjectCreate(0, candleName, OBJ_TEXT, 0, time, price))
    {
        ObjectSetString(0, candleName, OBJPROP_TEXT, " " + txt);
        ObjectSetInteger(0, candleName, OBJPROP_COLOR, clr);
    }
}

//--------------------------
void Tendencia(){

  
    
    if(rates[0].time == lastBar){
        return;
    } else {
        lastBar = rates[0].time;
    }
    // Verifica se há uma tendência de martelo (compra)
    if(rates[2].close < rates[1].open && rates[1].open < rates[1].close){
        
        Print("Verifica se há uma tendência de martelo (compra)");
        
        ObjectCreate(0, "Obj", OBJ_ARROW, 0, rates[1].time, rates[1].low);
        ObjectSetInteger(0, "Obj", OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, "Obj", OBJPROP_ARROWCODE, 233);

        
        
        
    }
    
    
}

//-------------------------
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
      OpenSell(0,0,"Topo_Duplo");
    }
  }
}

//---------------------------------
void HHLL()
{
    //|   // Candle declaration
    double High[], Low[], open[], close[];
    ArraySetAsSeries(High, true);
    ArraySetAsSeries(Low, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(open, true);
    CopyHigh(Symbol(), timeframe, 0, 1000, High);
    CopyLow(Symbol(), timeframe, 0, 1000, Low);
    CopyOpen(_Symbol, timeframe, 0, 100, open);
    CopyClose(_Symbol, timeframe, 0, 100, close);

    // Highest high and lowest low declaration

    int highest = ArrayMaximum(High, 2, 300);
    int lowest = ArrayMinimum(Low,2, 300);
    double HH = High[highest];
    Drawline("Suporte", clrRed, HH);
    double LL = Low[lowest];
    Drawline("Resistencia", clrBlue, LL);

    // Moving average declaration

    CopyBuffer(Handle_MAHH, 0, 0, 1000, MA_FilterHH);
    ArraySetAsSeries(MA_FilterHH, true);

    //|   Broker parameter

    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double spread = ask - bid;
    double stoplevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    int freezerlevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);

    //     Count bjuy and count sell

    int count_buy = 0;
    int count_sell = 0;
    //count_position(count_buy, count_sell);

    // Main condition for buy and sell

    if (count_buy == 0)
    {
      if (ask > (HH) && High[highest] > MA_FilterHH[highest])
      {
        double entryprice = ask;
        double sl = LL;
        double tp = entryprice ;
        double lotsize = calculate_lotsize(sl, entryprice);
        if (bid - sl > stoplevel && tp - bid > stoplevel && CheckVolumeValue(lotsize))
        {
         Print("Temos um compra do ll aqui");
        }
      }
    }
    if (count_sell == 0)
    {
      if (bid < (LL) && Low[lowest] < MA_FilterHH[lowest])
      {
        double entryprice = bid;
        double sl = HH;
        double tp = entryprice ;
        double lotsize = calculate_lotsize(sl, entryprice);
        if (sl - ask > stoplevel && ask - tp > stoplevel && CheckVolumeValue(lotsize))
        {
         Print("Temos uma venda do ll aqui"); 
        }
      }
    }
  
}
