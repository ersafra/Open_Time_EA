//+------------------------------------------------------------------+
//|                                                Cruzamento3x1.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                             up3x1_Krohabor_D.mq5 |
//|                                          Copyright 2012, Integer |
//|                          https://login.mql5.com/ru/users/Integer |
//+------------------------------------------------------------------+
#property copyright "Integer"
#property link "https://login.mql5.com/ru/users/Integer"
#property description "Rewritten from MQL4. Link to the original publication - http://codebase.mql4.com/ru/337, author: izhutov (http://www.mql4.com/ru/users/izhutov)"
#property version   "1.00"



//input double MaximumRisk        = 0.05;  /*MaximumRisk*/       // Risco (usado se Lots=0)
/*input*/ double Lots               = 0.1;   /*Lots*/              // Lote
//input int    DecreaseFactor     = 0;     /*DecreaseFactor*/    // Fator de redução de lote após operações perdedoras. 0 - redução desativada. Quanto menor o valor, maior a redução. Onde não for possível reduzir o tamanho do lote, a posição mínima de lote é aberta.
/*input*/ int    TakeProfit         = 50;    /*TakeProfit*/        // Take Profit em pontos
//input int    StopLoss           = 1100;  /*StopLoss*/          // Stop Loss em pontos
/*input*/ int    TrailingStop       = 100;   /*TrailingStop*/      // Trailing Stop em pontos. Se o valor for 0, a função de Trailing Stop é desativada
/*input*/ int    FastPeriod         = 24;    /*FastPeriod*/        // Período da Média Móvel Rápida
/*input*/ int    FastShift          = 6;     /*FastShift*/         // Deslocamento da Média Móvel Rápida
/*input*/ int    MiddlePeriod       = 60;    /*MiddlePeriod*/      // Período da Média Móvel Intermediária
/*input*/ int    MiddleShift        = 6;     /*MiddleShift*/       // Deslocamento da Média Móvel Intermediária
/*input*/ int    SlowPeriod         = 120;   /*SlowPeriod*/        // Período da Média Móvel Lenta
/*input*/ int    SlowShift          = 6;     /*SlowShift*/         // Deslocamento da Média Móvel Lenta



int ma14h,ma25h,ma36h;

double f1[1],f0[1],m1[1],m0[1],s1[1],s0[1];

