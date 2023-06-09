#property copyright "Copyright © 2011-2018, ClusterDelta.com"
#property link      "http://my.clusterdelta.com/premium"
#property description "ClusterDelta Splash, Version 4.1 (compiled 24.08.2018)"
#property description "\nIndicator VWAP - Volume Weighted Average Price (VWAP). In finance, volume-weighted average price (VWAP) is the ratio of the value traded to total volume traded over a particular time horizon (usually one day). It is a measure of the average price a stock traded at over the trading horizon."
#property description "\nMore information can be found here: http://my.clusterdelta.com/vwap"

#import "premium_mt5_v4x1.dll"
int InitDLL(int&);
string Receive_Information(int&,string);
int Send_Query(int &, string, string, int, string, string, string, string, string, string, int, string, string, string,int);
#import

#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots   7
#property indicator_applied_price PRICE_OPEN

#property indicator_type1   DRAW_LINE
#property indicator_color1  DodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_type2   DRAW_LINE
#property indicator_color2 Gray
#property indicator_style2  STYLE_SOLID
#property indicator_width2 1

#property indicator_type3   DRAW_LINE
#property indicator_color3 Gray
#property indicator_style3 STYLE_SOLID
#property indicator_width3 1

#property indicator_type4   DRAW_LINE
#property indicator_color4 Gray
#property indicator_style4 STYLE_SOLID
#property indicator_width4 1
#property indicator_type5   DRAW_LINE
#property indicator_color5 Gray
#property indicator_style5 STYLE_SOLID
#property indicator_width5 1
#property indicator_type6   DRAW_LINE
#property indicator_color6 Gray
#property indicator_style6 STYLE_SOLID
#property indicator_width6 1
#property indicator_type7   DRAW_LINE
#property indicator_color7 Gray
#property indicator_style7 STYLE_SOLID
#property indicator_width7 1


enum  ProfilePeriod{ Custom_Period=0, per_Hour=1, Daily=2, Weekly=3, per_Asia=4, per_Europe=5, per_NYSE=6, per_CME=7, per_Contract=8 };
enum Update_Intervals {every_1min=60, every_5min=300 };                                 

//---- input parameters
extern string HELP_URL="http://my.clusterdelta.com/vwap";
input string Instrument="AUTO";
input Update_Intervals Update_in_sec=every_1min;
input string MetaTrader_GMT="AUTO";
input ProfilePeriod VWAP_Period = Daily;
input int Amount_of_VWAPs=1;
input bool Forex_auto_shift=true;
input int Forex_shift=0;
input string Custom_Period_Settings="--------- Settings for Custom Period ---------";
input bool Get_Custom_Period_from_Chart=true;
input datetime Custom_Start_time=D'2017.01.01 00:00';
input datetime Custom_End_time=D'2017.01.01 00:00';
input string Deviation_Settings="--------- Deviation Channels ---------";
input int numDev1=1;
input int numDev2=-1;
input int numDev3=2;
input int numDev4=-2;
input int numDev5=3;
input int numDev6=-3;
input string Reverse_Settings="--------- Reverse for USD/XXX symbols ---------";
input bool ReverseChart=false;
input double PriceMultiplier=1;
input string DO_NOT_SET_ReverseChart="...for USD/JPY, USD/CAD, USD/CHF --";


double VWAPBuf0[];
double VWAPBuf1[];
double VWAPBuf2[];
double VWAPBuf3[];
double VWAPBuf4[];
double VWAPBuf5[];
double VWAPBuf6[];



datetime TimeData[];
double ValueData[];
double DeviationData[];

string clusterdelta_client=""; // key to DLL
string indicator_id=""; // Indicator Global ID
string indicator_name = "ClusterDelta VWAP";
bool ReverseChart_SET=false; // for USD/ pairs
datetime LastTime[]; // global instead of Time
double LastLow[]; // global instead of Low
double LastHigh[]; // global instead of High
int UpdateFreq=60; // update frequency interval 
int Amount_of_VWAP=0; // Number of VWAPs to load
int NumberRates=0; // Total rates number
datetime myUpdateTime=D'1970.01.01 00:00'; // init of fvar
bool lastprofileloaded=false;  // flah of loaded last profile
string ver = "4.1"; // indy version
string MessageFromServer=""; // first string of response
double forex_shift_auto = 0; // forex_shift value

