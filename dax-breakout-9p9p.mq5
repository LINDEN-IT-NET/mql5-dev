#property copyright "money by code"
#property link      "git@github.com:LINDEN-IT-NET/mql5-dev.git"
#property version "666"

//include the class
#include <9p9p_Dax-conditions-close.mqh>
#include <lib_cisnewbar.mqh>
//#include <Trade\Trade-Book.mqh>
#include <GetPositionProperties.mqh>
#include <Tester\StopAtDate.mqh>
#include <getMomentum1-0.mq5>
#include <Mql5Book/TrailingStops.mqh>

//--- input parameters

int     StopLoss=9;
int     TakeProfit=9;

//input vars for TrailingStop
bool UseTrailingStop=false ;
int TrailingStop=30;
int MinimumProfit=1152;
int Step=50;

double   SLp=9;
double   TPp=9;
int      EA_Magic=12345;   // EA Magic Number
double   Lot=1;          // Lots to Trade
int      Margin_Chk=0;     // Check Margin before placing trade(0=No, 1=Yes)
double   Trd_percent=15.0; // Percentage of Free Margin To use for Trading

bool Buy_opened = false;
bool Sell_opened = false;
double Profit = 0;
datetime checktime;
datetime tradetime;
bool buytradetimetrue = false;
bool selltradetimetrue = false;
bool onedaypause = false;
bool dailytradedone = false;
bool dailybuytradedone = false;
bool dailyselltradedone = false;
double LAST_TRADE_PROFIT = 0;
bool stop_trading = false;
MqlDateTime mdt;
MqlDateTime tradingtime;
MqlDateTime servertime;
int servertimeHour;
int servertimeMinute;
int servertimeSecond;
enum postype {BUY,SELL,NONE};
static int prevposition=NONE;


//--- Other parameters
int STP,TKP;   // To be used for Stop Loss & Take Profit values
//bool initialstopbt=false;


// Create an object of our class
Cclass object;
//CTrade trade;
CTrade_Book Trade;
CTrailing trail;
CisNewBar current_chart;

input ulong deviation = 2;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Set all other necessary variables for our class object
   Trade.Deviation(deviation);
   object.setPeriod(_Period);     // sets the chart period/timeframe
   object.setSymbol(_Symbol);     // sets the chart symbol/currency-pair
   object.setMagic(EA_Magic);    // sets the Magic Number
   object.setLOTS(Lot);          // set the Lots value
   object.setchkMAG(Margin_Chk); // set the margin check variable
   object.setTRpct(Trd_percent); // set the percentage of Free Margin for trade
//--- Let us handle brokers that offers 5 digit prices instead of 4
   STP = StopLoss;
   TKP = TakeProfit;
   if(_Digits==5 || _Digits==3)
     {
      STP = STP*10;
      TKP = TKP*10;
     }



//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
/*
void OnDeinit(const int reason)
  {
//---//--- Run UnIntilialize function
   object.doUninit();
  }
*/
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   /*
    if(current_chart.isNewBar()>0)
      {
       PrintFormat("New bar: %s",TimeToString(TimeCurrent(),TIME_SECONDS));
       //Print("m_new_bars: ",current_chart.m_new_bars);
      }
    */
//---

   checktime=TimeCurrent();
   Comment("TimeCurrent: ",checktime);

//tradetime=TimeGMT();
//int tradetime = TimeToString(TimeLocal(),TIME_MINUTES);

   TimeToStruct(checktime,servertime);
   servertimeHour = servertime.hour;
   servertimeMinute = servertime.min;
   servertimeSecond = servertime.sec;

   if((servertimeHour == 8) && (dailybuytradedone==true) && (dailyselltradedone==true))
     {
      dailybuytradedone=false;
      dailyselltradedone=false;
     }

   if((servertimeHour == 9) && (servertimeMinute <= 5) && (dailybuytradedone==false))
     {
      buytradetimetrue = true;
      Print("BuyTradetime: ",servertimeHour, ":", servertimeMinute);
     }
   else
      buytradetimetrue = false;

   if((servertimeHour == 9) && (servertimeMinute <= 5) && (dailyselltradedone==false))
     {
      selltradetimetrue = true;
      Print("SellTradetime: ",servertimeHour, ":", servertimeMinute);
     }
   else
      selltradetimetrue = false;


