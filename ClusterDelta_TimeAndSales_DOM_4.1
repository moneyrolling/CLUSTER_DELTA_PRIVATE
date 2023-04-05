//+------------------------------------------------------------------+
//|                                               TimeAndSales.mq4   |
//|                   Copyright 2008-2015, Clusterdelta.com          |
//|                                          http://clusterdelta.com |
//+------------------------------------------------------------------+
#property copyright   "Clusterdelta.com"
#property link        "http://my.clusterdelta.com/premium"
#property description "Time And Sales and DOM for Metatrader"

#import "tsanddom_mt5_v4x1.dll"
int Online_Init(int&);
string Online_Data(int&,string);
int Online_Subscribe(int &, string, string, int, string, string, string, string, string, string, int, string, string, string,int);
#import

#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1


input string HELP_URL="http://my.clusterdelta.com/dom";
input string Instrument="AUTO";
input string TS_SETTINGS="==== T&S Parameters ====";
input bool Show_TimeAndSales=true;
input color ASK_Color=YellowGreen;
input color BID_Color=OrangeRed;
input int MinVolume=0;
input int Forex_Shift=0;
input color Title_Color=Gray;
input color Time_ASK_Color=Gray;
input color Time_BID_Color=Gray;
input string TS_Rows = "AUTO";
input color Background=clrNONE;
input color Border=Gray;
input int Hour_Shift=0;
input string DOM_SETTINGS="==== DOM Parameters ====";
input int Width_In_Pixels=150; 
input bool Show_DOM = true;
input bool Show_PRICE=true;

input bool Show_VOLUME=true;
input bool Show_Sum=true;
input bool Use_Forex_Shift=true;
input bool DirectionToLeft=true;
input int Interface_Scale=100;
input int Font_Size=8;

double Interface_Zoom = 1;

bool Show_TS=Show_TimeAndSales;
bool Display_DOM=Show_DOM;

bool LeftDirection=DirectionToLeft;

int moved=0;
int move=0;

int dommoved=0;
int dommove=0;

color PriceColor=LightGray;
color VolumeColor=LightGray;

int ActualWidth=(int)(150*Interface_Zoom);

int Sum_DOM_Ask=0, Sum_DOM_Bid=0;

string Rows=TS_Rows;

int X_coord=50;
int Y_coord=40;

static bool AlreadyInit=false;
static bool DeInit=false;
int Lines=0;
int prevLines=0;

string ver = "4.1";
datetime last_loaded=0;
datetime myUpdateTime=0;
int UpdateFreq=60; // sec


double CHART_CHANGED_REASON_1, CHART_CHANGED_REASON_2;
datetime CHART_CHANGED_REASON_3, CHART_CHANGED_REASON_4;

string clusterdelta_client="";

string indicator_id="";
string indicator_name = "Time And Sales/DOM "+ver+" (© http://my.clusterdelta.com/premium)";
string short_name="";

string TS_Arrow="";
string TS_Row="";

string TS_Name="";
string TS_SiteName="";

string TS_DOMButton="";

datetime LastTime[]; // global instead of Time
double LastClose[]; // global instead of Low
double LastHigh[]; // global instead of High
bool query_in_progress=false;
int NumberRates=0;


int OnInit()
{
   ActualWidth=(int)(Width_In_Pixels*Interface_Zoom);
  if (Width_In_Pixels*Interface_Zoom<40*Interface_Zoom) { ActualWidth=(int)(40*Interface_Zoom); }
  if (Width_In_Pixels*Interface_Zoom>400*Interface_Zoom) { ActualWidth=(int)(400*Interface_Zoom); }
  DeInit=false;
  AlreadyInit=false;
  
//---- name for DataWindow and indicator subwindow label
   short_name="Time And Sales/DOM "+ver+" (© http://my.clusterdelta.com/premium)";
   IndicatorSetString(INDICATOR_SHORTNAME,indicator_name);   

   
   Interface_Zoom = 1;
  
   if(Interface_Scale>20 && Interface_Scale<=500) {Interface_Zoom=Interface_Scale / 100.0;}
   
   // this block do not use ClusterDelta_Server but register for unique id
   do
   {
     clusterdelta_client = "CDPT" + StringSubstr(IntegerToString(TimeLocal()),7,3)+""+DoubleToString(MathAbs(MathRand()%10),0);     
     indicator_id = "CLUSTERDELTA_"+clusterdelta_client;
   } while (GlobalVariableCheck(indicator_id));
   GlobalVariableTemp(indicator_id);
   
   TS_Name="TSDOM_Button1"+"_"+indicator_id;
   TS_SiteName="TSDOM_Button2"+"_"+indicator_id;  
   TS_Arrow="TSDOM_Arrow"+"_"+indicator_id; //+HASH_IND;
   TS_Row = "TSDOM_Row"+"_"+indicator_id; //+HASH_IND;
   TS_DOMButton = "TSDOM_Button"+"_"+indicator_id;
  
   EventSetMillisecondTimer(100);
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
      ArrayResize(LastClose, ArraySize(close));
      //ArrayResize(LastHigh, ArraySize(high));            
      ArrayCopy(LastTime , time);
      ArrayCopy(LastClose , close);      
      //ArrayCopy(LastHigh , high);            
      return (1);//MainCode();

  }
  
