#property copyright "Copyright © 2011-2018, ClusterDelta.com"
#property link      "http://my.clusterdelta.com/premium"
#property description "ClusterDelta Premium CumDelta, Version 4.1 (compiled 24.08.2018)"
#property description "\nDelta Indicator show difference between ASK volume and BID volume. This indicator shows how delta changing during some period so it shows total sum of delta values. Data looks like a curve of changing delta values."
#property description "\nMore information can be found here: http://my.clusterdelta.com/cumdelta"

#import "premium_mt5_v4x1.dll"
int InitDLL(int&);
string Receive_Information(int&,string);
int Send_Query(int &, string, string, int, string, string, string, string, string, string, int, string, string, string,int);
#import


#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   1
//--- plot ColorCandles 
#property indicator_label1  "CumDelta Chart" 
#property indicator_type1   DRAW_COLOR_CANDLES 
#property indicator_color1  clrRed,clrGreen,clrDarkGray
#property indicator_width1  1




input string Comment_Instrument="--- Futures Ticker or AUTO ";
input string Instrument="AUTO";
input string MetaTrader_GMT="AUTO";
input string Comment_History="--- Premium Settings ";
input int Days_in_History=0;
input bool Show_Cumulative=true;
input datetime Custom_Start_time=D'2017.01.01 00:00';
input datetime Custom_End_time=D'2017.01.01 00:00';
input string Reverse_Settings="--------- Reverse for USD/XXX symbols ---------";
input bool ReverseChart=false;
input string DO_NOT_SET_ReverseChart="...for USD/JPY, USD/CAD, USD/CHF --";

int Update_in_sec=16;


double ColorCandlesColors[];         // Буфер цвета 

datetime TimeData[];
double OpenData[];
double HighData[];
double LowData[];
double CloseData[];
double DeltaCum[];

double         ColorCandlesBuffer1[]; 
double         ColorCandlesBuffer2[]; 
double         ColorCandlesBuffer3[]; 
double         ColorCandlesBuffer4[]; 

string ver = "4.1";
string MessageFromServer="";
datetime last_loaded=D'1970.01.01 00:00';
datetime myUpdateTime=D'1970.01.01 00:00';
int UpdateFreq=12; // sec
int OneTimeAlert=0;

string clusterdelta_client="";

string indicator_id="";
string indicator_name = "ClusterDelta_PremiumCumDelta_Chart";
string short_name="";
bool ReverseChart_SET=false;

int NumberRates=0;
datetime LastTime[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   


//--- indicator buffers mapping 
   SetIndexBuffer(0,ColorCandlesBuffer1,INDICATOR_DATA); 
   SetIndexBuffer(1,ColorCandlesBuffer2,INDICATOR_DATA); 
   SetIndexBuffer(2,ColorCandlesBuffer3,INDICATOR_DATA); 
   SetIndexBuffer(3,ColorCandlesBuffer4,INDICATOR_DATA); 
   SetIndexBuffer(4,ColorCandlesColors,INDICATOR_COLOR_INDEX); 
   SetIndexBuffer(5,DeltaCum,INDICATOR_CALCULATIONS);    
//--- пустое значение 
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE); 
//--- имя символа, по которому рисуются бары 
   string symbol=_Symbol; 
//--- установим отображение символа  
   PlotIndexSetString(0,PLOT_LABEL,symbol+" Open;"+symbol+" High;"+symbol+" Low;"+symbol+" Close"); 

