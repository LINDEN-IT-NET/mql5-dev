//+------------------------------------------------------------------+
//|                                             article116_class.mqh |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"

#include <lib_cisnewbar.mqh>

//+------------------------------------------------------------------+
//| CLASS DECLARATION                                                |
//+------------------------------------------------------------------+
class Cclass
  {
   //--- private members
private:
   int               Magic_No;   // Expert Magic Number
   int               Chk_Margin; // Margin Check before placing trade? (1 or 0)
   double            LOTS;       // Lots or volume to Trade
   double            TradePct;   // Percentage of Account Free Margin to trade
   double            Closeprice; // variable to hold the previous bar closed price
   MqlTradeRequest   trequest;    // MQL5 trade request structure to be used for sending our trade requests
   MqlTradeResult    tresult;     // MQL5 trade result structure to be used to get our trade results
   string            symbol;     // variable to hold the current symbol name
   ENUM_TIMEFRAMES   period;      // variable to hold the current timeframe value
   string            Errormsg;   // variable to hold our error messages
   int               Errcode;    // variable to hold our error codes
   CisNewBar         current_chart_inclass; // instance of the CisNewBar class: current chart




   //--- Public member/functions
public:
   void              Cclass();                                 //Class Constructor
   void              setSymbol(string syb) {symbol = syb;}        //function to set current symbol
   void              setPeriod(ENUM_TIMEFRAMES prd) {period = prd;} //function to set current symbol timeframe/period
   void              setCloseprice(double prc) {Closeprice=prc;}  //function to set prev bar closed price
   void              setchkMAG(int mag) {Chk_Margin=mag;}         //function to set Margin Check value
   void              setLOTS(double lot) {LOTS=lot;}              //function to set The Lot size to trade
   void              setTRpct(double trpct) {TradePct=trpct/100;}  //function to set Percentage of Free margin to use for trading
   void              setMagic(int magic) {Magic_No=magic;}        //function to set Expert Magic number
  
   //void              doUninit();                                  //function to be used at EA de-initializatio
   bool              checkBuy();                                  //function to check for Buy conditions
   bool              checkSell();                                 //function to check for Sell conditions
   void              openBuy(ENUM_ORDER_TYPE otype,double askprice,double SL,
                             double TP,int dev,string comment="");   //function to open Buy positions
   void              openSell(ENUM_ORDER_TYPE otype,double bidprice,double SL,
                              double TP,int dev,string comment="");  //function to open Sell positions
   void              setinitialsetbt(double pStopLoss, double pwinpips);
   void              check4winbt(double cprice, double pwinpips);
   void              setinitialsetst(double pStopLoss, double pwinpips);
   void              check4winst(double bprice, double pwinpips);
   void              trailStopBuy(double cprice, double pprofit);
   void              trailStopSell(double bprice, double pprofit);

   // double            getMomentum();
   // static double     m_MomentumValue;
   
   double            getHighest();
   int               highest59number;
   double            highest59;
   double            highest59_array[];
   MqlRates          highest59_rates[];
   int               highest59_pricedata;
   double            getLowest();
   int               lowest59number;
   double            lowest59;
   double            lowest59_array[];
   MqlRates          lowest59_rates[];
   int               lowest59_pricedata;   

   //--- Define some MQL5 Structures we will use for our trade
   MqlTick           latest_price;      // To be used for getting recent/latest price quotes
   MqlRates          mrate[];          // To be used to store the prices, volumes and spread of each bar



   //+------------------------------------------------------------------+

   //--- Protected members
protected:
   void              showError(string msg, int ercode);   //function for use to display error messages
   void              getBuffers();                       //function for getting Indicator buffers
   bool              MarginOK();                         //function to check if margin required for lots is OK

  };   // end of class declaration

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
// Definition of our Class/member functions
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|  This CLASS CONSTRUCTOR
//|  *Does not have any input parameters
//|  *Initilizes all the necessary variables
//+------------------------------------------------------------------+
void Cclass::Cclass()
  {
//initialize all necessary variables
   //ZeroMemory();
   Errormsg="";
   Errcode=0;
  }