int MainCode()
{ 
   static int dllalert=0;
   static bool dll_init=0;

   int online_is_ready;   
   bool ready_to_fetch;
   

  
   if(!dll_init)
   {
     int res;
     ENUM_ACCOUNT_TRADE_MODE account_type=(ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE); 
     int acc=(int)AccountInfoInteger(ACCOUNT_LOGIN);
     if(account_type == ACCOUNT_TRADE_MODE_REAL) { acc = acc * -1; } // we will care for real mode account, comment it if you dont like to it
     Online_Init(res);          
     if(res==-1) { Print("Error during DLL init. ") ; return 0; }     
     dll_init=1;
     InitLines();     
   }
  

   ready_to_fetch=((TimeLocal() >= myUpdateTime) ? true : false ); 

   online_is_ready = GetOnline();      
   if(ready_to_fetch)
   {  
     // set new update time
     myUpdateTime = TimeLocal() + UpdateFreq;
     // send parameter for data update
     SetData();
   }
   
   // if we got data before   
   //if(!online_is_ready ) { return 1; }// from GetData
   ChartRedraw();
  
   return 1;
}
int WindowFirstVisibleBar()
{
  return (int)ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR,0);
}
int WindowBarsPerChart()
{
  return (int)ChartGetInteger(0,CHART_WIDTH_IN_BARS,0);
}

void OnChartEvent(const int id,         // идентификатор события   
                  const long& lparam,   // параметр события типа long 
                  const double& dparam, // параметр события типа double 
                  const string& sparam  // параметр события типа string 
)
{



   int mywidth=(ENUM_CHART_PROPERTY_INTEGER)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS); 
   int myheight=(ENUM_CHART_PROPERTY_INTEGER)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS); 

   int obj_total,x,y;
   long x_distance;

   if(id==CHARTEVENT_CHART_CHANGE)
   {
     if(CHART_CHANGED_REASON_1 != mywidth || CHART_CHANGED_REASON_2!=myheight)
     {
       InitLines();
       ChartRedraw();
     }
   }
   
   if(id==CHARTEVENT_OBJECT_CLICK)
   {
     if(sparam==TS_DOMButton && ObjectGetInteger(0,TS_DOMButton,OBJPROP_STATE)==true) 
     {
        
        dommove=1;
        ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,1); 

     }
     if(sparam==TS_DOMButton && ObjectGetInteger(0,TS_DOMButton,OBJPROP_STATE)==false) 
     {
        if(NumberRates<1) return;
        dommove=0;
        dommoved=1;
        ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,0); 
        ChartTimePriceToXY(0,0,LastTime[NumberRates-1],LastClose[NumberRates-1],x,y);  
        ObjectSetInteger(0,TS_DOMButton, OBJPROP_YDISTANCE, y-7);         
        ObjectSetInteger(0,TS_DOMButton, OBJPROP_XDISTANCE,lparam-5);
     }
   
   
     if(sparam==TS_Arrow && ObjectGetInteger(0,TS_Arrow,OBJPROP_STATE)==true) 
     {
        
        move=1;
        ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,1); 

     }
     if(sparam==TS_Arrow && ObjectGetInteger(0,TS_Arrow,OBJPROP_STATE)==false) 
     {
        move=0;
        moved=1;
        ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,0); 
        ObjectSetInteger(0,TS_Arrow, OBJPROP_XDISTANCE, (int)lparam-25);
        ObjectSetInteger(0,TS_Arrow, OBJPROP_YDISTANCE, (int)dparam-8);
         
        InitLines();
     }
     if(sparam==TS_Row && ObjectGetInteger(0,TS_Row,OBJPROP_STATE)==true) 
     {
        move=2;
        ObjectSetInteger(0, TS_Row, OBJPROP_YDISTANCE, (int)dparam);
        ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,1); 
        ObjectSetInteger(0,TS_Row,OBJPROP_BGCOLOR,C'255,255,255');         //--- установим цвет фона 
        
     } else
     if(sparam==TS_Row && ObjectGetInteger(0,TS_Row,OBJPROP_STATE)==false) 
     {
        move=0;
        ObjectSetInteger(0,TS_Row,OBJPROP_BGCOLOR,C'236,233,216');         
        ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,0); 
        InitLines();
     
     }     
     if(sparam == TS_Name && ObjectGetInteger(0,TS_Name,OBJPROP_STATE)==true)
     {
        Show_TS = false; 
          
        ObjectDelete(0,TS_Row);  
        ObjectSetInteger(0,"DTS_Rectangle"+"_"+indicator_id,OBJPROP_COLOR,clrNONE);
        
        obj_total=ObjectsTotal(9);
        for(int j=0;j<obj_total;j++)
        {
          while ((StringSubstr(ObjectName(0,j),0,8) == "DTS_Line")) { ObjectDelete(0,ObjectName(0,j));  }
        }
     } else 
     if(sparam == TS_Name && ObjectGetInteger(0,TS_Name,OBJPROP_STATE)==false)
     {
        Show_TS = true; 
        prevLines=0;
        InitLines();
     } 
     
     if(sparam == TS_SiteName)
     {
        if(ObjectGetInteger(0,TS_SiteName,OBJPROP_STATE)==true) { Display_DOM = false; 
        obj_total=ObjectsTotal(0);
        for(int i=0;i<obj_total;i++)
        {
            while ((StringSubstr(ObjectName(0,i),0,3) == "DOM")) { ObjectDelete(0,ObjectName(0,i));  }
        }
        } else { Display_DOM=true; }
        InitLines();        
     }
     
   }
   
  
   if(id==CHARTEVENT_MOUSE_MOVE ) 
   {
       if(move==1)
       {
         ObjectSetInteger(0,TS_Arrow, OBJPROP_XDISTANCE, (int)(lparam-25));
         ObjectSetInteger(0,TS_Arrow, OBJPROP_YDISTANCE, (int)(dparam-8));
       }
       if(move==2)
       {
         
         ObjectSetInteger(0,TS_Row, OBJPROP_YDISTANCE, (int)dparam);
       }
       if(dommove==1)
       {
         if(NumberRates<1) return;
         ChartTimePriceToXY(0,0,LastTime[NumberRates-1],LastClose[NumberRates-1],x,y);  
         ObjectSetInteger(0,TS_DOMButton, OBJPROP_YDISTANCE, y-7);         
         ObjectSetInteger(0,TS_DOMButton, OBJPROP_XDISTANCE, lparam-5);
         
         ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,x_distance);         
         if(lparam < ActualWidth && LeftDirection) LeftDirection=false;
         if(x_distance - lparam < ActualWidth && !LeftDirection) LeftDirection=true;

       }

       if(move>0) { InitLines(); }
       
   }
       

}


