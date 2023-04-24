//+------------------------------------------------------------------+
//|                                      Volume & Delta template.mq4 |
//|                                                                  |
//|                                                 Alex. 20.07.2020 |
//+------------------------------------------------------------------+
#property strict
//####################################################################                                                     //+----------------- CLUSTERDELTA VOLUME DATA --------------------------+

#include <tools/DateTime.mqh>

string     dll_clusterdelta_version="5.2";
string     dll_footprint_version="1.0";
string     footprint_ver = "1.0";

#import "clusterdelta_v5x2.dll"
string     Receive_Information (int &, string);
int        Send_Query (int &, string, string, int, string, string, string, string, string, string, int, string, string, string,int);
#import

#import "footprint_v1x0.dll"
string     Footprint_Data(int&,string);
int        Footprint_Subscribe(int &, string, string, int, string, string, string, string, string, string, int, string, string, string,int);
#import

#import "online_mt4_v4x1.dll"
int        Online_Init(int&, string, int);
string     Online_Data(int&,string);
int        Online_Subscribe(int &, string, string, int, string, string, string, string, string, string, int, string, string, string,int);
#import


datetime   TIME_Array[];   // Array for TIME
double     VOLUME_Array[]; // Array of Volumes, indexes of array are corelated to TIME_ARRAY
double     DELTA_Array[];  // Array of Deltas, indexes of array are corelated to TIME_ARRAY

int        t_Vol, t_Del;


int        GMT_SET = 1;  // Metatrader GMT set to GMT =3, not auto;
int        Delta_inv;
string     indicator_client;
string     MetaTrader_GMT;   //= "+3";  // Change if GMT is different for both

//####################################################################                                                     //+----------------- CLUSTERDELTA CLUSTERS DATA --------------------------+



string     clusterdelta_client = ""; // key to DLL
string     indicator_id = ""; // Indicator Global ID
string     HASH_IND     = " ";

string     Ticker, FuturesName;
int        X_Period;

int        DigitsAfterComa = 0;
int        UpdateFreq      = 15;
datetime   myUpdateTime    = D'1970.01.01 00:00'; // init of fvar
datetime   X_last_loaded = 0;
bool       query_in_progress = false;


datetime   TM[2];
long       VL[2], DL[2];

struct Cluster {

  datetime opentime;    // Open bar TIME
  double   open;        // OPEN price
  double   close;       // CLOSE price
  double   high;        // HIGH price
  double   low;         // LOW price

  long     total_ask;   // SUM OF ASK
  long     total_bid;   // SUM OF ASK / BID
  long     volume;
  long     delta;

  double   prices[];    // Cluster Data - Price
  long     ask[];       // Cluster Data - Ask
  long     bid[];       // Cluster Data - Bid

} Clusters[], LastMinute;
datetime opentimeIdx[];  int clustersIdx[];


//####################################################################

      bool      Reload_Data         = false;
input int       GMT                 = 3;               // MetaTrader_GMT
input string    Instrument          = "AUTO";          // Ticker
input int       Cluster_Period      = PERIOD_CURRENT;  // Cluster data TimeFrame

input bool      Load_Vol_Del        = true;            // !!! Back Test only - Load monthly Volume & Delta from file


