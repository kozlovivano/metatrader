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
input double   Volume=0.1;
input int      Takeprofit;
input int      Stoploss;
input int      Openpoint;

CTrade trade;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
    // Point value
    Print("Point: ", _Point);
    
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

}
//+------------------------------------------------------------------+
//Follow me on https://github.com/laguna99999