void OnDeinit(const int reason)
{
  EventKillTimer();
  DeInit = true;
  ObjectDelete(0,"InfoMessage"+"_"+indicator_id);
  ObjectDelete(0,TS_Name);
  ObjectDelete(0,TS_SiteName);  
  ObjectDelete(0,"DTS_Rectangle"+"_"+indicator_id);
  ObjectDelete(0,TS_Arrow);
  ObjectDelete(0,TS_Row);  
  ObjectDelete(0,TS_DOMButton);
  int    obj_total=ObjectsTotal(0);
  int i;
  for(i=0;i<obj_total;i++)
    {
       
       while ((StringSubstr(ObjectName(0,i),0,8) == "DTS_Line")) { if(StringFind(ObjectName(0,i),indicator_id)!=-1) {ObjectDelete(0,ObjectName(0,i)); } else { i++; } }
    }
  for(i=0;i<obj_total;i++)
    {
       while ((StringSubstr(ObjectName(0,i),0,3) == "DOM"))  { if(StringFind(ObjectName(0,i),indicator_id)!=-1) {ObjectDelete(0,ObjectName(0,i)); } else { i++; } }
    }
    
  return;
}

int SetData()
{

//  int k=0,i;
//  i = Online_Subscribe(k,clusterdelta_client, Symbol(), Period(), TimeToStr(TimeCurrent()), TimeToStr(Time[0]), Instrument, TimeToStr(last_loaded),0,ver,0,D'2017.01.01 00:00',D'2017.01.01 00:00',AccountCompany(),AccountNumber());     
  if(NumberRates<1) return 0;
  int k=0,i;
  string sym=Symbol();
  int per=1;//Period_To_Minutes();
  
  string tmc=TimeToString(TimeTradeServer());
  string tm0=TimeToString(LastTime[NumberRates-1]);
  string lsl=TimeToString(last_loaded);
  string cst=TimeToString(D'2017.01.01 00:00');
  string cet=TimeToString(D'2017.01.01 00:00');
  string cmp=AccountInfoString(ACCOUNT_COMPANY);
  int acnt=(int)AccountInfoInteger(ACCOUNT_LOGIN);
  string MetaTrader_GMT="AUTO";
  int Days_in_History=0;

  i = Online_Subscribe(k,clusterdelta_client, sym, per, tmc, tm0, Instrument, lsl,MetaTrader_GMT,ver,Days_in_History,cst,cet,cmp,acnt);       
 
  return 1;
}  


int GetOnline()
{
   string ts_stream;
   int length=0;   
  
   int s,i,d;
   string IncomingTime[500],IncomingPrice[500],IncomingVolume[500],IncomingType[500],DOM_index[200],DOM_price[200],DOM_volume[200];   
   color TimeColor,AskBidColor;
   int current_width,  n, max_vol;
   string Pr, vol;

   static string DOM_vols[200];
   static int max_index=0;
   max_vol=1;
   
   ts_stream = Online_Data(length, clusterdelta_client);
   if(length  == 0) { return 0; }

   
   s = Parse_Stream(ts_stream, IncomingTime,IncomingPrice,IncomingType,IncomingVolume,DOM_index,DOM_price,DOM_volume,d);
   
   if(d>0){
   for(i=0; i<d; i++)
   {
     n = (int)StringToInteger(DOM_index[i])*2;
     if(n<0) n=MathAbs(n)-1;
     DOM_vols[n]=DOM_volume[i];
     if(i>max_index){max_index=i;}
   }
   for (i=0; i<max_index; i++)
   {
     if(max_vol<StringToInteger(DOM_vols[i])){max_vol=(int)StringToInteger(DOM_vols[i]);}
   }
   
   
   
   //DOM
   for (i=0; i<d; i++) 
   {
     n = (int)StringToInteger(DOM_index[i]);
     Pr = DOM_price[i];
     vol = DOM_volume[i];
     if(!(max_vol>0))
     {
       max_vol=1;
     }
     current_width = (int)MathRound(StringToInteger(vol) * ActualWidth / max_vol); 
     
     if(StringToDouble(Pr)>0)
     {
       if (Display_DOM) { Create_DOM(n, DoubleToString(NormalizeDouble(StringToDouble(Pr),Digits()),Digits()), vol, current_width, d); }
     }
   
   }   
   }//if d>0

   if(s>0 && Show_TS) 
   { 
   

     for (i=0; i<s; i++)
     {
       ShiftLines(1);
     // T&S
       if(IncomingType[i]=="B") { AskBidColor=BID_Color; TimeColor = Time_BID_Color; } else   { AskBidColor=ASK_Color; TimeColor = Time_ASK_Color; }
       SetLineN_Text(1 /* i+1 */,IncomingTime[i],IncomingPrice[i],IncomingVolume[i],AskBidColor,TimeColor);
     
     }
   }

   ChartRedraw(ChartID());
   return 1;
}

