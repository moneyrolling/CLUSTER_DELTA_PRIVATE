#property copyright "Copyright © 2011-2018, ClusterDelta.com"
#property link      "http://my.clusterdelta.com/premium"
#property description "ClusterDelta Premium Volume, Version 4.1 (compiled 24.08.2018)\n\n"
#property description "Volume Indicator shows summary information for total volume orders in the each bar. This information visualize situation of trading on the world exchanges and shows it in the histogram in separate indicator window. More information can be found here: http://my.clusterdelta.com/volume"

#import "premium_mt5_v4x1.dll"
int InitDLL(int&);
string Receive_Information(int&,string);
int Send_Query(int &, string, string, int, string, string, string, string, string, string, int, string, string, string,int);
#import

#import "online_mt5_v4x1.dll"
int Online_Init(int&,string,int);
string Online_Data(int&,string);
int Online_Subscribe(int &, string, string, int, string, string, string, string, string, string, int, string, string, string,int);
#import

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  DodgerBlue
#property indicator_style1  0
#property indicator_width1  2
#property indicator_minimum 0.0


input string HELP_URL="http://my.clusterdelta.com/volume_chart";
input string Comment_Instrument="--- Futures Ticker or AUTO ";
input string Instrument="AUTO";
input string MetaTrader_GMT="AUTO";
input string Comment_History="--- Premium Settings ";
input int Days_in_History=0;
input datetime Custom_Start_time=D'2017.01.01 00:00';
input datetime Custom_End_time=D'2017.01.01 00:00';
input color Current_Volume=clrRed;
input int Zoom=25;
input color LineColor=DodgerBlue;
input int Font_Size=8;


int Update_in_sec=15;

//double VolumeBuf[];
//double bufValueClr[];         // Буфер цвета 



datetime TimeData[];
double VolumeData[];
double DeltaData[];

int LineWidth=3;
string ver = "4.1";
string MessageFromServer="";
datetime last_loaded=D'1970.01.01 00:00';
datetime myUpdateTime=D'1970.01.01 00:00';
int UpdateFreq=15; // sec
int OneTimeAlert=0;

string clusterdelta_client="";
string indicator_id="";
string indicator_name = "PremiumVolumeChart (http://my.clusterdelta.com)";
string short_name="";

int GMT=0;
int GMT_SET=0;

int NumberRates=0;
datetime LastTime[];

string HASH_IND;

double CHART_CHANGED_REASON_1, CHART_CHANGED_REASON_2;
datetime CHART_CHANGED_REASON_3, CHART_CHANGED_REASON_4;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   
//---- buffers   
//   SetIndexBuffer(0,VolumeBuf,INDICATOR_DATA);
//   SetIndexBuffer(1,bufValueClr,INDICATOR_COLOR_INDEX);

//   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,indicator_name);
//---- indicator digits
//   IndicatorSetInteger(INDICATOR_DIGITS,0);
//----

   //HASH_IND=DoubleToString(TimeLocal())+""+DoubleToString(MathAbs(MathRand()*10000000),0); 

   // this block do not use ClusterDelta_Server but register for unique id
   do
   {
     clusterdelta_client = "CDPA" + StringSubstr(IntegerToString(TimeLocal()),7,3)+""+DoubleToString(MathAbs(MathRand()%10),0);     
     indicator_id = "CLUSTERDELTA_"+clusterdelta_client;
   } while (GlobalVariableCheck(indicator_id));
   GlobalVariableTemp(indicator_id);
   HASH_IND="CDP"+StringSubstr(clusterdelta_client,4);
   
   ArrayResize(TimeData, 0);
   ArrayResize(VolumeData, 0);
   ArrayResize(DeltaData, 0);   
   ArrayResize(LastTime, 0);
   if (Update_in_sec>2 && Update_in_sec<130) { UpdateFreq=Update_in_sec; }   

   EventSetMillisecondTimer(100);
   return (INIT_SUCCEEDED);

  }
  