//+------------------------------------------------------------------+
//|  SHOWERROR FUNCTION
//|  *Input Parameters - Error Message, Error Code
//+------------------------------------------------------------------+
void Cclass::showError(string msg,int ercode)
  {
   Alert(msg,"-error:",ercode,"!!"); // display error
  }

//+------------------------------------------------------------------+
//|  GETBUFFERS FUNCTION
//|  *No input parameters
//|  *Uses the class data members to get indicator's buffers
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


  
//  void OnStart()

double Cclass::getHighest()
  {
  /*
   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   int copied=CopyRates(NULL,0,0,59,rates);
   if(copied>0)
     {
      Print("Bars copied: "+copied);
      string format="open = %G, high = %G, low = %G, close = %G, volume = %d";
      string out;
      int size=fmin(copied,10);
      for(int i=0;i<size;i++)
        {
         out=i+":"+TimeToString(rates[i].time);
         out=out+" "+StringFormat(format,
                                  rates[i].open,
                                  rates[i].high,
                                  rates[i].low,
                                  rates[i].close,
                                  rates[i].tick_volume);
         Print(out);
        }
     }
   else Print("Failed to get history data for the symbol ",Symbol());
 */
   
// iHighest: get the index of highest close of last 59 minute bars
//--- Calculation of the highest Close value among 59 consecutive bars
//--- From index 0 to index 58 inclusive, on the current timeframe
   // highest59_array[];
   ArraySetAsSeries(highest59_rates,true);
   ArraySetAsSeries(highest59_array,true);
   //highest59_pricedata=CopyRates(_Symbol,_Period,0,58,highest59_rates);
   CopyRates(_Symbol,_Period,0,58,highest59_rates);
   CopyHigh(_Symbol,PERIOD_M1,0,58,highest59_array);
   highest59number=ArrayMaximum(highest59_array,0,WHOLE_ARRAY);
   Print("HighestCandleIndexNumber: ",highest59number);
   highest59=highest59_rates[highest59number].close;
   Print("Highest59: ",highest59);
   Comment("Highest59: ",highest59);
   return(highest59);
   }
   
double Cclass::getLowest()      
   {
   ArraySetAsSeries(lowest59_rates,true);
   ArraySetAsSeries(lowest59_array,true);
   //lowest59_pricedata=CopyRates(_Symbol,_Period,0,58,lowest59_rates);
   CopyRates(_Symbol,_Period,0,58,lowest59_rates);
   CopyLow(_Symbol,PERIOD_M1,0,58,lowest59_array);
   lowest59number=ArrayMinimum(lowest59_array,0,WHOLE_ARRAY);
   Print("LowestCandleIndexNumber: ", lowest59number);
   lowest59=lowest59_rates[lowest59number].close;
   Print("Lowest59: ",lowest59);
   return(lowest59);
   }  // onStart bracket   

//+------------------------------------------------------------------+
//|  MARGINOK FUNCTION
//| *No input parameters
//| *Uses the Class data members to check margin required to place a trade
//|  with the lot size is ok
//| *Returns TRUE on success and FALSE on failure
//+------------------------------------------------------------------+
bool Cclass::MarginOK()
  {
   double one_lot_price;                                                        //Margin required for one lot
   double act_f_mag     = AccountInfoDouble(ACCOUNT_FREEMARGIN);                //Account free margin
   long   levrage       = AccountInfoInteger(ACCOUNT_LEVERAGE);                 //Leverage for this account
   double contract_size = SymbolInfoDouble(symbol,SYMBOL_TRADE_CONTRACT_SIZE);  //Total units for one lot
   string base_currency = SymbolInfoString(symbol,SYMBOL_CURRENCY_BASE);        //Base currency for currency pair
//
   if(base_currency=="USD")
     {
      one_lot_price=contract_size/levrage;
     }
   else
     {
      double bprice= SymbolInfoDouble(symbol,SYMBOL_BID);
      one_lot_price=bprice*contract_size/levrage;
     }
// Check if margin required is okay based on setting
   if(MathFloor(LOTS*one_lot_price)>MathFloor(act_f_mag*TradePct))
     {
      return(false);
     }
   else
     {
      return(true);
     }
  }