int Parse_Stream(string stream, string& OutTime[], string& OutPrice[], string& OutType[], string& OutVolume[], string& OutDOM[],string& DOMp[],string& DOMv[], int &d)
{
   string packet[],internal[],allpackets[], domdata[];
   d=0; // for dom init
   int i,number_of_packets, ts, all,l,k;
   int line=0;   
   
   int DOM_saved=0;
   
   //Parse_String(stream,";",packet);
   if(StringLen(stream)<10) return 0;
   string check_client = StringSubstr(stream,0,8);

   all = StringSplit(stream,StringGetCharacter(":",0),allpackets);         
   
   // check if data comes is data for my client id
   if(allpackets[0] != clusterdelta_client) return 0; // if no drop it
   
   for(l=1; l<all; l++)
   {
   
   number_of_packets=StringSplit(allpackets[l],StringGetCharacter("#",0),packet);      

   
   for (i=0;i<number_of_packets; i++) // save ticker orders in the big packet
   {
     if(packet[i]==":" || StringLen(packet[i])<3) continue;

     ts = StringSplit(packet[i],StringGetCharacter(";",0),internal);      
     
     if(packet[i] == "DOM") { DOM_saved=1; continue;}
     if(DOM_saved == 1) 
     {
         int dom_lines=0;

         Sum_DOM_Ask=0; Sum_DOM_Bid=0;
         for(k=0; k<ts; k++)
         {
            int n = StringSplit(internal[k],StringGetCharacter("|",0),domdata);      
            if(n) 
            {
               if (StringSubstr(domdata[0],0,1) == "A")
               {
                  OutDOM[dom_lines]= IntegerToString(StringToInteger(StringSubstr(domdata[0],1,2)));
                  Sum_DOM_Ask += (int)StringToInteger(domdata[1]);                  
               }
               if (StringSubstr(domdata[0],0,1) == "B")
               {
                  OutDOM[dom_lines]= IntegerToString(-1*StringToInteger(StringSubstr(domdata[0],1,2)));
                  Sum_DOM_Bid += (int)StringToInteger(domdata[1]);
               }
               DOMp[dom_lines] = StringSubstr(domdata[0],3);
               DOMv[dom_lines] = domdata[1];
               dom_lines++;
            }
         }
         d=dom_lines;
         DOM_saved=0;
         continue;
     } 
     
     
     if(ts == 3 && line<500) // time and sales record
     {
      // fill vales with time and sales data       
      if (StringToInteger(internal[2])>=MinVolume)
      {
        //Print(number_of_packets, ": ",internal[0], " ", internal[2]);
        OutTime[line]= TimeToString(StringToInteger(StringSubstr(internal[1],0,10))+Hour_Shift*3600,TIME_MINUTES|TIME_SECONDS);
        OutPrice[line]=StringSubstr(internal[1],11);
        OutType[line]=StringSubstr(internal[1],10,1);
        OutVolume[line]=internal[2];
        line++;
      }
     }//if ts==3
   } // fir i=0
   } // for l=0
   
   
   
/*

   //Check Header
*/   
   return (line);
   
  
}


