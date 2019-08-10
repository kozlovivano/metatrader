//+------------------------------------------------------------------+
//|                                                   08_10_2019.mq5 |
//|                                                           laguna |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "laguna"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include<Trade\Trade.mqh>
//--- input parameters
input double   Volume = 0.1;
input int      Takeprofit = 20;
input int      Stoploss = 20;
input int      Pips = 20;

CTrade trade;

double past_ask = 0.0;
double past_bid = 0.0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
    ulong  ticket;
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    double tp = 0.0;
    double sl = 0.0;
    double price = 0.0;
    if(((bid - past_ask) > Pips * _Point) || ((past_bid - ask) > Pips * _Point)){

        uint total = OrdersTotal();

        if((bid - past_ask) > Pips * _Point){
            ticket = OrderGetTicket(total - 1);
        }else{
            ticket =  OrderGetTicket(0);
        }
        trade.OrderDelete(ticket);
        Print("Order ticket deleted: ", ticket);
        //Print("Order ticket to be delete: ", ticket);
        Print("////////////////////////////////////////////////////");
        Print("Long point.");
        tp = ask + Takeprofit * _Point;
        sl = bid - Stoploss * _Point;
        price = ask + Pips * _Point;
        trade.Buy(Volume, NULL, ask, sl, tp, NULL);
        trade.BuyStop(Volume, price, NULL, price - Stoploss * _Point, price + Takeprofit * _Point);

        Print("Short point");
        tp = bid - Takeprofit * _Point;
        sl = ask + Stoploss * _Point;
        price = bid - Pips * _Point;
        trade.Sell(Volume, NULL, bid, sl, tp, NULL);
        trade.SellStop(Volume, price, NULL, price + Stoploss * _Point, price - Takeprofit * _Point);

        past_ask = ask;
        past_bid = bid;
    }else{
        Print("Status maintaining...");
    }
}
//+------------------------------------------------------------------+
//Follow me on https://github.com/laguna99999
