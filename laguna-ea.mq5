//+------------------------------------------------------------------+
//|                                                  laguna_ea.mq5 |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//--- input parameters
input int      StopLoss=8;      // Stop Loss
int      TakeProfit=100;   // Take Profit
input int      ADX_Period=4;     // ADX Period
input int      MA_Period=4;      // Moving Average Period
input int      EA_Magic=12345;   // EA Magic Number
input double   Adx_Min=22.0;     // Minimum ADX Value
input double   Lot=0.1;          // Lots to Trade
//--- Other parameters
int adxHandle; // handle for our ADX indicator
int maHandle;  // handle for our Moving Average indicator
double plsDI[],minDI[],adxVal[]; // Dynamic arrays to hold the values of +DI, -DI and ADX values for each bars
double maVal[]; // Dynamic array to hold the values of Moving Average for each bars
double p_close, CSTL, ESTL, current_top; // Variable to store the close value of a bar
int STP, TKP;   // To be used for Stop Loss & Take Profit values
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   current_top = 0;
//--- Get handle for ADX indicator
   adxHandle=iADX(NULL,0,ADX_Period);
//--- Get the handle for Moving Average indicator
   maHandle=iMA(_Symbol,_Period,MA_Period,0,MODE_EMA,PRICE_CLOSE);
//--- What if handle returns Invalid Handle
   if(adxHandle<0 || maHandle<0)
     {
      Alert("Error Creating Handles for indicators - error: ",GetLastError(),"!!");
      return(-1);
     }

//--- Let us handle currency pairs with 5 or 3 digit prices instead of 4
   STP = StopLoss;
   TKP = TakeProfit;
   CSTL = 0;
   ESTL = 0;
   if(_Digits==5 || _Digits==3)
     {
      //STP = STP*10;
      //TKP = TKP*10;
     }
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- Release our indicator handles
   IndicatorRelease(adxHandle);
   IndicatorRelease(maHandle);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
     
//--- Do we have enough bars to work with
   if(Bars(_Symbol,_Period)<60) // if total bars is less than 60 bars
     {
      Alert("We have less than 60 bars, EA will now exit!!");
      return;
     }  

// We will use the static Old_Time variable to serve the bar time.
// At each OnTick execution we will check the current bar time with the saved one.
// If the bar time isn't equal to the saved time, it indicates that we have a new tick.

   static datetime Old_Time;
   datetime New_Time[1];
   bool IsNewBar=false;

// copying the last bar time to the element New_Time[0]
   int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
   if(copied>0) // ok, the data has been copied successfully
     {
      if(Old_Time!=New_Time[0]) // if old time isn't equal to new bar time
        {
         IsNewBar=true;   // if it isn't a first call, the new bar has appeared
         if(MQL5InfoInteger(MQL5_DEBUGGING)) Print("We have new bar here ",New_Time[0]," old time was ",Old_Time);
         Old_Time=New_Time[0];            // saving bar time
        }
     }
   else
     {
      Alert("Error in copying historical times data, error =",GetLastError());
      ResetLastError();
      return;
     }

//--- EA should only check for new trade if we have a new bar
   //if(IsNewBar==false)
   //  {
   //   return;
   //  }
 
//--- Do we have enough bars to work with
   int Mybars=Bars(_Symbol,_Period);
   if(Mybars<60) // if total bars is less than 60 bars
     {
      Alert("We have less than 60 bars, EA will now exit!!");
      return;
     }

//--- Define some MQL5 Structures we will use for our trade
   MqlTick latest_price;      // To be used for getting recent/latest price quotes
   MqlTradeRequest mrequest;  // To be used for sending our trade requests
   MqlTradeResult mresult;    // To be used to get our trade results
   MqlRates mrate[];          // To be used to store the prices, volumes and spread of each bar
   ZeroMemory(mrequest);      // Initialization of mrequest structure
/*
     Let's make sure our arrays values for the Rates, ADX Values and MA values 
     is store serially similar to the timeseries array
*/
// the rates arrays
   ArraySetAsSeries(mrate,true);