void ShiftLines(int NumberOfLines)
{

  if(NumberOfLines>=Lines) return;

  int s,n;
  string VolumeGetName, VolumeSetName, VolumePriceGetName,VolumePriceSetName, VolumeTimeGetName, VolumeTimeSetName;
  string VolumeValue, VolumePriceValue, VolumeTimeValue;
  color oldTextColor, oldTimeColor;
  //Comment(Lines-NumberOfLines);  
  n=Lines;
  s=Lines-NumberOfLines;
  
  while (s>=1)
  {
    
    VolumeGetName =  "DTS_Line_DVolume_"+IntegerToString(s)+"_"+indicator_id;
    VolumeSetName =  "DTS_Line_DVolume_"+IntegerToString(n)+"_"+indicator_id;
    
    VolumePriceGetName =  "DTS_Line_DPrice_"+IntegerToString(s)+"_"+indicator_id;
    VolumePriceSetName =  "DTS_Line_DPrice_"+IntegerToString(n)+"_"+indicator_id;

    VolumeTimeGetName =  "DTS_Line_DTime_"+IntegerToString(s)+"_"+indicator_id;
    VolumeTimeSetName =  "DTS_Line_DTime_"+IntegerToString(n)+"_"+indicator_id;


    VolumeTimeValue = ObjectGetString(0,VolumeTimeGetName,OBJPROP_TEXT);    
    VolumePriceValue = ObjectGetString(0,VolumePriceGetName,OBJPROP_TEXT);
    VolumeValue = ObjectGetString(0,VolumeGetName,OBJPROP_TEXT);    
    oldTextColor = (color)ObjectGetInteger(0,VolumeGetName,OBJPROP_COLOR);
    oldTimeColor = (color)ObjectGetInteger(0,VolumeTimeGetName,OBJPROP_COLOR);    

    ObjectSetText(VolumeSetName,VolumeValue,Font_Size,"Arial",oldTextColor);
    ObjectSetText(VolumePriceSetName,VolumePriceValue,Font_Size,"Arial",oldTextColor);
    ObjectSetText(VolumeTimeSetName,VolumeTimeValue,Font_Size,"Arial",oldTimeColor);
    n--; s--;
  }
 
   
    

}

void ObjectSetText(string n, string v, int s, string f, color c)
{
  ObjectSetString(0,n,OBJPROP_TEXT,v);
  ObjectSetString(0,n,OBJPROP_FONT,f);
  ObjectSetInteger(0,n,OBJPROP_FONTSIZE,s);
  ObjectSetInteger(0,n,OBJPROP_COLOR,c);
}


void InitLines()
{


  int j;

  string Time_Text="";
  string Price_Text="";  
  string Volume_Text="";  
    
  color Line_Color=ASK_Color;
  color Time_Color=Time_ASK_Color;
  
  
  
 


  int mywidth=(ENUM_CHART_PROPERTY_INTEGER)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS); 
  int myheight=(ENUM_CHART_PROPERTY_INTEGER)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS); 
  CHART_CHANGED_REASON_1 = mywidth;
  CHART_CHANGED_REASON_2 = myheight;
   


 
//--- размеры окна графика
  long x_distance;
  long y_distance;
  long y_shift=0;
//--- определим размеры окна
   if(!ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,x_distance))
     {
      DeInit=true;
      return;
     }
   if(!ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0,y_distance))
     {
      DeInit=true;
      return;
     }

   if(move==1 || moved==1)
   {
     x_distance = (int)(ObjectGetInteger(0,TS_Arrow, OBJPROP_XDISTANCE)-120*Interface_Zoom+202*Interface_Zoom);
     y_shift = ObjectGetInteger(0,TS_Arrow, OBJPROP_YDISTANCE)-38;
   }
   if(move==2)
   {
     int y_row = (int)ObjectGetInteger(0,TS_Row, OBJPROP_YDISTANCE);
     Rows=IntegerToString((int)MathRound((y_row+30-y_shift - 102) / (Font_Size*1.65)));
   }



     
   if (!(StringToInteger(Rows)>0))
   {

     Lines = (int)MathRound((y_distance-y_shift - 102) / (Font_Size*1.65));
   } else
   {
     Lines = (int)StringToInteger(Rows);
   }
   if (Lines > 100) Lines=100;
   if (Lines <= 0) Lines=25;   

   int x;
   int y;
   int width;
   int height;
   

   x = (int)(x_distance - 210*Interface_Zoom); y=(int)(35+y_shift);
   width = (int)(180*Interface_Zoom);
   height = 42 + int(Lines * (Font_Size*1.65));

   if(Show_TS) {  RectLabelCreate(0,"DTS_Rectangle"+"_"+indicator_id,0,x,y,width,height,Background,BORDER_FLAT,0,Border,STYLE_SOLID,1,true,false,false,0); }
   X_coord=(int)(x_distance-(int)(202*Interface_Zoom));
   Y_coord=(int)(40+y_shift);


   ObjectCreate(0,TS_Name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0,TS_Name, OBJPROP_CORNER, 0);    
   ObjectSetInteger(0,TS_Name, OBJPROP_XDISTANCE, (int)X_coord);
   ObjectSetInteger(0,TS_Name, OBJPROP_YDISTANCE, (int)(Y_coord-2));
   ObjectSetString(0,TS_Name,OBJPROP_TEXT,"T&S"); 
   ObjectSetString(0,TS_Name,OBJPROP_FONT,"Arial"); 
   ObjectSetInteger(0,TS_Name,OBJPROP_COLOR,C'0,0,0'); 
   ObjectSetInteger(0,TS_Name,OBJPROP_FONTSIZE,Font_Size);    
   ObjectSetInteger(0,TS_Name,OBJPROP_XSIZE,(int)(49*Interface_Zoom)); 
   ObjectSetInteger(0,TS_Name,OBJPROP_YSIZE,Font_Size*2); 
   ObjectSetInteger(0,TS_Name,OBJPROP_BGCOLOR,C'236,233,216'); 
   ObjectSetInteger(0,TS_Name,OBJPROP_BORDER_COLOR,clrNONE); 
   
   

   ObjectCreate(0,TS_SiteName, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0,TS_SiteName, OBJPROP_CORNER, 0);    
   ObjectSetInteger(0,TS_SiteName, OBJPROP_XDISTANCE, (int)(X_coord+60*Interface_Zoom));
   ObjectSetInteger(0,TS_SiteName, OBJPROP_YDISTANCE, (int)(Y_coord-2));
   ObjectSetString(0,TS_SiteName,OBJPROP_TEXT,"DOM"); 
   ObjectSetString(0,TS_SiteName,OBJPROP_FONT,"Arial"); 
   ObjectSetInteger(0,TS_SiteName,OBJPROP_COLOR,C'0,0,0'); 
   ObjectSetInteger(0,TS_SiteName,OBJPROP_FONTSIZE,Font_Size);    
   ObjectSetInteger(0,TS_SiteName,OBJPROP_XSIZE,(int)(49*Interface_Zoom)); 
   ObjectSetInteger(0,TS_SiteName,OBJPROP_YSIZE,Font_Size*2); 
   ObjectSetInteger(0,TS_SiteName,OBJPROP_BGCOLOR,C'236,233,216'); 
   ObjectSetInteger(0,TS_SiteName,OBJPROP_BORDER_COLOR,clrNONE); 

   
   ObjectCreate(0,TS_Arrow, OBJ_BUTTON, 0, 0, 0);   
   ObjectSetInteger(0,TS_Arrow, OBJPROP_CORNER, 0);    
   ObjectSetInteger(0,TS_Arrow, OBJPROP_XDISTANCE, (int)(X_coord+120*Interface_Zoom));
   ObjectSetInteger(0,TS_Arrow, OBJPROP_YDISTANCE, (int)(Y_coord-2));
   ObjectSetInteger(0,TS_Arrow,OBJPROP_XSIZE,(int)(49*Interface_Zoom)); 
   ObjectSetInteger(0,TS_Arrow,OBJPROP_YSIZE,Font_Size*2); 
   ObjectSetString(0,TS_Arrow,OBJPROP_TEXT,"Move"); 
   ObjectSetString(0,TS_Arrow,OBJPROP_FONT,"Arial"); 
   ObjectSetInteger(0,TS_Arrow,OBJPROP_COLOR,C'0,0,0'); 
   ObjectSetInteger(0,TS_Arrow,OBJPROP_FONTSIZE,Font_Size); 
   ObjectSetInteger(0,TS_Arrow,OBJPROP_BGCOLOR,C'236,233,216'); 
   ObjectSetInteger(0,TS_Arrow,OBJPROP_BORDER_COLOR,clrNONE); 