datetime ctm[1];
datetime LastTime;
double lote,slv,tpv;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit3x1(){

   // Calcula a Média Móvel Simples (SMA) de acordo com os períodos e deslocamentos fornecidos
   ma14h = iMA(_Symbol, PERIOD_CURRENT, FastPeriod, FastShift, MODE_SMA, PRICE_CLOSE);
   ma25h = iMA(_Symbol, PERIOD_CURRENT, MiddlePeriod, MiddleShift, MODE_SMA, PRICE_CLOSE);
   ma36h = iMA(_Symbol, PERIOD_CURRENT, SlowPeriod, SlowShift, MODE_SMA, PRICE_CLOSE);

   // Verifica se algum dos handles da média móvel é inválido
   if(ma14h == INVALID_HANDLE || ma25h == INVALID_HANDLE || ma36h == INVALID_HANDLE){
      Alert("Erro ao carregar o indicador, por favor tente novamente");
      return(-1);
   }  

   // Verifica se há erro na inicialização da informação do símbolo
   if(!m_symbol_info.Name(_Symbol)){
      Alert("Erro na inicialização do CSymbolInfo, por favor tente novamente");    
      return(-1);
   }

   // Indica que a inicialização do Expert Advisor foi concluída
   Print("Inicialização do Expert Advisor concluída");
  
   return(0);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit3x1(const int reason){
   if(ma14h!=INVALID_HANDLE)IndicatorRelease(ma14h);
   if(ma25h!=INVALID_HANDLE)IndicatorRelease(ma25h);
   if(ma36h!=INVALID_HANDLE)IndicatorRelease(ma36h);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void Ordens3x1(){

      
      // Verifica as condições para compra e venda
      bool OpBuy = OpenBuy();
      bool OpSell = OpenSell();
      
      // Abertura de ordens
      if(!m_position.Select(_Symbol)){
            // Ordem de compra
            if(OpBuy && !OpSell){
               if(!m_symbol_info.RefreshRates()) return;        
               if(!LotsOptimized(lot)) return;
               slv = NormalizeDouble(m_symbol_info.Ask() - _Point * StopLoss, _Digits);  // Calcula o Stop Loss
               tpv = NormalizeDouble(m_symbol_info.Ask() + _Point * TakeProfit, _Digits);  // Calcula o Take Profit
               trade.SetDeviationInPoints(m_symbol_info.Spread() * 3);
               if(!trade.Buy(lot, _Symbol, 0, slv, tpv, "Buy3x1")) return;
            }
            // Ordem de venda
            if(OpSell && !OpBuy){
               if(!m_symbol_info.RefreshRates()) return;        
               if(!LotsOptimized(lot)) return;
               slv = NormalizeDouble(m_symbol_info.Bid() + _Point * StopLoss, _Digits);  // Calcula o Stop Loss
               tpv = NormalizeDouble(m_symbol_info.Bid() - _Point * TakeProfit, _Digits);  // Calcula o Take Profit
               trade.SetDeviationInPoints(m_symbol_info.Spread() * 3);
               if(!trade.Sell(lot, _Symbol, 0, slv, tpv, "Sell3x1")) return;
            }
      }            
   // Função para trailing stop simples
   fSimpleTrailing();
}

//+------------------------------------------------------------------+
//| Simple Trailing function                                       |
//+------------------------------------------------------------------+
void fSimpleTrailing(){
   // Verifica se o Trailing Stop está habilitado
   if(TrailingStop <= 0){
      return;
   }

   // Seleciona a posição do símbolo atual
   if(!m_position.Select(_Symbol)){
      return;
   }

   // Atualiza as taxas de mercado
   if(!m_symbol_info.RefreshRates()){
      return;  
   }

   double nsl, tmsl, psl;  // Variáveis para novos níveis de stop loss e verificações

   // Verifica o tipo de posição (compra ou venda)
   switch(m_position.PositionType()){
      case POSITION_TYPE_BUY:  // Para posições de compra
         nsl = NormalizeDouble(m_symbol_info.Bid() - _Point * TrailingStop, _Digits);  // Calcula o novo stop loss
            if(nsl >= NormalizeDouble(m_position.PriceOpen(), _Digits)){  // Verifica se o novo stop loss está acima do preço de abertura
               if(nsl > NormalizeDouble(m_position.StopLoss(), _Digits)){  // Verifica se o novo stop loss é maior que o atual
                  tmsl = NormalizeDouble(m_symbol_info.Bid() - _Point * m_symbol_info.StopsLevel(), _Digits);  // Calcula o nível mínimo permitido de stop loss
                     if(nsl < tmsl){  // Verifica se o novo stop loss está dentro do nível permitido
                        trade.PositionModify(_Symbol, nsl, m_position.TakeProfit());  // Modifica a posição para aplicar o novo stop loss
                     }
               }
            }
      break;

      case POSITION_TYPE_SELL:  // Para posições de venda
         nsl = NormalizeDouble(m_symbol_info.Ask() + _Point * TrailingStop, _Digits);  // Calcula o novo stop loss
            if(nsl <= NormalizeDouble(m_position.PriceOpen(), _Digits)){  // Verifica se o novo stop loss está abaixo do preço de abertura
               psl = NormalizeDouble(m_position.StopLoss(), _Digits);  // Obtém o stop loss atual
                  if(nsl < psl || psl == 0){  // Verifica se o novo stop loss é menor ou se não há stop loss definido
                     tmsl = NormalizeDouble(m_symbol_info.Ask() + _Point * m_symbol_info.StopsLevel(), _Digits);  // Calcula o nível mínimo permitido de stop loss
                        if(nsl > tmsl){  // Verifica se o novo stop loss está dentro do nível permitido
                           trade.PositionModify(_Symbol, nsl, m_position.TakeProfit());  // Modifica a posição para aplicar o novo stop loss
                        }
                  }
            }
      break;
   }
}

//+------------------------------------------------------------------+
//| Function for getting indicator values                           |
//+------------------------------------------------------------------+
bool Indicators(){

   // Copia os valores dos buffers das médias móveis
   if(
      // Copia o valor da média móvel rápida (MA14) na penúltima barra e na última barra
      CopyBuffer(ma14h, 0, 1, 1, f1) == -1 ||  
      CopyBuffer(ma14h, 0, 0, 1, f0) == -1 ||  

      // Copia o valor da média móvel intermediária (MA25) na penúltima barra e na última barra
      CopyBuffer(ma25h, 0, 1, 1, m1) == -1 ||  
      CopyBuffer(ma25h, 0, 0, 1, m0) == -1 ||  

      // Copia o valor da média móvel lenta (MA36) na penúltima barra e na última barra
      CopyBuffer(ma36h, 0, 1, 1, s1) == -1 ||  
      CopyBuffer(ma36h, 0, 0, 1, s0) == -1  
   ){
      return(false);  // Se houver erro ao copiar os buffers, retorna falso
   }  

   return(true);  // Se tudo correr bem, retorna verdadeiro
}


//+------------------------------------------------------------------+
//|   Function for determining buy signals                           |
//+------------------------------------------------------------------+
bool OpenBuy(){
  
   // Verifica se a Média Móvel Rápida cruzou a Média Móvel Intermediária para cima
   bool FastCrossMidUp = (f0[0] > m0[0] && f1[0] < m1[0]);
   
   // Verifica se a Média Móvel Rápida está acima da Média Móvel Lenta e também estava na barra anterior
   bool FastMoreSlow = (f0[0] > s0[0] && f0[0] > s1[0] && f1[0] > s0[0] && f1[0] > s1[0]);
   
   // Verifica se a Média Móvel Intermediária está acima da Média Móvel Lenta e também estava na barra anterior
   bool MiddMoreSlow = (m0[0] > s0[0] && m0[0] > s1[0] && m1[0] > s0[0] && m1[0] > s1[0]);

   return (FastCrossMidUp && FastMoreSlow && MiddMoreSlow);

   /*
   
   A MA rápida cruzou a MA intermediária para cima.

   A MA rápida está acima da MA lenta,
   a MA rápida está acima da MA lenta na barra anterior,
   a MA rápida na barra anterior está acima da MA lenta,
   a MA rápida na barra anterior está acima da MA lenta da barra anterior.

   A MA intermediária está acima da MA lenta,
   a MA intermediária está acima da MA lenta na barra anterior,
   a MA intermediária na barra anterior está acima da MA lenta,
   a MA intermediária na barra anterior está acima da MA lenta da barra anterior.
   
   */
}  


//+------------------------------------------------------------------+
//|   Function for determining sell signals                           |
//+------------------------------------------------------------------+
bool OpenSell(){

   // Verifica se a Média Móvel Rápida cruzou a Média Móvel Intermediária para baixo
   bool FastCrossMidDn = (f0[0] < m0[0] && f1[0] > m1[0]);

   // Verifica se a Média Móvel Rápida está abaixo da Média Móvel Lenta e também estava na barra anterior
   bool FastLessSlow = (f0[0] < s0[0] && f0[0] < s1[0] && f1[0] < s0[0] && f1[0] < s1[0]);

   // Verifica se a Média Móvel Intermediária está abaixo da Média Móvel Lenta e também estava na barra anterior
   bool MiddLessSlow = (m0[0] < s0[0] && m0[0] < s1[0] && m1[0] < s0[0] && m1[0] < s1[0]);

   return (FastCrossMidDn && FastLessSlow && MiddLessSlow);

   /*
   
   A MA rápida cruzou a MA intermediária para baixo.

   A MA rápida está abaixo da MA lenta,
   a MA rápida está abaixo da MA lenta na barra anterior,
   a MA rápida na barra anterior está abaixo da MA lenta,
   a MA rápida na barra anterior está abaixo da MA lenta da barra anterior.

   A MA intermediária está abaixo da MA lenta,
   a MA intermediária está abaixo da MA lenta na barra anterior,
   a MA intermediária na barra anterior está abaixo da MA lenta,
   a MA intermediária na barra anterior está abaixo da MA lenta da barra anterior.
   
   */
}


//+------------------------------------------------------------------+
//|   Function for determining the lot based on the trade results               |
//+------------------------------------------------------------------+
bool LotsOptimized(double &aLots){
   // Se o tamanho do lote (Lots) for 0, calcula o lote otimizado com base na margem livre e no risco máximo
   if(Lots == 0){
      aLots = fLotsNormalize(AccountInfoDouble(ACCOUNT_FREEMARGIN) * MaximumRisk / 1000.0);        
   }
   else{
      aLots = Lots;  // Caso contrário, usa o valor definido na variável Lots
   }

   // Se o fator de redução (DecreaseFactor) for 0 ou negativo, não há redução, retorna verdadeiro
   if(DecreaseFactor <= 0){
      return(true);
   }

   // Seleciona o histórico de negociações até o momento atual
   if(!HistorySelect(0, TimeCurrent())){
      return(false);  // Se não conseguir selecionar o histórico, retorna falso
   }

   int losses = 0;  // Variável para contar o número de negociações com prejuízo

   // Percorre o histórico de negociações
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--){
      if(!m_deal.SelectByIndex(i)) return(false);  // Seleciona a negociação pelo índice

      // Ignora negociações que não sejam de compra ou venda
      if(m_deal.DealType() != DEAL_TYPE_BUY && m_deal.DealType() != DEAL_TYPE_SELL) continue;

      // Ignora negociações que ainda estejam abertas (não fechadas)
      if(m_deal.Entry() != DEAL_ENTRY_OUT) continue;

      // Se a negociação foi lucrativa, para a contagem
      if(m_deal.Profit() > 0) break;

      // Se a negociação foi com prejuízo, incrementa o contador de perdas
      if(m_deal.Profit() < 0) losses++;
   }

   // Se houver mais de uma negociação com prejuízo, ajusta o tamanho do lote
   if(losses > 1){
      aLots = fLotsNormalize(aLots - aLots * losses / DecreaseFactor);      
   }

   return(true);  // Retorna verdadeiro se a função foi executada corretamente
}

//+------------------------------------------------------------------+
//|   Função de normalização do lote                                  |
//+------------------------------------------------------------------+
double fLotsNormalize(double aLots){
   // Subtrai o volume mínimo permitido do símbolo
   aLots -= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   // Divide pelo passo de volume do símbolo
   aLots /= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   // Arredonda o valor para o inteiro mais próximo
   aLots = MathRound(aLots);

   // Multiplica novamente pelo passo de volume
   aLots *= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   // Adiciona o volume mínimo permitido do símbolo
   aLots += SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   // Normaliza o valor do lote para 2 casas decimais
   aLots = NormalizeDouble(aLots, 2);

   // Garante que o valor não exceda o volume máximo permitido
   aLots = MathMin(aLots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));

   // Garante que o valor não seja menor que o volume mínimo permitido
   aLots = MathMax(aLots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));  

   // Retorna o valor do lote normalizado
   return(aLots);
}