//   if(StopAtDate.Check("2020.11.25", "07:59:00"))
//      DebugBreak();   // hier hält das Programm an

//--- Do we have enough bars to work with
   int Mybars=Bars(_Symbol,_Period);
   if(Mybars<59) // if total bars is less than 60 bars
     {
      Alert("We have less than 59 bars, EA will now exit!!");
      return;
     }

   ArraySetAsSeries(object.mrate,true);

//--- Get the details of the latest 59 bars
   if((servertimeHour == 8) && (servertimeMinute == 59))
     {
      if(CopyRates(_Symbol,_Period,0,59,object.mrate)<0)
        {
         Alert("Error copying rates/history data - error:",GetLastError(),"!!");
         return;
        }
     }


//--- Do we have positions opened already?
//bool Buy_opened = false, Sell_opened=false; // variables to hold the result of the opened position

   if(PositionSelect(_Symbol)==true)   // we have an opened position
     {
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
         Buy_opened = true;  //It is a Buy
        }
      else
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
           {
            Sell_opened = true; // It is a Sell
           }
     }
   else
     {
      Buy_opened=false;
      Sell_opened=false;
     }


//+------------------------------------------------------------------+
//| START opening buy position                                       |
//+------------------------------------------------------------------+
// if((Buy_opened==false)&&(stop_trading==false))
// {
//if((object.checkBuy()==true)&&(Signal=="buy"))
   if((buytradetimetrue==true) && (dailybuytradedone!=true))
      //if(Signal=="buy")
     {
      // Do we already have an opened buy position
      object.getHighest();
      double highestprice=NormalizeDouble(object.highest59,_Digits);              // current Ask price
      double stopbt=NormalizeDouble(object.highest59 - STP,_Digits); // Stop Loss
      double winclosebt=NormalizeDouble(object.highest59 + TKP,_Digits); // Take profit
      //int    mdev   = 5;                                                    // Maximum deviation
      // place order
      //object.openBuy(ORDER_TYPE_BUY,cprice,stopbt,winclosebt,mdev);
      //Trade.OpenPosition(_Symbol,ORDER_TYPE_BUY,Lot,cprice,stopbt,winclosebt);  // Open Trade with SL & TP
      //Trade.OpenPosition(_Symbol,ORDER_TYPE_BUY,Lot,stopbt,winclosebt);  // Open Trade with SL & TP
      datetime debugtimebuy = TimeCurrent();
      Print("DebugTimeBuy: ",debugtimebuy);
      datetime buyExpiration = TimeCurrent()+PeriodSeconds(PERIOD_H1); 
      Trade.BuyStop(_Symbol,Lot,highestprice,(highestprice-9),(highestprice+9),buyExpiration);
      Print("BuyTrade opened @", debugtimebuy);
      //trade.openBuy
      // object.openBuy()
      //trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,Lot,cprice,0,0);                  // Open Trade w/o SL & TP
      // Bei Trades ohne direkten SL & TP müssen direkt hier SL & TP gesetzt werden
      bool openPosition=PositionSelect(_Symbol);
      Buy_opened=true;
      // prevposition=BUY;
      dailybuytradedone=true;
     }
// }

//--- Check for any Sell position
//+------------------------------------------------------------------+
//| START opening sell position                                      |
//+------------------------------------------------------------------+