if (Show_TS)
{
   ObjectCreate(0,TS_Row, OBJ_BUTTON, 0, 0, 0);   
   ObjectSetInteger(0,TS_Row, OBJPROP_CORNER, 0);    
   ObjectSetInteger(0,TS_Row, OBJPROP_XDISTANCE, (int)(X_coord+167*Interface_Zoom));
   ObjectSetInteger(0,TS_Row, OBJPROP_YDISTANCE, (int)(Y_coord+32+Lines*(Font_Size*1.65)));
   ObjectSetInteger(0,TS_Row,OBJPROP_XSIZE,8); 
   ObjectSetInteger(0,TS_Row,OBJPROP_YSIZE,8); 
   ObjectSetString(0,TS_Row,OBJPROP_TEXT,""); 
   ObjectSetString(0,TS_Row,OBJPROP_FONT,"Arial"); 
   ObjectSetInteger(0,TS_Row,OBJPROP_COLOR,C'0,0,0'); 
   ObjectSetInteger(0,TS_Row,OBJPROP_FONTSIZE,Font_Size); 
   ObjectSetInteger(0,TS_Row,OBJPROP_BGCOLOR,C'236,233,216'); 
   ObjectSetInteger(0,TS_Row,OBJPROP_BORDER_COLOR,clrNONE); 
}



    Time_Text = " ";
    Price_Text = " ";
    Volume_Text = " ";
    Line_Color = ASK_Color;
    Time_Color = Time_ASK_Color;
   
   for (j=Lines; j<=prevLines; j++) { SetLineN_Text(j,Time_Text,Price_Text,Volume_Text,Line_Color,Time_Color); }

   for (j=1; j<=Lines; j++)
   {
    CreateLine(j);
    SetLineN_Coords(j,X_coord,Y_coord+16);
    if(prevLines==0 || j>=prevLines || !Show_TS) { SetLineN_Text(j,Time_Text,Price_Text,Volume_Text,Line_Color,Time_Color); }
   }
   prevLines = Lines;

}

void CreateLine(int n)
{
  CreateLine_Type(n, "DTime");
  CreateLine_Type(n, "DPrice");
  CreateLine_Type(n, "DVolume");
}

void CreateLine_Type(int n, string LineType)
{
    string Line_Name = "DTS_Line_"+LineType+"_"+IntegerToString(n)+"_"+indicator_id;
    ObjectSetString(0,Line_Name, OBJPROP_TEXT, " ");        
    ObjectCreate(0,Line_Name, OBJ_LABEL, 0, 0, 0);
    ObjectSetString(0,Line_Name, OBJPROP_TEXT, " ");        
    ObjectSetInteger(0,Line_Name, OBJPROP_SELECTABLE, false);       
}