string HASH_IND=" ";
string vertical_line_name1="";
string vertical_line_name2="";
datetime TIME1,TIME2;//время на передачу профилю   



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   
//---- buffers   
   SetIndexBuffer(0,VWAPBuf0,INDICATOR_DATA);
   SetIndexBuffer(1,VWAPBuf1,INDICATOR_DATA);
   SetIndexBuffer(2,VWAPBuf2,INDICATOR_DATA);
   SetIndexBuffer(3,VWAPBuf3,INDICATOR_DATA);
   SetIndexBuffer(4,VWAPBuf4,INDICATOR_DATA);
   SetIndexBuffer(5,VWAPBuf5,INDICATOR_DATA);
   SetIndexBuffer(6,VWAPBuf6,INDICATOR_DATA);
   
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);   
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);   
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);   
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);   
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,EMPTY_VALUE);      
   
//---- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,indicator_name);
//---- indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//----

   // this block do not use ClusterDelta_Server but register for unique id
   do
   {
     clusterdelta_client = "CDPW" + StringSubstr(IntegerToString(TimeLocal()),7,3)+""+DoubleToString(MathAbs(MathRand()%10),0);     
     indicator_id = "CLUSTERDELTA_"+clusterdelta_client;
   } while (GlobalVariableCheck(indicator_id));
   GlobalVariableSet(indicator_id,1);
   HASH_IND=clusterdelta_client;   
   vertical_line_name1="VWLine_C1_"+HASH_IND;
   vertical_line_name2="VWLine_C2_"+HASH_IND;
   
   TIME1=Custom_Start_time;
   TIME2=Custom_End_time;
   

   ReverseChart_SET=ReverseChart;
   
   ArrayResize(TimeData, 0);
   ArrayResize(ValueData, 0);
   ArrayResize(LastTime, 0);
   if (Update_in_sec>2) { UpdateFreq=Update_in_sec; }   
   
   Amount_of_VWAP = Amount_of_VWAPs;
   if(VWAP_Period == 0) Amount_of_VWAP=1;
   
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
      ArrayResize(LastLow, ArraySize(low));
      ArrayResize(LastHigh, ArraySize(high));            
      ArrayCopy(LastTime , time);
      ArrayCopy(LastLow , low);      
      ArrayCopy(LastHigh , high);            

      return (1);//MainCode();

  }
  