// the ADX DI+values array
   ArraySetAsSeries(plsDI,true);
// the ADX DI-values array
   ArraySetAsSeries(minDI,true);
// the ADX values arrays
   ArraySetAsSeries(adxVal,true);
// the MA-8 values arrays
   ArraySetAsSeries(maVal,true);


//--- Get the last price quote using the MQL5 MqlTick Structure
   if(!SymbolInfoTick(_Symbol,latest_price))
     {
      Alert("Error getting the latest price quote - error:",GetLastError(),"!!");
      return;
     }

//--- Get the details of the latest 3 bars
   if(CopyRates(_Symbol,_Period,0,3,mrate)<0)
     {
      Alert("Error copying rates/history data - error:",GetLastError(),"!!");
      ResetLastError();
      return;
     }

//--- Copy the new values of our indicators to buffers (arrays) using the handle
   if(CopyBuffer(adxHandle,0,0,3,adxVal)<0 || CopyBuffer(adxHandle,1,0,3,plsDI)<0
      || CopyBuffer(adxHandle,2,0,3,minDI)<0)
     {
      Alert("Error copying ADX indicator Buffers - error:",GetLastError(),"!!");
      ResetLastError();
      return;
     }
   if(CopyBuffer(maHandle,0,0,3,maVal)<0)
     {
      Alert("Error copying Moving Average indicator buffer - error:",GetLastError());
      ResetLastError();
      return;
     }
//--- we have no errors, so continue
//--- Do we have positions opened already?
   bool Buy_opened=false;  // variable to hold the result of Buy opened position
   bool Sell_opened=false; // variables to hold the result of Sell opened position

   if(PositionSelect(_Symbol)==true) // we have an opened position
     {
      
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
        {
         Buy_opened=true;  //It is a Buy
        }
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
        {
         Sell_opened=true; // It is a Sell
        }
     }
// Copy the bar close price for the previous bar prior to the current bar, that is Bar 1
   p_close=mrate[1].close;  // bar 1 close price
   //Print(latest_price.bid);
   
   double Ask,Bid; 
   
   Ask=SymbolInfoDouble(Symbol(),SYMBOL_ASK); 
   Bid=SymbolInfoDouble(Symbol(),SYMBOL_BID); 
   
   if(Buy_opened){
      if(current_top < Ask){
         CSTL = CSTL + (Ask - current_top);
         current_top = Ask;
         
         
      }
   }
   
   if(Sell_opened){
      if(Bid < current_top){
         CSTL = CSTL - (current_top - Bid);
         current_top = Bid;
      }
   }
   
   
   Comment(StringFormat("Show prices\n Ask = %G\n Bid = %G\n p_close = %G\n current_top = %G\n CSTL = %G",Ask,Bid, p_close, current_top, CSTL));
/*
    1. Check for a long/Buy Setup : MA-8 increasing upwards, 
    previous price close above it, ADX > 22, +DI > -DI
*/
//--- Declare bool type variables to hold our Buy Conditions
   bool Buy_Condition_1=(maVal[0]>maVal[1]) && (maVal[1]>maVal[2]); // MA-8 Increasing upwards
   bool Buy_Condition_2 = (p_close > maVal[1]);         // previuos price closed above MA-8
   bool Buy_Condition_3 = (adxVal[0]>Adx_Min);          // Current ADX value greater than minimum value (22)
   bool Buy_Condition_4 = (plsDI[0]>minDI[0]);          // +DI greater than -DI