void SetLineN_Coords(int n, int x, int y)
{
  SetLineN_Coords_Type(n,x,y,"DTime");
  SetLineN_Coords_Type(n,x+(int)(70*Interface_Zoom),y,"DPrice");
  SetLineN_Coords_Type(n,x+(int)(135*Interface_Zoom),y,"DVolume");
  
}
void SetLineN_Coords_Type(int n, int x, int y, string LineType)
{
    string Line_Name="DTS_Line_"+LineType+"_"+IntegerToString(n)+"_"+indicator_id;
    ObjectSetInteger(0,Line_Name, OBJPROP_CORNER, 0);    // Привязка угол   
    ObjectSetInteger(0,Line_Name, OBJPROP_XDISTANCE, x);// Координата Х   
    ObjectSetInteger(0,Line_Name, OBJPROP_YDISTANCE, y+(int)(n*(Font_Size*1.6)));// Координата Y
    ObjectSetInteger(0,Line_Name,OBJPROP_SELECTABLE,false);
    ObjectSetInteger(0,Line_Name,OBJPROP_SELECTED,false);
    
}
void SetLineN_Text(int n, string Time_Text,string Price_Text,string Volume_Text,color Line_Color, color Time_Color)
{
   SetLineN_Text_Type (n,Time_Text,Time_Color,"DTime");
   SetLineN_Text_Type (n,Price_Text,Line_Color,"DPrice");   
   SetLineN_Text_Type (n,Volume_Text,Line_Color,"DVolume");      
   
}
void SetLineN_Text_Type(int n, string Text, color LineColor, string LineType)
{
    string Line_Name="DTS_Line_"+LineType+"_"+IntegerToString(n)+"_"+indicator_id;
    if (LineType == "DVolume") {Text = StringFormat("%4s",Text); }
    if (LineType == "DPrice" && StringToDouble(Text)>0) {Text = DoubleToString(NormalizeDouble(StringToDouble(Text)+Forex_Shift*_Point,Digits()),Digits()); }
    ObjectSetText(Line_Name,Text,Font_Size,"Arial",LineColor);
}

bool RectLabelCreate(const long             chart_ID=0,               // ID графика
                     const string           name="RectLabel",         // имя метки
                     const int              sub_window=0,             // номер подокна
                     const int              x=0,                      // координата по оси X
                     const int              y=0,                      // координата по оси Y
                     const int              width=50,                 // ширина
                     const int              height=18,                // высота
                     const color            back_clr=C'236,233,216',  // цвет фона
                     const ENUM_BORDER_TYPE border=BORDER_SUNKEN,     // тип границы
                     const ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER, // угол графика для привязки
                     const color            clr=clrRed,               // цвет плоской границы (Flat)
                     const ENUM_LINE_STYLE  style=STYLE_SOLID,        // стиль плоской границы
                     const int              line_width=1,             // толщина плоской границы
                     const bool             back=false,               // на заднем плане
                     const bool             selection=false,          // выделить для перемещений
                     const bool             hidden=true,              // скрыт в списке объектов
                     const long             z_order=0)                // приоритет на нажатие мышью
  {
//--- сбросим значение ошибки
   ResetLastError();
//--- создадим прямоугольную метку
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE_LABEL,sub_window,0,0))
     {
//      Print(__FUNCTION__,
//            ": не удалось создать прямоугольную метку! Код ошибки = ",GetLastError());
//      return(false);
     }
//--- установим координаты метки
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- установим размеры метки
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
//--- установим цвет фона
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
//--- установим тип границы
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE,border);
//--- установим угол графика, относительно которого будут определяться координаты точки
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- установим цвет плоской рамки (в режиме Flat)
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- установим стиль линии плоской рамки
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- установим толщину плоской границы
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,line_width);
//--- отобразим на переднем (false) или заднем (true) плане
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- включим (true) или отключим (false) режим перемещения метки мышью
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- установим приоритет на получение события нажатия мыши на графике
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- успешное выполнение
   return(true);
  }

void LabelCreate(const int xcoord, const int ycoord, string STS_Name, string TS_Text, color titleColor)
{

   ObjectCreate(0,STS_Name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0,STS_Name, OBJPROP_CORNER, 0);    
   ObjectSetInteger(0,STS_Name, OBJPROP_XDISTANCE, xcoord);
   ObjectSetInteger(0,STS_Name, OBJPROP_YDISTANCE, ycoord);
   ObjectSetText(STS_Name,TS_Text,Font_Size,"Arial",titleColor);  

   ObjectSetInteger(0,STS_Name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,STS_Name,OBJPROP_SELECTED,false);

   
   
}