//---- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"ClusterDelta CumDeltaChart");
//---- indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//----

   // this block do not use ClusterDelta_Server but register for unique id
   do
   {
     clusterdelta_client = "CDPB" + StringSubstr(IntegerToString(TimeLocal()),7,3)+""+DoubleToString(MathAbs(MathRand()%10),0);     
     indicator_id = "CLUSTERDELTA_"+clusterdelta_client;
   } while (GlobalVariableCheck(indicator_id));
   GlobalVariableSet(indicator_id,1);

   ReverseChart_SET=ReverseChart;
   
   ArrayResize(TimeData, 0);
   ArrayResize(OpenData, 0);
   ArrayResize(HighData, 0);   
   ArrayResize(LowData, 0);
   ArrayResize(CloseData, 0);   
 
   ArrayResize(LastTime, 0);
   if (Update_in_sec>2) { UpdateFreq=Update_in_sec; }   
   int usd_str_index = StringFind(Symbol(),"USD");
   int cad_str_index = StringFind(Symbol(),"CAD");
   int chf_str_index = StringFind(Symbol(),"CHF");
   int jpy_str_index = StringFind(Symbol(),"JPY");   

         if (usd_str_index!=-1) // точно форекс
         {
             if (  cad_str_index  != -1 || chf_str_index  != -1 || jpy_str_index  != -1)
             {
                ReverseChart_SET= !ReverseChart ;
             }
         }         

   EventSetMillisecondTimer(200);
   return (INIT_SUCCEEDED);

  }
  
void OnTimer()
{
  MainCode();
} 
//+------------------------------------------------------------------+
//| Average True Range                                               |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
      NumberRates = rates_total;
      ArrayResize(LastTime, ArraySize(time));
      ArrayCopy(LastTime , time);
      return (1);//MainCode();

  }
  
int MainCode()
{ 
//---check for rates total

   static int dll_init=0;   
   int data_is_ready;
   bool ready_to_fetch;

   int ix=0;
   int iBase;
   double mydelta=0;

   int count = 0;
      //int myvolume;
   
   double LastClose=0;
   double cumdelta=0;


   if(ArraySize(LastTime)==0) return 0;

   if(!dll_init)
   {
     ENUM_ACCOUNT_TRADE_MODE account_type=(ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE); 
     int acc=(int)AccountInfoInteger(ACCOUNT_LOGIN);
     if(account_type == ACCOUNT_TRADE_MODE_REAL) { acc = acc * -1; } // we will care for real mode account, comment it if you dont like to it
     int res=acc;
     string cmp=AccountInfoString(ACCOUNT_COMPANY);
     InitDLL(res);     if(res==-1) { Print("Error during DLL init. ") ; EventKillTimer(); return (0); }
     dll_init=1;
   }

   ready_to_fetch=((TimeLocal() >= myUpdateTime) ? true : false ); 
   
   data_is_ready = GetData();
   if(ready_to_fetch)
   {  
     // set new update time
     myUpdateTime = TimeLocal() + UpdateFreq;
     // send parameter for data update
     SetData();
   }
   ChartRedraw();   
   // if we got data before   
   if(!data_is_ready) { return 1; }// from GetData
    // data are in the buffer just show them


   int finish_idx=NumberRates-1;

   ix = NumberRates-1;
   if(ArraySize(TimeData)<finish_idx) finish_idx = ArraySize(TimeData) ;
   if (Custom_Start_time!=D'2017.01.01 00:00' || Custom_End_time!=D'2017.01.01 00:00') { finish_idx=NumberRates-1; }
   
   if (finish_idx ==0 ) return 0;

   ix =0;  
   ix = (NumberRates-finish_idx);   
   if(ix==0) { ix=1; }
   while(ix < NumberRates)
   {
      ColorCandlesColors[ix]=0;
      //if(!use_standart_bsearch) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] ); } else { iBase = ArrayBsearch(TimeData, LastTime[ix] ); }      
      iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] );

      if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 1*60 ); } // 1 Min BrokenHour
      if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 2*60 ); } // 1 Min BrokenHour      
      if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 3*60 ); } // 1 Min BrokenHour            
      if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 4*60 ); } // 1 Min BrokenHour                  
      if (iBase < 0 && Period() >= PERIOD_M15) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 5*60 ); } // 5 Min BrokenHour      
      if (iBase < 0 && Period() >= PERIOD_H1) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 30*60 ); } // 35 Min BrokenHour / ES      
      if (iBase < 0 && Period() >= PERIOD_H1) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 35*60 ); } // 35 Min BrokenHour / ES
      if (iBase < 0 && Period() >= PERIOD_H4) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 60*60 ); } // 60 Min BrokenHour / ES      
      if (iBase < 0 && Period() >= PERIOD_H4) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] + 60*60 ); } // 60 Min BrokenHour / ES            
      if (iBase < 0 && Period() >= PERIOD_H4) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] + 2*60*60 ); } // 120 Min BrokenHour / ES            

      if (iBase < 0 && Period() >= PERIOD_W1) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] + 24*60*60); } // 35 Min BrokenHour / ES            
      if (iBase < 0 && Period() >= PERIOD_W1) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] + 25*60*60); } // 35 Min BrokenHour / ES      
      
      
      if (Show_Cumulative) 
      { 
        LastClose = DeltaCum[ix-1]; 
      }
      if (iBase >= 0)
      {
      
         count++;             
         ColorCandlesBuffer1[ix]=OpenData[iBase]*(ReverseChart_SET ? -1:1)+LastClose;
         ColorCandlesBuffer2[ix]=HighData[iBase]*(ReverseChart_SET ? -1:1)+LastClose;
         ColorCandlesBuffer3[ix]=LowData[iBase]*(ReverseChart_SET ? -1:1)+LastClose;         
         ColorCandlesBuffer4[ix]=CloseData[iBase]*(ReverseChart_SET ? -1:1)+LastClose;
         if(OpenData[iBase]*(ReverseChart_SET ? -1:1)<CloseData[iBase]*(ReverseChart_SET ? -1:1))  ColorCandlesColors[ix]=1;
         cumdelta = CloseData[iBase]*(ReverseChart_SET ? -1:1);
      }
      else { cumdelta=0;
         ColorCandlesBuffer1[ix]=EMPTY_VALUE;
         ColorCandlesBuffer2[ix]=EMPTY_VALUE;
         ColorCandlesBuffer3[ix]=EMPTY_VALUE;
         ColorCandlesBuffer4[ix]=EMPTY_VALUE;
         ColorCandlesColors[ix]=2;
      
       }
      
      DeltaCum[ix]=DeltaCum[ix-1]+cumdelta;      
     
      ix++;
   }
   ChartRedraw(0);      
   
   
   return(1);
  }
