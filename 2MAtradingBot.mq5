#include <trade/trade.mqh>

//2 MA strategy, one long term 200ma and short term 50ma

//Golden cross
   //Short term crosses above long term, long term buy
//Death cross
   //Short term crosses below long term, long term sell

CTrade trade;

int handleMaS;
int handleMaL;

input ENUM_TIMEFRAMES Timeframe = PERIOD_H4;
input int MovingAvLongTerm = 200;
input int MovingAvShortTerm = 50;

input double Lots = 1;
input double StopLoss = 700;
input double TakeProfit = 1100;

input float DistanceMas=5;

int OnInit(){
   handleMaL = iMA(_Symbol,Timeframe,MovingAvLongTerm,0,MODE_SMA,0);
   handleMaS = iMA(_Symbol,Timeframe,MovingAvShortTerm,0,MODE_SMA,0);
   return(INIT_SUCCEEDED);
}


void OnDeinit(const int reason){}

bool goldenCross=false;
bool deathCross=false;
bool activeOrder=false;

double priceSell=0;
double priceBuy=0;
int ticket=-1;

void OnTick(){
   checkOrder(ticket);
   priceSell = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   priceBuy = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   
   double maL[];
   CopyBuffer(handleMaL,0,1,1,maL);
   double maS[]; 
   CopyBuffer(handleMaS,0,1,1,maS);
   
   NormalizeDouble(maL[0],_Digits);
   NormalizeDouble(maS[0],_Digits);
   
   if(maL[0] > maS[0]){
      if(MathAbs(maL[0] - maS[0]) <= DistanceMas
       && deathCross==false && activeOrder==false){     
         deathCross = true;
         activeOrder = true;
         executeSell();
         Print("DEATH CROSS", " Diff: ", MathAbs(maL[0] - maS[0]));        
      }
      goldenCross=false;   
   }
   
   if(maL[0] < maS[0]){
      if(MathAbs(maL[0] - maS[0]) <= DistanceMas
       && goldenCross==false && activeOrder==false){     
         goldenCross = true;
         activeOrder = true;
         executeBuy();
         Print("GOLDEN CROSS", " Diff: ", MathAbs(maL[0] - maS[0]));        
      }   
      deathCross = false;
   }
}

void executeSell(){
   double entry = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   entry = NormalizeDouble(entry,_Digits);
   activeOrder=true;
   trade.Sell(Lots,_Symbol,entry,entry+StopLoss*_Point,entry-TakeProfit*_Point,"Allah");
   ticket = trade.ResultOrder();
}
void executeBuy(){
   double entry = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   entry = NormalizeDouble(entry,_Digits);
   activeOrder=true;
   trade.Buy(Lots,_Symbol,entry,entry-StopLoss*_Point,entry+TakeProfit*_Point,"Allah");
   ticket = trade.ResultOrder();
}
void checkOrder(ulong ticket){ 
    if(PositionSelectByTicket(ticket)==false){
      ticket=-1;
      activeOrder=false;
   } 
}