//####################################################################

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {

  myUpdateTime = TimeLocal();

  if(Cluster_Period    == PERIOD_CURRENT)  X_Period = Period();
  else                                     X_Period = Cluster_Period;


  if(Instrument == "AUTO")
  {
    Ticker = "AUTO";
    if(StringFind(Symbol(),"NQ100") != -1)  Ticker = "NQ";
    if(StringFind(Symbol(),"SP500") != -1)  Ticker = "ES";
    if(StringFind(Symbol(),"DJI")   != -1)  Ticker = "YM";
  }   else Ticker = Instrument;



  if(Period() > 240)  {Print("Current TimeFrame not supported"); ExpertRemove();}

  // --- Volume & Delta ---
  GlobalVariableDel(indicator_client);
  GlobalVariableDel(indicator_id);
  if(GMT >  0) MetaTrader_GMT = "+" + IntegerToString(GMT);
  if(GMT <= 0) MetaTrader_GMT = IntegerToString(GMT);


  if(!IsDllsAllowed())    { Print("!!! --- DLL disallowed --- !!!");          ExpertRemove();}
  int DLL_init = 1; Online_Init(DLL_init, AccountCompany(), AccountNumber());





  do // Volume & Delta  ---  DO NOT CHANGE THIS CODE & DATA
  {
    indicator_client =
       "CDPA" + StringSubstr(DoubleToString(TimeLocal(),0),7,3)+""+DoubleToStr(MathAbs((MathRand()+3)%10),0);
  } while (GlobalVariableCheck(indicator_client));
  GlobalVariableTemp(indicator_client);


  do  // Clusters  ---  this block do not use ClusterDelta_Server but register for unique id
  {
    clusterdelta_client = "CDPF" + StringSubstr(IntegerToString(TimeLocal()),7,3)+""+DoubleToString(MathAbs(MathRand()%10),0);
    indicator_id = "CLUSTERDELTA_"+clusterdelta_client;
  } while (GlobalVariableCheck(indicator_id));
  GlobalVariableTemp(indicator_id);  HASH_IND = clusterdelta_client;



  if(StringFind(Symbol(),"USDJPY",0) == -1 &&
     StringFind(Symbol(),"USDCAD",0) == -1 &&
     StringFind(Symbol(),"USDCHF",0) == -1   )  Delta_inv = 1;                                                            // Invert Delta for JPY, CHF, CAD
  else Delta_inv = -1;


//--- create timer
   if(!IsTesting())  EventSetMillisecondTimer(100);

   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   EventKillTimer();
   GlobalVariableDel(indicator_id);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {

  static int mmm, ddd, mn;  static long Cluster_vol, Cluster_vol_0, OL_vol, OL_vol_0;
  int arr_sz, x_ix;  datetime dt;
  
  string id, txt; datetime t; double p;
  long x_vol = 0, x_del = 0, x_ask =0, x_bid = 0, x_vol_tl = 0, x_ask_tl = 0, x_bid_tl = 0; 
  int vol, del;


  if(IsTesting())
  {
    if(mmm != Month()  &&  Load_Vol_Del)  {mmm = Month(); Testing_Load_file_Vol_Delta_by_Month();}
    if(   TimeDay(iTime(NULL,PERIOD_CURRENT,1))!= Day()
       || TimeHour(iTime(NULL,PERIOD_CURRENT,1)) > TimeHour(iTime(NULL,PERIOD_CURRENT,0))
       || ddd != Day()                                                                    )                                // ###  NEW DAY  ###
    {
      ddd = Day();
      if(!CLUSTER_Daily_File_Load(Time[0]))                                                                                // load Cluster data from file
      {
        Print("  !!! --- Claster data file not found --- !!!");
        if(!CLUSTER_Testing_Load())                                                                                        // no file - create Cluster data file
          Print("  !!! --- Claster data not downloaded --- !!!");                                                          // Cluster data not downloaded
        else                                                                                                               // Get Cluster data
        {
          CLUSTER_Daily_File_Write(iTime(NULL,PERIOD_D1,0));                                                               // write Cluster data to file (for future use)
          arr_sz = ArraySize(Clusters);  ArrayResize(opentimeIdx, arr_sz);  ArrayResize(clustersIdx, arr_sz);              // create Claster search array
          for(int i = 0; i < arr_sz; i ++)  {opentimeIdx[i] = Clusters[i].opentime; clustersIdx[i] = i; }                  // fill Claster search array
          CLUSTER_SortDictionary(opentimeIdx, clustersIdx, arr_sz);                                                        // sort Claster search array
        }
      }
    }

    if(mn != Minute())
    {
      mn = Minute();
      if(TimeHour(Time[1]) > 0)
      {
        x_ix = CLUSTER_by_index(1);
        if(x_ix != 0)
        {
          t = Time[1]; x_vol = Clusters[x_ix].volume;  x_del = Clusters[x_ix].delta;

          id = "vol_m_X"; p = Low [1] -15 *Point;  txt = IntegerToString(x_del);
          ObjectsDeleteAll(0, id + IntegerToString((int)t));  SetText(id, txt, t, p, DodgerBlue, 8, false, false);

          id = "del_m_X"; p = Low [1] -25 *Point;  txt = IntegerToString(x_vol);
          ObjectsDeleteAll(0, id + IntegerToString((int)t));  SetText(id, txt, t, p, Salmon, 8, false, false);

          if(Load_Vol_Del)
          {
            t_Vol = VOLUME_by_index(1); t_Del = DELTA_by_index(1);

            id = "vol_m_V"; p = Low [1] +25 *Point;  txt = IntegerToString(t_Del);
            ObjectsDeleteAll(0, id + IntegerToString((int)t));  SetText(id, txt, t, p, Blue, 8, true, false);

            id = "del_m_V"; p = Low [1] +15 *Point;  txt = IntegerToString(t_Vol);
            ObjectsDeleteAll(0, id + IntegerToString((int)t));  SetText(id, txt, t, p, Red, 8, true, false);
          }
        }
      }
    }
  }


  if(!IsTesting())
  {   
    if(TimeHour(Time[1]) > 0)
    {
      x_ix = CLUSTER_by_index(1);
      if(x_ix != 0)
      {
        if(ArraySize(Clusters[x_ix].prices) > 0)
        {
          x_ask_tl = Clusters[x_ix].total_ask;  x_bid_tl = Clusters[x_ix].total_bid;
          x_vol_tl = x_ask_tl + x_bid_tl;
          for(int i = 0; i < ArraySize(Clusters[x_ix].prices); i ++)
          {
            x_ask += Clusters[x_ix].ask[i];
            x_bid += Clusters[x_ix].bid[i];
          }
          x_vol = x_ask + x_bid;
        }

        if(Cluster_vol != x_vol_tl  ||  OL_vol != VL[1])
        {
          int sec = Seconds();
          Cluster_vol = x_vol_tl;  OL_vol = VL[1];

          t = Time[1];

          id = "sec"; p = High[1] +25 *Point;
          ObjectsDeleteAll(0, id + IntegerToString((int)t));  SetText(id, IntegerToString(sec) +"'", t, p, Pink, 8, true,  false);

          id = "ask_m"; p = High[1] +10 *Point;
          ObjectsDeleteAll(0, id + IntegerToString((int)t));  SetText(id, IntegerToString(x_ask), t, p, YellowGreen, 8, true,  false);
          id = "bid_m"; p = Low [1] -15 *Point;
          ObjectsDeleteAll(0, id + IntegerToString((int)t));  SetText(id, IntegerToString(x_bid), t, p, Salmon, 8, false, false);
          id = "vol_m"; p = Low [1] -30 *Point;
          ObjectsDeleteAll(0, id + IntegerToString((int)t));  SetText(id, IntegerToString(x_vol_tl), t, p, DodgerBlue, 8, false, false);

          id = "vol_m_V"; p = Low [1] -60 *Point;  txt = IntegerToString(VL[1]);
          ObjectsDeleteAll(0, id + IntegerToString((int)t));  SetText(id, txt, t, p, Blue, 8, false, false);

          id = "del_m_V"; p = Low [1] -70 *Point;  txt = IntegerToString(DL[1]);
          ObjectsDeleteAll(0, id + IntegerToString((int)t));  SetText(id, txt, t, p, Red, 8, false, false);

          id = "vol_m_X"; p = Low [1] -90 *Point;
          txt = IntegerToString(Clusters[x_ix].volume);
          ObjectsDeleteAll(0, id + IntegerToString((int)t));  SetText(id, txt, t, p, White, 8, false, false);

          id = "del_m_X"; p = Low [1] -100 *Point;
          txt = IntegerToString(Clusters[x_ix]. delta);
          ObjectsDeleteAll(0, id + IntegerToString((int)t));  SetText(id, txt, t, p, White, 8, false, false);
        }
      }

      x_ix = CLUSTER_by_index(0);
      if(x_ix != 0)
      {
        if(Cluster_vol_0 != Clusters[x_ix].volume  ||  OL_vol_0 != VL[0])
        {
          Cluster_vol_0 = Clusters[x_ix].volume;  OL_vol_0 = VL[0]; t = Time[0];

          id = "vol_m_X_0"; p = Low [0] -120 *Point;
          txt = IntegerToString(Clusters[x_ix].volume);
          ObjectsDeleteAll(0, id + IntegerToString((int)t));  SetText(id, txt, t, p, Lime, 8, false, false);

          id = "del_m_X_0"; p = Low [0] -130 *Point;
          txt = IntegerToString(Clusters[x_ix]. delta);
          ObjectsDeleteAll(0, id + IntegerToString((int)t));  SetText(id, txt, t, p, Lime, 8, false, false);

          id = "ol_vol_m_X_0"; p = Low [0] -150 *Point;
          txt = IntegerToString(VL[0]);
          ObjectsDeleteAll(0, id + IntegerToString((int)t));  SetText(id, txt, t, p, Magenta, 8, false, false);

          id = "ol_del_m_X_0"; p = Low [0] -160 *Point;
          txt = IntegerToString(DL[0]);
          ObjectsDeleteAll(0, id + IntegerToString((int)t));  SetText(id, txt, t, p, Magenta, 8, false, false);
        }
      }
    }
  }
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {

  uchar static Timer = 0, Timer_X = 0, mn;
  int x_ix_0, x_ix_1;
  bool activ = false, active_x = false;

  if(TimeHour(TimeCurrent()) < 1)   return;                                                                                // Do not download DPOC data before 1:00 (if set)
  if(!IsTesting())
  {
    Timer ++;  Timer_X ++;

    if(mn != Minute())  {CLUSTER_LastMinute_Subscribe(); mn = Minute();}
    if(Seconds() == 59  ||  Timer >= 5)  { if(VOLUMES_GetOnline())   Timer = 0;}                                           // Volume update On-line
    if(!query_in_progress  &&  myUpdateTime <= TimeLocal())                                                                // Server request FULL X_update
    {
      myUpdateTime = TimeLocal() + UpdateFreq;
      if(CLUSTER_SetData(iTime(NULL,PERIOD_D1,0), TimeLocal()))  {query_in_progress = true;  active_x = true;}
    }

    if(query_in_progress  &&  Timer >= 50)                                                                                 // request FULL X_update
    {
      if(CLUSTER_GetData())  {query_in_progress = false; Timer = 0; activ = true;}
    }

    if(Timer_X >= 50  &&  DigitsAfterComa != 0  &&  !activ)  { CLUSTER_LastMinute();  Timer_X = 0;}                        // Volume[0] On-Line bigger, request LastMimute X_update


    x_ix_0 = CLUSTER_by_index(0);
    x_ix_1 = CLUSTER_by_index(1);
    if(x_ix_0 == 0  ||  x_ix_1 == 0)                                                               return;

    if(VL[1] > Clusters[x_ix_1].volume  &&  !active_x)                                                                     // Volume[1] On-Line bigger, Server request FULL X_update
    {
      myUpdateTime = TimeLocal() + UpdateFreq;
      if(CLUSTER_SetData(iTime(NULL,PERIOD_D1,0), TimeLocal()))  query_in_progress = true;
    }

    if(query_in_progress  &&  VL[0] > Clusters[x_ix_0].volume  &&  !activ)
      {if(CLUSTER_GetData())  query_in_progress = false; Timer = 0;}                                                       // Volume[1] On-Line bigger, request FULL X_update

    if(VL[0] > Clusters[x_ix_0].volume  &&  Timer_X >= 10  &&  DigitsAfterComa != 0  &&  !activ)
      { CLUSTER_LastMinute();  Timer_X = 0;}                                                                               // Volume[0] On-Line bigger, request LastMimute X_update
  }
}
//+------------------------------------------------------------------+



bool  CLUSTER_Testing_Load() {

  ulong    Timer_uSEC;
  bool     X_load = false;
  int      it, itt, c;
  datetime startTime, endTime;

  for(itt = 0; itt < 5; itt ++)                                                                                            // 5 attempt with reinitialization
  {
    clusterdelta_client = "CDPF" + StringSubstr(IntegerToString(TimeLocal()),7,3)+""+DoubleToString(MathAbs(MathRand()%10),0);
    indicator_id = "CLUSTERDELTA_"+clusterdelta_client;
    Print("     Cluster - initialization # ", itt);
    for(it = 0; it < 3; it ++)                                                                                             // 3 attempt to load single request
    {
      Timer_uSEC = GetMicrosecondCount();   // ---------- send server request
      for(c = 1; c <= 3; c ++)
      {
        Print("     Cluster - send server request # ",c);
        X_last_loaded = 0;
        startTime = iTime(NULL,PERIOD_D1,0);
        endTime   = startTime + 86399;
        //startTime = iTime(NULL,PERIOD_D1,0);  endTime = startTime - 86400;
        if(!CLUSTER_SetData( startTime, endTime ))
        {
          while(!IsStopped()  &&  GetMicrosecondCount() < (Timer_uSEC + 5000000 *c))  { for( int cc = 0; cc < 100; cc ++)}
        }   else { Print("     Cluster data loaded, date - ", TimeToStr(startTime)); break; }
      }

      Timer_uSEC = GetMicrosecondCount();   // ---------- check for loaded data
      for(c = 1; c <= 5; c ++)
      {
        Print("     Cluster - check for server response # ",c);
        int arr_sz = 1440 / X_Period;
        ArrayFree(Clusters);     ArrayResize(Clusters, arr_sz);
        if(!CLUSTER_GetData())
        {
          while(!IsStopped()  &&  GetMicrosecondCount() < (Timer_uSEC + 5000000 * c))  for( int cc = 0; cc < 100; cc ++);  // no data, pause before next try
        }   else  { Print("     Cluster data loaded # ",it); X_load = true; break;}
      }
      if(X_load)  break;
    }
    if(X_load)  break;
  }

  return(X_load);
}
bool  CLUSTER_LastMinute_Subscribe() {

  int i, k = 0;

  i = Footprint_Subscribe(k,clusterdelta_client,
                      Symbol(), 1,
                      TimeToStr(TimeCurrent()), TimeToStr(Time[0]),
                      Ticker,
                      TimeToStr(X_last_loaded),
                      MetaTrader_GMT,footprint_ver,0,
                      "","",
                      AccountCompany(),AccountNumber());

  if (i < 0) { Alert ("Error during query registration");                                          return(false);}


  string ver="4.1";
  i = Online_Subscribe(k,indicator_client,
                      Symbol(), X_Period,
                      TimeToStr(TimeCurrent()), TimeToStr(Time[0]),
                      Ticker,
                      TimeToStr(X_last_loaded),
                      MetaTrader_GMT,ver, 1,
                      TimeToStr(D'2017.01.01 00:00'), TimeToStr(D'2017.01.01 00:00'),
                      AccountCompany(),AccountNumber());

  if (i < 0) { Alert ("Error during query registration");                                          return(false);}

  return(true);
}
bool  CLUSTER_LastMinute() {

  string    ts_stream,
            stream[],lines[],candle[],data[],
            bartime;
  int       arr_sz, length = 0, rows;
  double    price, open, close;
  long      deltaAsk, deltaBid, newAsk, newBid;
  datetime  newDateTime;
  CDateTime BarOpen;


  ts_stream = Footprint_Data(length, clusterdelta_client);
  if(length  == 0) {                     return(false); }
  if(StringLen(ts_stream))
  {
    arr_sz = ArraySize(Clusters) -1;
    rows = StringSplit(ts_stream, '\n', lines);
    for(int i = 0; i < rows; i ++)
    {
      if(StringSplit(ts_stream,':',stream) >= 3)
      {
        if(stream[0] == clusterdelta_client && StringToUpper(stream[1])==StringToUpper(FuturesName))                       // that is our stream
        {
          bartime = "";
          int n = StringSplit(stream[2],'|',candle);                                                                      // split to bar data (all bar data to 1 line)
          if(n > 0)
          {
            int r = StringSplit(candle[0],';',data);                                                                       // split current bar data
            if(r >= 2)
            {
              bartime = data[0];                                                                                           // -- last minute bar opentime
              open  = NormalizeDouble(StringToDouble(data[1]),DigitsAfterComa);                                            // -- last minute bar open
              close = NormalizeDouble(StringToDouble(data[2]),DigitsAfterComa);                                            // -- last minute bar close

              if(Delta_inv < 0)                                                                                            // --  for USDJPY, USDCAD, USDCHF
              {
                open  = ND(1.0 /open);
                close = ND(1.0 /close);
              }
            }
          }

          if(bartime != "")                                                                                                // last minute bar opentime not blank
          {
            BarOpen.Year((int)StringToInteger(StringSubstr(bartime,0,4)));
            BarOpen.Mon((int)StringToInteger(StringSubstr(bartime,4,2)));
            BarOpen.Day((int)StringToInteger(StringSubstr(bartime,6,2)));
            BarOpen.Hour((int)StringToInteger(StringSubstr(bartime,8,2)));
            BarOpen.Min((int)StringToInteger(StringSubstr(bartime,10,2)));
            BarOpen.Sec(0); // we get 1min close bar so open is 0

            if(BarOpen.DateTime() < LastMinute.opentime)                                           continue;               // Time & sales behind clusters (something bad happens)
            if(TimeToString(BarOpen.DateTime(),TIME_DATE) !=
               TimeToString(Clusters[arr_sz].opentime,TIME_DATE))                                                          // T&S Bar opentime != last saved Cluster Bar opentime
            {
              // different days between LastMinute and Stream
              // we may allow it only if it monday open
              if(!(BarOpen.day_of_week == 1 && BarOpen.hour <= 1))                                 continue;
            }

            if(BarOpen.DateTime() > LastMinute.opentime)                                                                   // new bar, save last minute bar opentime
            {
              ArrayFree(LastMinute.prices); ArrayFree(LastMinute.ask); ArrayFree(LastMinute.bid);
              LastMinute.opentime = BarOpen.DateTime();
            }


            if(Clusters[arr_sz].opentime + X_Period * 60 <= BarOpen.DateTime())                                            // #####   T&S ahead Clusters Bars data. NEED NEW RECORDS   #####
            {
              int w=1;
              do
              {newDateTime = Clusters[arr_sz].opentime + w * X_Period * 60;  w++;}                                         // -- getting correct bar open time for using timeframe
              while (newDateTime + X_Period *60 < BarOpen.DateTime());

              arr_sz +=1;                                                                                                  // -- encrease Clusters array size (arr_sz - last array element, not size)
              ArrayResize(Clusters, arr_sz +1);
              ArrayResize(opentimeIdx, arr_sz +1);
              ArrayResize(clustersIdx, arr_sz +1);

              opentimeIdx[arr_sz] = newDateTime;                                                                           // -- "index search" array update
              clustersIdx[arr_sz] = arr_sz;

              Clusters[arr_sz].opentime = newDateTime;                                                                     // -- fill just created new Bar Cluster
              Clusters[arr_sz].open  = open;
              Clusters[arr_sz].close = close;
              Clusters[arr_sz].high  =   open >= close ? open  : close ;
              Clusters[arr_sz].low   =   open >= close ? close : open;
              Clusters[arr_sz].total_ask = 0;
              Clusters[arr_sz].total_bid = 0;
            }                                                                                                              // new records created


            ArrayFree(LastMinute.prices);  ArrayFree(LastMinute.ask);  ArrayFree(LastMinute.bid);                          // reset array for last minute Bar cluster (price, ask, bid)
            int arr_last = -1, j;
            for(j = 1; j < n; j ++)                                                                                    // n=number of cluster inside information
            {
              int k = StringSplit(candle[j],';', data);
              if(k >= 2)
              {
                // DATA FROM STREAM
                price   = NormalizeDouble(StringToDouble(data[0]),DigitsAfterComa);
                newAsk  = StringToInteger(data[1]);
                newBid  = StringToInteger(data[2]);
                if(!(price == 0 || newAsk  < 0 || newBid < 0))                                                             // cluster data valid, fill depends on instrument
                {
                  arr_last ++;                                                                                             // -- data valid encrease array size for last minute cluster data
                  ArrayResize(LastMinute.prices, arr_last +1);
                  ArrayResize(LastMinute.ask,    arr_last +1);
                  ArrayResize(LastMinute.bid,    arr_last +1);
                  if(Delta_inv > 0)                                                                                        // -- most of the Instruments
                  {
                    LastMinute.prices[arr_last] = price;
                    LastMinute.ask   [arr_last] = newAsk;
                    LastMinute.bid   [arr_last] = newBid;
                  }
                  else                                                                                                     // -- for USDJPY, USDCAD, USDCHF
                  {
                    LastMinute.prices[arr_last] = ND(1.0/price);
                    LastMinute.ask   [arr_last] = newBid;
                    LastMinute.bid   [arr_last] = newAsk;
                  }
                }
              }
            }  CLUSTER_SortArray(LastMinute.prices, LastMinute.ask, LastMinute.bid );                                     // get last minute clusters data to array and sort it


            if(ArraySize(Clusters[arr_sz].prices) == 0)                                                                    // #####   NEW BAR. CREATE and FILL DATA   #####
            {
              int new_sz = ArraySize(LastMinute.prices);                                                                   // -- set correct array size for just created new Bar Clusters same as last minute array
              ArrayResize(Clusters[arr_sz].prices, new_sz);
              ArrayResize(Clusters[arr_sz].ask,    new_sz);
              ArrayResize(Clusters[arr_sz].bid,    new_sz);

              for(j = 0; j < new_sz; j ++)                                                                                 // -- fill last minute clusters data to just created new Bar
              {
                Clusters[arr_sz].prices [j] = LastMinute.prices  [j];
                Clusters[arr_sz].ask    [j] = LastMinute.ask     [j];
                Clusters[arr_sz].bid    [j] = LastMinute.bid     [j];

                Clusters[arr_sz].total_ask += LastMinute.ask [j];
                Clusters[arr_sz].total_bid += LastMinute.bid [j];
              }



              Clusters[arr_sz].low  = LastMinute.prices[0];
              Clusters[arr_sz].high = LastMinute.prices[new_sz -1];

              Clusters[arr_sz].volume = Clusters[arr_sz].total_ask + Clusters[arr_sz].total_bid;
              Clusters[arr_sz].delta  = Clusters[arr_sz].total_ask - Clusters[arr_sz].total_bid;
            }

            else                                                                                                           // #####   EXISTING BAR   #####
            {
              int    x_sz  = ArraySize(Clusters[arr_sz].prices);                                                           // clusters size for existing Bar
              double x_min = Clusters[arr_sz].prices[0],                                                                   // min price
                     x_max = Clusters[arr_sz].prices[x_sz -1];                                                             // max price

              for(j = 0; j < ArraySize(LastMinute.prices); j ++)                                                           // Search to asign last minute cluster data
              {
                if(LastMinute.prices[j] - x_min + 0.1 * Point >= 0  &&  LastMinute.prices[j] - x_max - 0.1 * Point <= 0)   // +++++   last minute cluster data inside Bar   +++++
                {
                  for(int q = 0; q < x_sz; q ++)                                                                           // -- search price cluster in existing bar
                  {
                    if(MathAbs(Clusters[arr_sz].prices[q] - LastMinute.prices[j]) <= 0.1 *Point)                           // -- cluster price mutch, update data
                    {
                      if(Clusters[arr_sz].ask [q] < LastMinute.ask [j])
                      {
                        deltaAsk = LastMinute.ask [j] - Clusters[arr_sz].ask [q];
                        Clusters[arr_sz].total_ask += deltaAsk;
                        Clusters[arr_sz].ask [q] = LastMinute.ask [j];
                      }

                      if(Clusters[arr_sz].bid [q] < LastMinute.bid [j])
                      {
                        deltaBid = LastMinute.bid [j] - Clusters[arr_sz].bid [q];
                        Clusters[arr_sz].total_bid += deltaBid;
                        Clusters[arr_sz].bid [q] = LastMinute.bid [j];
                      }
                      break;                                                                                               // data updated, no need to continue Bar price search cluster
                    }
                  }
                }

                else                                                                                                       // +++++   last minute cluster data outside Bar +++
                {
                  int new_sz = ArraySize(Clusters[arr_sz].prices) +1;                                                      // -- encrease array size for new cluster
                  ArrayResize(Clusters[arr_sz].prices, new_sz);
                  ArrayResize(Clusters[arr_sz].ask,    new_sz);
                  ArrayResize(Clusters[arr_sz].bid,    new_sz);

                  Clusters[arr_sz].prices [new_sz -1] = LastMinute.prices [j];                                             // -- create cluster data
                  Clusters[arr_sz].ask    [new_sz -1] = LastMinute.ask   [j];
                  Clusters[arr_sz].bid    [new_sz -1] = LastMinute.bid   [j];

                  Clusters[arr_sz].total_ask += LastMinute.ask [j];                                                        // -- update total Ask & Bid
                  Clusters[arr_sz].total_bid += LastMinute.bid [j];
                }
              }

              CLUSTER_SortArray(Clusters[arr_sz].prices, Clusters[arr_sz].ask, Clusters[arr_sz].bid );
              Clusters[arr_sz].low  = Clusters[arr_sz].prices[0];
              Clusters[arr_sz].high = Clusters[arr_sz].prices[ArraySize(Clusters[arr_sz].prices) -1];

              Clusters[arr_sz].volume = Clusters[arr_sz].total_ask + Clusters[arr_sz].total_bid;
              Clusters[arr_sz].delta  = Clusters[arr_sz].total_ask - Clusters[arr_sz].total_bid;
            }

          } // bartime
        } // stream[0] == clusterdelta_client
      } // ts_Stream, stream;
    } // for i=0; lines for diff instruments
  } // StringLen

  return (true);
}
bool  CLUSTER_SetData(datetime startTime, datetime endTime) {

  int k = 0, i = 0;
  i = Send_Query(k,clusterdelta_client,
                 Symbol(),
                 X_Period,                                                                                                 // Timeframe in minutes
                 TimeToStr(TimeCurrent()), TimeToStr(Time[0]),
                 Ticker,
                 TimeToStr(X_last_loaded),                                                                                 // last_loaded
                 MetaTrader_GMT,footprint_ver,
                 (int)StringToInteger(""),
                 TimeToStr(startTime),TimeToStr(endTime),"API",0);

  if (i < 0) { Alert ("Error during query registration"); return(false); }

  return(true);
}
bool  CLUSTER_GetData() {


  if(!IsTesting())
  {
    static int ddd;
    if(TimeDay(Time[1]) != ddd)
    {
      ddd = Day();
      ArrayFree(Clusters);
    }
  }

  int  index = -1, arr_sz, new_sz;
  bool new_bar;



  int m, e, i, n, p, b, d, c;

  datetime bartime;
  double   baropen, barhigh, barlow, barclos, price, ask, bid;
  string   barstartid;
  string   ticksizeStr;

  string lines[];
  string v[];
  string candle[];
  string ohlc[];
  string data[], askbid[];
  //string tsdata[];

  string  response = "";
  int     length   = 0;
  int     rows     = 0;


  response = Receive_Information (length, clusterdelta_client);   if (length==0)                   return(false);          // Data from DLL
  if(StringLen(response) > 1)                                                                                              // if we got response (no care how), convert it to mt4 buffers
  {
    rows = StringSplit(response, '\n', lines);                                                                             // data to rows - array lines[]
    if(rows)                                                                                                               // no data - 1 row
    {
      string FirstStringFromServer = lines[0];                                                                             // first string of response
      if(StringSubstr(FirstStringFromServer,0,5) == "Alert")  Print("!!! --- User Not Authorized --- !!!");
    }
    if(rows > 1)
    {
      e = StringSplit(lines[0], ' ', v);                                                                                   // 1st row to v[]
      if(e >= 4)
      {
        string myticker = v[0];                                                                                            // ticker name v[0]
        FuturesName = myticker;
        ticksizeStr = v[1];                                                                                                // ticksize v[1]
        c = StringFind(ticksizeStr,".");
        if(c > 0) DigitsAfterComa = StringLen(ticksizeStr) - c -1;

        for(i = 1; i < rows; i++)                                                                                          // Get data from lines (rows). 1 Bar - 1 row
        {
          if(StringSubstr(lines[i],0,3) == "//!")   continue;                                                              // header
          if(StringSubstr(lines[i],0,2) == "//" )   continue;
          if(StringSubstr(lines[i],0,3) == "Exp")   continue;
          if(StringSubstr(lines[i],0,1) == "*"  )   continue;


          m = StringSplit(lines[i],'#',candle);                                                                            // #time; o; h; l; c  # cluster  (OHLC - candle[1], Clusters - candle[2])
          if(m < 2) {/*Print ("Error:",lines[i]);*/ continue; } // wrong data format

          //Print("  4th stage, split bar data");
          n = StringSplit(candle[1],';', ohlc);                                                                            // get OHLC from txt candle array
          if(n < 5) {/*Print("Error:",candle[1]);*/ continue; } // wrong data format
          //Print("  5th stage, get bar data details");
          bartime = StringToTime(ohlc[0]);
          baropen = NormalizeDouble(StringToDouble(ohlc[1]),DigitsAfterComa);
          barhigh = NormalizeDouble(StringToDouble(ohlc[2]),DigitsAfterComa);
          barlow  = NormalizeDouble(StringToDouble(ohlc[3]),DigitsAfterComa);
          barclos = NormalizeDouble(StringToDouble(ohlc[4]),DigitsAfterComa);
          barstartid = "0";
          if(n >= 6)  barstartid = ohlc[5];                                                                                // range chart id

          if(Delta_inv < 0)
          {
            baropen = ND(1.0 /baropen);
            barhigh = ND(1.0 /barhigh);
            barlow  = ND(1.0 /barlow);
            barclos = ND(1.0 /barclos);
          }


          if(IsTesting())                                                                                                  // Testing, do Clusters index by time
          {
            new_bar   = true;
            int ix_mn = TimeMinute(bartime);
            int ix_hh = TimeHour(bartime);
            index = (ix_hh * 60 + ix_mn) / X_Period;
          }
          else                                                                                                             // Real Time, do Clusters index one by one
          {
            arr_sz = ArraySize(Clusters); new_bar = false;
            if(arr_sz == 0)
            {
              ArrayResize(Clusters, 1);
              ArrayResize(opentimeIdx, 1);
              ArrayResize(clustersIdx, 1);
              index = 0;
            }
            else
            {
              if(bartime > Clusters[arr_sz -1].opentime)
              {
                ArrayResize(Clusters, arr_sz +1);
                ArrayResize(opentimeIdx, arr_sz +1);
                ArrayResize(clustersIdx, arr_sz +1);
                index = arr_sz;
                new_bar = true;
              }
              else index = arr_sz -1;
            }
          }

          if(index >= ArraySize(Clusters))  {Print("   !!! --- Cluster Index calculation error --- !!!"); ExpertRemove();}


          if(new_bar)
          {
            Clusters[index].open = baropen;
            Clusters[index].close = barclos;
            Clusters[index].high = barhigh;
            Clusters[index].low  = barlow;
            Clusters[index].opentime = bartime;

            Clusters[index].total_ask = 0;                                                                                 // -- reset total Ask & Bid
            Clusters[index].total_bid = 0;
            Clusters[index].volume    = 0;
            Clusters[index].delta     = 0;

            ArrayFree(Clusters[index].prices);                                                                             // -- reset cluster array
            ArrayFree(Clusters[index].ask);
            ArrayFree(Clusters[index].bid);

            if(!IsTesting())  {opentimeIdx[index] = bartime; clustersIdx[index] = index;}
          }

          if(m >= 3)                                                                                                       // cluster data exist - candle[2]
          {
            p = StringSplit(candle[2], ';', data);                                                                         // split clusters(price:ask:bid) from candle[2] to data[]
            if(p > 0)                                                                                                      // get at least 1 cluster
            {
              //if(ArraySize(Clusters[index].prices) == 0)  new_bar = true;
              if(new_bar)
              {

                ArrayResize(Clusters[index].prices, p -1);  ArrayFill(Clusters[index].prices, 0, p -1, 0);                 // resize cluster array
                ArrayResize(Clusters[index].ask,    p -1);  ArrayFill(Clusters[index].ask,    0, p -1, 0);
                ArrayResize(Clusters[index].bid,    p -1);  ArrayFill(Clusters[index].bid,    0, p -1, 0);
              }


              for(d = 0; d < p -1; d ++)                                                                                   // process each claster
              {
                b = StringSplit(data[d], ':', askbid);                                                                     // split each cluster (price:ask:bid) from data[] to separate askbid[]
                if(b >= 2)
                {
                  price = NormalizeDouble(StringToDouble(askbid[0]),DigitsAfterComa);                                      // cluster - price
                  ask = StringToInteger(askbid[1]);                                                                        // cluster - ask
                  bid = StringToInteger(askbid[2]);                                                                        // cluster - bid

                  if(Delta_inv < 0)
                  {
                    price = ND(1.0 /price);
                    int askCopy = ask; int bidCopy = bid;
                    ask = bidCopy;
                    bid = askCopy;
                  }

                  if(new_bar)                                                                                              // NEW BAR, just fill clusters
                  {
                    Clusters[index].prices [d] = price;
                    Clusters[index].ask    [d] = ask;
                    Clusters[index].bid    [d] = bid;

                    Clusters[index].total_ask  += ask;
                    Clusters[index].total_bid  += bid;

                    Clusters[index].volume = Clusters[index].total_ask + Clusters[index].total_bid;
                    Clusters[index].delta  = Clusters[index].total_ask - Clusters[index].total_bid;
                  }
                  else                                                                                                     // EXISTING BAR
                  {
                    int index_x;
                    if(bartime == Clusters[index].opentime)  index_x = index;
                    else
                    {
                      index_x = CLUSTER_by_index(iBarShift(NULL,X_Period,bartime));
                      if(index_x == 0)  continue;
                    }
                    int q; long deltaAsk, deltaBid;  arr_sz = ArraySize(Clusters[index_x].prices);
                    for(q = 0; q < arr_sz; q ++)                                                                           // -- search cluster in existing bar
                    {
                      if(MathAbs(price - Clusters[index_x].prices[q]) < 0.1 * Point)                                         // -- cluster found
                      {
                        if(Clusters[index_x].ask[q] < ask)                                                                   // -- new ask data, update
                        {
                          deltaAsk = ask - Clusters[index_x].ask[q];
                          Clusters[index_x].ask[q] = ask;
                          Clusters[index_x].total_ask  += deltaAsk;
                          Clusters[index_x].close = barclos;                                                                 // -- new info in existing bar, update close/high/low
                          if(Clusters[index_x].high < barhigh)  Clusters[index_x].high  = barhigh;
                          if(Clusters[index_x].low  > barlow)   Clusters[index_x].low   = barlow;
                        }
                        if(Clusters[index_x].bid[q] < bid)                                                                   // -- new bid data, update
                        {
                          deltaBid = bid - Clusters[index_x].bid[q];
                          Clusters[index_x].bid[q] = bid;
                          Clusters[index_x].total_bid  += deltaBid;
                          Clusters[index_x].close = barclos;                                                                 // -- new info in existing bar, update close/high/low
                          if(Clusters[index_x].high < barhigh)  Clusters[index_x].high  = barhigh;
                          if(Clusters[index_x].low  > barlow)   Clusters[index_x].low   = barlow;
                        }

                        break;                                                                                             // -- cluster found break cycle
                      }
                    }

                    if(q >= arr_sz)                                                                                      // cluster not found in exising bar
                    {
                      new_sz = ArraySize(Clusters[index_x].prices) +1;                                                     // -- resize clusters array size
                      ArrayResize(Clusters[index_x].prices, new_sz); Clusters[index_x].prices [new_sz -1] = price;
                      ArrayResize(Clusters[index_x].ask,    new_sz); Clusters[index_x].ask    [new_sz -1] = ask;
                      ArrayResize(Clusters[index_x].bid,    new_sz); Clusters[index_x].bid    [new_sz -1] = bid;
                      Clusters[index_x].total_ask  += ask;
                      Clusters[index_x].total_bid  += bid;
                      Clusters[index_x].close = barclos;                                                                   // -- new info in existing bar, update close/high/low
                      if(Clusters[index_x].high < barhigh)  Clusters[index_x].high  = barhigh;
                      if(Clusters[index_x].low  > barlow)   Clusters[index_x].low   = barlow;
                    }

                    Clusters[index_x].volume = Clusters[index_x].total_ask + Clusters[index_x].total_bid;
                    Clusters[index_x].delta  = Clusters[index_x].total_ask - Clusters[index_x].total_bid;
                  }
                }  // b>0    single cluster
              }    // for d  by every cluster
            }      // p>0    cluster quantity
          }        // m>=3   cluster data exist
        }          // for i
      }            // e>0
    }              // rows>1

    if(index >= 0)
    {
      if(ArraySize(Clusters[index].prices) > 1)
      {
        CLUSTER_SortArray(Clusters[index].prices, Clusters[index].ask, Clusters[index].bid);                               // sort price clusters
      }
    }

    if(!IsTesting()  && index >= 0)
    {
      X_last_loaded = Clusters[index].opentime;
      CLUSTER_SortDictionary(opentimeIdx, clustersIdx, ArraySize(clustersIdx));                                             // Sort by opentime
    }
  } // len response > 1
  else                                                                                             return(false);

  return (true);
}
bool  CLUSTER_Daily_File_Load(datetime dd) {

  datetime f_date, f_datetime, x_date;
  int      f_pefiod, arr_sz, arr_sz_x, tl_ask, tl_bid, f_handle;
  string   yyy, mmm, ddd, id;
  string   file_name, f_futures, f_time;

  if(TimeMonth(dd) < 10)  mmm = "0"+ IntegerToString(TimeMonth(dd)); else mmm = IntegerToString(TimeMonth(dd));
  if(TimeDay(dd)   < 10)  ddd = "0"+ IntegerToString(TimeDay(dd));   else ddd = IntegerToString(TimeDay(dd));
  yyy = IntegerToString(TimeYear(dd));

  id = "Cluster - "+ yyy +"."+ mmm +"."+ ddd +" .csv";
  file_name = Symbol() +"\\"+"CLUSTER"+"\\"+ Period() +"\\"+ yyy +"\\"+ mmm +"\\"+ id;

  if(!FileIsExist(file_name))
  {
    Print("   !!! --- Cluster daily file not found --- !!!");
    Print("   file name - ",file_name);
    return(false);
  }
  else
  {
    f_handle = FileOpen(file_name, FILE_READ|FILE_WRITE|FILE_CSV);

    f_date    = FileReadString(f_handle);
    FileReadString(f_handle);
    f_futures = FileReadString(f_handle);
    f_pefiod  = FileReadString(f_handle);

    if(TimeDayOfYear(f_date) != TimeDayOfYear(dd)  ||  TimeYear(f_date) != TimeYear(dd))
    {
      Print("   !!! --- Cluster daily file Date not match real Date  --- !!!");
      Print(TimeToStr(f_date),"  //  request day ",TimeToStr(dd));
      Print(IntegerToString((int)f_date), "  //  ", IntegerToString((int)dd));
      ExpertRemove();
    }
    if(f_pefiod != Period())
    {
      Print("   !!! --- Cluster daily file TimeFrame not match real Chart TimeFrame --- !!!");
      ExpertRemove();
    }

    ArrayFree(Clusters);  ArrayFree(opentimeIdx);  ArrayFree(clustersIdx);


    while(!FileIsEnding(f_handle)  && !IsStopped())
    {
      //f_datetime, f_date, f_time, f_open, f_close, f_high, f_low, f_tl_ask, f_tl_bid   - file txt format
      tl_ask = 0;  tl_bid = 0;
      arr_sz = ArraySize(Clusters);
      ArrayResize(Clusters,    arr_sz +1);  //ArrayFill(Clusters,    arr_sz, 1, 0);
      ArrayResize(opentimeIdx, arr_sz +1);  ArrayFill(opentimeIdx, arr_sz, 1, 0);
      ArrayResize(clustersIdx, arr_sz +1);  ArrayFill(clustersIdx, arr_sz, 1, 0);

      Clusters[arr_sz].opentime = FileReadString(f_handle);                                                                // Date & Time Bar (datetime)
      FileReadString(f_handle);  FileReadString(f_handle);                                                                 // Date, Time (string)

      Clusters[arr_sz].open  = FileReadString(f_handle);
      Clusters[arr_sz].close = FileReadString(f_handle);
      Clusters[arr_sz].high  = FileReadString(f_handle);
      Clusters[arr_sz].low   = FileReadString(f_handle);

      Clusters[arr_sz].total_ask = FileReadString(f_handle);
      Clusters[arr_sz].total_bid = FileReadString(f_handle);

      opentimeIdx[arr_sz] = Clusters[arr_sz].opentime;
      clustersIdx[arr_sz] = arr_sz;

      ArrayFree(Clusters[arr_sz].prices);  ArrayFree(Clusters[arr_sz].ask);  ArrayFree(Clusters[arr_sz].bid);

      if(Clusters[arr_sz].total_ask != 0  ||  Clusters[arr_sz].total_bid != 0)
      {
        do
        {
          // f_datetime, f_date, f_time, f_price, f_ask, f_bid  - file txt format
          arr_sz_x = ArraySize(Clusters[arr_sz].prices);
          ArrayResize(Clusters[arr_sz].prices, arr_sz_x +1);
          ArrayResize(Clusters[arr_sz].ask,    arr_sz_x +1);
          ArrayResize(Clusters[arr_sz].bid,    arr_sz_x +1);

          x_date = FileReadString(f_handle);                                                                               // Date & Time Bar (datetime)
          if(arr_sz_x > 0 &&  x_date != Clusters[arr_sz].opentime)
          {
            Print("   !!! --- Error reading cluster date, cluster d/t different from Bar open d/t --- !!!");
            ExpertRemove();
          }
          FileReadString(f_handle);  FileReadString(f_handle);                                                             // Date, Time (string)

          Clusters[arr_sz].prices[arr_sz_x] = FileReadString(f_handle);
          Clusters[arr_sz].ask[arr_sz_x]    = FileReadString(f_handle);
          Clusters[arr_sz].bid[arr_sz_x]    = FileReadString(f_handle);

          tl_ask += Clusters[arr_sz].ask[arr_sz_x];
          tl_bid += Clusters[arr_sz].bid[arr_sz_x];
        } while(tl_ask < Clusters[arr_sz].total_ask  || tl_bid < Clusters[arr_sz].total_bid);
      }
    }
  }

  CLUSTER_SortDictionary(opentimeIdx, clustersIdx, ArraySize(clustersIdx));
  arr_sz = ArraySize(Clusters);
  if(arr_sz > 0)
  {
    for(int i = 0; i < arr_sz; i ++)
    {
      Clusters[i].volume = Clusters[i].total_ask + Clusters[i].total_bid;
      Clusters[i].delta  = Clusters[i].total_ask - Clusters[i].total_bid;
    }
  }


  Print("   File read compleated, array size ", ArraySize(clustersIdx));
  return(true);
}
bool  CLUSTER_Daily_File_Write(datetime dd) {

  string  yyy, mmm, ddd, hh_ , mm_ , id;
  string  file_name, f_time, f_date, f_datetime;
  string  f_ask, f_bid, f_price, f_tl_ask, f_tl_bid, f_open, f_close, f_high, f_low;
  int     f_handle, ix, x_ix;
  datetime dt;

  if(TimeDayOfWeek(dd) == 0  ||  TimeDayOfWeek(dd) == 6)                                           return(true);

  if(TimeMonth(dd) < 10)  mmm = "0"+ IntegerToString(TimeMonth(dd)); else mmm = IntegerToString(TimeMonth(dd));
  if(TimeDay(dd)   < 10)  ddd = "0"+ IntegerToString(TimeDay(dd));   else ddd = IntegerToString(TimeDay(dd));
  yyy = IntegerToString(TimeYear(dd));

  id = "Cluster - "+ yyy +"."+ mmm +"."+ ddd +" .csv";
  file_name = Symbol() +"\\"+"CLUSTER"+"\\"+ Period() +"\\"+ yyy +"\\"+ mmm +"\\"+ id;

  if(FileIsExist(file_name))
  {
    if(Reload_Data)  FileDelete(file_name);
    else             return(true);
  }

  f_handle = FileOpen(file_name, FILE_READ|FILE_WRITE|FILE_CSV);


  if(f_handle > 0)
  {
    FileWrite(f_handle, IntegerToString((int)dd), TimeToStr(dd), FuturesName, IntegerToString(X_Period));
    for(ix = 0; ix < ArraySize(Clusters); ix ++)
    {
      dt = Clusters[ix].opentime;
      if(TimeHour   (dt)  <= 9)  hh_ = "0" + IntegerToString(TimeHour(dt));
      else                       hh_ =       IntegerToString(TimeHour(dt));
      if(TimeMinute (dt)  <= 9)  mm_ = "0" + IntegerToString(TimeMinute(dt));
      else                       mm_ =       IntegerToString(TimeMinute(dt));

      f_datetime = IntegerToString((int)Clusters[ix].opentime);      // bartime;
      f_date = yyy +"."+ mmm  +"."+ ddd;                             // bartime date
      f_time = hh_ +":"+ mm_ ;                                       // bartime time

      f_open  = DoubleToStr(Clusters[ix].open,  Digits);              // baropen
      f_close = DoubleToStr(Clusters[ix].close, Digits);              // barclose
      f_high  = DoubleToStr(Clusters[ix].high,  Digits);              // barhigh
      f_low   = DoubleToStr(Clusters[ix].low,   Digits);              // barlow

      f_tl_ask = IntegerToString(Clusters[ix].total_ask);
      f_tl_bid = IntegerToString(Clusters[ix].total_bid);

      FileWrite(f_handle, f_datetime, f_date, f_time, f_open, f_close, f_high, f_low, f_tl_ask, f_tl_bid);

      for(x_ix = 0; x_ix < ArraySize(Clusters[ix].prices); x_ix ++)
      {
        f_price = DoubleToStr    (Clusters[ix].prices[x_ix], Digits);
        f_ask   = IntegerToString(Clusters[ix].ask[x_ix],    Digits);
        f_bid   = IntegerToString(Clusters[ix].bid[x_ix],    Digits);

        FileWrite(f_handle, f_datetime, f_date, f_time, f_price, f_ask, f_bid);
      }
    }
    FileClose(f_handle);
  }                                                                                           else return(false);

  return(true);

}
void  CLUSTER_SortArray(double &key_price[], long &ask[], long &bid[]) {

  double keyCopy[];
  int    askCopy[], bidCopy[];

  ArrayCopy(keyCopy,    key_price);
  ArrayCopy(askCopy,    ask);
  ArrayCopy(bidCopy,    bid);


  ArraySort(key_price,WHOLE_ARRAY, 0, MODE_ASCEND);
  for(int i = 0; i < ArraySize(key_price); i ++)
  {
    ask    [ArrayBsearch(key_price, keyCopy[i])] = askCopy [i];
    bid    [ArrayBsearch(key_price, keyCopy[i])] = bidCopy [i];
  }
}
void  CLUSTER_SortDictionary(datetime &keys[], int &values[], int count, int sortDirection = MODE_ASCEND) {

  int keyCopy[];
  int valueCopy[];
  int i,j;

  ArrayCopy(keyCopy, keys,0,0,count);
  ArrayCopy(valueCopy, values,0,0,count);
  ArraySort(keys, count, 0, sortDirection);

  for (i = 0; i < count; i ++)
  {
    for(j = 0; j < count; j ++)  if(keys[j] == keyCopy[i]) break;
    if(j < count)  values[j] = valueCopy[i];
  }
}
int   CLUSTER_by_index(int ix, bool BrokehHour=true)  {

  if(ArraySize(opentimeIdx) <2) return 0;
  if(ArraySize(Time) <= ix) return 0;

  int iBase = ArrayBsearchCorrect(opentimeIdx, Time[ix] );

  if (iBase < 0 && Period() >= PERIOD_M5  && BrokehHour) { iBase = ArrayBsearchCorrect(opentimeIdx, Time[ix] - 1*60 ); } // 1 Min BrokenHour
  if (iBase < 0 && Period() >= PERIOD_M5  && BrokehHour) { iBase = ArrayBsearchCorrect(opentimeIdx, Time[ix] - 2*60 ); } // 1 Min BrokenHour
  if (iBase < 0 && Period() >= PERIOD_M5  && BrokehHour) { iBase = ArrayBsearchCorrect(opentimeIdx, Time[ix] - 3*60 ); } // 1 Min BrokenHour
  if (iBase < 0 && Period() >= PERIOD_M5  && BrokehHour) { iBase = ArrayBsearchCorrect(opentimeIdx, Time[ix] - 4*60 ); } // 1 Min BrokenHour
  if (iBase < 0 && Period() >= PERIOD_M15 && BrokehHour) { iBase = ArrayBsearchCorrect(opentimeIdx, Time[ix] - 5*60 ); } // 5 Min BrokenHour
  if (iBase < 0 && Period() >= PERIOD_H1  && BrokehHour) { iBase = ArrayBsearchCorrect(opentimeIdx, Time[ix] - 30*60 ); } // 35 Min BrokenHour / ES
  if (iBase < 0 && Period() >= PERIOD_H1  && BrokehHour) { iBase = ArrayBsearchCorrect(opentimeIdx, Time[ix] - 35*60 ); } // 35 Min BrokenHour / ES
  if (iBase < 0 && Period() >= PERIOD_H4  && BrokehHour) { iBase = ArrayBsearchCorrect(opentimeIdx, Time[ix] - 60*60 ); } // 60 Min BrokenHour / ES
  if (iBase < 0 && Period() >= PERIOD_H4  && BrokehHour) { iBase = ArrayBsearchCorrect(opentimeIdx, Time[ix] + 60*60 ); } // 60 Min BrokenHour / ES
  if (iBase < 0 && Period() >= PERIOD_H4  && BrokehHour) { iBase = ArrayBsearchCorrect(opentimeIdx, Time[ix] + 2*60*60 ); } // 120 Min BrokenHour / ES
  if (iBase < 0 && Period() >= PERIOD_W1  && BrokehHour) { iBase = ArrayBsearchCorrect(opentimeIdx, Time[ix] + 24*60*60); } // 35 Min BrokenHour / ES


  if (iBase >= 0)  return (int)clustersIdx[iBase];

  return 0;
}



void  Testing_Load_file_Vol_Delta_by_Month() {

  string f_name, yyy, mmm, date;  int f_handle;
  yyy = IntegerToString(Year());
  if(Month() < 10)  mmm = "0"+ IntegerToString(Month()); else mmm = Month();
  f_name = Symbol() +"\\"+ IntegerToString(X_Period) +"\\"+ yyy +"_"+ mmm +".csv";

  if(!FileIsExist(f_name))  {Print("   !!! --- monthly Volume & Delta file not found --- !!!"); ExpertRemove();}

  f_handle = FileOpen(f_name, FILE_READ|FILE_WRITE|FILE_CSV);
  while(!FileIsEnding(f_handle))
  {
    ArrayResize(TIME_Array,   ArraySize(TIME_Array)   +1);
    ArrayResize(VOLUME_Array, ArraySize(VOLUME_Array) +1);
    ArrayResize(DELTA_Array,  ArraySize(DELTA_Array)  +1);

    date = FileReadString(f_handle);
    TIME_Array  [ArraySize(TIME_Array)   -1] = FileReadString(f_handle);
    VOLUME_Array[ArraySize(VOLUME_Array) -1] = FileReadString(f_handle);
    DELTA_Array [ArraySize(DELTA_Array)  -1] = FileReadString(f_handle);
  }
  FileClose(f_handle);
}
bool  VOLUMES_GetOnline() {

   string response = "", mydata = "", key= "";
   int    length = 0, key_i;

   //if(Period()>60) return false;
   response = Online_Data(length, indicator_client);  if(length  == 0)                             return false;


   key_i  = StringFind(response, ":");
   key = StringSubstr(response,0,key_i);
   mydata = StringSubstr(response,key_i+1);


   string result[];
   string bardata[];
   if(key == indicator_client)
   {
      StringSplit(mydata,StringGetCharacter("!",0),result);

      StringSplit(result[0],StringGetCharacter(";",0),bardata);   // Bar_0
      TM[0] = StringToInteger(bardata[0])+3600*GMT;
      VL[0] = StringToInteger(bardata[1]);
      DL[0] = StringToInteger(bardata[2]);

      StringSplit(result[1],StringGetCharacter(";",0),bardata);   // Bar_1
      TM[1] = StringToInteger(bardata[0])+3600*GMT;
      VL[1] = StringToInteger(bardata[1]);
      DL[1] = StringToInteger(bardata[2]);
   }
   return true;
}
int   VOLUME_by_index(int ix, bool BrokehHour=true)  {
      if(ArraySize(TIME_Array)<2) return 0;
      if(ArraySize(Time)<=ix) return 0;

      int iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] );

      if (iBase < 0 && Period() >= PERIOD_M5  && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] - 1*60 ); } // 1 Min BrokenHour
      if (iBase < 0 && Period() >= PERIOD_M5  && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] - 2*60 ); } // 1 Min BrokenHour
      if (iBase < 0 && Period() >= PERIOD_M5  && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] - 3*60 ); } // 1 Min BrokenHour
      if (iBase < 0 && Period() >= PERIOD_M5  && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] - 4*60 ); } // 1 Min BrokenHour
      if (iBase < 0 && Period() >= PERIOD_M15 && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] - 5*60 ); } // 5 Min BrokenHour
      if (iBase < 0 && Period() >= PERIOD_H1  && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] - 30*60 ); } // 35 Min BrokenHour / ES
      if (iBase < 0 && Period() >= PERIOD_H1  && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] - 35*60 ); } // 35 Min BrokenHour / ES
      if (iBase < 0 && Period() >= PERIOD_H4  && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] - 60*60 ); } // 60 Min BrokenHour / ES
      if (iBase < 0 && Period() >= PERIOD_H4  && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] + 60*60 ); } // 60 Min BrokenHour / ES
      if (iBase < 0 && Period() >= PERIOD_H4  && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] + 2*60*60 ); } // 120 Min BrokenHour / ES
      if (iBase < 0 && Period() >= PERIOD_W1  && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] + 24*60*60); } // 35 Min BrokenHour / ES


      if (iBase >= 0)
      {
         return (int)VOLUME_Array[iBase];
      }

      return 0;
}
int   DELTA_by_index (int ix, bool BrokehHour=true)  {
      if(ArraySize(TIME_Array)<2) return 0;
      if(ArraySize(Time)<=ix) return 0;

      int iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] );

      if (iBase < 0 && Period() >= PERIOD_M5 && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] - 1*60 ); } // 1 Min BrokenHour
      if (iBase < 0 && Period() >= PERIOD_M5 && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] - 2*60 ); } // 1 Min BrokenHour
      if (iBase < 0 && Period() >= PERIOD_M5 && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] - 3*60 ); } // 1 Min BrokenHour
      if (iBase < 0 && Period() >= PERIOD_M5 && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] - 4*60 ); } // 1 Min BrokenHour
      if (iBase < 0 && Period() >= PERIOD_M15 && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] - 5*60 ); } // 5 Min BrokenHour
      if (iBase < 0 && Period() >= PERIOD_H1 && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] - 30*60 ); } // 35 Min BrokenHour / ES
      if (iBase < 0 && Period() >= PERIOD_H1 && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] - 35*60 ); } // 35 Min BrokenHour / ES
      if (iBase < 0 && Period() >= PERIOD_H4 && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] - 60*60 ); } // 60 Min BrokenHour / ES
      if (iBase < 0 && Period() >= PERIOD_H4 && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] + 60*60 ); } // 60 Min BrokenHour / ES
      if (iBase < 0 && Period() >= PERIOD_H4 && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] + 2*60*60 ); } // 120 Min BrokenHour / ES
      if (iBase < 0 && Period() >= PERIOD_W1 && BrokehHour) { iBase = ArrayBsearchCorrect(TIME_Array, Time[ix] + 24*60*60); } // 35 Min BrokenHour / ES


      if (iBase >= 0)
      {
         return (int)DELTA_Array[iBase] * Delta_inv;
      }

      return 0;
}
int   ArrayBsearchCorrect(datetime &array[], double value,
                          int count = WHOLE_ARRAY, int start = 0,
                          int direction = MODE_ASCEND) {
   if(ArraySize(array)==0) return(-1);
   int i = ArrayBsearch(array, (datetime)value, count, start, direction);
   if (value != array[i])
   {
      i = -1;
   }
   return (i);
}