int MainCode()
{ 
//---check for rates total

   static bool dll_init=false;
   static bool custom_lines=false;
   int data_is_ready;
   bool ready_to_fetch;

   int ix=0, iBase;
   int count = 0;

   if(ArraySize(LastTime)==0) return 0; // no time data yer

   if(!dll_init) // Attempt to Init DLL 
   {
     int res;
     ENUM_ACCOUNT_TRADE_MODE account_type=(ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE); 
     int acc=(int)AccountInfoInteger(ACCOUNT_LOGIN);
     if(account_type == ACCOUNT_TRADE_MODE_REAL) { acc = acc * -1; } // we will care for real mode account, comment it if you dont like to it

     InitDLL(res);
     if(res==-1) { Print("Error during DLL init. ") ; EventKillTimer(); return (0); } // Something goes wrong
     dll_init=1;  // DLL was succesfully started
   }
   
   if(!custom_lines && VWAP_Period==0)
   {
      CustomLines();
      custom_lines=true;
   }

   // check for frequency of update
   ready_to_fetch=((TimeLocal() >= myUpdateTime) ? true : false ); 
   // check for any data in DLL buffer
   data_is_ready = GetData();

   // load more than one profile
   if(data_is_ready && !ready_to_fetch && Amount_of_VWAP>1) { ready_to_fetch=true; }  
   // load last profile before waiting up update time
   if(data_is_ready && !ready_to_fetch && Amount_of_VWAP==1 && lastprofileloaded==false) { ready_to_fetch=true; lastprofileloaded=true;  }     

   // we can ready to reload profile
   if(ready_to_fetch)
   {  
     // set new update time
     myUpdateTime = TimeLocal() + UpdateFreq;
     // send parameter for data update
     SetData();
   }
   
   // if we got data before   
   if(!data_is_ready) { return 1; }// from GetData
   // data are in the buffer just show them

   if(ArraySize(TimeData)==0) { return 1; }

      ix=0;
      while(ix < NumberRates)
      {

        iBase = ArrayBsearchCorrect(TimeData, LastTime[ix]);
        if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 1*60 ); } // 1 Min BrokenHour
        if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 2*60 ); } // 1 Min BrokenHour      
        if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 3*60 ); } // 1 Min BrokenHour            
        if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 4*60 ); } // 1 Min BrokenHour                  
        if (iBase < 0 && Period() >= PERIOD_M15) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 5*60 ); } // 5 Min BrokenHour      
        if (iBase < 0 && Period() >= PERIOD_H1) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 30*60 ); } // 35 Min BrokenHour / ES      
        if (iBase < 0 && Period() >= PERIOD_H1) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 35*60 ); } // 35 Min BrokenHour / ES
        if (iBase < 0 && Period() >= PERIOD_W1) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] + 24*60*60); } // 35 Min BrokenHour / ES            
        if (iBase < 0 && Period() >= PERIOD_W1) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] + 25*60*60); } // 35 Min BrokenHour / ES            

      
        if (iBase >= 0) //  && (MathAbs(LastTime[ix]-TimeData[iBase])<Period()*60))
        {
         count++;    
         double vwap=ValueData[iBase];
         //Print("ix=",ix, " VWAP: "+vwap);
         
         if(vwap>0)
         {
         VWAPBuf0[ix]=vwap; 
         if (numDev1!=0) { VWAPBuf1[ix]= vwap + DeviationData[iBase]*numDev1; }
         if (numDev2!=0) { VWAPBuf2[ix]= vwap + DeviationData[iBase]*numDev2; }
         if (numDev3!=0) { VWAPBuf3[ix]= vwap + DeviationData[iBase]*numDev3; }
         if (numDev4!=0) { VWAPBuf4[ix]= vwap + DeviationData[iBase]*numDev4; }                  
         if (numDev5!=0) { VWAPBuf5[ix]= vwap + DeviationData[iBase]*numDev5; }
         if (numDev6!=0) { VWAPBuf6[ix]= vwap + DeviationData[iBase]*numDev6; }                  

         count++;
         }
        } else {
         VWAPBuf0[ix]=EMPTY_VALUE;
         VWAPBuf1[ix]=EMPTY_VALUE;
         VWAPBuf2[ix]=EMPTY_VALUE;
         VWAPBuf3[ix]=EMPTY_VALUE;
         VWAPBuf4[ix]=EMPTY_VALUE;         
         VWAPBuf5[ix]=EMPTY_VALUE;
         VWAPBuf6[ix]=EMPTY_VALUE;         
        }
        ix++;
      }
      ChartRedraw(0);      
  

   return(ix);
  }
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{

  GlobalVariableDel(indicator_id);
  EventKillTimer();
  int    obj_total=ObjectsTotal(0);
  for(int i=0;i<obj_total;i++)
    {
     if((reason!=3 && reason!=5) || (ObjectName(0,i)!=vertical_line_name1 && ObjectName(0,i)!=vertical_line_name2))
     {
       while ( (StringFind(ObjectName(0,i),HASH_IND)!= -1) ) { ObjectDelete(0,ObjectName(0,i));  }
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
  string tm0=IntegerToString(Amount_of_VWAP-1);
  string lsl=TimeToString(TimeTradeServer()); //last_loaded);
  string cst=TimeToString(TIME1);
  string cet=TimeToString(TIME2);
  string cmp=AccountInfoString(ACCOUNT_COMPANY);
  int acnt=(int)AccountInfoInteger(ACCOUNT_LOGIN);
  
  int amount=VWAP_Period;

  i = Send_Query(k,clusterdelta_client, sym, per, tmc, tm0, Instrument, lsl,MetaTrader_GMT,ver,amount,cst,cet,cmp,acnt);     

  if (i < 0) { Alert ("Error during query registration"); return -1; }
  
  return 1;
}  

void CustomLines()
{
   if(VWAP_Period == 0)
   {
     if (Get_Custom_Period_from_Chart)
     {
        if(ObjectFind(0,vertical_line_name1)==-1 || ObjectFind(0,vertical_line_name2)==-1)
        {
          color vert_line_color=DeepSkyBlue;
          ENUM_LINE_STYLE vert_line_stye=STYLE_DOT;
          int another_custom_profiles=0;
          int objects=ObjectsTotal(0);                    
          
          int start_time = ArrayBsearch(LastTime,LastTime[NumberRates-1]-Period_To_Minutes()*60*60);
         
          datetime time_line1=LastTime[start_time];
          datetime time_line2=LastTime[NumberRates-1]+Period_To_Minutes()*1*60;
          datetime v1_time=D'1970.01.01 00:00', v2_time=D'1970.01.01 00:00';
          ENUM_LINE_STYLE prev_style=STYLE_SOLID;
          color prev_color=clrBlack;
          bool get_old_lines = false;
          string hash_client_name="";
          
          for(int j=0;j<objects;j++)
          {
            if (StringSubstr(ObjectName(0,j),0,8) == "VWLine_C") 
            { 
              hash_client_name=StringSubstr(ObjectName(0,j),10);
              if (GlobalVariableGet("CLUSTERDELTA_"+hash_client_name)) 
              {  another_custom_profiles++;  


              } else
              {
                // lines of nobody, maybe mine

                ResetLastError();

                v1_time = (datetime)ObjectGetInteger(0,"VWLine_C1_"+hash_client_name,OBJPROP_TIME);
                v2_time = (datetime)ObjectGetInteger(0,"VWLine_C2_"+hash_client_name,OBJPROP_TIME);
           
                if(v1_time!=D'1970.01.01 00:00' && v2_time!=D'1970.01.01 00:00') 
                {
                  prev_style = (ENUM_LINE_STYLE)ObjectGetInteger(0,"VWLine_C1_"+hash_client_name,OBJPROP_STYLE);
                  prev_color = (color)ObjectGetInteger(0,"VWLine_C1_"+hash_client_name,OBJPROP_COLOR);
                  get_old_lines=true;
                }
              }
            }
            if(get_old_lines) break;
          }

          if (another_custom_profiles>=1 && another_custom_profiles<=2) { vert_line_color=Orange; vert_line_stye=STYLE_DASHDOTDOT;}
          if (another_custom_profiles>=3 && another_custom_profiles<=4) { vert_line_color=DodgerBlue; vert_line_stye=STYLE_DASHDOT;}

          if(get_old_lines)
          {
            time_line1=v1_time;
            time_line2=v2_time;
            vert_line_stye=prev_style;
            vert_line_color=prev_color;
            ObjectDelete(0,"VWLine_C1_"+hash_client_name);
            ObjectDelete(0,"VWLine_C2_"+hash_client_name);            
          }
          
          ObjectCreate(0,vertical_line_name1, OBJ_VLINE, 0, time_line1,0);
          ObjectCreate(0,vertical_line_name2, OBJ_VLINE, 0, time_line2,0);
          ObjectSetInteger(0,vertical_line_name1,OBJPROP_STYLE,vert_line_stye);
          ObjectSetInteger(0,vertical_line_name1,OBJPROP_COLOR,vert_line_color);      
          ObjectSetInteger(0,vertical_line_name2,OBJPROP_STYLE,vert_line_stye);
          ObjectSetInteger(0,vertical_line_name2,OBJPROP_COLOR,vert_line_color);      
          ObjectSetInteger(0,vertical_line_name1,OBJPROP_SELECTABLE, 1);
          ObjectSetInteger(0,vertical_line_name2,OBJPROP_SELECTABLE, 1);
          
        }
        
        if(ObjectFind(0,vertical_line_name1)!=-1 && ObjectFind(0,vertical_line_name2)!=-1)
        {
            datetime t1=(datetime)ObjectGetInteger(0,vertical_line_name1,OBJPROP_TIME); 
            datetime t2=(datetime)ObjectGetInteger(0,vertical_line_name2,OBJPROP_TIME); 

            if(t1<t2)
            {                                                 //В случае, если координаты времени линии ориентированы неправильно,
               TIME1=(datetime)ObjectGetInteger(0,vertical_line_name1,OBJPROP_TIME);   //берем первой вторую координату времени
               TIME2=(datetime)ObjectGetInteger(0,vertical_line_name2,OBJPROP_TIME)+Period_To_Minutes()*60; //во вторую координату включаем время одного бара
            } else
            if(t1>t2)
            {                                                 //В случае, если координаты времени линии ориентированы правильно,
               TIME1=(datetime)ObjectGetInteger(0,vertical_line_name2,OBJPROP_TIME);   //берем первой первую координату времени
               TIME2=(datetime)ObjectGetInteger(0,vertical_line_name1,OBJPROP_TIME)+Period_To_Minutes()*60; //во вторую координату включаем время одного бара
            }
            //request="http://generatedata.biz/mt4/vwap.php?symbol="+UrlEncode(Symbol()) + "&timeframe=" + Period()+  "&static="+VWAP_Period+"&amount="+(Amount_of_VWAPs-1)+"&starttime="+TimeToStr(TIME1)+"&endtime="+TimeToStr(TIME2)+  "&usertime="+TimeToStr(TimeCurrent())+"&instrument="+UrlEncode(Instrument)+"&mtgmt="+MetaTrader_GMT+"&ver="+UrlEncode(ver)+"&company="+UrlEncode(AccountCompany())+"&accnumber="+UrlEncode(AccountNumber());             
         }
     } else
     {
       ObjectDelete(0,vertical_line_name1);
       ObjectDelete(0,vertical_line_name2);       
     }
   } else
   {
     ObjectDelete(0,vertical_line_name1);
     ObjectDelete(0,vertical_line_name2);       
   }
}

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{

//-------------------------------------------------------------------------------------------------
   if(id==CHARTEVENT_OBJECT_CLICK || id==CHARTEVENT_CLICK || id==CHARTEVENT_OBJECT_DRAG)
     { //если было нажатие на какую-то кнопку

        if(ObjectFind(0,vertical_line_name1)!=-1 && ObjectFind(0,vertical_line_name2)!=-1)
        {
            datetime t1=(datetime)ObjectGetInteger(0,vertical_line_name1,OBJPROP_TIME); 
            datetime t2=(datetime)ObjectGetInteger(0,vertical_line_name2,OBJPROP_TIME); 
            datetime Check_TIME1,Check_TIME2;
            if(t1<t2)
            {                                                 //В случае, если координаты времени линии ориентированы неправильно,
               Check_TIME1=(datetime)ObjectGetInteger(0,vertical_line_name1,OBJPROP_TIME);   //берем первой вторую координату времени
               Check_TIME2=(datetime)ObjectGetInteger(0,vertical_line_name2,OBJPROP_TIME)+Period_To_Minutes()*60; //во вторую координату включаем время одного бара
            } else
            {                                                 //В случае, если координаты времени линии ориентированы правильно,
               Check_TIME1=(datetime)ObjectGetInteger(0,vertical_line_name2,OBJPROP_TIME);   //берем первой первую координату времени
               Check_TIME2=(datetime)ObjectGetInteger(0,vertical_line_name1,OBJPROP_TIME)+Period_To_Minutes()*60; //во вторую координату включаем время одного бара
            }
            if(Check_TIME1 != TIME1 || Check_TIME2!=TIME2) 
            {
              myUpdateTime=TimeLocal();
              ArrayResize(TimeData,0);
              ArrayResize(ValueData,0);
              ArrayResize(DeviationData,0);
              
              ArrayFill(VWAPBuf0,0,ArraySize(VWAPBuf0),0);
              ArrayFill(VWAPBuf1,0,ArraySize(VWAPBuf1),0);
              ArrayFill(VWAPBuf2,0,ArraySize(VWAPBuf2),0);
              ArrayFill(VWAPBuf3,0,ArraySize(VWAPBuf3),0);
              ArrayFill(VWAPBuf4,0,ArraySize(VWAPBuf4),0);
              ArrayFill(VWAPBuf5,0,ArraySize(VWAPBuf5),0);
              ArrayFill(VWAPBuf6,0,ArraySize(VWAPBuf6),0);
              TIME1=Check_TIME1;
              TIME2=Check_TIME2;
            }
            
        } 
     }
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
   int    int_index=0;
   int calc_index=0;
   double avg=0, sumsq=0, cur_dev=0;
   
   response = Receive_Information(length, clusterdelta_client);

   if (length==0) { return 0; }
    
    if(StringLen(response)>1) // if we got response (no care how), convert it to mt4 buffers
    {
      forex_shift_auto = Forex_shift;    
      len=StringSplit(response,StringGetCharacter("\n",0),result);                
      if(!len) { return 0; }
      StringSplit(result[0],StringGetCharacter(";",0),bardata);                      
      if (Forex_auto_shift) forex_shift_auto = get_forex_shift(result[0]);                    
      int_index=0;
      for(i=1;i<len;i++)
      {
        if(ArraySize(result)<=i) continue;
        if(StringLen(result[i])==0) continue;
        StringSplit(result[i],StringGetCharacter(";",0),bardata);                
        td_index=ArraySize(TimeData);
        index = StringToTime(bardata[0]);
        volume_value= StringToDouble(bardata[1]);
        
        if(index==0) continue;
        iBase = ArrayBsearchCorrect(TimeData, index ); 
        if (iBase >= 0) { td_index=iBase; } 
        if(int_index==0) int_index=td_index;        
        if(td_index>=ArraySize(TimeData))
        {
           ArrayResize(TimeData, td_index+1);
           ArrayResize(ValueData, td_index+1);
           ArrayResize(DeviationData, td_index+1);           
        } 
    
        TimeData[td_index]= index;
        ValueData[td_index] = (ReverseChart_SET?(1/volume_value):volume_value)+forex_shift_auto*_Point;

        // -------- deviations
        int max_index = td_index+1;
        calc_index=0;
        avg=0;
        for(calc_index=int_index; calc_index<max_index; calc_index++) avg=avg+ValueData[calc_index];
        avg=avg/(max_index-int_index);
        sumsq = 0;
        for(calc_index=int_index; calc_index<max_index; calc_index++)
        {
          sumsq=sumsq+(ValueData[calc_index]-avg)*(ValueData[calc_index]-avg);
        }
        cur_dev=0;
        if((max_index-int_index)>1)
        {
          cur_dev = MathSqrt(sumsq / ((max_index-int_index)-1));
          DeviationData[td_index] = cur_dev;      
        }    
       // ------------ end of devi
       
      }           
      valid=ArraySize(TimeData);

      if (valid>0)
      {
       Sort2Dictionary(TimeData,ValueData,DeviationData);
      } 
    }
    if(Amount_of_VWAP>1) { Amount_of_VWAP--;  }
    return (1);
}


int ArrayBsearchCorrect(datetime &array[], datetime value)
{
   if(ArraySize(array)==0) return(-1);   
   int i = ArrayBsearch(array, value); //, count, start);
   if (value != array[i])
   {
      i = -1;
   }
   return (i);
}
/*
int ConvertResponseToArrays(string st, datetime& td[],double& vd[], double& dd[], string de1, string de2, string& msg, int checkUpdate=0) 
{ 

  int    i=0, np, dp, iBase;
  string stp,dtp,dtv;
  datetime indexx;

  double int_vd[];
  int    int_index=0;
  int calc_index=0;
  double avg=0, sumsq=0, cur_dev=0;
  
  ArrayResize(int_vd,0);
  forex_shift_auto = Forex_shift;

  
  np=StringFind(st, de1);
  

  if(np>0)
  {
      stp=StringSubstr(st, 0, np);
      msg=stp;
      st=StringSubstr(st, np+1);
      if (Forex_auto_shift) forex_shift_auto = get_forex_shift(msg);              
  }
  
  while (StringLen(st)>0 && np>0) {
    np=StringFind(st, de1);

    if (np<0) {
      stp=st;
      st="";
    } else {
      stp=StringSubstr(st, 0, np);
      st=StringSubstr(st, np+1);
    }
    
    i++;
    dp=StringFind(stp, de2);
    if(dp<0)
    {
      dtp="0";
      dtv="0";      
    } else 
    {
      dtp=StringSubstr(stp, 0, dp);
      dtv=StringSubstr(stp, dp+1);

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
      ArrayResize(vd, i+1);
      ArrayResize(dd, i+1);      
    }
    
    td[i]= StringToTime(dtp);
    //vd[i]= StringToDouble(dtv);
    vd[i]= (ReverseChart_SET?(1/StringToDouble(dtv)):StringToDouble(dtv))*PriceMultiplier+forex_shift_auto*_Point;
    
    
    
    // -------- deviations
    int_index = ArraySize(int_vd);
    ArrayResize(int_vd, int_index+1);
    int_vd[int_index] = vd[i];
   
    calc_index=0;
    int_index++;
    avg=0;
    for(calc_index=0; calc_index<int_index; calc_index++)
    {
      avg=avg+int_vd[calc_index];
    }
    avg=avg/int_index;
    sumsq = 0;
    for(calc_index=0; calc_index<int_index; calc_index++)
    {
      sumsq=sumsq+(int_vd[calc_index]-avg)*(int_vd[calc_index]-avg);
    }
    cur_dev=0;
    if(int_index>1)
    {
      cur_dev = MathSqrt(sumsq / (int_index-1));
    }    
    
    dd[i] = cur_dev;
    // ------------ end of devi
    
    
    }
  }
  return(ArraySize(td));

}
*/
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

double get_forex_shift(string prices)
{
  double forex_shift_low=0;
  double forex_shift_high=0;
  double forex_auto=0;
  int np,next_pos;
  string minprice, maxprice, mintime, maxtime;
  
  np=StringFind(prices,";");
  if(np>0)
  {
    minprice=StringSubstr(prices,0,np); // min price 
    next_pos=StringFind(prices,";",np+1);
    maxprice=StringSubstr(prices,np+1,next_pos-np-1); // max price
    np=next_pos;
    next_pos=StringFind(prices,";",np+1);
    mintime=StringSubstr(prices,np+1,next_pos-np-1); // max price
    maxtime=StringSubstr(prices,next_pos+1);    
  } else
  {
    return 0;
  }




  if ( StringToDouble(minprice)==0 || StringToDouble(maxprice)==0 ) return 0;
  if (ArraySize(LastTime) == 0) return 0;
  
  double futures_minimum = (ReverseChart_SET ? 1/StringToDouble(minprice) : StringToDouble(minprice))*PriceMultiplier;
  double futures_maximum = (ReverseChart_SET ? 1/StringToDouble(maxprice) : StringToDouble(maxprice))*PriceMultiplier;

  datetime last_Start_time=StringToTime(mintime)-Period_To_Minutes()*60;
  datetime last_End_time=StringToTime(maxtime)-Period_To_Minutes()*60;
  
  int start_index_time = ArrayBsearch(LastTime,last_Start_time);
  int last_index_time = ArraySize(LastTime);
  
  if (last_End_time<=LastTime[ArraySize(LastTime)-1])
  {
    last_index_time = ArrayBsearch(LastTime,last_End_time);
  } 

  int forex_minimum = ArrayMinimum(LastLow, start_index_time, last_index_time-start_index_time);
  int forex_maximum = ArrayMaximum(LastHigh, start_index_time, last_index_time-start_index_time);
  
  forex_shift_low = MathRound((LastLow[forex_minimum]-futures_minimum)/_Point);
  forex_shift_high= MathRound((LastHigh[forex_maximum]-futures_maximum)/_Point);
  if (ReverseChart_SET) 
  {
    forex_shift_low = MathRound((LastLow[forex_minimum]-futures_maximum)/_Point);
    forex_shift_high= MathRound((LastHigh[forex_maximum]-futures_minimum)/_Point);
  }
  forex_auto = forex_shift_low;
  if (forex_maximum < forex_minimum) forex_auto = forex_shift_high;
  return forex_auto;

}
