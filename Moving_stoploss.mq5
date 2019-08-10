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
input int      StopLoss = 20;   // Stoploss in point
input double   Volumn = 0.1;     // Volumn for transaction
input int TradeType = 0;        // Buy: 0 Sell: 1
int CurrentTradeType = -1;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
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
      
      if(PositionsTotal() < 1){
         if(CurrentTradeType == 1){
            CurrentTradeType = 0;
            trade.Buy(Volumn, NULL, ask, (ask - StopLoss * _Point), 0, NULL);
         }else if(CurrentTradeType == 0){
            CurrentTradeType = 1;
            trade.Sell(Volumn, NULL, bid, (bid + StopLoss * _Point), 0, NULL);
         }else{
            if(TradeType == 0){
               CurrentTradeType = 0;
               trade.Buy(Volumn, NULL, ask, (ask - StopLoss * _Point), 0, NULL);
            }else{
               CurrentTradeType = 1;
               trade.Sell(Volumn, NULL, bid, (bid + StopLoss * _Point), 0, NULL);
            }
         }
      }

     if(CurrentTradeType == 0){
         temp = ask;
      }else{
         temp = bid;
      }
      
      CheckTrailingStop(temp);

  }
  
void CheckTrailingStop(double val){
   double sl;
   if(CurrentTradeType == 0){
      sl = val - StopLoss * _Point;
   }else{
      sl = val + StopLoss * _Point;
   }
   
   string symbol = PositionGetSymbol(0);
   if(_Symbol == symbol){
      ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
      double CurrentStopLoss = PositionGetDouble(POSITION_SL);
      
      if(CurrentTradeType == 0){
         if(CurrentStopLoss < sl){
            trade.PositionModify(PositionTicket, (CurrentStopLoss + _Point), 0);
         }
      }else{
         if(sl < CurrentStopLoss){
            trade.PositionModify(PositionTicket, (CurrentStopLoss - _Point), 0);
         }
      }
   }
}
//+------------------------------------------------------------------+