//+------------------------------------------------------------------+

void OnDeinit(const int reason)

{
    ObjectDelete(0,"PremiumVolumeLine_Alert");
    GlobalVariableDel(indicator_id);
    EventKillTimer();
}

int Period_To_Minutes()
{

  switch(_Period)
  {
    case (PERIOD_M1): return 1;
    case (PERIOD_M2): return 2;
    case (PERIOD_M3): return 3;
    case (PERIOD_M4): return 4;
    case (PERIOD_M5): return 5;
    case (PERIOD_M6): return 6;
    case (PERIOD_M10): return 10;
    case (PERIOD_M12): return 12;
    case (PERIOD_M15): return 15;
    case (PERIOD_M20): return 20;
    case (PERIOD_M30): return 30;
    case (PERIOD_H1): return 60;
    case (PERIOD_H2): return 120;
    case (PERIOD_H3): return 180;
    case (PERIOD_H4): return 240;
    case (PERIOD_H6): return 360;
    case (PERIOD_H8): return 480;
    case (PERIOD_H12): return 60;
    case (PERIOD_D1): return 1440;
    case (PERIOD_W1): return 10080;    
    case (PERIOD_MN1): return 302400;    
    default: return 60;
    
  }

}

int SetData()
{

  int k=0,i;
  string sym=Symbol();
  int per=Period_To_Minutes();
  
  string tmc=TimeToString(TimeTradeServer());
  string tm0=TimeToString(LastTime[NumberRates-1]);
  string lsl=TimeToString(last_loaded);
  string cst=TimeToString(Custom_Start_time);
  string cet=TimeToString(Custom_End_time);
  string cmp=AccountInfoString(ACCOUNT_COMPANY);
  int acnt=(int)AccountInfoInteger(ACCOUNT_LOGIN);

  i = Send_Query(k,clusterdelta_client, sym, per, tmc, tm0, Instrument, lsl,MetaTrader_GMT,ver,Days_in_History,cst,cet,cmp,acnt);     

  if (i < 0) { Alert ("Error during query registration"); return -1; }
  
  return 1;
}  