void OnTimer()
{
  MainCode();
} 

void OnChartEvent(const int id,         // Event identifier  
                  const long& lparam,   // Event parameter of long type
                  const double& dparam, // Event parameter of double type
                  const string& sparam) // Event parameter of string type
 {
   if(id==CHARTEVENT_CHART_CHANGE)
   {
//      Print("Chart changed");
      Draw_Volumes_on_Chart();
   } 
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


   static bool dll_init=false;
   int data_is_ready;
   int online_is_ready;
   bool ready_to_fetch;
   int ix=0;
   int count = 0;
   static int reload=0;   

   if(ArraySize(LastTime)==0) return 0;

   if(!dll_init)
   {
     ENUM_ACCOUNT_TRADE_MODE account_type=(ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE); 
     int acc=(int)AccountInfoInteger(ACCOUNT_LOGIN);
     if(account_type == ACCOUNT_TRADE_MODE_REAL) { acc = acc * -1; } // we will care for real mode account, comment it if you dont like to it
     int res=acc;
     string cmp=AccountInfoString(ACCOUNT_COMPANY);
     InitDLL(res);
     if(res==-1) { Print("Error during DLL init. ") ; EventKillTimer(); return (0); }
     Online_Init(res,cmp,acc);     
     dll_init=1;
   }

   ready_to_fetch=((TimeLocal() >= myUpdateTime) ? true : false ); 
   data_is_ready = GetData();
   online_is_ready = GetOnline();   
   if(ready_to_fetch)
   {  
     // set new update time
     myUpdateTime = TimeLocal() + UpdateFreq;
     // send parameter for data update
     SetData();
   }
   ChartRedraw(ChartID());      
   
   // if we got data before   
   if(!data_is_ready && !online_is_ready) { return 1; }// from GetData
   
   // data are in the buffer just show them
   count=Draw_Volumes_on_Chart();
   
   ChartRedraw(0);
   return(1);
}

int Draw_Volumes_on_Chart()
{

   int ix;
   int iBase;
   int count=0;
   int max_volume;
   if(ArraySize(LastTime)==0) return 0;
   if(ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR) == 0) return 0;
   double   top_price=ChartGetDouble(0,CHART_PRICE_MAX,0);
   double   bottom_price=ChartGetDouble(0,CHART_PRICE_MIN,0);
   datetime left=LastTime[	NumberRates-(int)ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR) ]; 
   int      right_bound=(int)ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR)+1-(int)ChartGetInteger(0,CHART_VISIBLE_BARS); 
   if(right_bound<0) right_bound=0;
   datetime right=LastTime[NumberRates-right_bound-1]; 
   double area = (top_price - bottom_price) * Zoom * 1.0 / 100;
   LineWidth=(int)ChartGetInteger(0,CHART_SCALE,0);
   if(LineWidth<1) LineWidth=1;
   int LastVolume=0;
   

   int finish_idx=NumberRates-1;

   ix = NumberRates-1;
   if(ArraySize(TimeData)<finish_idx) finish_idx = ArraySize(TimeData) ;
   if (Custom_Start_time!=D'2017.01.01 00:00' || Custom_End_time!=D'2017.01.01 00:00') { finish_idx=NumberRates-1; }
   if (finish_idx ==0 ) return 0;

   ix =0;  
