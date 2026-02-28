//+------------------------------------------------------------------+
//|                                            Grid_4_Mohamed_32v.mq5 |
//|                                    Copyright 2025, Yousuf Mesalm. |
//|  www.yousufmesalm.com | WhatsApp +201006179048 | Upwork: https://www.upwork.com/freelancers/youssefmesalm |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Yousuf Mesalm. www.yousufmesalm.com | WhatsApp +201006179048"
#property link      "https://www.yousufmesalm.com"
#property link      "https://www.yousufmesalm.com"
#property description      "Developed by Yousuf Mesalm"
#property description      "https://www.Yousuf-mesalm.com"
#property description      "https://www.mql5.com/en/users/20163440"
#property version   "1.00"

#include  <YM\YM.mqh>
#include <Arrays\ArrayDouble.mqh>
enum close
  {
   buy,
   sell,
   buyAndsell,
   None,
  };
enum Great
  {
   wins,loss
  };
// inputs
sinput string set1 = "<-------------- Currency Pairs Settings-------------->";
input string Suffix="";
input string Perfix="";
input string CustomPairs = "EURUSD";
sinput string set2 = "<----------------Trading Settings-------------------->";
input Great WhichIsBigger=wins;   // which order bigger

input double lotStarter = 0.01;  //Lot Start
input double LotMultiplier=1.6; //Lot Multiplier
input int TradingLevelsNumbers=10; // Levels Number
input int GapBetweenLevels=100;     // Pips between Each level
input bool CloseWith_Points=false;  // Close All Opend Trades with x pips ?
input int ProfitPointsToCloseLossTrades=10;// Close Trades with Profit in Pips
input bool CloseWith_Dollar=false;// Close All Opend Trades with x Dollar ?
input double ProfitUSDToCloseLossTrades=100; // Close Trades with Profit in Dollar
input double Stoploss_for_Lossing= 200 ;   // Stop loss for lossing Trades
input double trailingStop_win=50;  //trailing stop for wins in pips
input double trailingStop_loss=50;  //trailing stop for loss in pips
input double trailingStop_first_wins=100; // First trailing stop wins in pips
input double trailingStop_first_loss=100; // First trailing stop loss in pips
input double closeUSDAccountProfit  = 100;  // Close All when account with profit in Dollar
input long magic_Number = 2020;

//global variables
int TB=0,TS=0,TT=0;
int Total[],TotalSell[],TotalBuy[];
close WhichClos[];
int Highest[],lowest[];

// Arrays
string Symbols[];
double lots[];

// Class object
CExecute *trades[];
CPosition *Positions[];
CPosition *SellPositions[];
CPosition *BuyPositions[];
COrder *Pendings[];
COrder *SellPendings[];
COrder *BuyPendings[];
CUtilities *tools[];
int openDirection[];
CArrayDouble *Levelprices[];
bool trailinghappened=false;
//arrays
double lossSl=0;
double upPrice[];
double dnPrice[];
bool profitUpdate=false;
long HighestTicket=-1;
long lowestTicket=-1;
//+------------------------------------------------------------------+
//|  www.yousufmesalm.com | WhatsApp +201006179048 | Upwork: https://www.upwork.com/freelancers/youssefmesalm |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   StringSplit(CustomPairs, StringGetCharacter(",", 0), Symbols);
   int size= ArraySize(Symbols);
   ArrayResize(trades,size,size);
   ArrayResize(Positions,size,size);
   ArrayResize(SellPositions,size,size);
   ArrayResize(BuyPositions,size,size);
   ArrayResize(Pendings,size,size);
   ArrayResize(BuyPendings,size,size);
   ArrayResize(SellPendings,size,size);
   ArrayResize(tools,size,size);
   ArrayResize(upPrice,size,size);
   ArrayResize(dnPrice,size,size);
   ArrayResize(Levelprices,size,size);
   ArrayResize(WhichClos,size,size);
   ArrayResize(Total,size,size);
   ArrayResize(TotalBuy,size,size);
   ArrayResize(TotalSell,size,size);
   ArrayResize(openDirection,size,size);
   ArrayResize(Highest,size,size);
   ArrayResize(lowest,size,size);
   ArrayResize(lots,TradingLevelsNumbers,TradingLevelsNumbers);


   for(int i=0; i<size; i++)
     {
      Symbols[i]=Perfix+Symbols[i]+Suffix;
      if(SymbolSelect(Symbols[i],true))
        {
         Print(Symbols[i]+" added to Market watch");
        }
      else
        {
         Print(Symbols[i]+" does't Exist");
        }

      trades[i] = new CExecute(Symbols[i], magic_Number);
      BuyPositions[i] = new CPosition(Symbols[i], magic_Number, GROUP_POSITIONS_BUYS);
      SellPositions[i] = new CPosition(Symbols[i], magic_Number, GROUP_POSITIONS_SELLS);
      Positions[i] = new CPosition(Symbols[i], magic_Number, GROUP_POSITIONS_ALL);
      Pendings[i]=new COrder(Symbols[i],magic_Number,GROUP_ORDERS_ALL);
      BuyPendings[i]=new COrder(Symbols[i],magic_Number,GROUP_ORDERS_BUY_STOP);
      SellPendings[i]=new COrder(Symbols[i],magic_Number,GROUP_ORDERS_SELL_STOP);
      tools[i] = new CUtilities(Symbols[i]);


      WhichClos[i]=None;
      Total[i]=0;
      TotalBuy[i]=0;
      TotalSell[i]=0;
      openDirection[i]=0;
      Highest[i]=0;
      lowest[i]=0;
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|  www.yousufmesalm.com | WhatsApp +201006179048 | Upwork: https://www.upwork.com/freelancers/youssefmesalm |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   int size= ArraySize(Symbols);
   for(int i=0; i<size; i++)
     {
      delete(trades[i]);
      delete(BuyPositions[i]);
      delete(SellPositions[i]);
      delete(Positions[i]);
      delete(Pendings[i]);
      delete(tools[i]);

     }

  }