int GetData()
{

   string response="";
   int length=0;
   int valid=0;   
   response = Receive_Information(length, clusterdelta_client);

   if (length==0) { return 0; }
    
    if(StringLen(response)>1) // if we got response (no care how), convert it to mt4 buffers
    {
      //valid = ConvertResponseToArrays(response,TimeData,ValueData,"\n",";",MessageFromServer,1); 
      if(!ReverseChart_SET)
      {
        valid = ConvertResponseTo4Arrays(response,TimeData,OpenData,HighData,LowData,CloseData,"\n",";",MessageFromServer,1); 
      } else
      {
        valid = ConvertResponseTo4Arrays(response,TimeData,OpenData,LowData,HighData,CloseData,"\n",";",MessageFromServer,1);       
      }
      if (valid>0)
      {
       //SortDictionary(TimeData,ValueData);
       Sort4Dictionary(TimeData,OpenData,HighData,LowData,CloseData);       
       int lastindex = ArraySize(TimeData);
       last_loaded=TimeData[lastindex-1];  
       if(last_loaded>LastTime[NumberRates-1])last_loaded=LastTime[NumberRates-1]; 
      } 
      if (StringLen(MessageFromServer)>8 && OneTimeAlert==0) { 
/*      
          ObjectCreate(0,"PremiumVolumeLine_Alert", OBJ_LABEL, 0, 0, 0);
          ObjectSetInteger(0,"PremiumVolumeLine_Alert", OBJPROP_CORNER, CORNER_RIGHT_UPPER);    
          ObjectSetInteger(0,"PremiumVolumeLine_Alert", OBJPROP_XDISTANCE, 10);
          ObjectSetInteger(0,"PremiumVolumeLine_Alert", OBJPROP_YDISTANCE, 10);
          ObjectSetString(0,"PremiumVolumeLine_Alert",OBJPROP_TEXT,MessageFromServer);
          ObjectSetString(0,"PremiumVolumeLine_Alert",OBJPROP_FONT, "Arial");
          ObjectSetInteger(0,"PremiumVolumeLine_Alert",OBJPROP_FONTSIZE, 8);
          ObjectSetInteger(0,"PremiumVolumeLine_Alert",OBJPROP_COLOR, clrLightGreen); */
          OneTimeAlert=1; } /* else { ObjectDelete(0,"PremiumVolumeLine_Alert"); }*/

      if (StringLen(MessageFromServer)>8 && OneTimeAlert==1) { Print("MT4 Time ",TimeToString(TimeCurrent()),",  data source info:", MessageFromServer ); OneTimeAlert=2;}      
    }
    return (1);
}


int ArrayBsearchCorrect(datetime &array[], datetime value, 
                        int count = WHOLE_ARRAY, int start = 0)
{
   if(ArraySize(array)==0) return(-1);   
   int i = ArrayBsearch(array, value); //, count, start);
   if (value != array[i])
   {
      i = -1;
   }
   return (i);
}