//--- Putting all together   
   if(Buy_Condition_1 && Buy_Condition_2)
     {
      if(Buy_Condition_3 && Buy_Condition_4)
        {
         // any opened Buy position?
         if(PositionSelect(_Symbol))
         {
            if(Buy_opened){
               //Alert("We already have a Buy Position!!!");
               printf("We already have a Buy Position!!!");
            }else{
               //Alert("We already have a Sell Position!!!");
               printf("We already have a Sell Position!!!");
            }
             
             return;    // Don't open a new Buy Position
         }else{
            ZeroMemory(mrequest);
            
            mrequest.action = TRADE_ACTION_DEAL;                                  // immediate order execution
            mrequest.price = (latest_price.ask);           // latest ask price
            mrequest.sl = (latest_price.ask - STP*_Point); // Stop Loss
            mrequest.tp = (latest_price.ask + TKP*_Point); // Take Profit
            mrequest.symbol = _Symbol;                                            // currency pair
            mrequest.volume = Lot;                                                 // number of lots to trade
            mrequest.magic = EA_Magic;                                             // Order Magic Number
            mrequest.type = ORDER_TYPE_BUY;                                        // Buy Order
            mrequest.type_filling = ORDER_FILLING_FOK;                             // Order execution type
            mrequest.deviation=100;                                                // Deviation from current price
            //--- send order
            OrderSend(mrequest,mresult);
            Buy_opened = true;
            // get the result code
            if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
              {
               Alert("A Buy order has been successfully placed with Ticket#:",mresult.order,"!!");
               CSTL = (latest_price.ask - STP*_Point);
               current_top = (latest_price.ask);
              }
            else
              {
               Alert("The Buy order request could not be completed -error:",GetLastError());
               ResetLastError();           
               return;
              }
           }
         }
         
     }
/*
    2. Check for a Short/Sell Setup : MA-8 decreasing downwards, 
    previous price close below it, ADX > 22, -DI > +DI
*/
//--- Declare bool type variables to hold our Sell Conditions
   bool Sell_Condition_1 = (maVal[0]<maVal[1]) && (maVal[1]<maVal[2]);  // MA-8 decreasing downwards
   bool Sell_Condition_2 = (p_close <maVal[1]);                         // Previous price closed below MA-8
   bool Sell_Condition_3 = (adxVal[0]>Adx_Min);                         // Current ADX value greater than minimum (22)
   bool Sell_Condition_4 = (plsDI[0]<minDI[0]);                         // -DI greater than +DI

//--- Putting all together
   if(Sell_Condition_1 && Sell_Condition_2)
     {
      if(Sell_Condition_3 && Sell_Condition_4)
        {
         // any opened Sell position?
            if(PositionSelect(_Symbol))
            {
               if(Buy_opened){
                  //Alert("We already have a Buy Position!!!");
                  printf("We already have a Buy Position!!!");
               }else{
                  //Alert("We already have a Sell Position!!!");
                  printf("We already have a Sell Position!!!");
               }
               return;    // Don't open a new Sell Position
            }else{
               ZeroMemory(mrequest);
               
               mrequest.action=TRADE_ACTION_DEAL;                                // immediate order execution
               mrequest.price = (latest_price.bid);           // latest Bid price
               mrequest.sl = (latest_price.bid + STP*_Point); // Stop Loss
               mrequest.tp = (latest_price.bid - TKP*_Point); // Take Profit
               mrequest.symbol = _Symbol;                                          // currency pair
               mrequest.volume = Lot;                                              // number of lots to trade
               mrequest.magic = EA_Magic;                                          // Order Magic Number
               mrequest.type= ORDER_TYPE_SELL;                                     // Sell Order
               mrequest.type_filling = ORDER_FILLING_FOK;                          // Order execution type
               mrequest.deviation=100;                                             // Deviation from current price
               //--- send order
               OrderSend(mrequest,mresult);
               Sell_opened = true;
               // get the result code
               if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
                 {
                  Alert("A Sell order has been successfully placed with Ticket#:",mresult.order,"!!");
                  CSTL = (latest_price.bid + STP*_Point);
                  current_top = (latest_price.bid);
                 }
               else
                 {
                  Alert("The Sell order request could not be completed -error:",GetLastError());
                  ResetLastError();
                  return;
                 }
              }
         }
     }
   return;
  }
//+------------------------------------------------------------------+