//+------------------------------------------------------------------+
//|  www.yousufmesalm.com | WhatsApp +201006179048 | Upwork: https://www.upwork.com/freelancers/youssefmesalm |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int size= ArraySize(Symbols);
   for(int i=0; i<size; i++)
     {
      int TotalPositions=Positions[i].GroupTotal();
      int TotalPendings=Pendings[i].GroupTotal();
      if(TotalPendings==0&&TotalPositions==0)
        {
         Total[i]=0;
         TotalBuy[i]=0;
         TotalSell[i]=0;
         Highest[i]=0;
         lowest[i]=0;
         openDirection[i]=0;
         WhichClos[i]=None;
         profitUpdate=false;
         HighestTicket=-1;
         lossSl=0;
         lowestTicket=-1;
         upPrice[i]=tools[i].Bid();
         dnPrice[i]=tools[i].Bid();
         double ssl=tools[i].Bid()+(GapBetweenLevels*(TradingLevelsNumbers+0.5)*tools[i].Pip());
         double bsl=tools[i].Ask()-(GapBetweenLevels*(TradingLevelsNumbers+0.5)*tools[i].Pip());
         bool first=true;
         double lot=0;
         for(int x=0; x<TradingLevelsNumbers; x++)
           {
            lots[x]=first?tools[i].NormalizeVolume(lotStarter*LotMultiplier,ROUNDING_OFF):tools[i].NormalizeVolume(lots[x-1]*LotMultiplier,ROUNDING_OFF);


            upPrice[i] =first?(upPrice[i]+(GapBetweenLevels/2)*tools[i].Pip()):upPrice[i]+(GapBetweenLevels*tools[i].Pip());
            dnPrice[i] =first?(dnPrice[i]-(GapBetweenLevels/2)*tools[i].Pip()):dnPrice[i]-(GapBetweenLevels*tools[i].Pip());
            if(WhichIsBigger==wins)
              {
               if(first)
                 {
                  trades[i].Order(TYPE_ORDER_BUYSTOP,lots[x],upPrice[i],bsl,0,SLTP_PRICE,0,30,(string)x);
                  trades[i].Order(TYPE_ORDER_BUYLIMIT,lotStarter,dnPrice[i],bsl,0,SLTP_PRICE,0,30,"-"+(string)x);
                  trades[i].Order(TYPE_ORDER_SELLLIMIT,lotStarter,upPrice[i],ssl,0,SLTP_PRICE,0,30,(string)x);
                  trades[i].Order(TYPE_ORDER_SELLSTOP,lots[x],dnPrice[i],ssl,0,SLTP_PRICE,0,30,"-"+(string)x);

                 }
               else
                 {
                  trades[i].Order(TYPE_ORDER_BUYSTOP,lots[x],upPrice[i],bsl,0,SLTP_PRICE,0,30,(string)x);
                  if(x<TradingLevelsNumbers-1)
                    {
                     trades[i].Order(TYPE_ORDER_BUYLIMIT,lots[x-1],dnPrice[i],bsl,0,SLTP_PRICE,0,30,"-"+(string)x);
                     trades[i].Order(TYPE_ORDER_SELLLIMIT,lots[x-1],upPrice[i],ssl,0,SLTP_PRICE,0,30,(string)x);
                    }
                  trades[i].Order(TYPE_ORDER_SELLSTOP,lots[x],dnPrice[i],ssl,0,SLTP_PRICE,0,30,"-"+(string)x);

                 }
               first=false;

              }
            else
              {
               if(first)
                 {
                  trades[i].Order(TYPE_ORDER_BUYSTOP,lotStarter,upPrice[i],bsl,0,SLTP_PRICE,0,30,(string)x);
                  trades[i].Order(TYPE_ORDER_BUYLIMIT,lots[x],dnPrice[i],bsl,0,SLTP_PRICE,0,30,"-"+(string)x);
                  trades[i].Order(TYPE_ORDER_SELLLIMIT,lots[x],upPrice[i],ssl,0,SLTP_PRICE,0,30,(string)x);
                  trades[i].Order(TYPE_ORDER_SELLSTOP,lotStarter,dnPrice[i],ssl,0,SLTP_PRICE,0,30,"-"+(string)x);
                 }
               else
                 {
                  trades[i].Order(TYPE_ORDER_BUYSTOP,lots[x-1],upPrice[i],bsl,0,SLTP_PRICE,0,30,(string)x);
                  if(x<TradingLevelsNumbers-1)
                    {
                     trades[i].Order(TYPE_ORDER_BUYLIMIT,lots[x],dnPrice[i],bsl,0,SLTP_PRICE,0,30,"-"+(string)x);
                     trades[i].Order(TYPE_ORDER_SELLLIMIT,lots[x],upPrice[i],ssl,0,SLTP_PRICE,0,30,(string)x);
                    }
                  trades[i].Order(TYPE_ORDER_SELLSTOP,lots[x-1],dnPrice[i],ssl,0,SLTP_PRICE,0,30,"-"+(string)x);
                 }
               first=false;

              }
           }


        }


      Traliling(BuyPositions[i],SellPositions[i],tools[i],Pendings[i],openDirection[i]);
      Closing(BuyPositions[i],SellPositions[i],tools[i],Pendings[i],upPrice[i],dnPrice[i],openDirection[i]);
      if(Positions[i].GroupTotal()==0&&Pendings[i].GroupTotal()<TradingLevelsNumbers*4-2)
        {
         Pendings[i].GroupCloseAll(20);
         openDirection[i]=0;
        }
     }
   if(AccountInfoDouble(ACCOUNT_PROFIT)>=closeUSDAccountProfit)
     {
      size= ArraySize(Symbols);
      for(int i=0; i<size; i++)
        {
         Positions[i].GroupCloseAll(30);
         Pendings[i].GroupCloseAll(30);
         openDirection[i]=0;
        }
     }
  }