//   while(ix<(NumberRates-finish_idx)){VolumeBuf[ix]=EMPTY_VALUE;bufValueClr[ix]=0;ix++; }
   ix = (NumberRates-finish_idx);   
   max_volume=1;
   
   while(ix < NumberRates)
   {
      //bufValueClr[ix]=0;
      iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] );

      if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 1*60 ); } // 1 Min BrokenHour
      if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 2*60 ); } // 1 Min BrokenHour      
      if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 3*60 ); } // 1 Min BrokenHour            
      if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 4*60 ); } // 1 Min BrokenHour                  
      if (iBase < 0 && Period() >= PERIOD_M15) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 5*60 ); } // 5 Min BrokenHour      
      if (iBase < 0 && Period() >= PERIOD_H1) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 30*60 ); } // 35 Min BrokenHour / ES      
      if (iBase < 0 && Period() >= PERIOD_H1) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 35*60 ); } // 35 Min BrokenHour / ES
      if (iBase < 0 && Period() >= PERIOD_W1) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] + 24*60*60); } // 35 Min BrokenHour / ES      
      if (iBase < 0 && Period() >= PERIOD_W1) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] + 25*60*60); } // 35 Min BrokenHour / ES      
      
      
      if (iBase >= 0  && (left<=LastTime[ix] && LastTime[ix]<=right)) //  && (MathAbs(LastTime[ix]-TimeData[iBase])<Period()*60))
      {
         if (VolumeData[iBase]>max_volume) max_volume=(int)VolumeData[iBase];      
      }
      ix++;
    }

    
    ix = NumberRates-1;
    if(ArraySize(TimeData)<finish_idx) finish_idx = ArraySize(TimeData) ;
    ix = (NumberRates-finish_idx);       

   
    while(ix < NumberRates)
    {
        //bufValueClr[ix]=0;
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
      
        if (iBase >= 0  && (left<=LastTime[ix] && LastTime[ix]<=right))
        {
           DrawVolumeBar(LastTime[ix], VolumeData[iBase], max_volume, area, bottom_price);

        } 
        if(ix == NumberRates-1 && iBase>=0) { LastVolume=(int)VolumeData[iBase]; }
      
      ix++;
   }

   if(ix == NumberRates)
   {
      ResetLastError();
      ObjectCreate(0,"VolumeChart"+HASH_IND,OBJ_TEXT,0,LastTime[NumberRates-1],ChartGetDouble(0,CHART_PRICE_MIN,0)+Point());
      if( GetLastError() )
      {
        ObjectSetInteger(0,"VolumeChart"+HASH_IND,OBJPROP_TIME,LastTime[NumberRates-1]);
        ObjectSetDouble(0,"VolumeChart"+HASH_IND,OBJPROP_PRICE,ChartGetDouble(0,CHART_PRICE_MIN,0)+Point());
      }
      ObjectSetInteger(0,"VolumeChart"+HASH_IND,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER); 
      ObjectSetString(0,"VolumeChart"+HASH_IND,OBJPROP_TOOLTIP,"Volume: "+DoubleToString(LastVolume,0));
      ObjectSetString(0,"VolumeChart"+HASH_IND,OBJPROP_TEXT,"  "+DoubleToString(LastVolume,0));      
      ObjectSetString(0,"VolumeChart"+HASH_IND,OBJPROP_FONT,"Arial");            
      ObjectSetInteger(0,"VolumeChart"+HASH_IND, OBJPROP_FONTSIZE, Font_Size);      
      ObjectSetInteger(0,"VolumeChart"+HASH_IND, OBJPROP_COLOR, Current_Volume);
      ObjectSetInteger(0,"VolumeChart"+HASH_IND, OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER); 
  
   }

   return(count);
  }
//+------------------------------------------------------------------+

void DrawVolumeBar(datetime t, double v, int max_vol, double area, double p_bot)
{
   string rec_name="VolChart_T"+IntegerToString(t)+"_hash"+HASH_IND;
      
   
   double pr2=NormalizeDouble(p_bot+area*v*1.0/max_vol+Point(),Digits());
   ObjectCreate(0,rec_name, OBJ_TREND,0,t,p_bot,t,pr2); 
   ObjectSetInteger(0,rec_name,OBJPROP_RAY, false);
   ObjectSetInteger(0,rec_name,OBJPROP_COLOR,LineColor); 
   ObjectSetInteger(0,rec_name,OBJPROP_WIDTH,LineWidth); 
   ObjectSetString(0,rec_name, OBJPROP_TEXT, "Volume: "+IntegerToString((int)v));
   ObjectSetString(0,rec_name, OBJPROP_TOOLTIP, "Volume: "+IntegerToString((int)v)+"\nTime: "+TimeToString(t));   
   ObjectSetInteger(0,rec_name,OBJPROP_SELECTABLE,false);       



}

