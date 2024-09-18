//+------------------------------------------------------------------+
//|                                            EA_MT5_Telegram_5.mq5 |
//|                                Rafaelfvcs 2021, Analistas Quant. |
//|                        https://crieseurobocommql5.wordpress.com/ |
//+------------------------------------------------------------------+
#property copyright "Rafaelfvcs 2021, Analistas Quant."
#property link      "https://crieseurobocommql5.wordpress.com/"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input string Token = "7539029827:AAHNszvodHcNcNfG214LXiXC68Mb4DgIfIg"; // Token Telegram

//---
#include <Telegram.mqh>
#include <Trade/Trade.mqh>

//---
CTrade            trade; //  Clase para envio e manipulações de Ordens e posições
//---

class CMyBot: public CCustomBot
  {
  
public:
   //+------------------------------------------------------------------+       
   void ProcessMessages(void)
     {
      
      for(int i=0;i<m_chats.Total();i++)
        {
         CCustomChat *chat=m_chats.GetNodeAtIndex(i);
         if(!chat.m_new_one.done)
           {
            chat.m_new_one.done=true;
            string text=chat.m_new_one.message_text;
            
            if(text =="/start" || text =="/help")
              {
               bot.SendMessage(chat.m_id,"Olá, seja bem vindo(a) ao robô MT5 Telegram");
              }
            if( text == "/comprar" )
              {
                Print("Vai tentar uma compra");
                if( !PositionSelect(_Symbol) )
                  {
                      compraMercado(0,0,0.1);
                      bot.SendMessage(chat.m_id,"Robô tentou comprar");
                  }
              }
            if(text == "/vender")
              {
                Print("Vai tentar uma venda");
                if( !PositionSelect(_Symbol) )
                  {
                      vendaMercado(0,0,0.1);
                      bot.SendMessage(chat.m_id,"Robô tentou vender");
                  }
              }
            if(text == "/fechar") // Fechar posição
              {
                  Print("Vai tentar fechar");
                  if( PositionSelect(_Symbol) )
                    {
                       fechaPosicao(PositionGetTicket(0));
                       bot.SendMessage(chat.m_id,"Robô tentou fechar");
                    }
              } 
           }
        }
     
     }
  };
//---
CMyBot bot; // Objeto para acessa a API do Telegram

int getme_result; // Variável para avaliar se a conexão funcionou

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(1); // Requisitar a função OnTimer de 1 em 1 segundo!
      
   bot.Token(Token); // Conectar Token com a API do Telegram
   
   getme_result = bot.GetMe(); // Fazer primeiro contato com o bot do telegram
   
   Print("Funcionou a conexão = ", getme_result); // se getme_result = 0 (zero), deu tudo certo
   Print("Nome do robô: ",bot.Name() ); // Retorna nome do Robô
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   // Podemos remover essa função OnTick() sem problemas
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
    if( getme_result != 0 ) // se diferente de zero é pq tivermos um erro!
     {
      Comment("Erro: ", GetErrorDescription(getme_result) );
      return;
     }else
        {
           bot.GetUpdates(); // coleta atualizações feitas no robô do Telegram
           
           bot.ProcessMessages(); // Rastrei comandos digitados pelos usuários do bot Telegram
        }

  }

//+------------------------------------------------------------------+
//|     Funções para envio de ordens                                 |
//+------------------------------------------------------------------+
void compraMercado(double tk, double sl, double num_lots = 20)
   {
        trade.Buy(num_lots,_Symbol,0,sl,tk);
                          
        if(trade.ResultRetcode() == 10008 || trade.ResultRetcode() == 10009)
          {
           Print("==> ORDEM DE COMPRA EXECUTADA COM SUCESSO !!");
          }
        else
          {
           Print("Erro ao EXECUTAR Ordem de Compra a mercado. Erro = ", GetLastError());
           ResetLastError();
          }
   }
//---
void vendaMercado(double tk, double sl, double num_lots = 20)
   {
        trade.Sell(num_lots,_Symbol,0,sl,tk);
                               
        if(trade.ResultRetcode() == 10008 || trade.ResultRetcode() == 10009)
          {
           Print("==> ORDEM DE VENDA EXECUTADA COM SUCESSO !!");
          }
        else
          {
           Print("Erro ao EXECUTAR Ordem de Venda a mercado. Erro = ", GetLastError());
           ResetLastError();
          }
   }   
