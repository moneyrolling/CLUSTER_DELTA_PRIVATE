#property copyright "Copyright © 2011-2018, ClusterDelta.com"
#property link      "http://my.clusterdelta.com/premium"
#property description "ClusterDelta Splash, Version 4.1 (compiled 24.08.2018)"
#property description "\nThe Splash indicator is developed for searching big splashes of volumes when big volumes took place in a short period of time. The exchange is a market place where buyers meet sellers. Big money on a tick chart will be divided into a lot of smaller ones, depending on the size of opposite orders. But sometimes there occur sellers and buyers of big volumes in the deal. "
#property description "\nMore information can be found here: http://my.clusterdelta.com/splash"

#import "premium_mt5_v4x1.dll"
int InitDLL(int&);
string Receive_Information(int&,string);
int Send_Query(int &, string, string, int, string, string, string, string, string, string, int, string, string, string,int);
#import



#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

enum DrawType { Circles=0, Rectangles=1 }; // Rectangles are not used
enum ForexShiftMode { Auto_Day=1, Manual_ForexShift=2 };
enum HistoryMode { until_NOW=0, until_CustomLastDate=1 };
enum CalculateMode { Simple_Mode=0, Expert_Mode=1 };
enum SourceData { Volumes=0, Delta=1 };

enum AggregateTicks { Tick_By_Tick=0, Aggregate_Tick=1 };




//---- input parameters
input string Help_URL="http://clusterdelta.com/splash";
input string Instrument="AUTO";
input string MetaTrader_GMT="AUTO";
input AggregateTicks TickAggregate_Mode = Aggregate_Tick;
input int Strike=120;
input int Days=14;
input string Other_Settings =" --- Period for calculations --- ";
input HistoryMode Online_Mode = until_NOW;
input datetime Custom_LastDate=D'2017.01.01 00:00';
input color Ask_Tick_Color=clrSeaGreen;
input color Bid_Tick_Color=clrSienna;
input int ObjectMaxRadius=36;
input string ObjectMaxVolume="AUTO";
input ForexShiftMode Forex_Shift_mode=Auto_Day;
input int ForexShift=0;
input string Reverse_Settings="--------- Reverse for USD/XXX symbols ---------";
input bool ReverseChart=false;
input string DO_NOT_SET_ReverseChart="...for USD/JPY, USD/CAD, USD/CHF --";
input string Comment_Alert="--- Alert Settings ";
input  bool Play_Alerts=true;
input  int Alert_StrikeSize=0;
input  int Alert_Numbers=3;
input  int Alert_Interval_sec=10;
input  string Alert_Filename="alert"; // Sounds/news.wav
input  color Alert_Color=clrLightGoldenrod;
int ALERT_BAR=0; // has to be "0" and never change it

datetime AlertPlayNext=0;
int AlertNumbers=0;
int AlertInterval=0;
datetime AlertTime=0;
int AlertSize=0;
double AlertPrice=0;
int AlertRadius=0;
int my_alertsize=0;
bool play_alert=false;


datetime TimeData[];
double ValueData[];
datetime LastTime[];
double LastLow[]; // global instead of Low
double LastHigh[]; // global instead of High
int NumberRates=0;

CalculateMode Calculate_Mode=Simple_Mode;
DrawType DrawMethod = Circles;
SourceData Source_Data=Volumes;
int RectangleMaxLength=20;
int DaysLength=0;
int Adaptive_Period=5;
int Percent_Of_Total_DayVolume = 4;
int Custom_Timeframe = 0;


string clusterdelta_client=""; // key to DLL
string indicator_id=""; // Indicator Global ID
string indicator_name = "ClusterDelta Splash";
bool ReverseChart_SET=false; // for USD/ pairs
int UpdateFreq=60; // update frequency interval 
int greatest_Volume=0; 

datetime myUpdateTime=D'1970.01.01 00:00'; // init of fvar

string ver = "4.1"; // indy version
string MessageFromServer=""; // first string of response


string HASH_IND=" ";
string vertical_line_name1="";
string vertical_line_name2="";
datetime TIME1,TIME2;//время на передачу профилю   