//+-----------------------------------------------------------------------+
// OUR PUBLIC FUNCTIONS                                                   |
//+-----------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| DOINIT FUNCTION
//| *Takes the ADX indicator's Period and Moving Average indicator's
//| period as input parameters
//| *To be used in the OnInit() function of our EA
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|  DOUNINIT FUNCTION
//|  *No input parameters
//|  *Used to release ADX and MA indicators handleS                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| CHECKBUY FUNCTION
//| *No input parameters
//| *Uses the class data members to check for Buy setup based on the
//|  the defined trade strategy
//| *Returns TRUE if Buy conditions are met or FALSE if not met
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/*
bool Cclass::checkBuy()
  {
   getBuffers();
//--- Declare bool type variables to hold our Buy Conditions
//bool Buy_Condition_1=(MA_val[0]>MA_val[1]) && (MA_val[1]>MA_val[2]); // MA Increasing upwards
  


//--- Putting all together
   /* if(current_chart_inclass.isNewBar()>0)
      {
       PrintFormat("New bar aus checkBuy: %s",TimeToString(TimeCurrent(),TIME_SECONDS));
       //Print("m_new_bars: ",current_chart.m_new_bars);
      }
      */
/*
   if(Buy_Condition_1 && (current_chart_inclass.isNewBar()>0))
     {
      return(true);
     }
   else
     {
      return(false);
     }
  }

//+------------------------------------------------------------------+
//| CHECKSELL FUNCTION
//| *No input parameters
//| *Uses the class data members to check for Sell setup based on the
//|  the defined trade strategy
//| *Returns TRUE if Sell conditions are met or FALSE if not met
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Cclass::checkSell()
  {
   /*
       Check for a Short/Sell Setup : MA decreasing downwards,
       previous price close below MA, ADX > ADX min, -DI > +DI
   */
/*   getBuffers();
//--- Declare bool type variables to hold our Sell Conditions
//   bool Sell_Condition_1=(MA_val[0]<MA2_val[0]) && (MA2_val[0]<MA3_val[0]); // MA < MA2 < MA3

//--- Putting all together
   if(Sell_Condition_4 && Sell_Condition_6  && (current_chart_inclass.isNewBar()>0))
     {
      return(true);
     }
   else
     {
      return(false);
     }
  }
*/

//+------------------------------------------------------------------+
//| OPENBUY FUNCTION
//| *Has Input parameters - order type, Current ASK price, Stop Loss,
//|  Take Profit, deviation, comment
//| *Checks account free margin before pacing trade if trader chooses
//| *Alerts of a success if position is opened or shows error
//+-----------------------------------------------------------------+
void Cclass::openBuy(ENUM_ORDER_TYPE otype,double askprice,double SL,double TP,int dev,string comment="")
  {
//--- do check Margin if enabled
   if(Chk_Margin==1)
     {
      if(MarginOK()==false)
        {
         Errormsg= "You do not have enough money to open this Position!!!";
         Errcode =GetLastError();
         showError(Errormsg,Errcode);
        }
      else
        {
         trequest.action=TRADE_ACTION_DEAL;
         trequest.type=otype;
         trequest.volume=LOTS;
         trequest.price=askprice;
         trequest.sl=SL;
         trequest.tp=TP;
         trequest.deviation=dev;
         trequest.magic=Magic_No;
         trequest.symbol=symbol;
         trequest.type_filling=ORDER_FILLING_FOK;
         // send
         bool reqsend = OrderSend(trequest,tresult);
         // check result
         if(tresult.retcode==10009 || tresult.retcode==10008) //Request successfully completed
           {
            Alert("A Buy order has been successfully placed with Ticket#:",tresult.order,"!!");
           }
         else
           {
            Errormsg= "The Buy order request could not be completed";
            Errcode =GetLastError();
            showError(Errormsg,Errcode);
           }
        }
     }
   else
     {
      trequest.action=TRADE_ACTION_DEAL;
      trequest.type=otype;
      trequest.volume=LOTS;
      trequest.price=askprice;
      trequest.sl=SL;
      trequest.tp=TP;
      trequest.deviation=dev;
      trequest.magic=Magic_No;
      trequest.symbol=symbol;
      trequest.type_filling=ORDER_FILLING_FOK;
      //--- send
      bool reqsend = OrderSend(trequest,tresult);
      //--- check result
      if(tresult.retcode==10009 || tresult.retcode==10008) //Request successfully completed
        {
         Alert("A Buy order has been successfully placed with Ticket#:",tresult.order,"!!");
        }
      else
        {
         Errormsg= "The Buy order request could not be completed";
         Errcode =GetLastError();
         showError(Errormsg,Errcode);
        }
     }
  }