void   SetText(string name,string text,datetime t,double p,color clr, int fs, bool top, bool right)  {

   static int nn = 0; nn ++;
   string nm = name + IntegerToString((int)t); //IntegerToString(nn);

   if(ObjectFind(0,nm)<0)
   {
     ObjectCreate     (0,nm,OBJ_TEXT,0,0,0);                                                                                   //--- создадим объект Label (chart_id,text,OBJ_TEXT,sub_window,time1,price);
     ObjectSetString  (0,nm,OBJPROP_FONT,"Arial");
     ObjectSetInteger (0,nm,OBJPROP_FONTSIZE,fs);

     ObjectSetInteger (0,nm,OBJPROP_COLOR,clr);
     ObjectSetInteger (0,nm,OBJPROP_BGCOLOR,Black);  //--- зададим цвет фона
     ObjectSetInteger (0,nm,OBJPROP_SELECTABLE,false);
     ObjectSetInteger (0,nm,OBJPROP_SELECTED,false);
     ObjectSetInteger (0,nm,OBJPROP_BACK,false);
     ObjectSetInteger (0,nm,OBJPROP_HIDDEN,false);
     ObjectSetString  (0,nm,OBJPROP_TEXT,text);
     ObjectSetDouble  (0,nm,OBJPROP_PRICE,p);
     ObjectSetInteger (0,nm,OBJPROP_TIME,t);
     if(top)
     {
        if(right)  ObjectSetInteger(0,nm,OBJPROP_ANCHOR,ANCHOR_RIGHT_LOWER);
        else       ObjectSetInteger(0,nm,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);
     }
     else
     {
       if(right)  ObjectSetInteger(0,nm,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
       else       ObjectSetInteger(0,nm,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
     }
      //ObjectSetInteger(0,text_name,OBJPROP_BGCOLOR,clrGreen);  //--- зададим цвет фона
      //CHART_PRICE_MAX, CHART_PRICE_MIN, double chart_max_price=ChartGetDouble(0,CHART_PRICE_MAX,0);
   }
}
float  ND(double nd) {
  return(NormalizeDouble(nd, Digits));
}
