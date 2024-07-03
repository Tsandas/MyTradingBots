//43% long winning trades with avg profit 129, loss 162 eurusd 5min
//20% short winning trades

#include <trade/trade.mqh>

input int Magic = 2024;
input int MaPeriodS = 20;
input int Lots = 1;
input int StartingSLl = 150;
input int PointsAboveMa = 30;
input int PointsBelowMa = 30;
input int ConsiderClosingBuyWhenAbovePoints=15;
input int ConsiderClosingSellWhenBelowPoints=15;
input bool selling=true;
input bool buying=true;
CTrade trade;

int handleMaS;
int handleMaL;
int OnInit(){
   handleMaS = iMA(_Symbol,PERIOD_CURRENT,MaPeriodS,0,MODE_SMA,0);
   return(INIT_SUCCEEDED);
}

double AsiaHigh;
double AsiaLow;
double price;
MqlDateTime time;
ulong posTicket;
bool got=false;
bool LondonLowFirst=false; 
bool LondonHighFirst=false; 
bool tickLower = false;
bool activeOrderBuy=false;
bool activeOrderSell=false;

void OnTick(){
   double maAs[];
   CopyBuffer(handleMaS,0,1,1,maAs);
   double mas = maAs[0];   
   TimeCurrent(time);
   price =  SymbolInfoDouble(_Symbol,SYMBOL_BID);        
   
   if(PositionsTotal()==0){
      activeOrderBuy=false;
      activeOrderSell=false;
   } 
   if(activeOrderBuy){
      double openPrice;
      if(PositionSelectByTicket(posTicket)) {
          openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         }
      checkBuyOrder(price,mas,openPrice,posTicket);
   }
   if(activeOrderSell){
      double openPrice;
      if(PositionSelectByTicket(posTicket)){
         openPrice=PositionGetDouble(POSITION_PRICE_CURRENT);
      }
      checkSellOrder(price,mas,openPrice,posTicket);
   }
   
  //Get Asiahigh and Asialow
  if(time.hour==7 && got==false ){
      AsiaHigh = getAsiaHigh();        
      AsiaLow = getAsiaLow();
      got=true;
      setAsiaBool(); //Set them both at false, and NewYorks ticker //Print(AsiaHigh," ",AsiaLow);
   }
   
   //Checking if we took asia low or high first
   if(time.hour>=9 && time.hour<12){
      got=false;
      if(price <AsiaLow && LondonHighFirst==false && LondonLowFirst==false){
         LondonLowFirst = true; //Print("ITS A BUY DAY");
      }else if(price >AsiaHigh && LondonLowFirst==false && LondonHighFirst==false){
         LondonHighFirst = true; //Print("ITS A SELL DAY");
      }       
   }

   //executing orders
   if(time.hour>=13 && time.hour<17){
      NormalizeDouble(mas,_Digits);
      if(LondonLowFirst == true && buying==true){
         NormalizeDouble(price,_Digits);
        
         if(price + 0.00005 < mas && tickLower == false){
            tickLower=true;          
         }
         if(price - 0.00005 > mas && tickLower == true){
            tickLower = false;
         }
         if(activeOrderBuy==false && activeOrderSell==false && (price - PointsAboveMa*_Point > mas) && tickLower==false){
               //Print("buy");
               executeBuy();
               posTicket = trade.ResultOrder();
               if(posTicket<=0){
                  activeOrderBuy=false;
                  //tickLower=false; // added this now check it
               }            
            }
      }else if(LondonHighFirst==true && selling==true){         
         if(price + 0.00005 < mas && tickLower == false){
            tickLower=true;          
         }
         if(price - 0.00005 > mas && tickLower == true){
            tickLower = false;
         }
         if(activeOrderSell==false && activeOrderBuy==false && (price + PointsBelowMa*_Point < mas) && tickLower==true){
            Print("Sell");
             executeSell();
             posTicket = trade.ResultOrder();
             if(posTicket<=0){
               activeOrderSell=false;           
             }
         }
       }
   }
   
}


double getAsiaHigh(){
   int AsiaH = iHighest(_Symbol,PERIOD_CURRENT,MODE_HIGH,80,0); //added some extra ones
   double asiaHigh = iHigh(_Symbol,PERIOD_CURRENT,AsiaH);
   NormalizeDouble(asiaHigh,_Digits);
   return asiaHigh;
}
double getAsiaLow(){
   int AsiaL = iLowest(_Symbol,PERIOD_CURRENT,MODE_LOW,80,0);
   double asiaLow = iLow(_Symbol,PERIOD_CURRENT,AsiaL);   
   NormalizeDouble(asiaLow,_Digits);
   return asiaLow; 
}
void setAsiaBool(){
   LondonLowFirst=false; //buy
   LondonHighFirst=false; // sell   
   tickLower=false;
}
void executeBuy(){
   double entry = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   entry = NormalizeDouble(entry,_Digits);
   double sl = entry - StartingSLl*_Point;
   sl = NormalizeDouble(sl,_Digits);
   activeOrderBuy=true;
   trade.Buy(Lots,NULL,entry,sl,price+1000*_Point,"allah");        
}
void executeSell(){
   double entry = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   entry = NormalizeDouble(entry,_Digits);
   double sl = entry + StartingSLl*_Point;
   sl = NormalizeDouble(sl,_Digits);
   activeOrderSell=true;
   trade.Sell(Lots,NULL,entry,sl,price-1000*_Point,"allah");
}
void checkBuyOrder(double cprice, double cma, double priceOpen,ulong pticket){ 
   if(cprice > priceOpen + ConsiderClosingBuyWhenAbovePoints*_Point){
      if(cprice <= cma){        
         if(activeOrderBuy==true){
            trade.PositionClose(pticket);
            activeOrderBuy=false;
         }      
      }
   }
}
void checkSellOrder(double cprice,double cma, double priceOpen,ulong pticket){
   if(cprice < priceOpen + ConsiderClosingSellWhenBelowPoints*_Point){
      if(cprice>=cma){
         if(activeOrderSell==true){
            trade.PositionClose(pticket);
            activeOrderSell=false;
         }
      }
   }
}