bool Create_DOM(int n, string Price, string Vol, int mywidth, int max_n)
{
   long x_distance;
   ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,x_distance);
   int x,y,PriceX, PriceY;
   if(NumberRates<1) return false;
   ChartTimePriceToXY(0,0,LastTime[NumberRates-1],LastClose[NumberRates-1],x,y);  



   PriceX = (int)(x_distance - ActualWidth - Font_Size*Interface_Zoom/2);
   PriceY = y;
   if(Show_TS) PriceX=PriceX-(int)(210*Interface_Zoom);

   if(dommoved || dommove)
   {
      PriceX = (int)ObjectGetInteger(0,TS_DOMButton, OBJPROP_XDISTANCE)-(int)(LeftDirection?ActualWidth-34*Interface_Zoom:0);   
   }

   ObjectCreate(0,TS_DOMButton, OBJ_BUTTON, 0, 0, 0);   
   ObjectSetInteger(0,TS_DOMButton, OBJPROP_CORNER, 0);    
   ObjectSetInteger(0,TS_DOMButton, OBJPROP_XDISTANCE, PriceX+(int)(LeftDirection?ActualWidth-34*Interface_Zoom:0));
   ObjectSetInteger(0,TS_DOMButton, OBJPROP_YDISTANCE, PriceY-7);
   ObjectSetInteger(0,TS_DOMButton,OBJPROP_XSIZE,8); 
   ObjectSetInteger(0,TS_DOMButton,OBJPROP_YSIZE,8); 
   ObjectSetString(0,TS_DOMButton,OBJPROP_TEXT,""); 
   ObjectSetString(0,TS_DOMButton,OBJPROP_FONT,"Arial"); 
   ObjectSetInteger(0,TS_DOMButton,OBJPROP_COLOR,C'0,0,0'); 
   ObjectSetInteger(0,TS_DOMButton,OBJPROP_FONTSIZE,Font_Size); 
   ObjectSetInteger(0,TS_DOMButton,OBJPROP_BGCOLOR,C'236,233,216'); 
   ObjectSetInteger(0,TS_DOMButton,OBJPROP_BORDER_COLOR,clrNONE); 



   


   int height=(int)(15*Interface_Zoom);
   int x_shift=0;
   color Bg=Lavender;
   string Text="";

   
   
   string RectName = "DOM_A"+IntegerToString(n)+"_"+indicator_id;
   string LabelName = RectName+"_TEXT"+"_"+indicator_id;
   string LabelVName = RectName+"_VOL"+"_"+indicator_id;   
   
   if (MathAbs(n)==2) Bg=Linen;
   if (MathAbs(n)==3) Bg=LightYellow;
   if (MathAbs(n)==4) Bg=LemonChiffon;   
   if (MathAbs(n)==5) Bg=Beige;   
   if (MathAbs(n)==6) Bg=WhiteSmoke;
   if (MathAbs(n)==7) Bg=LightYellow;
   if (MathAbs(n)==8) Bg=OldLace;   
   if (MathAbs(n)==9) Bg=Bisque;   
   if (MathAbs(n)==10) Bg=MistyRose;      



   if(Use_Forex_Shift)
   {
      Text = DoubleToString(NormalizeDouble(StringToDouble(Price)+Forex_Shift*_Point,Digits()),Digits()); 
   } else { Text=Price; }
   
   if (LeftDirection)
   {
     if(Show_PRICE) x_shift=(7*StringLen(Price)+3)*1;   
     RectLabelCreate(0,RectName,0,PriceX-x_shift + ActualWidth-mywidth ,PriceY-10-height*n+n,mywidth,height,Bg,BORDER_FLAT,0,clrNONE,STYLE_SOLID,1,true,false,false,0);
     if (Show_PRICE) { LabelCreate(PriceX+ActualWidth-7*StringLen(Price), PriceY-10-height*n+n, LabelName, Text, PriceColor);  }
     if (Show_VOLUME){ LabelCreate(PriceX-x_shift+ActualWidth-mywidth-Font_Size*StringLen(Vol), PriceY-10-height*n+n, LabelVName, Vol, VolumeColor); }  
     if (Show_Sum)
     {
         LabelCreate(PriceX+ActualWidth-x_shift-(int)(25*Interface_Zoom), PriceY-10-height*(-max_n/2)+(int)(4*Interface_Zoom),"DOM_SUM_BID"+indicator_id, IntegerToString(Sum_DOM_Bid), VolumeColor);
         LabelCreate(PriceX+ActualWidth-x_shift-(int)(25*Interface_Zoom), PriceY-10-height*(max_n/2)-(int)(4*Interface_Zoom),"DOM_SUM_ASK"+indicator_id, IntegerToString(Sum_DOM_Ask), VolumeColor);         
     }
   } else
   {
     if(Show_PRICE) x_shift=(Font_Size-1)*StringLen(Price)+3;   
     RectLabelCreate(0,RectName,0,PriceX+x_shift ,PriceY-10-height*n+n,mywidth,height,Bg,BORDER_FLAT,0,clrNONE,STYLE_SOLID,1,true,false,false,0);
     if (Show_PRICE) { LabelCreate(PriceX, PriceY-10-height*n+n, LabelName, Text, PriceColor);  }
     if (Show_VOLUME){ LabelCreate(PriceX+x_shift+mywidth+2, PriceY-10-height*n+n, LabelVName, Vol, VolumeColor); }  
     if (Show_Sum)
     {
         LabelCreate(PriceX+x_shift , PriceY-10-height*(-max_n/2)+(int)(4*Interface_Zoom),"DOM_SUM_BID"+indicator_id, IntegerToString(Sum_DOM_Bid), VolumeColor);
         LabelCreate(PriceX+x_shift , PriceY-10-height*(max_n/2)-(int)(4*Interface_Zoom),"DOM_SUM_ASK"+indicator_id, IntegerToString(Sum_DOM_Ask), VolumeColor);         
     }
     
   }
   return true;
}