int CustomStrike=0;



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
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);   
//---- indicator digits
//   IndicatorSetInteger(INDICATOR_DIGITS,0);
//----

   //HASH_IND=DoubleToString(TimeLocal())+""+DoubleToString(MathAbs(MathRand()*10000000),0); 

   // this block do not use ClusterDelta_Server but register for unique id
   do
   {
     if(TickAggregate_Mode == Tick_By_Tick) 
     {
       clusterdelta_client = "CDPT" + StringSubstr(IntegerToString(TimeLocal()),7,3)+""+DoubleToString(MathAbs(MathRand()%10),0);     
     } else
     if(TickAggregate_Mode == Aggregate_Tick)      
     { // use another script call
       clusterdelta_client = "CDPG" + StringSubstr(IntegerToString(TimeLocal()),7,3)+""+DoubleToString(MathAbs(MathRand()%10),0);          
     }
     indicator_id = "CLUSTERDELTA_"+clusterdelta_client;
   } while (GlobalVariableCheck(indicator_id));
   GlobalVariableTemp(indicator_id);
   HASH_IND=clusterdelta_client;
   
   ReverseChart_SET=ReverseChart;
   AlertSize = Alert_StrikeSize;
  
   ArrayResize(TimeData, 0);
   ArrayResize(ValueData, 0);
   ArrayResize(LastTime, 0);
   ArrayResize(LastLow, 0);
   ArrayResize(LastHigh, 0);


   DaysLength=Days;
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

   CustomStrike=Strike;
   EventSetMillisecondTimer(200);
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
//   if(id==CHARTEVENT_CHART_CHANGE)
//   {
//      Print("Chart changed");
//      Draw_Volumes_on_Chart();
//   } 
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
      ALERT_BAR=NumberRates-1;
      ArrayResize(LastTime, ArraySize(time));
      ArrayResize(LastLow, ArraySize(low));
      ArrayResize(LastHigh, ArraySize(high));            
      ArrayCopy(LastTime , time);
      ArrayCopy(LastLow , low);      
      ArrayCopy(LastHigh , high);            
      MainCode();

      
      
      return (1);//MainCode();
}
  
int MainCode()
{ 
//---check for rates total


   static bool dll_init=false;
   int data_is_ready;
   bool ready_to_fetch;

   if(ArraySize(LastTime)==0) return 0;

   if(!dll_init)
   {
     int res;
     ENUM_ACCOUNT_TRADE_MODE account_type=(ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE); 
     int acc=(int)AccountInfoInteger(ACCOUNT_LOGIN);
     if(account_type == ACCOUNT_TRADE_MODE_REAL) { acc = acc * -1; } // we will care for real mode account, comment it if you dont like to it

     InitDLL(res);
     if(res==-1) { Print("Error during DLL init. ") ; EventKillTimer(); return (0); }     
     dll_init=1;
   }

   if (play_alert) { PlayAlert(Alert_Filename); }       
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
   return(1);
}
void OnDeinit(const int reason)
{

    GlobalVariableDel(indicator_id);
    EventKillTimer();

  ObjectDelete(0,"InfLine_Alert");
  ObjectDelete(0,HASH_IND+"AlertLine"); 
  ObjectDelete(0, HASH_IND+"AlertLine2");  
    
   ArrayResize(TimeData, 0);
   ArrayResize(ValueData, 0);
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
  string tm0=IntegerToString(Percent_Of_Total_DayVolume);
  string lsl=IntegerToString(Adaptive_Period);
  string cst="sm"+IntegerToString(Forex_Shift_mode)+"cm"+IntegerToString(Calculate_Mode);
  string cet=TimeToString(Custom_LastDate);
  if (Source_Data == Volumes) cst = cst+"v";
  else
  if (Source_Data == Delta) cst = cst+"d";
  
  if(Calculate_Mode == 0) // Simple Mode, send Strike instead of Adaptive value
  {
    lsl = IntegerToString(CustomStrike);
  }
  if(Online_Mode == until_NOW)
  {
    cet="";
  }
  string cmp=AccountInfoString(ACCOUNT_COMPANY);
  int acnt=(int)AccountInfoInteger(ACCOUNT_LOGIN);
  
  int amount=DaysLength;  

  i = Send_Query(k,clusterdelta_client, sym, per, tmc, tm0, Instrument, lsl,MetaTrader_GMT,ver,amount,cst,cet,cmp,acnt);     

  if (i < 0) { Print ("Error during query registration"); return -1; }
  
 
  return 1;
}  


int GetData()
{

   string response="";
   int length=0;
   int valid=0;   
   
   int greatest_volume;
   string lines[];
   string v[];
   int rows=0;
   int m;
   ushort u_sep=StringGetCharacter("\n",0); 
   response = Receive_Information(length, clusterdelta_client);

   if (length==0) { return 0; }

    if(StringLen(response)>1) // if we got response (no care how), convert it to mt4 buffers
    {
       StringSplit(response, u_sep, lines);       
       rows = ArraySize(lines);
       if(rows>1)
       {
         m=StringFind(lines[0],"Max");
         if(m!=-1)
         {
           StringSplit(StringSubstr(lines[0], m+4), ' ', v);
           greatest_volume = (int)StringToInteger(v[0]);
           DrawCircles (greatest_volume, 0, rows, lines);
           DaysLength=2; // we do not need to reload long history 
         } else { Print("Error in response"); }
       } 
    }
    return (1);
}