//---
void fechaPosicao(ulong position_ticket)
   {
       Print("Fechamento da posição : ", position_ticket);
       trade.PositionClose(position_ticket); 
       if(trade.ResultRetcode() == 10009) // 10009 TRADE_RETCODE_DONE - Solicitação concluída
          {
           Print("==> ORDEM FECHADA COM SUCESSO !!");
          }
         else
          {
           Print("Erro ao FECHADA Ordem. Erro = ", GetLastError());
           ResetLastError();
          }

   }
   
   //---------------------
//comprar EURUSD Ct 0.5 Tk 50 Sl 25    = Exemplo de mensagem

void NewProcessMessages(void)
{
   for(int i = 0; i < m_chats.Total(); i++)
   {
      CCustomChat *chat = m_chats.GetNodeAtIndex(i);
      if(!chat.m_new_one.done)
      {
         chat.m_new_one.done = true;
         string text = chat.m_new_one.message_text;
         
         // Separar a mensagem em partes
         string parts[];
         StringSplit(text, ' ', parts);

         // Verificar se o comando é "/comprar" ou "/vender"
         if(parts[0] == "/comprar" || parts[0] == "/vender")
         {
            string ativo = parts[1];  // Ativo (ex: EURUSD)
            double contratos = 0.1;   // Default para contratos
            double takeProfit = 0;    // Default para Take Profit
            double stopLoss = 0;      // Default para Stop Loss

            // Loop para ler Ct, Tk e Sl da mensagem
            for(int j = 2; j < ArraySize(parts); j++)
            {
               if(StringFind(parts[j], "Ct") != -1)
               {
                  contratos = StringToDouble(parts[j+1]);
               }
               if(StringFind(parts[j], "Tk") != -1)
               {
                  takeProfit = StringToDouble(parts[j+1]);
               }
               if(StringFind(parts[j], "Sl") != -1)
               {
                  stopLoss = StringToDouble(parts[j+1]);
               }
            }

            if(parts[0] == "/comprar")
            {
               Print("Vai tentar uma compra no ativo " + ativo);
               if(!PositionSelect(ativo))
               {
                  if(compraMercado(contratos, stopLoss, takeProfit))
                     bot.SendMessage(chat.m_id, "Compra realizada com sucesso no ativo " + ativo);
                  else
                     bot.SendMessage(chat.m_id, "Erro ao tentar comprar " + ativo);
               }
               else
               {
                  bot.SendMessage(chat.m_id, "Já existe uma posição aberta para " + ativo);
               }
            }

            if(parts[0] == "/vender")
            {
               Print("Vai tentar uma venda no ativo " + ativo);
               if(!PositionSelect(ativo))
               {
                  if(vendaMercado(contratos, stopLoss, takeProfit))
                     bot.SendMessage(chat.m_id, "Venda realizada com sucesso no ativo " + ativo);
                  else
                     bot.SendMessage(chat.m_id, "Erro ao tentar vender " + ativo);
               }
               else
               {
                  bot.SendMessage(chat.m_id, "Já existe uma posição aberta para " + ativo);
               }
            }
         }
         
         // Verificar outros comandos como "/start" ou "/help"
         else if(text == "/start" || text == "/help")
         {
            bot.SendMessage(chat.m_id, "Olá, seja bem vindo(a) ao robô MT5 Telegram");
         }
         
         // Comando para fechar posição
         else if(text == "/fechar")
         {
            string ativo = parts[1]; // Assumindo que a mensagem também inclui o ativo para fechar
            Print("Vai tentar fechar posição no ativo " + ativo);
            if(PositionSelect(ativo))
            {
               if(fechaPosicao(PositionGetTicket(0)))
                  bot.SendMessage(chat.m_id, "Posição fechada com sucesso no ativo " + ativo);
               else
                  bot.SendMessage(chat.m_id, "Erro ao tentar fechar a posição no ativo " + ativo);
            }
            else
            {
               bot.SendMessage(chat.m_id, "Nenhuma posição aberta para " + ativo + " para fechar.");
            }
         }
      }
   }
}