//+------------------------------------------------------------------+
//| OPENSELL FUNCTION
//| *Has Input parameters - order type, Current BID price, Stop Loss,
//|  Take Profit, deviation, comment
//| *Checks account free margin before pacing trade if trader chooses
//| *Alerts of a success if position is opened or shows error
//+------------------------------------------------------------------+
void Cclass::openSell(ENUM_ORDER_TYPE otype,double bidprice,double SL,double TP,int dev,string comment="")
  {
//--- do check Margin if enabled
   if(Chk_Margin==1)
     {
      if(MarginOK()==false)
        {
         Errormsg= "You do not have enough money to open this Position!!!";
         Errcode =GetLastError();
         showError(Errormsg,Errcode);
        }
      else
        {
         trequest.action=TRADE_ACTION_DEAL;
         trequest.type=otype;
         trequest.volume=LOTS;
         trequest.price=bidprice;
         trequest.sl=SL;
         trequest.tp=TP;
         trequest.deviation=dev;
         trequest.magic=Magic_No;
         trequest.symbol=symbol;
         trequest.type_filling=ORDER_FILLING_FOK;
         // send
         bool reqsend = OrderSend(trequest,tresult);
         // check result
         if(tresult.retcode==10009 || tresult.retcode==10008) //Request successfully completed
           {
            Alert("A Sell order has been successfully placed with Ticket#:",tresult.order,"!!");
           }
         else
           {
            Errormsg= "The Sell order request could not be completed";
            Errcode =GetLastError();
            showError(Errormsg,Errcode);
           }
        }
     }
   else
     {
      trequest.action=TRADE_ACTION_DEAL;
      trequest.type=otype;
      trequest.volume=LOTS;
      trequest.price=bidprice;
      trequest.sl=SL;
      trequest.tp=TP;
      trequest.deviation=dev;
      trequest.magic=Magic_No;
      trequest.symbol=symbol;
      trequest.type_filling=ORDER_FILLING_FOK;
      //--- send
      bool reqsend = OrderSend(trequest,tresult);
      //--- check result
      if(tresult.retcode==10009 || tresult.retcode==10008) //Request successfully completed
        {
         Alert("A Sell order has been successfully placed with Ticket#:",tresult.order,"!!");
        }
      else
        {
         Errormsg= "The Sell order request could not be completed";
         Errcode =GetLastError();
         showError(Errormsg,Errcode);
        }
     }
  }


// ------------------------------------------------------------------------------------


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

/*
double Cclass::getMomentum()
  {
// create array for several prices
   double myPriceArray[];

// define properties of the momentum EA
   int iMomentumDefinition=iMomentum(_Symbol,_Period,14,PRICE_CLOSE);

// sort price array from the current candle downwards
   ArraySetAsSeries(myPriceArray,true);

// defined MA1, one line, current candle, 3 candles, store result
   CopyBuffer(iMomentumDefinition,0,0,14,myPriceArray);

// get value of current candle
//double MomentumValue=NormalizeDouble(myPriceArray[0],2);
   m_MomentumValue=NormalizeDouble(myPriceArray[0],2);
   return(m_MomentumValue);

// chart output depending on value
//if (myMomentumValue >100.0)Comment("Strong Momentum: ",myMomentumValue);
//if (myMomentumValue <99.9)Comment("Weak Momentum: ",myMomentumValue);
//if((myMomentumValue >99.9)&&(myMomentumValue>100.00))
//Comment(" ", myMomentumValue);
  }

*/
//+------------------------------------------------------------------+