void DrawCircles(int maxVolume, int maxDelta, int size, string &line[])
{
  string vars[];
  int bar_number;
  double strike;
  string name_prefix=HASH_IND+"_";
  string name_arrow;
  int k=1;
  int maxV = greatest_Volume; 
  
  if( maxVolume>greatest_Volume) { greatest_Volume=maxVolume; maxV=greatest_Volume; }
  
  int radius = 30;
  int radius_volume;
  color color_volume;
  
  if (DrawMethod == Circles) radius = ObjectMaxRadius;

  if(maxV == 0) return ;
  if( ObjectMaxVolume!="AUTO" && StringToInteger(ObjectMaxVolume)>=CustomStrike && StringToInteger(ObjectMaxVolume)<maxV) { maxV = (int)StringToInteger(ObjectMaxVolume); }
  
  for (k=1; k<size; k++)
  {
    name_arrow = name_prefix;// + k;
    StringSplit(line[k], ';', vars);
    
    if(ArraySize(vars)==0) continue;
    vars[3]=IntegerToString(StringToInteger(vars[3])*(ReverseChart_SET ? -1 : 1));    
        
      radius_volume = int(radius * MathAbs(StringToInteger(vars[3])) / maxV);
      if(StringToInteger(vars[3])<0) { color_volume=Bid_Tick_Color; } else { color_volume=Ask_Tick_Color; }
      my_alertsize=(int)StringToInteger(vars[3]);
      if(radius_volume<5)radius_volume=5;
     
 
    bar_number = ArrayBsearch(LastTime, StringToTime(vars[0])); 
    name_arrow = name_arrow+vars[0]+vars[1];    
    if(StringToDouble(vars[1]) == 0) continue;
    if(MathAbs(StringToInteger(vars[3]))<CustomStrike) continue; // CustomStrike
    
    strike = StringToDouble(vars[1])+get_forexshift(StringToDouble(vars[4]),StringToDouble(vars[5]),bar_number) ;
    if(ReverseChart_SET)
    {
      strike = 1/StringToDouble(vars[1])+get_forexshift(StringToDouble(vars[4]),StringToDouble(vars[5]),bar_number) ;    

    }
  
    if (DrawMethod == Circles) 
    {
      //RectangleCreate(0,name_arrow+"black",0,LastTime[bar_number],strike,LastTime[bar_number],strike,clrBlack ,STYLE_SOLID,radius_volume+2,false,false,false,false,0);        
      //RectangleCreate(0,name_arrow,0,LastTime[bar_number],strike,LastTime[bar_number],strike,color_volume ,STYLE_SOLID,radius_volume,false,false,false,false,0);    
      //ObjectSetString(0, name_arrow, OBJPROP_TOOLTIP, "Futures Price: "+vars[1]+"\nForex Price: "+IntegerToString((int)strike)+"\nVolume: "+vars[2]+"\nDelta: "+vars[3]);

      if(radius_volume>radius) 
      {
        radius_volume=radius+3;      
        RectangleCreate(0,name_arrow+"red",0,LastTime[bar_number],strike,LastTime[bar_number],strike,clrGoldenrod,STYLE_SOLID,radius_volume+4,false,false,false,false,0);                     
      }
      RectangleCreate(0,name_arrow+"black",0,LastTime[bar_number],strike,LastTime[bar_number],strike,clrBlack,STYLE_SOLID,radius_volume+2,false,false,false,false,0);             
      RectangleCreate(0,name_arrow,0,LastTime[bar_number],strike,LastTime[bar_number],strike,color_volume ,STYLE_SOLID,radius_volume,false,false,false,false,0); 

      ObjectSetString(0, name_arrow, OBJPROP_TOOLTIP, "Futures Price: "+vars[1]+"\nForex Price: "+DoubleToString(strike)+"\nTicks: "+vars[2]+"\nTick Volume: "+vars[3]);
      
      
    }
    if(ArraySize(LastTime)<1) return;
    if(bar_number == ALERT_BAR &&  MathAbs(my_alertsize)>AlertSize && AlertTime!=LastTime[ALERT_BAR] && !play_alert && Play_Alerts==true) 
    { 
           play_alert=true; 
           AlertTime = LastTime[ALERT_BAR];   
           AlertNumbers=Alert_Numbers;  
           AlertInterval=Alert_Interval_sec;
           AlertPlayNext=0;
           AlertPrice = strike;
           AlertRadius=radius_volume;
    }
  }
}