//if((Sell_opened==false)&&(stop_trading==false))
//{
//if((object.checkSell()==true)&&(Signal=="sell"))
   if((selltradetimetrue==true) && (dailyselltradedone!=true))
      //if(Signal=="sell")
     {
      object.getLowest();
      // Do we already have an opened Sell position
      double lowestprice=NormalizeDouble(object.lowest59,_Digits);
      // double stopst = NormalizeDouble(object.latest_price.bid + STP*_Point,_Digits); // Stop Loss
      double stopst=lowestprice+STP; // Stop Loss
      double winclosest=lowestprice-TKP; // Take Profit
      //int    bdev=10;                                                         // Maximum deviation
      // place order
      //Trade.OpenPosition(_Symbol,ORDER_TYPE_SELL,Lot,lowestprice,stopst,winclosest); // Open Trade with SL & TP
      //Trade.OpenPosition(_Symbol,ORDER_TYPE_SELL,Lot,stopst,winclosest); // Open Trade with SL & TP
      datetime debugtimesell = TimeCurrent();
      Print("DebugTimeSell: ",debugtimesell);
      datetime sellExpiration = TimeCurrent()+PeriodSeconds(PERIOD_H1); 
      Trade.SellStop(_Symbol,Lot,lowestprice,(lowestprice+9),(lowestprice-9),sellExpiration);
      Print("SellTrade opened @ ", debugtimesell);
      //trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,Lot,bprice,0,0);    // Open Trade w/o SL & TP
      // Bei Trades ohne direkten SL & TP müssen direkt hier SL & TP gesetzt werden
      bool openPosition=PositionSelect(_Symbol);
      Sell_opened=true;
      // prevposition=SELL;
      dailyselltradedone=true;
     }
// }


// TrailingStop eins für buy & sell

   if(UseTrailingStop==true && PositionType(_Symbol)!=-1)
     {
      trail.TrailingStop(_Symbol,TrailingStop,MinimumProfit,Step);
     }
  }


// Für die Profit or Loss Abfrage des letzten Trades, wenn Loss, dann Schluss für heute
void OnTrade()
  {
   static int previous_open_positions = 0;
   int current_open_positions = PositionsTotal();
   if(current_open_positions < previous_open_positions)             // a position just got closed:
     {
      previous_open_positions = current_open_positions;
      HistorySelect(TimeCurrent()-300, TimeCurrent()); // 5 minutes ago
      int All_Deals = HistoryDealsTotal();
      if(All_Deals < 1)
         Print("Some nasty shit error has occurred :s");
      // last deal (should be an DEAL_ENTRY_OUT type):
      ulong temp_Ticket = HistoryDealGetTicket(All_Deals-1);
      // here check some validity factors of the position-closing deal
      // (symbol, position ID, even MagicNumber if you care...)
      LAST_TRADE_PROFIT = HistoryDealGetDouble(temp_Ticket, DEAL_PROFIT);
      Print("Last Trade Profit : ", DoubleToString(LAST_TRADE_PROFIT));
      if(LAST_TRADE_PROFIT<0)
        {
         Print("LAST TRADE PROFIT war leider ein LOSS = <0");
         stop_trading=true;
        }
     }
   else
      if(current_open_positions > previous_open_positions)       // a position just got opened:
         previous_open_positions = current_open_positions;
  }

//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   HistorySelect(TimeCurrent()-3600,TimeCurrent());
   if(trans.type==TRADE_TRANSACTION_DEAL_ADD && trans.deal_type==DEAL_TYPE_SELL
      && PositionsTotal()==0 && prevposition==BUY)
     {
      if(HistoryDealGetInteger(trans.deal,DEAL_REASON)==DEAL_REASON_TP)
        {
         Print("BUY + DEAL_REASON_TP");
         prevposition=NONE;
        }
      if(HistoryDealGetInteger(trans.deal,DEAL_REASON)==DEAL_REASON_SL)
        {
         Print("BUY + DEAL_REASON_SL");
         prevposition=NONE;
        }
     }

   if(trans.type==TRADE_TRANSACTION_DEAL_ADD && trans.deal_type==DEAL_TYPE_BUY
      && PositionsTotal()==0 && prevposition==SELL)
     {
      if(HistoryDealGetInteger(trans.deal,DEAL_REASON)==DEAL_REASON_TP)
        {
         Print("SELL + DEAL_REASON_TP");
         prevposition=NONE;
        }
      if(HistoryDealGetInteger(trans.deal,DEAL_REASON)==DEAL_REASON_SL)
        {
         Print("SELL + DEAL_REASON_SL");
         prevposition=NONE;
        }
     }

  }

//+------------------------------------------------------------------+