void OnDeinit(const int reason)
{
    GlobalVariableDel(indicator_id);
    EventKillTimer();
    ObjectDelete(0,"VolumeChart"+HASH_IND);
   ArrayResize(TimeData, 0);
   ArrayResize(VolumeData, 0);
   ArrayResize(LastTime, 0);
    
  int    obj_total=ObjectsTotal(0,0);
  for(int i=0;i<obj_total;i++)
    {
     
       while ( (StringFind(ObjectName(0,i),HASH_IND)!= -1) ) 
       { 
         ObjectDelete(0,ObjectName(0,i)); 
       }

    }     
    
    
    return;
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

  if (i < 0) { Print ("Error during query registration"); return -1; }
  
  if(Period_To_Minutes()<=60) {
    i = Online_Subscribe(k,clusterdelta_client, sym, per, tmc, tm0, Instrument, lsl,MetaTrader_GMT,ver,Days_in_History,cst,cet,cmp,acnt);       
  }
  
  return 1;
}  

int GetOnline()
{
   string response="";
   int length=0;   
   string key="";
   string mydata="";
   int block=0;
   if(Period_To_Minutes()>60) return 0;

   response = Online_Data(length, clusterdelta_client);
   if(length  == 0) { return 0; }
   if(ArraySize(TimeData)<4) { return 0; }
   int key_i=StringFind(response, ":");
   key = StringSubstr(response,0,key_i);
   mydata =  StringSubstr(response,key_i+1);

   string result[];
   string bardata[];
   if(key == clusterdelta_client)
   {
      StringSplit(mydata,StringGetCharacter("!",0),result);
      
      if(!GMT_SET)
      {
        StringSplit(result[2],StringGetCharacter(";",0),bardata);      
        if(VolumeData[ArraySize(VolumeData)-3] == StringToDouble(bardata[1])) // 3-rd bar in stream is 3rd in series
        {
          StringSplit(result[0],StringGetCharacter(";",0),bardata);                      
          int compare_minutes = int( (double)(TimeData[ArraySize(TimeData)-1]) - StringToDouble(bardata[0]) );
          GMT = int(compare_minutes / 3600);
          GMT_SET=0;          
        } else
        if(VolumeData[ArraySize(VolumeData)-2] == StringToDouble(bardata[1])) // 3-rd bar in stream is 3rd in series
        {
          int compare_minutes = int( (double)(TimeData[ArraySize(TimeData)-2]) - StringToDouble(bardata[0]) );
          GMT = int(compare_minutes / 3600);
          GMT_SET=0;
        } 
      }
          StringSplit(result[0],StringGetCharacter(";",0),bardata);                
          UpdateArray(TimeData, VolumeData,DeltaData, StringToDouble(bardata[0])+3600*GMT, StringToDouble(bardata[1]),StringToDouble(bardata[2]));
          StringSplit(result[1],StringGetCharacter(";",0),bardata);               
          UpdateArray(TimeData, VolumeData,DeltaData, StringToDouble(bardata[0])+3600*GMT, StringToDouble(bardata[1]),StringToDouble(bardata[2]));


   }
   return 1; 
}