int PlayAlert(string filename)
{
  static int alert_radius=10;
  if(AlertNumbers == 0) 
  { 
     ObjectDelete(0,HASH_IND+"AlertLine"); ObjectDelete(0,HASH_IND+"AlertLine2");  }
  
  if(AlertNumbers>0 && AlertPlayNext>=TimeLocal())
  {
  
      if(alert_radius>=ObjectMaxRadius*1.6) alert_radius=AlertRadius;
      alert_radius=alert_radius+4;

      RectangleCreate(0,HASH_IND+"AlertLine",0,LastTime[ALERT_BAR],AlertPrice,LastTime[ALERT_BAR],AlertPrice,Alert_Color,STYLE_SOLID,alert_radius,false,false,false,false,0);   
      RectangleCreate(0,HASH_IND+"AlertLine2",0,LastTime[ALERT_BAR],AlertPrice,LastTime[ALERT_BAR],AlertPrice,(my_alertsize<0?Bid_Tick_Color:Ask_Tick_Color),STYLE_SOLID,AlertRadius,false,false,false,false,0);         
  
  }  
  
  if(AlertNumbers>0 && AlertPlayNext<TimeLocal())
  {
    alert_radius=AlertRadius;
    PlaySound(filename+".wav");
    AlertPlayNext = TimeLocal()+AlertInterval;
    AlertNumbers--;

      Print("Alert on Splash played");             
      if(AlertNumbers<=0) { play_alert=false; ObjectDelete(0,HASH_IND+"AlertLine"); ObjectDelete(0,HASH_IND+"AlertLine2");}
      
  }
  

  return 0;
}

bool RectangleCreate(const long            chart_ID=0,        // ID графика 
                     const string          name="Rectangle",  // имя прямоугольника 
                     const int             sub_window=0,      // номер подокна  
                     datetime              time1=0,           // время первой точки 
                     double                price1=0,          // цена первой точки 
                     datetime              time2=0,           // время второй точки 
                     double                price2=0,          // цена второй точки 
                     const color           clr=clrRed,        // цвет прямоугольника 
                     const ENUM_LINE_STYLE style=STYLE_SOLID, // стиль линий прямоугольника 
                     const int             width=1,           // толщина линий прямоугольника 
                     const bool            fill=false,        // заливка прямоугольника цветом 
                     const bool            back=false,        // на заднем плане 
                     const bool            selection=true,    // выделить для перемещений 
                     const bool            hidden=true,       // скрыт в списке объектов 
                     const long            z_order=0)         // приоритет на нажатие мышью 
  {

   ResetLastError(); 
   ObjectDelete(0,name);  
   ObjectCreate(chart_ID,name,OBJ_RECTANGLE,sub_window,time1,price1,time2,price2); 
   ResetLastError(); 

//--- установим цвет прямоугольника 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- установим стиль линий прямоугольника 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
//--- установим толщину линий прямоугольника 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); 
//--- отобразим на переднем (false) или заднем (true) плане 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- включим (true) или отключим (false) режим выделения прямоугольника для перемещений 
//--- при создании графического объекта функцией ObjectCreate, по умолчанию объект 
//--- нельзя выделить и перемещать. Внутри же этого метода параметр selection 
//--- по умолчанию равен true, что позволяет выделять и перемещать этот объект 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- установим приоритет на получение события нажатия мыши на графике 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
   
//--- успешное выполнение 
   return(true); 
  } 


double get_forexshift(double high_value, double low_value, int number)
{
     if(ReverseChart_SET && high_value>0 && low_value>0)
     {
       double temp = high_value;
       high_value=1/low_value;
       low_value=1/temp;
     }
  if(Forex_Shift_mode == Auto_Day)
  {
     int k=number;
     double DayLow, DayHigh;
     string date_compare = TimeToString(LastTime[number],TIME_DATE);
     DayLow=LastLow[k]; DayHigh=LastHigh[k];
     while(k<NumberRates-1) 
     { 
      if(TimeToString(LastTime[k],TIME_DATE) == TimeToString(LastTime[k+1],TIME_DATE))
      {
         if(LastLow[k+1]<DayLow) DayLow=LastLow[k+1];
         if(LastHigh[k+1]>DayHigh) DayHigh=LastHigh[k+1];      
      } else { break; }
      k++;
     }
     
     k=number;
     while(k>1) 
     { 
      if(TimeToString(LastTime[k],TIME_DATE) == TimeToString(LastTime[k-1],TIME_DATE)) 
      {
         if(LastLow[k-1]<DayLow) DayLow=LastLow[k-1];
         if(LastHigh[k-1]>DayHigh) DayHigh=LastHigh[k-1];      
      } else { break; }
      k--;
     }
    return NormalizeDouble(((DayLow-low_value) + (DayHigh-high_value) ) / 2,_Digits);  
  }
  return NormalizeDouble(ForexShift*_Point, _Digits);
}
