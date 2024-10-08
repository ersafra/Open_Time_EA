//+------------------------------------------------------------------+
//|                                           SuporteResistencia.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#define resLine "RESISTANCE LEVEL"
#define colorRes clrRed
#define resline_prefix "R"


#define supLine "SUPPORT LEVEL"
#define colorSup clrBlue
#define supline_prefix "S"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void suporteResistencia()
  {
//---

   int currBars = iBars(_Symbol,_Period);
   static int prevBars = currBars;
   if(prevBars == currBars)
      return;
   prevBars = currBars;

   int visible_bars = (int)ChartGetInteger(0,CHART_VISIBLE_BARS);
   bool stop_processing = false; // Flag to control outer loop
   bool matchFound_high1 = false, matchFound_low1 = false;
   bool matchFound_high2 = false, matchFound_low2 = false;

   ArrayFree(pricesHighest);
   ArrayFree(pricesLowest);

   int copiedBarsHighs = CopyHigh(_Symbol,_Period,1,visible_bars,pricesHighest);
   int copiedBarsLows = CopyLow(_Symbol,_Period,1,visible_bars,pricesLowest);


   ArraySort(pricesHighest);
   ArraySort(pricesLowest);

   ArrayRemove(pricesHighest,10,WHOLE_ARRAY);
   ArrayRemove(pricesLowest,0,visible_bars-10);


   for(int i=1; i<=visible_bars-1 && !stop_processing; i++)
     {

      double open = iOpen(_Symbol,_Period,i);
      double high = iHigh(_Symbol,_Period,i);
      double low = iLow(_Symbol,_Period,i);
      double close = iClose(_Symbol,_Period,i);
      datetime time = iTime(_Symbol,_Period,i);

      int diff_i_j = 10;

      for(int j=i+diff_i_j; j<=visible_bars-1; j++)
        {

         double open_j = iOpen(_Symbol,_Period,j);
         double high_j = iHigh(_Symbol,_Period,j);
         double low_j = iLow(_Symbol,_Period,j);
         double close_j = iClose(_Symbol,_Period,j);
         datetime time_j = iTime(_Symbol,_Period,j);

         // CHECK FOR RESISTANCE
         double high_diff = NormalizeDouble((MathAbs(high-high_j)/_Point),0);
         bool is_resistance = high_diff <= 10;

         // CHECK FOR SUPPORT
         double low_diff = NormalizeDouble((MathAbs(low-low_j)/_Point),0);
         bool is_support = low_diff <= 10;

         if(is_resistance)
           {
            for(int k=0; k<ArraySize(pricesHighest); k++)
              {
               if(pricesHighest[k]==high)
                 {
                  matchFound_high1 = true;        
                 }
               if(pricesHighest[k]==high_j)
                 {
                  matchFound_high2 = true;           
                 }
               if(matchFound_high1 && matchFound_high2)
                 {
                  if(resistanceLevels[0]==high || resistanceLevels[1]==high_j)
                    {
                     //Print("CONFIRMADO, MAS Este é o mesmo nível de resistência, pule a atualização!");
                     stop_processing = true; // Set the flag to stop processing
                     break; // stop the inner loop prematurily
                    }
                  else
                    {
                     //Print(" ++++++++++ NÍVEIS DE RESISTÊNCIA CONFIRMADOS NAS BARRAS ",i,
                          // "(",high,") & ",j,"(",high_j,")");
                     resistanceLevels[0] = high;
                     resistanceLevels[1] = high_j;
                     //ArrayPrint(resistanceLevels);

                     draw_S_R_Level(resLine,high,colorRes,5);
                     draw_S_R_Level_Point(resline_prefix,high,time,218,-1,colorRes,90);
                     draw_S_R_Level_Point(resline_prefix,high,time_j,218,-1,colorRes,90);

                     stop_processing = true; // Set the flag to stop processing
                     break;
                    }
                 }
              }
           }

         else
            if(is_support)
              {
               for(int k=0; k<ArraySize(pricesLowest); k++)
                 {
                  if(pricesLowest[k]==low)
                    {
                     matchFound_low1 = true;
                     
                    }
                  if(pricesLowest[k]==low_j)
                    {
                     matchFound_low2 = true;
                     
                    }
                  if(matchFound_low1 && matchFound_low2)
                    {
                     if(supportLevels[0]==low || supportLevels[1]==low_j)
                       {
                       // Print("CONFIRMADO, Mas este é o mesmo nível de suporte, pule a atualização!");
                        stop_processing = true; // Set the flag to stop processing
                        break; // stop the inner loop prematurely
                       }
                     else
                       {
                        //Print(" ++++++++++ NÍVEIS DE SUPORTE CONFIRMADOS NAS BARRAS ",i,
                              //"(",low,") & ",j,"(",low_j,")");
                        supportLevels[0] = low;
                        supportLevels[1] = low_j;
                        //ArrayPrint(supportLevels);

                        draw_S_R_Level(supLine,low,colorSup,5);
                        draw_S_R_Level_Point(supline_prefix,low,time,217,1,colorSup,-90);
                        draw_S_R_Level_Point(supline_prefix,low,time_j,217,1,colorSup,-90);

                        stop_processing = true; // Set the flag to stop processing
                        break;
                       }
                    }
                 }
              }
         if(stop_processing)
           {
            break;
           }
        }
      if(stop_processing)
        {
         break;
        }
     }
   if(ObjectFind(0,resLine) >= 0)
     {
      double objPrice = ObjectGetDouble(0,resLine,OBJPROP_PRICE);
      double visibleHighs[];
      ArraySetAsSeries(visibleHighs,true);
      CopyHigh(_Symbol,_Period,1,visible_bars,visibleHighs);
      
      bool matchHighFound = false;

      for(int i=0; i<ArraySize(visibleHighs); i++)
        {
         if(visibleHighs[i] == objPrice)
           {
            //Print("> Preço correspondente à resistência encontrada na barra # ",i+1," (",objPrice,")");
            matchHighFound = true;
            break;
           }
        }
      if(!matchHighFound)
        {
         //Print("(",objPrice,") > Preço correspondente para a linha de resistência não encontrado. Excluir!");
         deleteLevel(resLine);
        }
     }

   if(ObjectFind(0,supLine) >= 0)
     {
      double objPrice = ObjectGetDouble(0,supLine,OBJPROP_PRICE);
      double visibleLows[];
      ArraySetAsSeries(visibleLows,true);
      CopyLow(_Symbol,_Period,1,visible_bars,visibleLows);
      
      bool matchLowFound = false;

      for(int i=0; i<ArraySize(visibleLows); i++)
        {
         if(visibleLows[i] == objPrice)
           {
            //Print("> Preço correspondente ao suporte encontrado na barra # ",i+1," (",objPrice,")");
            matchLowFound = true;
            break;
           }
        }
      if(!matchLowFound)
        {
        // Print("(",objPrice,") > Preço correspondente para a linha de suporte não encontrado. Excluir!");
         deleteLevel(supLine);
        }
     }

//fim compra suporte
}
//+------------------------------------------------------------------+
void draw_S_R_Level(string levelName,double price,color clr,int width)
  {
   if(ObjectFind(0,levelName) < 0)
     {
      ObjectCreate(0,levelName,OBJ_HLINE,0,TimeCurrent(),price);
      ObjectSetInteger(0,levelName,OBJPROP_COLOR,clr);
      ObjectSetInteger(0,levelName,OBJPROP_WIDTH,width);
     }
   else
     {
      ObjectSetDouble(0,levelName,OBJPROP_PRICE,price);
     }
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void deleteLevel(string levelName)
  {
   ObjectDelete(0,levelName);
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void draw_S_R_Level_Point(string objName,double price,datetime time,
                          int arrowcode,int direction,color clr,double angle)
  {
//objName = " ";
   StringConcatenate(objName,objName," @ \nTempo: ",time,"\nPreço: ",DoubleToString(price,_Digits));
   if(ObjectCreate(0,objName,OBJ_ARROW,0,time,price))
     {
      ObjectSetInteger(0,objName,OBJPROP_ARROWCODE,arrowcode);
      ObjectSetInteger(0,objName,OBJPROP_COLOR,clr);
      ObjectSetInteger(0,objName,OBJPROP_FONTSIZE,10);
      if(direction > 0)
         ObjectSetInteger(0,objName,OBJPROP_ANCHOR,ANCHOR_TOP);
      if(direction < 0)
         ObjectSetInteger(0,objName,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
     }
   string prefix = resline_prefix;
   string txt = "\n"+prefix+"("+DoubleToString(price,_Digits)+")";
   string objNameDescription = objName + txt;
   if(ObjectCreate(0,objNameDescription,OBJ_TEXT,0,time,price))
     {
      // ObjectSetString(0,objNameDescription,OBJPROP_TEXT, "" + txt);
      ObjectSetInteger(0,objNameDescription,OBJPROP_COLOR,clr);
      ObjectSetDouble(0,objNameDescription,OBJPROP_ANGLE, angle);
      ObjectSetInteger(0,objNameDescription,OBJPROP_FONTSIZE,5);
      if(direction > 0)
        {
         ObjectSetInteger(0,objNameDescription,OBJPROP_ANCHOR,ANCHOR_LEFT);
         ObjectSetString(0,objNameDescription,OBJPROP_TEXT, "    " + txt);
        }
      if(direction < 0)
        {
         ObjectSetInteger(0,objNameDescription,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
         ObjectSetString(0,objNameDescription,OBJPROP_TEXT, "    " + txt);
        }
     }
   ChartRedraw(0);
  }
//+------------------------------------------------------------------+


bool HLineCreate(const long            chart_ID=0,        // ID de gráfico
                 const string          name="HLine",      // nome da linha
                 const int             sub_window=0,      // índice da sub-janela
                 double                price=0,           // line price
                 const color           clr=clrRed,        // cor da linha
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // estilo da linha
                 const int             width=1,           // largura da linha
                 const bool            back=false,        // no fundo
                 const bool            selection=true,    // destaque para mover
                 const bool            hidden=true,       //ocultar na lista de objetos
                 const long            z_order=0)         // prioridade para clique do mouse
  {
//--- se o preço não está definido, defina-o no atual nível de preço Bid
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- redefine o valor de erro
   ResetLastError();
//--- criar um linha horizontal
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price))
     {
      Print(__FUNCTION__,
            ": falha ao criar um linha horizontal! Código de erro = ",GetLastError());
      return(false);
     }
//--- definir cor da linha
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- definir o estilo de exibição da linha
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- definir a largura da linha
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- exibir em primeiro plano (false) ou fundo (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- habilitar (true) ou desabilitar (false) o modo do movimento da seta com o mouse
//--- ao criar um objeto gráfico usando a função ObjectCreate, o objeto não pode ser
//--- destacado e movimentado por padrão. Dentro deste método, o parâmetro de seleção
//--- é verdade por padrão, tornando possível destacar e mover o objeto
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- ocultar (true) ou exibir (false) o nome do objeto gráfico na lista de objeto 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- definir a prioridade para receber o evento com um clique do mouse no gráfico
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- sucesso na execução
   return(true);
  }