int GetData()
{

   string response="";
   int length=0;
   int valid=0;   
   int len=0,td_index;
   int i=0;
   datetime index;   
   int iBase=0;
   double volume_value=0, delta_value=0;
   string result[];
   string bardata[];      
   
   response = Receive_Information(length, clusterdelta_client);
   if (length==0) { return 0; }
    
    if(StringLen(response)>1) // if we got response (no care how), convert it to mt4 buffers
    {
      len=StringSplit(response,StringGetCharacter("\n",0),result);                
      if(!len) { return 0; }
      MessageFromServer=result[0];
      
      for(i=1;i<len;i++)
      {
        if(StringLen(result[i])==0) continue;
        if(StringSplit(result[i],StringGetCharacter(";",0),bardata)<2) continue;                
        td_index=ArraySize(TimeData);
        index = StringToTime(bardata[0]);
        volume_value= StringToDouble(bardata[1]);
        delta_value= StringToDouble(bardata[2])/* *(ReverseChart_SET?-1:1) */;        
        
        if(index==0) continue;
        iBase = ArrayBsearchCorrect(TimeData, index ); 
        if (iBase >= 0) { td_index=iBase; } 
        if(td_index>=ArraySize(TimeData))
        {
           ArrayResize(TimeData, td_index+1);
           ArrayResize(VolumeData, td_index+1);
           ArrayResize(DeltaData, td_index+1);           
        } else { if((VolumeData[td_index])>(volume_value) && td_index>=ArraySize(TimeData)-2) { volume_value=VolumeData[td_index]; delta_value=DeltaData[td_index];}  }
    
        TimeData[td_index]= index;
        VolumeData[td_index] = volume_value;
        DeltaData[td_index] = delta_value;        
      
      }
      valid=ArraySize(TimeData);      
      if (valid>0)
      {
       //SortDictionary(TimeData,ValueData);
       Sort2Dictionary(TimeData,VolumeData,DeltaData);       
       int lastindex = ArraySize(TimeData);
       last_loaded=TimeData[lastindex-1];  
       if(lastindex>5)
       {
         last_loaded=TimeData[lastindex-6];  
       }
       if(last_loaded>LastTime[NumberRates-1])last_loaded=LastTime[NumberRates-1]; 
      } 
      if (StringLen(MessageFromServer)>8 && OneTimeAlert==0) { 
          int gmt_shift_left_bracket = StringFind(MessageFromServer,"[");
          int gmt_shift_right_bracket = StringFind(MessageFromServer,"]");
          if (gmt_shift_left_bracket>0 && gmt_shift_right_bracket)
          {
            GMT = (int)StringSubstr(MessageFromServer,gmt_shift_left_bracket+1,gmt_shift_right_bracket-gmt_shift_left_bracket-1);
            GMT_SET=1;
          }
      
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

void UpdateArray(datetime& td[],double& ad[], double& bd[], double dtp, double dta, double dtb)
{
    datetime indexx = (datetime)dtp;

    int i=ArraySize(td);    
    int iBase = ArrayBsearchCorrect(td, indexx );
    
    if (iBase >= 0) { i=iBase;  } 
    
    if(i>=ArraySize(td))
    {      
      ArrayResize(td, i+1);
      ArrayResize(ad, i+1);
      ArrayResize(bd, i+1);      
    } else { 
      if(ad[i]>dta && i>=ArraySize(td)-2) { dta=ad[i]; dtb=bd[i]; }       
    }
    
    td[i]= (datetime)dtp;
    ad[i]= dta;
    bd[i]= dtb;
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



void Sort2Dictionary(datetime &keys[], double &values[],  double &values2[])
{
   datetime keyCopy[];
   double valueCopy[];
   double value2Copy[];
      
   ArrayCopy(keyCopy, keys);
   ArrayCopy(valueCopy, values);
   ArrayCopy(value2Copy, values2);
   
   ArraySort(keys); //, WHOLE_ARRAY, 0, sortDirection);
   for (int i = 0; i < MathMin(ArraySize(keys), ArraySize(values)); i++)
   {
      //values[i] = valueCopy[ArrayBsearch(keyCopy, keys[i])];
      values[ArrayBsearch(keys, keyCopy[i])] = valueCopy[i];
      values2[ArrayBsearch(keys, keyCopy[i])] = value2Copy[i];      
      
   }
}