//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|  www.yousufmesalm.com | WhatsApp +201006179048 | Upwork: https://www.upwork.com/freelancers/youssefmesalm |
//+------------------------------------------------------------------+
void Traliling(CPosition & BuyPos,CPosition & SellPos, CUtilities & tool,COrder & Pending,int & direction)
  {
   long tickets[];
// Positions numbers
   int totalBuy = BuyPos.GroupTotal();
   int totalSell = SellPos.GroupTotal();
//
   if(TB>0&&totalBuy==0)
     {
      TB=0;
     }
   if(TS>0&&totalSell==0)
     {
      TS=0;
     }
//Buy trailing
   double buyPriceOpen=0;
   double lowestBuy=0;
   int Buy_lowest_index=0;
   int Sell_Highestt_index=0;
   string Buy_lowest_comment="";
   string Sell_Highest_comment="";

//Get High Buy PriceOpen
   for(int i = 0; i < totalBuy; i++)
     {
      if(BuyPos.SelectByIndex(i))
        {
         if(BuyPos[i].GetPriceOpen()>buyPriceOpen&&tool.Bid()>BuyPos.GetPriceOpen())
           {
            buyPriceOpen=BuyPos[i].GetPriceOpen();
           }
         if(BuyPos[i].GetPriceOpen()<lowestBuy||lowestBuy==0)
           {
            lowestBuy=BuyPos[i].GetPriceOpen();
            Buy_lowest_index=(int)BuyPos[i].GetComment();
            Buy_lowest_comment=BuyPos[i].GetComment();
           }
        }
     }
   double sellPriceOpen=0;
   double HighestSell=0;
//Get low sell PriceOpen
   for(int i = 0; i < totalSell; i++)
     {
      if(SellPos.SelectByIndex(i))
        {
         if(tool.Bid()<SellPos.GetPriceOpen())
           {
            if(sellPriceOpen==0)
              {
               sellPriceOpen=SellPos[i].GetPriceOpen();
              }
            if(SellPos[i].GetPriceOpen()<sellPriceOpen)
              {
               sellPriceOpen=SellPos[i].GetPriceOpen();
              }
           }
         if(SellPos[i].GetPriceOpen()>HighestSell)
           {
            HighestSell=SellPos[i].GetPriceOpen();
            Sell_Highestt_index=(int)SellPos[i].GetComment();
            Sell_Highest_comment=SellPos[i].GetComment();
           }
        }
     }
   if(buyPriceOpen>0&&lowestBuy>0&&buyPriceOpen>=lowestBuy&&direction!=-1&&(Buy_lowest_index<0||(Buy_lowest_index==0&&Buy_lowest_comment=="0"))&&SellPos.GroupTotal()>0&&BuyPos.GroupTotal()>0)
     {
      double stop=(totalBuy==2&&totalSell==2)?trailingStop_first_wins:trailingStop_win;

      double sl=buyPriceOpen -(stop*tool.Pip());
      TB=totalBuy;
      for(int i = 0; i < totalBuy; i++)
        {
         if(BuyPos.SelectByIndex(i))
           {
            if(BuyPos.GetStopLoss()<sl)
               if(BuyPos.Modify(sl,BuyPos.GetTakeProfit(),SLTP_PRICE))
                 {
                  stop=(totalBuy==2&&totalSell==2)?trailingStop_first_loss:trailingStop_loss;
                  sl=buyPriceOpen -(stop*tool.Pip());
                  for(int z = 0; z < totalSell; z++)
                    {
                     if(SellPos.SelectByIndex(z))
                       {
                        if(SellPos[z].GetComment()==BuyPos[i].GetComment())
                          {
                           if(lossSl==0)
                             {
                              lossSl =SellPos[z].GetStopLoss()+Stoploss_for_Lossing*tool.Pip();
                              SellPos[z].Modify(lossSl,sl,SLTP_PRICE);
                              for(int zz=0; zz<Pending.GroupTotal(); zz++)
                                {
                                 if(Pending[zz].GetType()==TYPE_ORDER_SELLLIMIT)
                                   {
                                    if(Pending[zz].GetStopLoss()!=lossSl)
                                       Pending[zz].Modify(-1,lossSl,-1,SLTP_PRICE);
                                   }
                                }
                             }
                           break;
                          }
                       }
                    }
                  direction=1;
                  int s=Pending.GroupTotal();
                  for(int x=0; x<s; x++)
                    {
                     int c=(int)Pending[x].GetComment();
                     if(c<=Buy_lowest_index)
                       {
                        long ticket=Pending[x].GetTicket();
                        int tsize=ArraySize(tickets);
                        ArrayResize(tickets,tsize+1);
                        tickets[tsize]=ticket;
                       }
                    }
                  for(int xx=0; xx<ArraySize(tickets); xx++)
                    {
                     Pending[tickets[xx]].Close(30);
                    }
                 }
           }
        }
     }



   if(sellPriceOpen>0&&HighestSell>0&&sellPriceOpen<=HighestSell&&direction!=1&&(Sell_Highestt_index>0||(Sell_Highestt_index==0&&Sell_Highest_comment=="-0"))&&SellPos.GroupTotal()>0&&BuyPos.GroupTotal()>0)
     {
      double stop=(totalBuy==2&&totalSell==2)?trailingStop_first_wins:trailingStop_win;
      double sl=sellPriceOpen +(stop*tool.Pip());
      TS=totalSell;
      for(int i = 0; i < totalSell; i++)
        {
         if(SellPos.SelectByIndex(i))
           {
            if(SellPos[i].GetStopLoss()>sl)
               if(SellPos.Modify(sl,SellPos.GetTakeProfit(),SLTP_PRICE))
                 {
                  stop=(totalBuy==2&&totalSell==2)?trailingStop_first_loss:trailingStop_loss;
                  sl=sellPriceOpen +(stop*tool.Pip());
                  for(int z = 0; z < totalBuy; z++)
                    {
                     if(BuyPos.SelectByIndex(z))
                       {
                        if(BuyPos[z].GetComment()==SellPos[i].GetComment())
                          {
                           if(lossSl==0)
                             {
                              lossSl=BuyPos[z].GetStopLoss()-Stoploss_for_Lossing*tool.Pip();
                              BuyPos[z].Modify(lossSl,sl,SLTP_PRICE);
                              for(int zz=0; zz<Pending.GroupTotal(); zz++)
                                {
                                 if(Pending[zz].GetType()==TYPE_ORDER_BUYLIMIT)
                                   {
                                    if(Pending[zz].GetStopLoss()!=lossSl)
                                       Pending[zz].Modify(-1,lossSl,-1,SLTP_PRICE);
                                   }
                                }
                             }
                           break;
                          }
                       }
                    }
                  direction=-1;
                  int s=Pending.GroupTotal();
                  for(int x=0; x<s; x++)
                    {
                     int c=(int)Pending[x].GetComment();
                     if(c>=Sell_Highestt_index)
                       {
                        long ticket=Pending[x].GetTicket();
                        int tsize=ArraySize(tickets);
                        ArrayResize(tickets,tsize+1);
                        tickets[tsize]=ticket;
                       }
                    }
                  for(int xx=0; xx<ArraySize(tickets); xx++)
                    {
                     Pending[tickets[xx]].Close(30);
                    }
                 }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|  www.yousufmesalm.com | WhatsApp +201006179048 | Upwork: https://www.upwork.com/freelancers/youssefmesalm |
//+------------------------------------------------------------------+
void Closing(CPosition & BuyPos,CPosition & SellPos, CUtilities & tool,COrder & Pending,double up,double dn,int & direction)
  {
// Positions numbers
   int totalBuy = BuyPos.GroupTotal();
   int totalSell = SellPos.GroupTotal();
   double profitpoint=0;
// logics

   if(CloseWith_Points)
     {
      if(totalSell>0&&totalBuy==0&&tool.Bid()>dn)
        {
         if(SellPos.GroupTotalProfit()>0)
           {

            for(int i=0; i<totalSell; i++)
              {

               profitpoint+=SellPos[i].GetPriceOpen()-tool.Bid();
              }

            if(profitpoint>=ProfitPointsToCloseLossTrades*tool.Pip())
              {
               SellPos.GroupCloseAll(20);
               Pending.GroupCloseAll(20);
              }

           }
        }
      else
         if(totalBuy>0&&totalSell==0&&tool.Ask()<up)
           {
            if(BuyPos.GroupTotalProfit()>0)
              {


               for(int i=0; i<totalBuy; i++)
                 {

                  profitpoint+=tool.Bid()-BuyPos[i].GetPriceOpen();
                 }

               if(profitpoint>=ProfitPointsToCloseLossTrades*tool.Pip())
                 {
                  BuyPos.GroupCloseAll(20);
                  Pending.GroupCloseAll(20);
                 }

              }
           }
     }
   if(CloseWith_Dollar)
     {
      if(SellPos.GroupTotalProfit()>=ProfitUSDToCloseLossTrades)
        {

         if(totalSell>0&&totalBuy==0&&tool.Bid()>dn)
           {


            SellPos.GroupCloseAll(20);
            Pending.GroupCloseAll(20);

           }
        }
      if(BuyPos.GroupTotalProfit()>=ProfitUSDToCloseLossTrades)
        {
         if(totalBuy>0&&totalSell==0&&tool.Ask()<up)
           {

            BuyPos.GroupCloseAll(20);
            Pending.GroupCloseAll(20);

           }
        }
     }

   if(direction!=0)
     {
      if(totalSell>0&&totalBuy==0)
        {

         SellPos.GroupCloseAll(20);
         Pending.GroupCloseAll(20);
         direction=0;
        }
      if(totalBuy>0&&totalSell==0)
        {

         BuyPos.GroupCloseAll(20);
         Pending.GroupCloseAll(20);
         direction=0;
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
