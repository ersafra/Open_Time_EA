//+------------------------------------------------------------------+
//|                                          hasOpenPositionWith.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool hasOpenPositionWith(string symbol,string comment)
  {
// Obtém o número total de posições
   int positionsTotal = PositionsTotal();

// Itera pelas posições
   for(int i = 0; i < positionsTotal; i++)
     {
      // Reinicia o último erro
      ResetLastError();

      // Obtém as informações da posição
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         //string retrievedSymbol = PositionGetSymbol(i);
         string retrievedSymbol = PositionGetString(POSITION_SYMBOL);
         if(retrievedSymbol != "" && retrievedSymbol == _Symbol)    // Verifica primeiro o símbolo correspondente
           // if(Symbol() != "" && retrievedSymbol == symbol)    // Verifica primeiro o símbolo correspondente
           {
            long positionId = PositionGetInteger(POSITION_IDENTIFIER);
            double priceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
            ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            long positionMagic = PositionGetInteger(POSITION_MAGIC);
            string positionComment = PositionGetString(POSITION_COMMENT);

            // Verifica se o número mágico corresponde e o comentário corresponde (case-sensitive)
            if(positionMagic == InpMagic && positionComment == comment)
              {
               // Imprime detalhes da posição se necessário (para depuração ou registro)
                //PrintFormat("Posição #%d por %s: POSITION_MAGIC = %d, preço = %G, tipo = %s, comentário = %s",
               //positionId, symbol, positionMagic, priceOpen, EnumToString(type), positionComment);

               return true; // Posição encontrada com comentário correspondente
              }
           }
         else
           {
            // Imprime erro se a recuperação da posição falhar ou o símbolo não corresponder
            if(retrievedSymbol == "")
              {
               // PrintFormat("Erro ao recuperar a posição com índice %d. Código de erro: %d\n", i, GetLastError());
              }
            else
              {
             //  PrintFormat("Símbolo não corresponde à posição no índice %d. Símbolo recuperado: %s\n ", i, retrievedSymbol);
              }
           }
        }
     }
// Nenhuma posição encontrada com comentário correspondente
   return false;
  }

/*
bool hasOpenPositionPatern(string symbol, const ENUM_PATTERN_TYPE &pattern_type)
{
    // Obtém a descrição do padrão a partir do tipo de padrão
    string comment = patt.DescriptPattern(pattern_type);
    
    // Obtém o número total de posições
    int positionsTotal = PositionsTotal();

    // Itera pelas posições
    for(int i = 0; i < positionsTotal; i++)
    {
        // Reinicia o último erro
        ResetLastError();

        // Obtém as informações da posição
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            // Obtém o símbolo da posição
            string retrievedSymbol = PositionGetString(POSITION_SYMBOL);

            // Verifica se o símbolo corresponde
            if(retrievedSymbol != "" && retrievedSymbol == _Symbol)
            {
                // Obtém outros detalhes da posição
                long positionId = PositionGetInteger(POSITION_IDENTIFIER);
                double priceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
                ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                long positionMagic = PositionGetInteger(POSITION_MAGIC);
                string positionComment = PositionGetString(POSITION_COMMENT);

                // Verifica se o número mágico corresponde e o comentário contém algum dos padrões definidos na matriz
                for(int j = 0; j < ArraySize(ArrayNames); j++)
                {
                    if(positionMagic == InpMagic && positionComment == ArrayNames[j][1])
                    {
                        // Verifica se o comentário atual corresponde ao padrão solicitado
                        if(positionComment == comment)
                        {
                            // Posição encontrada com comentário correspondente
                            return true;
                        }
                    }
                }
            }
        }
    }
    // Nenhuma posição encontrada com comentário correspondente
    return false;
}


bool hasOpenPositionBard(string symbol, const ENUM_PATTERN_TYPE &pattern_type)
{
   // Obtém a descrição do padrão a partir do tipo de padrão
   string pattern = patt.DescriptPattern(pattern_type);

   // Obtém o número total de posições
   int positionsTotal = PositionsTotal();

   // Itera pelas posições
   for (int i = 0; i < positionsTotal; i++)
   {
      if (!PositionSelectByTicket(PositionGetTicket(i)))
         continue;

      // Verifica se o símbolo e o número mágico correspondem
      if (PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == InpMagic)
      {
         // Verifica se o comentário da posição contém o padrão desejado
         if (StringFind(PositionGetString(POSITION_COMMENT), pattern) >= 0)
            return true;
      }
   }

   // Nenhuma posição encontrada com comentário correspondente
   return false;
}
*/