//int ConvertResponseTo4Arrays(string st, datetime& td[],double& vd[], string de1, string de2, string& msg, int checkUpdate=0) 
int ConvertResponseTo4Arrays(string st, datetime& td[],double& v1[],double& v2[],double& v3[],double& v4[], string de1, string de2, string& msg, int checkUpdate=0)  
{ 

  int    i=0, np, dp, iBase;
  int c1,c2,c3; //,c4;  
  datetime indexx;
  string stp,dtp,mv1,mv2,mv3,dtv1,dtv2,dtv3,dtv4; // dtp2, mv4  

  
  np=StringFind(st, de1);

  if(np>0)
  {
      stp=StringSubstr(st, 0, np);
      msg=stp;
      st=StringSubstr(st, np+1);
  }
  
  while (StringLen(st)>0 && np>0) 
  {
    np=StringFind(st, de1);

    if (np<0) {
      stp=st;
      st="";
    } else {
      stp=StringSubstr(st, 0, np);
      st=StringSubstr(st, np+1);
    }
    

    dp=StringFind(stp, de2);
    if(dp<0)
    {
      dtp="0";
      dtv1="0";dtv2="0";dtv3="0";dtv4="0";
    } else 
    {
      dtp=StringSubstr(stp, 0, dp);
      mv1=StringSubstr(stp, dp+1);
      c1=StringFind(mv1,de2);     
      if(c1<0)
      {
         dtv1="0";dtv2="0";dtv3="0";dtv4="0";
      } else {
         dtv1=StringSubstr(mv1, 0, c1);
         mv2=StringSubstr(mv1, c1+1);
         c2=StringFind(mv2,de2);
         dtv2=StringSubstr(mv2, 0, c2);
         mv3=StringSubstr(mv2, c2+1);
         c3=StringFind(mv3,de2);
         dtv3=StringSubstr(mv3, 0, c3);
         dtv4=StringSubstr(mv3,c3+1); // last
      }

    }
    if(dtp!="0")
    {
    
    i=ArraySize(td);
    if (checkUpdate==1)
    {
      indexx = StringToTime(dtp);
      iBase = ArrayBsearchCorrect(td, indexx );
      if (iBase >= 0) { i=iBase;  } 
    }
    if(i>=ArraySize(td))
    {      
      ArrayResize(td, i+1);
      ArrayResize(v1, i+1);
      ArrayResize(v2, i+1);
      ArrayResize(v3, i+1);
      ArrayResize(v4, i+1);                  

    }
    
    td[i]= StringToTime(dtp);
    v1[i]= StringToDouble(dtv1);
    v2[i]= StringToDouble(dtv2);
    v3[i]= StringToDouble(dtv3);        
    v4[i]= StringToDouble(dtv4);    
    }
  }
  return(ArraySize(td));

}

void SortDictionary(datetime &keys[], double &values[])
{
   datetime keyCopy[];
   double valueCopy[];
   ArrayCopy(keyCopy, keys);
   ArrayCopy(valueCopy, values);
   ArraySort(keys); // , WHOLE_ARRAY, 0, sortDirection);
   for (int i = 0; i < MathMin(ArraySize(keys), ArraySize(values)); i++)
   {
      values[ArrayBsearch(keys, keyCopy[i])] = valueCopy[i];
   }
}

void Sort4Dictionary(datetime &keys[], double &values[],  double &values2[], double &values3[],  double &values4[])
{
   datetime keyCopy[];
   double valueCopy[];
   double value2Copy[];
   double value3Copy[];
   double value4Copy[];
      
   ArrayCopy(keyCopy, keys);
   ArrayCopy(valueCopy, values);
   ArrayCopy(value2Copy, values2);
   ArrayCopy(value3Copy, values3);
   ArrayCopy(value4Copy, values4);
   
   ArraySort(keys); //, WHOLE_ARRAY, 0, sortDirection);
   for (int i = 0; i < MathMin(ArraySize(keys), ArraySize(values)); i++)
   {
      //values[i] = valueCopy[ArrayBsearch(keyCopy, keys[i])];
      values[ArrayBsearch(keys, keyCopy[i])] = valueCopy[i];
      values2[ArrayBsearch(keys, keyCopy[i])] = value2Copy[i];      
      values3[ArrayBsearch(keys, keyCopy[i])] = value3Copy[i];      
      values4[ArrayBsearch(keys, keyCopy[i])] = value4Copy[i];      
      
   }
}

