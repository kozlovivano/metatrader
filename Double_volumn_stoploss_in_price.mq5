//+------------------------------------------------------------------+
//|                                              Moving_stoploss.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include<Trade\Trade.mqh>

CTrade trade;
//--- input parameters
input int      Profit = 20;   // Profit
input int      StopLoss = 20;   // Stoploss in price
input double   Volumn = 0.1;     // Volumn for transaction
input int TradeType = 0;        // Buy: 0 Sell: 1
double balance = 100000;
int CurrentTradeType = -1;
double tp = 0.0;
double sl = 0.0;
double _volumn;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
//---
   _volumn = Volumn / 2;
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      
      if((CurrentTradeType == 0) && (ask > tp)){
         ExpertRemove();
      }
      
      if((CurrentTradeType == 1) && (bid < tp)){
         ExpertRemove();
      }
      if(PositionsTotal() < 1){
         _volumn = 2 * _volumn;
         if(CurrentTradeType == 1){
            CurrentTradeType = 0;
            tp = ask + Profit / (balance * Volumn);
            sl = ask - StopLoss / (balance * Volumn);
            trade.Buy(_volumn, NULL, ask, sl, tp, NULL);
         }else if(CurrentTradeType == 0){
            CurrentTradeType = 1;
            tp = bid - Profit / (balance * Volumn);
            sl = bid + StopLoss / (balance * Volumn);
            trade.Sell(_volumn, NULL, bid, sl, tp, NULL);
         }else{
            if(TradeType == 0){
               CurrentTradeType = 0;
               tp = ask + Profit / (balance * Volumn);
               sl = ask - StopLoss / (balance * Volumn);
               trade.Buy(_volumn, NULL, ask, sl, tp, NULL);
            }else{
               CurrentTradeType = 1;
               tp = bid - Profit / (balance * Volumn);
               sl = bid + StopLoss / (balance * Volumn);
               trade.Sell(_volumn, NULL, bid, sl, tp, NULL);
            }
         }
      }

      double temp = 0.0;
      if(CurrentTradeType == 0){
         temp = ask;
      }else{
         temp = bid;
      }
      
      CheckTrailingStop(temp, tp);

  }
  
void CheckTrailingStop(double val, double t_p){
   double _sl;
   if(CurrentTradeType == 0){
      _sl = val - StopLoss / ( balance * Volumn );
   }else{
      _sl = val + StopLoss / ( balance * Volumn );
   }
   
   string symbol = PositionGetSymbol(0);
   if(_Symbol == symbol){
      ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
      double CurrentStopLoss = PositionGetDouble(POSITION_SL);
      
      if(CurrentTradeType == 0){
         if(CurrentStopLoss < _sl){
            trade.PositionModify(PositionTicket, (CurrentStopLoss + _Point), t_p);
         }
      }else{
         if(_sl < CurrentStopLoss){
            trade.PositionModify(PositionTicket, (CurrentStopLoss - _Point), t_p);
         }
      }
   }
}
//+------------------------------------------------------------------+
