#property copyright "Copyright © 2011-2018, ClusterDelta.com"
#property link      "http://my.clusterdelta.com/premium"
#property description "ClusterDelta Profile, Version 4.1 (compiled 24.08.2018)"
#property description "\nThe volume profile shows the distribution of volumes (deltas, ask/bid levels) at prices for a certain period of time. This is an important information as the accumulation of volumes often becomes lines of support and resistance. "
#property description "\nMore information can be found here: http://my.clusterdelta.com/profile"

#import "premium_mt5_v4x1.dll"
int InitDLL(int&);
string Receive_Information(int&,string);
int Send_Query(int &, string, string, int, string, string, string, string, string, string, int, string, string, string,int);
#import

#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1


enum  VolumeProfilePosition{ Draw_OnChart=0, WindowLeft=1, WindowRight=2 };
enum  ProfilePeriod{ Custom_Period=0, per_Hour=1, Daily=2, Globex=9, Weekly=3, per_Asia=4, per_Europe=5, per_NYSE=6, per_CME=7, per_Contract=8 };
enum  VolumeProfileType{ AskBidProfile=0, DeltaProfile=1, VolumeProfile=2 };
enum  LineDirection {Left =0, Right=1};

input string Help_URL="http://clusterdelta.com/volumeprofile";
input VolumeProfileType _Profile_Type=VolumeProfile;
input string Instrument="AUTO"; // Instrument Field
input string MetaTrader_GMT="AUTO";

input int Update_in_sec=30;
input ProfilePeriod _Profile_Period = Daily;
input int _Amount_of_Profiles=1;
input VolumeProfilePosition _Profile_Position=Draw_OnChart;
input bool Forex_auto_shift=true;
input int Forex_shift=0;
input int _LineColor_Width=1;
input string Comment_AskBidProfile="--- Ask/Bid Profile settings";
input color AskColor_AskBidProfile=DodgerBlue;
input color BidColor_AskBidProfile=OrangeRed;
input LineDirection Ask_Direction=Right;
input LineDirection Bid_Direction=Left;
input string Comment_DeltaProfile="--- Delta Profile settings";
input color DeltaPositive_DeltaProfile=DodgerBlue;
input color DeltaNegative_DeltaProfile=Salmon;
input LineDirection DeltaPositive_Direction=Right;
input LineDirection DeltaNegative_Direction=Left;
input string Comment_VolumeProfile="--- Volume Profile settings";
input color VolumeLine_VolumeProfile_Color=clrGray;
input color VolumeLine_VolumeArea_Color=Silver;
input color VolumeLine_Max_Volume=Red;
input LineDirection VolumeLines_Direction=Right;
input double Max_Volume_k=0.85;
input bool Print_Max_Volume=false;
input int Correlate_Volume_To=0; 

input string Reverse_Settings="--------- Reverse for USD/XXX symbols ---------";
input bool ReverseChart=false;
input string DO_NOT_SET_ReverseChart="...for USD/JPY, USD/CAD, USD/CHF --";

input string Custom_Period_Settings="--------- Settings for Custom Period ---------";
input bool Get_Custom_Period_from_Chart=true;
input datetime _Custom_Start_time=D'2017.01.01 00:00';
input  datetime _Custom_End_time=D'2017.01.01 00:00';
input int Custom_Zoom = 100;

input bool Lines_are_Background=true;
input bool Lines_are_Active=false;

input string Expert_User_Settings="--------- Settings for expert users ---------";
input int history_back_profiles=0;
input int ZOOM_scale_in_percent=60;
input bool Information_Buttons_Show=true;
input int _Information_Corner=0;
input bool Show_Sum_Values=false;
input int Interface_Scale=100;
input int Font_Size=8;

bool Information_Buttons = Information_Buttons_Show;

bool Draw_as_Background=true;
//datetime Start_time;
//datetime End_time;

//---- buffers

int Profile_Type = _Profile_Type;
double Interface_Zoom;

bool Draw_POC_Continious=false; //  not used in Premium Version
int Continious_line_style=2;//  not used in Premium Version
int Minutes_Between_Profiles=0;//  not used in Premium Version

string ver = "4.1";
string MessageFromServer="";
datetime last_loaded=D'1970.01.01 00:00';
datetime myUpdateTime=D'1970.01.01 00:00';
int UpdateFreq=60; // sec
int forex_shift_auto = 0;
int Custom_Timeframe = 0;
int OneTimeAlert=0;
bool ONLINE=true;
bool loaded=false;
string clusterdelta_client="";
int Save_Amount_Of_Profiles=0;
int Profile_Period=0;
int Profile_Position=0;
int Information_Corner=0;
int LineColor_Width=1;
//string response=" ";

datetime last_Start_time;
datetime last_End_time;

bool ReverseChart_SET=false;
bool newdata=false;

double min_price=0;
double PriceData[];
double AskData[];
double BidData[];


string indicator_id="";
string indicator_name = "ClusterDelta_Profile";
string short_name="";
string HASH_IND=" ";
string vertical_line_name1="";
string vertical_line_name2="";
string settings_line="";
datetime TIME1,TIME2;//время на передачу профилю   
datetime Custom_Start_time=D'2017.01.01 00:00';
datetime Custom_End_time=D'2017.01.01 00:00';

int ButtonStartX=4, ButtonStartY=16, RightShiftX=0; 
int TotalProfiles=0;
datetime LastTime[]; // global instead of Time
double LastLow[]; // global instead of Low
double LastHigh[]; // global instead of High
bool query_in_progress=false;
int NumberRates=0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   
//---- buffers   
//---- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"ClusterDelta Profile");
//----

   // this block do not use ClusterDelta_Server but register for unique id
   do
   {
     clusterdelta_client = "CDPP" + StringSubstr(IntegerToString(TimeLocal()),7,3)+""+DoubleToString(MathAbs(MathRand()%10),0);     
     indicator_id = "CLUSTERDELTA_"+clusterdelta_client;
   } while (GlobalVariableCheck(indicator_id));
   GlobalVariableTemp(indicator_id);
   HASH_IND="CDP"+StringSubstr(clusterdelta_client,4);
   
   vertical_line_name1="VPLine_C1_"+HASH_IND;
   vertical_line_name2="VPLine_C2_"+HASH_IND;
   settings_line="SETTINGS"+HASH_IND;   

   Interface_Zoom = 1;
  
   if(Interface_Scale>20 && Interface_Scale<=500) {Interface_Zoom=Interface_Scale / 100.0;}

   Custom_Start_time=_Custom_Start_time;
   Custom_End_time=_Custom_End_time;
   TIME1=Custom_Start_time;
   TIME2=Custom_End_time;

   ReverseChart_SET=ReverseChart;
   
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
        
   Profile_Period = _Profile_Period;
   Profile_Type = _Profile_Type; 
   Profile_Position = _Profile_Position;
   Information_Corner = _Information_Corner;
   LineColor_Width=_LineColor_Width;
   
   if (Update_in_sec>2) { UpdateFreq=Update_in_sec; }   
   Save_Amount_Of_Profiles   = _Amount_of_Profiles;   
   if(Save_Amount_Of_Profiles   <1 || Save_Amount_Of_Profiles   >100) { Save_Amount_Of_Profiles=1; } 
   if(Profile_Position>0) { Save_Amount_Of_Profiles =1; }   
   if (Profile_Period==8) { Save_Amount_Of_Profiles =1; }
 

   TotalProfiles=Save_Amount_Of_Profiles;
   Custom_Timeframe = OBJ_ALL_PERIODS;
   TIME1=Custom_Start_time;
   TIME2=Custom_End_time;
   ChooseCorner();
   DrawButton(1,1,1,1);
   
   ChartSetInteger(0,CHART_SHOW_OBJECT_DESCR,0);


   EventSetMillisecondTimer(200);
   return (INIT_SUCCEEDED);

}

int ChooseCorner()
{
  int j;
  int operation=0;
  int objects=ObjectsTotal(0);           
  string hash_client_name="";
     while(operation<10)
     {
          for(j=0;j<objects;j++)
          {
            if (StringSubstr(ObjectName(0,j),0,6) == "VPHIDE" || StringSubstr(ObjectName(0,j),0,6) == "VPLine")  
            { 
              hash_client_name=StringSubstr(ObjectName(0,j),StringLen(ObjectName(0,j))-7,7);
              if(hash_client_name != HASH_IND)
              {
                   string ccdpp="CDPP"+StringSubstr(hash_client_name,3);
                   int clean=0;
                   if (GlobalVariableCheck("CLUSTERDELTA_"+ccdpp)/*PremiumProfile*/ || GlobalVariableCheck("CLUSTERDELTA_"+hash_client_name) /*VolumeProfile*/) 
                   {
                     
                     if (ObjectGetInteger(0,"VPHIDE"+StringSubstr(ObjectName(0,j),6),OBJPROP_HIDDEN,0)==1)
                     { 
                       clean=1;
                     }  
                    
                   } else { clean=1; }
                   if(clean)
                   {
                         int    obj_total=ObjectsTotal(0);
                         for(int i=0;i<obj_total;i++)
                         {
                           while ( (StringFind(ObjectName(0,i),hash_client_name)!= -1) ) 
                           { 
                              ObjectDelete(0,ObjectName(0,i));  
                           }
                         } //for

                   }
              } // hash_client_name
            }
          }
          if(j>=objects) break;
          operation++;
     }


          int Corners0=0, Corners1=0, Corners2=0, Corners3=0, ICorner=0;
          string old_settings="";
          int set=0,newset=0;               
          operation=0;
          
          
          for(j=0;j<objects;j++)
          {
            if (StringSubstr(ObjectName(0,j),0,8) == "SETTINGS" && ObjectName(0,j)!=settings_line) 
            { 
                old_settings= ObjectGetString(0,ObjectName(0,j),OBJPROP_TEXT);
                //old_settings= ObjectDescription(ObjectName(0,j));
                set = (int)StringToInteger(old_settings);            
                newset = (int)MathFloor(set/1000)*1000;
                ICorner = ((set - newset)/100)-1;              
                if(ICorner>=5) ICorner=ICorner-5;
                if(ICorner==0) Corners0++;
                if(ICorner==1) Corners1++;
                if(ICorner==2) Corners2++;
                if(ICorner==3) Corners3++;
                operation++;
            }

          }
          if(Information_Corner == 0 && Corners0) Information_Corner=1;
          if(Information_Corner == 1 && Corners1) Information_Corner=2;
          if(Information_Corner == 2 && Corners2) Information_Corner=3;          
          if(Information_Corner == 3 && Corners3) Information_Corner=0;                    
          
          
          
          
          
          set=0;
          hash_client_name="";

          for(j=0;j<objects;j++)
          {
            if (StringSubstr(ObjectName(0,j),0,8) == "SETTINGS" && ObjectName(0,j)!=settings_line) 
            { 
              hash_client_name=StringSubstr(ObjectName(0,j),8);
              string cdpp="CDPP"+StringSubstr(hash_client_name,3);
              if (GlobalVariableGet("CLUSTERDELTA_"+cdpp)==-1) 
              {
                // setting of nobody, maybe mine
                ResetLastError();
                old_settings= ObjectGetString(0,ObjectName(0,j),OBJPROP_TEXT);
                set = (int)StringToInteger(old_settings);
                if(set>100000) {break;} 
              } 
              
            }
          }
          if(set>100000)
          {
              newset = (int)MathFloor(set/10)*10;
              Profile_Type = VolumeProfileType ( (set - newset)-1 );
              set=newset;
              newset = (int)MathFloor(set/100)*100;
              Profile_Position = VolumeProfilePosition ((set - newset)/10 - 1);
              set=newset;
              
              newset = (int)MathFloor(set/1000)*1000;
              Information_Corner = ((set - newset)/100)-1;              
              if(Information_Corner>=5) { Information_Corner=Information_Corner-5; Information_Buttons=1; } else { Information_Buttons=0; }
              if(Information_Corner<0) { Information_Corner=0; Information_Buttons=0; Print ("Abnormal settings\n");} // abnormal
              
              set=newset;
              newset = (int)MathFloor(set/10000)*10000;
              Profile_Period =  ProfilePeriod ((set - newset)/1000 - 1);              
              set=newset;
              newset = (int)MathFloor(set/1000000)*1000000;
              TotalProfiles = (int)((set /*- newset*/)/100000);              
              Save_Amount_Of_Profiles = TotalProfiles;
             
              ObjectDelete(0,ObjectName(0,j));

          }
          
   if(Information_Corner == 2 || Information_Corner == 3) { ButtonStartY= 24; RightShiftX=1; }
   if(Information_Corner == 0 || Information_Corner == 1) { ButtonStartX= 4; RightShiftX=0; ButtonStartY=24; }  

   return 0;
}

int DrawButton(int dtype, int dtime, int ddir, int damount)
{
  ObjectDelete(0,settings_line);
  // int settings = (Profile_Type+1)*1+(Profile_Position+1)*10+(Profile_Period+1)*1000+TotalProfiles*100000;
 int settings = (Profile_Type+1)*1+(Profile_Position+1)*10+  (Information_Corner+1 + (Information_Buttons?5:0))*100 +  (Profile_Period+1)*1000+TotalProfiles*100000;  
  
  ObjectCreate(0,settings_line,OBJ_LABEL,0,0,0);
  ObjectSetString(0,settings_line,OBJPROP_TEXT,IntegerToString(settings));
  ObjectSetInteger(0,settings_line,OBJPROP_XDISTANCE,0); 
  ObjectSetInteger(0,settings_line,OBJPROP_YDISTANCE,1200); 
  
  if (!Information_Buttons) 
  {
     ButtonCreate(0,"VPHIDE"+HASH_IND,0,ButtonStartX+RightShiftX*29,ButtonStartY,(int)(30*Interface_Zoom),(int)(18*Interface_Zoom),0,"[ + ]","Arial",8,C'255,255,255',C'192,128,128',C'64,64,192',clrNONE,false,true,false,true,0,"");     
     ObjectDelete(0,"VPTYPE1"+HASH_IND);ObjectDelete(0,"VPTYPE2"+HASH_IND);ObjectDelete(0,"VPTYPE3"+HASH_IND);
     ObjectDelete(0,"VPDIR1"+HASH_IND);ObjectDelete(0,"VPDIR2"+HASH_IND);ObjectDelete(0,"VPDIR3"+HASH_IND);     
     ObjectDelete(0,"VPTIME0"+HASH_IND);ObjectDelete(0,"VPTIME1"+HASH_IND);ObjectDelete(0,"VPTIME2"+HASH_IND);ObjectDelete(0,"VPTIME3"+HASH_IND);ObjectDelete(0,"VPTIME4"+HASH_IND);
     ObjectDelete(0,"VPTIME5"+HASH_IND);ObjectDelete(0,"VPTIME6"+HASH_IND);ObjectDelete(0,"VPTIME7"+HASH_IND);ObjectDelete(0,"VPTIME8"+HASH_IND);ObjectDelete(0,"VPTIME9"+HASH_IND);     
     ObjectDelete(0,"VPNUMS1"+HASH_IND);ObjectDelete(0,"VPNUMS2"+HASH_IND);ObjectDelete(0,"VPNUMS3"+HASH_IND);ObjectDelete(0,"VPNUMS4"+HASH_IND);
     ObjectDelete(0,"VPNUMS5"+HASH_IND);ObjectDelete(0,"VPNUMS6"+HASH_IND);ObjectDelete(0,"VPNUMS7"+HASH_IND);ObjectDelete(0,"VPNUMS8"+HASH_IND);ObjectDelete(0,"VPNUMS9"+HASH_IND);     

     return 0;
  }
  if(dtype)
  {
   ButtonCreate(0,"VPTYPE1"+HASH_IND,0,ButtonStartX+(int)(93*0*Interface_Zoom)+(int)(RightShiftX*90*Interface_Zoom),ButtonStartY,(int)(90*Interface_Zoom),(int)(18*Interface_Zoom),0,"Volume Profile","Arial",Font_Size,C'255,255,255',C'192,128,128',C'128,128,128',clrNONE,Profile_Type == VolumeProfile,true,false,true,0,"");
   ButtonCreate(0,"VPTYPE2"+HASH_IND,0,ButtonStartX+(int)(93*1*Interface_Zoom)+(int)(RightShiftX*90*Interface_Zoom),ButtonStartY,(int)(90*Interface_Zoom),(int)(18*Interface_Zoom),0,"Delta Profile","Arial",Font_Size,C'255,255,255',C'192,128,128',C'128,128,128',clrNONE,Profile_Type == DeltaProfile,true,false,true,0,"");
   ButtonCreate(0,"VPTYPE3"+HASH_IND,0,ButtonStartX+(int)(93*2*Interface_Zoom)+(int)(RightShiftX*90*Interface_Zoom),ButtonStartY,(int)(90*Interface_Zoom),(int)(18*Interface_Zoom),0,"Ask/Bid Profile","Arial",Font_Size,C'255,255,255',C'192,128,128',C'128,128,128',clrNONE,Profile_Type == AskBidProfile,true,false,true,0,"");
   ButtonCreate(0,"VPHIDE"+HASH_IND,0,ButtonStartX+(int)(93*3*Interface_Zoom)+(int)(RightShiftX*29*Interface_Zoom),ButtonStartY,(int)(29*Interface_Zoom),(int)(18*Interface_Zoom),0,"[ - ]","Arial",Font_Size,C'255,255,255',C'192,128,128',C'64,64,192',clrNONE,false,true,false,true,0,"");   
  }
  if(dtime)
  {
   ButtonCreate(0,"VPTIME2"+HASH_IND,0,ButtonStartX+(int)(62*0*Interface_Zoom)+(int)(RightShiftX*60*Interface_Zoom),ButtonStartY+(int)(24*Interface_Zoom),(int)(60*Interface_Zoom),(int)(18*Interface_Zoom),0,"Daily","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,Profile_Period == 2,true,false,true,0,"");
   ButtonCreate(0,"VPTIME3"+HASH_IND,0,ButtonStartX+(int)(62*1*Interface_Zoom)+(int)(RightShiftX*60*Interface_Zoom),ButtonStartY+(int)(24*Interface_Zoom),(int)(60*Interface_Zoom),(int)(18*Interface_Zoom),0,"Weekly","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,Profile_Period == 3,true,false,true,0,"");   
   ButtonCreate(0,"VPTIME8"+HASH_IND,0,ButtonStartX+(int)(62*2*Interface_Zoom)+(int)(RightShiftX*60*Interface_Zoom),ButtonStartY+(int)(24*Interface_Zoom),(int)(60*Interface_Zoom),(int)(18*Interface_Zoom),0,"Contract","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,Profile_Period == 8,true,false,true,0,"");      
   ButtonCreate(0,"VPTIME9"+HASH_IND,0,ButtonStartX+(int)(62*3*Interface_Zoom)+(int)(RightShiftX*60*Interface_Zoom),ButtonStartY+(int)(24*Interface_Zoom),(int)(60*Interface_Zoom),(int)(18*Interface_Zoom),0,"Globex","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,Profile_Period == 9,true,false,true,0,"");   
   ButtonCreate(0,"VPTIME0"+HASH_IND,0,ButtonStartX+(int)(62*4*Interface_Zoom)+(int)(RightShiftX*60*Interface_Zoom),ButtonStartY+(int)(24*Interface_Zoom),(int)(60*Interface_Zoom),(int)(18*Interface_Zoom),0,"Custom","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,Profile_Period == 0,true,false,true,0,"");   
   
   ButtonCreate(0,"VPTIME1"+HASH_IND,0,ButtonStartX+(int)(62*0*Interface_Zoom)+(int)(RightShiftX*60*Interface_Zoom),ButtonStartY+(int)(2*Interface_Zoom)+(int)(21*2*Interface_Zoom),(int)(60*Interface_Zoom),(int)(18*Interface_Zoom),0,"Hour","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,Profile_Period == 1,true,false,true,0,"");
   ButtonCreate(0,"VPTIME4"+HASH_IND,0,ButtonStartX+(int)(62*1*Interface_Zoom)+(int)(RightShiftX*60*Interface_Zoom),ButtonStartY+(int)(2*Interface_Zoom)+(int)(21*2*Interface_Zoom),(int)(60*Interface_Zoom),(int)(18*Interface_Zoom),0,"Asia","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,Profile_Period == 4,true,false,true,0,"");   
   ButtonCreate(0,"VPTIME5"+HASH_IND,0,ButtonStartX+(int)(62*2*Interface_Zoom)+(int)(RightShiftX*60*Interface_Zoom),ButtonStartY+(int)(2*Interface_Zoom)+(int)(21*2*Interface_Zoom),(int)(60*Interface_Zoom),(int)(18*Interface_Zoom),0,"Europe","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,Profile_Period == 5,true,false,true,0,"");      
   ButtonCreate(0,"VPTIME6"+HASH_IND,0,ButtonStartX+(int)(62*3*Interface_Zoom)+(int)(RightShiftX*60*Interface_Zoom),ButtonStartY+(int)(2*Interface_Zoom)+(int)(21*2*Interface_Zoom),(int)(60*Interface_Zoom),(int)(18*Interface_Zoom),0,"Nyse","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,Profile_Period == 6,true,false,true,0,"");   
   ButtonCreate(0,"VPTIME7"+HASH_IND,0,ButtonStartX+(int)(62*4*Interface_Zoom)+(int)(RightShiftX*60*Interface_Zoom),ButtonStartY+(int)(2*Interface_Zoom)+(int)(21*2*Interface_Zoom),(int)(60*Interface_Zoom),(int)(18*Interface_Zoom),0,"CME","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,Profile_Period == 7,true,false,true,0,"");   
  }
  if (ddir)
  { 
   ButtonCreate(0,"VPDIR1"+HASH_IND,0,ButtonStartX+(int)(104*0*Interface_Zoom)+(int)(RightShiftX*100*Interface_Zoom),ButtonStartY+(int)(2*Interface_Zoom)+(int)(21*3*Interface_Zoom),(int)(100*Interface_Zoom),(int)(18*Interface_Zoom),0,"Left Side","Arial",Font_Size,C'255,255,255',C'192,128,128',C'128,128,128',clrNONE,Profile_Position==1,true,false,true,0,"");
   ButtonCreate(0,"VPDIR2"+HASH_IND,0,ButtonStartX+(int)(104*1*Interface_Zoom)+(int)(RightShiftX*100*Interface_Zoom),ButtonStartY+(int)(2*Interface_Zoom)+(int)(21*3*Interface_Zoom),(int)(100*Interface_Zoom),(int)(18*Interface_Zoom),0,"Chart","Arial",Font_Size,C'255,255,255',C'192,128,128',C'128,128,128',clrNONE,Profile_Position==0,true,false,true,0,"");
   ButtonCreate(0,"VPDIR3"+HASH_IND,0,ButtonStartX+(int)(104*2*Interface_Zoom)+(int)(RightShiftX*100*Interface_Zoom),ButtonStartY+(int)(2*Interface_Zoom)+(int)(21*3*Interface_Zoom),(int)(100*Interface_Zoom),(int)(18*Interface_Zoom),0,"Right Side","Arial",Font_Size,C'255,255,255',C'192,128,128',C'128,128,128',clrNONE,Profile_Position==2,true,false,true,0,"");
  }
  if(damount)
  {
   ButtonCreate(0,"VPNUMS1"+HASH_IND,0,ButtonStartX+(int)(34*0*Interface_Zoom)+(int)(RightShiftX*30*Interface_Zoom),ButtonStartY+(int)(2*Interface_Zoom)+(int)(21*4*Interface_Zoom),(int)(32*Interface_Zoom),(int)(18*Interface_Zoom),0,"1","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,TotalProfiles==1,true,false,true,0,"");   
   ButtonCreate(0,"VPNUMS2"+HASH_IND,0,ButtonStartX+(int)(34*1*Interface_Zoom)+(int)(RightShiftX*30*Interface_Zoom),ButtonStartY+(int)(2*Interface_Zoom)+(int)(21*4*Interface_Zoom),(int)(32*Interface_Zoom),(int)(18*Interface_Zoom),0,"2","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,TotalProfiles==2,true,false,true,0,"");
   ButtonCreate(0,"VPNUMS3"+HASH_IND,0,ButtonStartX+(int)(34*2*Interface_Zoom)+(int)(RightShiftX*30*Interface_Zoom),ButtonStartY+(int)(2*Interface_Zoom)+(int)(21*4*Interface_Zoom),(int)(32*Interface_Zoom),(int)(18*Interface_Zoom),0,"3","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,TotalProfiles==3,true,false,true,0,"");   
   ButtonCreate(0,"VPNUMS4"+HASH_IND,0,ButtonStartX+(int)(34*3*Interface_Zoom)+(int)(RightShiftX*30*Interface_Zoom),ButtonStartY+(int)(2*Interface_Zoom)+(int)(21*4*Interface_Zoom),(int)(32*Interface_Zoom),(int)(18*Interface_Zoom),0,"5","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,TotalProfiles==5,true,false,true,0,"");      
   ButtonCreate(0,"VPNUMS5"+HASH_IND,0,ButtonStartX+(int)(34*4*Interface_Zoom)+(int)(RightShiftX*30*Interface_Zoom),ButtonStartY+(int)(2*Interface_Zoom)+(int)(21*4*Interface_Zoom),(int)(32*Interface_Zoom),(int)(18*Interface_Zoom),0,"7","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,TotalProfiles==7,true,false,true,0,"");   
   ButtonCreate(0,"VPNUMS6"+HASH_IND,0,ButtonStartX+(int)(34*5*Interface_Zoom)+(int)(RightShiftX*30*Interface_Zoom),ButtonStartY+(int)(2*Interface_Zoom)+(int)(21*4*Interface_Zoom),(int)(33*Interface_Zoom),(int)(18*Interface_Zoom),0,"10","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,TotalProfiles==10,true,false,true,0,"");   
   ButtonCreate(0,"VPNUMS7"+HASH_IND,0,ButtonStartX+(int)(34*6*Interface_Zoom)+(int)(1*Interface_Zoom)+(int)(RightShiftX*30*Interface_Zoom),ButtonStartY+(int)(2*Interface_Zoom)+(int)(21*4*Interface_Zoom),(int)(33*Interface_Zoom),(int)(18*Interface_Zoom),0,"15","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,TotalProfiles==15,true,false,true,0,"");      
   ButtonCreate(0,"VPNUMS8"+HASH_IND,0,ButtonStartX+(int)(34*7*Interface_Zoom)+(int)(2*Interface_Zoom)+(int)(RightShiftX*30*Interface_Zoom),ButtonStartY+(int)(2*Interface_Zoom)+(int)(21*4*Interface_Zoom),(int)(33*Interface_Zoom),(int)(18*Interface_Zoom),0,"20","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,TotalProfiles==20,true,false,true,0,"");         
   ButtonCreate(0,"VPNUMS9"+HASH_IND,0,ButtonStartX+(int)(34*8*Interface_Zoom)+(int)(3*Interface_Zoom)+(int)(RightShiftX*30*Interface_Zoom),ButtonStartY+(int)(2*Interface_Zoom)+(int)(21*4*Interface_Zoom),(int)(33*Interface_Zoom),(int)(18*Interface_Zoom),0,"31","Arial",Font_Size,C'224,224,224',C'192,128,128',C'96,96,96',clrNONE,TotalProfiles==31,true,false,true,0,"");            
  }
 

return 1;
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

   static int dllalert=0;
   static bool dll_init=false;
   
   static int CHART_CHANGED_REASON_1 = 0; //WindowBarsPerChart();
   static int CHART_CHANGED_REASON_2 = 0; //WindowFirstVisibleBar();
   int period_to_obj=0;

   if(ArraySize(LastTime)==0) return 0;
   ChartRedraw(0);   
   if(!dll_init)
   {
     int res;
     ENUM_ACCOUNT_TRADE_MODE account_type=(ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE); 
     int acc=(int)AccountInfoInteger(ACCOUNT_LOGIN);
     if(account_type == ACCOUNT_TRADE_MODE_REAL) { acc = acc * -1; } // we will care for real mode account, comment it if you dont like to it

     InitDLL(res);
     if(res==-1) { Print("Error during DLL init. ") ; return (0); }
     dll_init=1;
   }

  

   GetData();        
   if (loaded && (CHART_CHANGED_REASON_1 != WindowBarsPerChart() || CHART_CHANGED_REASON_2 != WindowFirstVisibleBar()))
   {
     // redraw VP
     if ( newdata || CHART_CHANGED_REASON_1  || CHART_CHANGED_REASON_2 ) DrawVP(min_price,PriceData,AskData,BidData); 
     CHART_CHANGED_REASON_1 = WindowBarsPerChart();
     CHART_CHANGED_REASON_2 = WindowFirstVisibleBar();

   
   }

   if (TimeLocal() < myUpdateTime && loaded) { return(1); } else 
   { 
      myUpdateTime = TimeLocal() + UpdateFreq; 
   }

   if (ONLINE || !loaded)
   {
     SetData();  
   }
   
   ChartRedraw(0);

   return(1);
  }
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
  ObjectDelete(0,"InfoMessage"+"_"+indicator_id);
  GlobalVariableSet(indicator_id,-1);
  
  EventKillTimer();
  int    obj_total=ObjectsTotal(0);
     
  for(int i=0;i<obj_total;i++)
    {
     
       while ( (StringFind(ObjectName(0,i),HASH_IND)!= -1) ) 
       { 
         if((reason!=3 && reason!=5) ||(ObjectName(0,i)!=vertical_line_name1 && ObjectName(0,i)!=vertical_line_name2 && ObjectName(0,i)!=settings_line)) { ObjectDelete(0,ObjectName(0,i)); } 
         else 
         { break; } 
       }

    }     
    
    return ;
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

int button_clicked(string name) 
{ 
   if(ObjectGetInteger(0,name+HASH_IND,OBJPROP_STATE)==true) 
      return 1; 
   return 0; 
}  
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{

//-------------------------------------------------------------------------------------------------
//Print(id);

   string clickedChartObject=sparam;
   int changed=0, changed_type=0, changed_time=0, changed_direction=0, changed_amount=0;
   if(id==CHARTEVENT_CLICK)
   {
       if (button_clicked("VPHIDE")) { Information_Buttons=!Information_Buttons; changed=1; Save_Amount_Of_Profiles=TotalProfiles; if(Information_Buttons){changed_type=-1;changed_time=-1;changed_direction=-1;changed_amount=-1;} }
       if (button_clicked("VPTYPE1")  && Profile_Type!=VolumeProfile) { Profile_Type=VolumeProfile; changed=1; changed_type=1; Save_Amount_Of_Profiles=TotalProfiles;} else
       if (button_clicked("VPTYPE2") && Profile_Type!=DeltaProfile) { Profile_Type=DeltaProfile; changed=1; changed_type=2; Save_Amount_Of_Profiles=TotalProfiles; } else
       if (button_clicked("VPTYPE3") && Profile_Type!=AskBidProfile) { Profile_Type=AskBidProfile; changed=1; changed_type=3; Save_Amount_Of_Profiles=TotalProfiles;} 

       if (button_clicked("VPTIME0")  && Profile_Period!=0) { Profile_Period=0; changed=1; changed_time=10;  Save_Amount_Of_Profiles=1; changed_amount=1; TotalProfiles=Save_Amount_Of_Profiles;} else
       if (button_clicked("VPTIME1")  && Profile_Period!=1) { Profile_Period=1; changed=1; changed_time=11; TotalProfiles=Save_Amount_Of_Profiles;} else       
       if (button_clicked("VPTIME2")  && Profile_Period!=2) { Profile_Period=2; changed=1; changed_time=12; TotalProfiles=Save_Amount_Of_Profiles;} else       
       if (button_clicked("VPTIME3")  && Profile_Period!=3) { Profile_Period=3; changed=1; changed_time=13; TotalProfiles=Save_Amount_Of_Profiles;} else
       if (button_clicked("VPTIME4")  && Profile_Period!=4) { Profile_Period=4; changed=1; changed_time=14; TotalProfiles=Save_Amount_Of_Profiles;} else       
       if (button_clicked("VPTIME5")  && Profile_Period!=5) { Profile_Period=5; changed=1; changed_time=15; TotalProfiles=Save_Amount_Of_Profiles;} else       
       if (button_clicked("VPTIME6")  && Profile_Period!=6) { Profile_Period=6; changed=1; changed_time=16; TotalProfiles=Save_Amount_Of_Profiles;} else
       if (button_clicked("VPTIME7")  && Profile_Period!=7) { Profile_Period=7; changed=1; changed_time=17; TotalProfiles=Save_Amount_Of_Profiles;} else       
       if (button_clicked("VPTIME8")  && Profile_Period!=8) { Profile_Period=8; changed=1; changed_time=18;  Save_Amount_Of_Profiles=1; changed_amount=1;TotalProfiles=Save_Amount_Of_Profiles;} else       
       if (button_clicked("VPTIME9")  && Profile_Period!=9) { Profile_Period=9; changed=1; changed_time=19;  TotalProfiles=Save_Amount_Of_Profiles;} 

       if (button_clicked("VPDIR1")  && Profile_Position!=1) { Profile_Position=1; changed=1; changed_direction=1;  Save_Amount_Of_Profiles=1; changed_amount=1;TotalProfiles=Save_Amount_Of_Profiles;} else
       if (button_clicked("VPDIR2") && Profile_Position!=0) { Profile_Position=0; changed=1; changed_direction=2; } else
       if (button_clicked("VPDIR3") && Profile_Position!=2) { Profile_Position=2; changed=1; changed_direction=3; Save_Amount_Of_Profiles=1; changed_amount=1; TotalProfiles=Save_Amount_Of_Profiles;} 


       if (button_clicked("VPNUMS1")  && TotalProfiles!=1 ) { Save_Amount_Of_Profiles=1; changed=1; changed_amount=1; TotalProfiles=Save_Amount_Of_Profiles;} else
       if (button_clicked("VPNUMS2")  && TotalProfiles!=2 && Profile_Position==0 && Profile_Period!=0 && Profile_Period!=8) { Save_Amount_Of_Profiles=2; changed=1; changed_amount=2; TotalProfiles=Save_Amount_Of_Profiles;} else
       if (button_clicked("VPNUMS3")  && TotalProfiles!=3 && Profile_Position==0 && Profile_Period!=0 && Profile_Period!=8) { Save_Amount_Of_Profiles=3; changed=1; changed_amount=3; TotalProfiles=Save_Amount_Of_Profiles;} else       
       if (button_clicked("VPNUMS4")  && TotalProfiles!=5 && Profile_Position==0 && Profile_Period!=0 && Profile_Period!=8) { Save_Amount_Of_Profiles=5; changed=1; changed_amount=5; TotalProfiles=Save_Amount_Of_Profiles;} else              
       if (button_clicked("VPNUMS5")  && TotalProfiles!=7 && Profile_Position==0 && Profile_Period!=0 && Profile_Period!=8) { Save_Amount_Of_Profiles=7; changed=1; changed_amount=7; TotalProfiles=Save_Amount_Of_Profiles;} else                     
       if (button_clicked("VPNUMS6")  && TotalProfiles!=10 && Profile_Position==0 && Profile_Period!=0 && Profile_Period!=8) { Save_Amount_Of_Profiles=10; changed=1; changed_amount=10; TotalProfiles=Save_Amount_Of_Profiles; } else                            
       if (button_clicked("VPNUMS7")  && TotalProfiles!=15 && Profile_Position==0 && Profile_Period!=0 && Profile_Period!=8) { Save_Amount_Of_Profiles=15; changed=1; changed_amount=15; TotalProfiles=Save_Amount_Of_Profiles;} else                            
       if (button_clicked("VPNUMS8")  && TotalProfiles!=20 && Profile_Position==0 && Profile_Period!=0 && Profile_Period!=8) { Save_Amount_Of_Profiles=20; changed=1; changed_amount=20; TotalProfiles=Save_Amount_Of_Profiles;} else                            
       if (button_clicked("VPNUMS9")  && TotalProfiles!=31 && Profile_Position==0 && Profile_Period!=0 && Profile_Period!=8) { Save_Amount_Of_Profiles=31; changed=1; changed_amount=31; TotalProfiles=Save_Amount_Of_Profiles;} 
       


       if(changed)
       {
              DrawButton(changed_type,changed_time,changed_direction,changed_amount);       
              ONLINE=true;
              myUpdateTime=TimeLocal()+1;
              min_price=0;
              ArrayResize(PriceData,0);
              ArrayResize(AskData,0);
              ArrayResize(BidData,0);              
              int    obj_total=ObjectsTotal(0);
              for(int i=0;i<obj_total;i++)
              {
                while ((StringSubstr(ObjectName(0,i),0,8) == "VPLine_P") && (StringFind(ObjectName(0,i),HASH_IND)!= -1)) { ObjectDelete(0,ObjectName(0,i));  }
              }
              
          
       }

   
    }
   
}


int SetData()
{

  int k=0,i;
  string sym=Symbol();
  int per=Profile_Period;
  if(query_in_progress) return -1;
    
  string tmc=TimeToString(TimeTradeServer());
  string tm0=IntegerToString(Save_Amount_Of_Profiles-1);
  string lsl=TimeToString(last_loaded);
  string cst=TimeToString(TIME1);
  string cet=TimeToString(TIME2);
  string cmp=AccountInfoString(ACCOUNT_COMPANY);
  int acnt=(int)AccountInfoInteger(ACCOUNT_LOGIN);

  query_in_progress=true;

  i = Send_Query(k,clusterdelta_client, sym, per, tmc, tm0, Instrument, lsl,MetaTrader_GMT,ver,history_back_profiles,cst,cet,cmp,acnt);     

  if (i < 0) { Alert ("Error during query registration"); return -1; }
  
  return 1;
}  


void CustomLines(int length)
{
   string hash_client_name="";
   string cdpp="";
   bool get_old_lines = false;   
   int j;
   if(Profile_Period == 0)
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

          
          
          for(j=0;j<objects;j++)
          {
            if (StringSubstr(ObjectName(0,j),0,8) == "VPLine_C") 
            { 
              hash_client_name=StringSubstr(ObjectName(0,j),10);
              cdpp="CDPP"+StringSubstr(hash_client_name,3);              
              if ((GlobalVariableCheck("CLUSTERDELTA_"+cdpp) || GlobalVariableCheck("CLUSTERDELTA_"+hash_client_name)) && GlobalVariableGet("CLUSTERDELTA_"+cdpp)!=-1) 
              {  another_custom_profiles++;  


              } else
              {
                // lines of nobody, maybe mine

                ResetLastError();

                v1_time = (datetime)ObjectGetInteger(0,"VPLine_C1_"+hash_client_name,OBJPROP_TIME);
                v2_time = (datetime)ObjectGetInteger(0,"VPLine_C2_"+hash_client_name,OBJPROP_TIME);
           
                if(v1_time!=D'1970.01.01 00:00' && v2_time!=D'1970.01.01 00:00') 
                {
                  prev_style = (ENUM_LINE_STYLE)ObjectGetInteger(0,"VPLine_C1_"+hash_client_name,OBJPROP_STYLE);
                  prev_color = (color)ObjectGetInteger(0,"VPLine_C1_"+hash_client_name,OBJPROP_COLOR);
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
            ObjectDelete(0,"DPLine_C1_"+hash_client_name);
            ObjectDelete(0,"DPLine_C2_"+hash_client_name);            
          }
          
          ObjectCreate(0,vertical_line_name1, OBJ_VLINE, 0, time_line1,0);
          ObjectCreate(0,vertical_line_name2, OBJ_VLINE, 0, time_line2,0);
          ObjectSetInteger(0,vertical_line_name1,OBJPROP_STYLE,vert_line_stye);
          ObjectSetInteger(0,vertical_line_name1,OBJPROP_COLOR,vert_line_color);      
          ObjectSetInteger(0,vertical_line_name2,OBJPROP_STYLE,vert_line_stye);
          ObjectSetInteger(0,vertical_line_name2,OBJPROP_COLOR,vert_line_color);      
          ObjectSetInteger(0,vertical_line_name1,OBJPROP_SELECTABLE, 1);
          ObjectSetInteger(0,vertical_line_name2,OBJPROP_SELECTABLE, 1);
          
          ObjectSetInteger(0,vertical_line_name1, OBJPROP_BACK, Lines_are_Background);
          ObjectSetInteger(0,vertical_line_name1, OBJPROP_SELECTED, Lines_are_Active);
          ObjectSetInteger(0,vertical_line_name2, OBJPROP_BACK, Lines_are_Background);
          ObjectSetInteger(0,vertical_line_name2, OBJPROP_SELECTED, Lines_are_Active);
        }
        
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
            if((Check_TIME1 != TIME1 || Check_TIME2!=TIME2))
            {
              TIME1=Check_TIME1;
              TIME2=Check_TIME2;
              Custom_Start_time=TIME1;
              Custom_End_time=TIME2;
              
              
              ONLINE=true;
              myUpdateTime=TimeLocal()+1;
              min_price=0;
              ArrayResize(PriceData,0);
              ArrayResize(AskData,0);
              ArrayResize(BidData,0);              
              int    obj_total=ObjectsTotal(0);
              for(int i=0;i<obj_total;i++)
              {
                while ((StringSubstr(ObjectName(0,i),0,8) == "VPLine_P") && (StringFind(ObjectName(0,i),HASH_IND)!= -1)) { ObjectDelete(0,ObjectName(0,i));  }
              }
            }
            
         }
     } else
     {
       ObjectDelete(0,vertical_line_name1);
       ObjectDelete(0,vertical_line_name2);       
     }
   } else
   if(length>0)
   {
     ObjectDelete(0,vertical_line_name1);
     ObjectDelete(0,vertical_line_name2);       
          hash_client_name="";
          get_old_lines=false;
          int myobjects=ObjectsTotal(0);         
          for(j=0;j<myobjects;j++)
          {
            if (StringSubstr(ObjectName(0,j),0,8) == "VPLine_C") 
            { 
            
              hash_client_name=StringSubstr(ObjectName(0,j),10,7);
              cdpp="CDPP"+StringSubstr(hash_client_name,3);
              if (!GlobalVariableCheck("CLUSTERDELTA_"+cdpp) && !GlobalVariableCheck("CLUSTERDELTA_"+hash_client_name)) 
              {
                  ObjectDelete(0,"VPLine_C1_"+hash_client_name);
                  ObjectDelete(0,"VPLine_C2_"+hash_client_name);            
                  break;

              }
            }
          }
     
   }
}

int GetData()
{

   string response="";
   int length=0;
   int valid=0;   
   response = Receive_Information(length, clusterdelta_client);

   if (length>0) {   query_in_progress=false; }
   if(Profile_Period == 0) 
   {   CustomLines(length); }

   if(StringLen(response)>1)
   {
       
      while(StringLen(response)>1) // if we got response (no care how), convert it to mt4 buffers
      {
         Process_Response(response);
      } // response >1 else
      if(Save_Amount_Of_Profiles>1) { Save_Amount_Of_Profiles=1;  }
      else
      {
        if (last_End_time < LastTime[NumberRates-1])
        {
           ONLINE=false;
        }
      }
   }
    return (1);
}

void Process_Response(string &res)
{
   int valid=0;
   
   valid= ConvertResponseToArrays(res,PriceData,AskData,BidData,"\n",";",MessageFromServer, last_Start_time, last_End_time); 
   if (valid>0 && ArraySize(PriceData)>0)
   {
     if (ReverseChart_SET) // точно форекс
     {
          ReversePrices(PriceData,false,1);
     }
     SortDictionary(PriceData,AskData,BidData);
     DrawVP(min_price,PriceData,AskData,BidData); 
         

      if(StringLen(MessageFromServer)>8 && OneTimeAlert==0 )
      { 
          ObjectCreate(0,"InfoMessage"+"_"+indicator_id,OBJ_LABEL,0,0,0); 
          ObjectSetInteger(0,"InfoMessage"+"_"+indicator_id, OBJPROP_CORNER, Information_Corner);    
          ObjectSetInteger(0,"InfoMessage"+"_"+indicator_id, OBJPROP_XDISTANCE, 4+(Information_Corner>2 ? StringLen("PremiumProfile: "+MessageFromServer)*5 : 0));
          ObjectSetInteger(0,"InfoMessage"+"_"+indicator_id, OBJPROP_YDISTANCE, 130);
          ObjectSetString(0,"InfoMessage"+"_"+indicator_id,OBJPROP_TEXT,"PremiumProfile: "+MessageFromServer);
          ObjectSetInteger(0,"InfoMessage"+"_"+indicator_id,OBJPROP_FONTSIZE,Font_Size);
          ObjectSetString(0,"InfoMessage"+"_"+indicator_id,OBJPROP_FONT,"Arial");
          ObjectSetInteger(0,"InfoMessage"+"_"+indicator_id,OBJPROP_COLOR,LightGreen);            
          OneTimeAlert=1; 
      } else { ObjectDelete(0,"InfoMessage"+"_"+indicator_id); }
      
      if (StringLen(MessageFromServer)>8 && OneTimeAlert==1) { Print("MT4 Time ",TimeToString(TimeCurrent()),",  data source info:", MessageFromServer ); OneTimeAlert=2; }       
      newdata=true;
   } 
   loaded=true;   
}

int WindowFirstVisibleBar()
{
  return (int)ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR,0);
}
int WindowBarsPerChart()
{
  return (int)ChartGetInteger(0,CHART_WIDTH_IN_BARS,0);
}
void DrawVP(double mymin_price, double &prices[], double &volumes[], double &deltas[])
{
int i=0;
double arrprice;
double arrvol;
double arrask;
double arrbid;
int time_s, shift_vp1=0, shift_vp=0;

datetime drawrange, drawrange2; 
int volrange, volrange2;
double next_price;
int start_index, end_index;

double val=0, vah=0;
int max_volume_index=0;
double mymax_volume=0;
double mymax_ask = 0;
double mymax_bid = 0;

double delta_max=0;
double delta_min=0;

double total_volume=0;
double total_ask=0;
double total_bid=0;

if(ArraySize(volumes)==0 && ArraySize(deltas)==0) return;
newdata=false;
bool bkg=true;

int ask_direction=1;
int bid_direction=1;

max_volume_index = ArrayMaximum(volumes);
mymax_volume = volumes[max_volume_index];
double max_volume_price = prices[max_volume_index];
check_VA(val,vah,max_volume_price,max_volume_index,prices,volumes);

color askcolor=AskColor_AskBidProfile, bidcolor=BidColor_AskBidProfile;

if(Profile_Type == AskBidProfile)
{
  if(!Ask_Direction) ask_direction=-1; // left
  if(Bid_Direction) bid_direction=-1; // right
  askcolor=AskColor_AskBidProfile;
  bidcolor=BidColor_AskBidProfile;
}

if(Profile_Type == DeltaProfile)
{
  if(!DeltaPositive_Direction) ask_direction=-1; // left
  if(DeltaNegative_Direction) bid_direction=-1; // right
  askcolor=DeltaPositive_DeltaProfile;
  bidcolor=DeltaNegative_DeltaProfile;
  
}

//double max_volume_price=0;

for (i=0; i<ArraySize(prices); i++)
{
  if(Profile_Type==VolumeProfile)  
  {
    if(mymax_volume < (volumes[i])) { mymax_volume = (volumes[i]); /* max_volume_price = prices[i];*/ }
    total_volume=total_volume+volumes[i];    
  }
  if(Profile_Type==AskBidProfile)
  {
    if(mymax_ask < ((volumes[i]+deltas[i])/2)) { mymax_ask = (volumes[i]+deltas[i])/2; }  
    if(mymax_bid < ((volumes[i]-deltas[i])/2)) { mymax_bid = (volumes[i]-deltas[i])/2; }    
    mymax_volume=MathAbs(mymax_ask);    
    if(mymax_volume<MathAbs(mymax_bid)){mymax_volume=MathAbs(mymax_bid);}    
    total_ask=total_ask+(volumes[i]+deltas[i])/2;
    total_bid=total_bid+(volumes[i]-deltas[i])/2;        
   
  }
  if(Profile_Type == DeltaProfile)
  {
    if(deltas[i]>0 && mymax_ask < deltas[i]) { mymax_ask = deltas[i]; }  
    if(deltas[i]<0 && mymax_bid > deltas[i]) { mymax_bid = deltas[i]; }    
    mymax_volume=MathAbs(mymax_ask);
    //if(mymax_volume<mymax_ask){mymax_volume=mymax_ask;}
    if(mymax_volume<MathAbs(mymax_bid)){mymax_volume=MathAbs(mymax_bid);}    

    if(deltas[i]>0) { total_ask=total_ask+deltas[i]; }
    if(deltas[i]<0) { total_bid=total_bid+deltas[i]; }
  }
  
}
//Print(mymax_ask," ",mymax_bid);



//check_VA(val,vah,max_volume_price,max_volume_index,prices,volumes);

forex_shift_auto = (int)get_forex_shift();



int last_bar = (WindowFirstVisibleBar() - WindowBarsPerChart());
int empty_space =0 ;
datetime last_date;
int end_shift=0;
string total_name;


//Print("last_bar=",last_bar, " w1=",WindowFirstVisibleBar());

if (last_bar <= 0)
{
  empty_space = WindowBarsPerChart() - WindowFirstVisibleBar();
  last_date=LastTime[NumberRates-1]+60*Period_To_Minutes()*empty_space;
} else
{
  last_date=LastTime[NumberRates-last_bar];
}


int zoom = 100;

if (ZOOM_scale_in_percent >= 10 && ZOOM_scale_in_percent <= 200) { zoom = ZOOM_scale_in_percent; }
if (zoom>300) zoom=300;
if (zoom<10) zoom=10;

if(Profile_Period == 0 && Custom_Zoom>=10 && Custom_Zoom<=300) zoom=Custom_Zoom -1;

double calc_max_volume = mymax_volume;
if (Correlate_Volume_To>0)
{
  if ((mymax_volume*1.0 / Correlate_Volume_To ) < 5)  { calc_max_volume = Correlate_Volume_To; } else { Print ("Correlate Volume too small ",Correlate_Volume_To,"x5 < ",mymax_volume); }
}

for (i=0; i<ArraySize(prices); i++)
{
  arrprice = prices[i];
  arrvol   = volumes[i];
  arrask = (volumes[i]+deltas[i])/2;
  arrbid = (volumes[i]-deltas[i])/2;
  if(Profile_Type == DeltaProfile)
  {
    if(arrask>=arrbid) { arrask = arrask-arrbid; arrbid=0; }
    if(arrask<arrbid) { arrbid = arrbid-arrask; arrask=0; }    
  }
  
  next_price = arrprice + 1/MathPow(10,_Digits);   

  if (Profile_Position == 0)
  {
     int s = ArrayBsearch(LastTime,last_Start_time);
     //Start_time = Time[s];
     start_index = s;
     if (last_End_time<=LastTime[NumberRates-1])
     {
       s = ArrayBsearch(LastTime,last_End_time);
     } else { s =NumberRates-1; }
     
     end_index = s;

    if(Profile_Type == VolumeProfile)
    {
      volrange =  (int)MathRound(((end_index - start_index)*arrvol*1.0*zoom) /(calc_max_volume*100));
      if(start_index+volrange > NumberRates-1)
      {
        drawrange = LastTime[NumberRates-1] +  (start_index + volrange - NumberRates+1)*Period_To_Minutes()*60;
      } else
      {
        drawrange = LastTime[start_index + volrange]; // * Period_To_Minutes() * 60;
      }
      DrawVPLine(arrprice, next_price, LastTime[start_index], drawrange, arrvol, mymax_volume, val, vah, last_date);
    } 
    if(Profile_Type == AskBidProfile || Profile_Type==DeltaProfile)
    {
      volrange =  (int)MathRound(((end_index - start_index)*ask_direction*(arrask)*1.0*zoom/1.618) /(calc_max_volume*100));
      if(start_index+volrange > NumberRates-1)
      {
        drawrange = LastTime[NumberRates-1] +  (start_index + volrange - NumberRates+1)*Period_To_Minutes()*60;
      } else
      {
        drawrange = LastTime[start_index + volrange]; // * Period_To_Minutes() * 60;
      }
      volrange2 =  (int)MathRound(((end_index - start_index)*(-arrbid)*bid_direction*1.0*zoom/1.618) /(calc_max_volume*100));
      if(start_index+volrange2 > NumberRates-1)
      {
        drawrange2 = LastTime[NumberRates-1] +  (start_index + volrange2 - NumberRates+1)*Period_To_Minutes()*60;
      } else
      {
        drawrange2 = LastTime[start_index + volrange2]; // * Period_To_Minutes() * 60;
      }
    
      if(Profile_Type == AskBidProfile && MathAbs(arrbid)>MathAbs(arrask) && ((ask_direction!=1 && bid_direction==1)||(ask_direction==1 && bid_direction!=1)))
      {
        if(start_index+volrange > NumberRates-1)
        {
          drawrange = LastTime[NumberRates-1] +  (start_index + volrange - NumberRates+1)*Period_To_Minutes()*60;
        } else
        {
          drawrange = LastTime[start_index + volrange]; // * Period_To_Minutes() * 60;
        }
        if(start_index+volrange-volrange2 > NumberRates-1)
        {
          drawrange2 = LastTime[NumberRates-1] +  (start_index + volrange -volrange2 - NumberRates+1)*Period_To_Minutes()*60;
        } else
        {
          drawrange2 = LastTime[start_index + volrange-volrange2]; // * Period_To_Minutes() * 60;
        }

        //DrawABPLine(arrprice, next_price, Time[start_index], drawrange2, arrbid*bid_direction, mymax_ask,mymax_bid, last_date,"bid");    
        DrawABPLine(arrprice, next_price, drawrange, drawrange2, arrbid*bid_direction, mymax_ask,mymax_bid, last_date,"bid",bidcolor,askcolor);    
        DrawABPLine(arrprice, next_price, LastTime[start_index], drawrange, -arrask*ask_direction, mymax_ask,mymax_bid, last_date,"ask",bidcolor,askcolor);
      } else 
      if(Profile_Type == AskBidProfile && MathAbs(arrbid)<MathAbs(arrask) && ((ask_direction!=1 && bid_direction==1)||(ask_direction==1 && bid_direction!=1)))
      {
        if(start_index+volrange-volrange2 > NumberRates-1)
        {
          drawrange = LastTime[NumberRates-1] +  (start_index + volrange -volrange2 - NumberRates+1)*Period_To_Minutes()*60;
        } else
        {
          drawrange = LastTime[start_index + volrange-volrange2]; // * Period_To_Minutes() * 60;
        }
        if(start_index+volrange > NumberRates-1)
        {
          drawrange2 = LastTime[NumberRates-1] +  (start_index + volrange - NumberRates+1)*Period_To_Minutes()*60;
        } else
        {
          drawrange2 = LastTime[start_index + volrange]; // * Period_To_Minutes() * 60;
        }
        DrawABPLine(arrprice, next_price, LastTime[start_index], drawrange2, arrbid*bid_direction, mymax_ask,mymax_bid, last_date,"bid",bidcolor,askcolor);    
        DrawABPLine(arrprice, next_price, drawrange2, drawrange, -arrask*ask_direction, mymax_ask,mymax_bid, last_date,"ask",bidcolor,askcolor);
      } else
      {
        DrawABPLine(arrprice, next_price, LastTime[start_index], drawrange2, arrbid*bid_direction, mymax_ask,mymax_bid, last_date,"bid",bidcolor,askcolor);    
        DrawABPLine(arrprice, next_price, LastTime[start_index], drawrange, -arrask*ask_direction, mymax_ask,mymax_bid, last_date,"ask",bidcolor,askcolor);
      }
    }
  } else
  if (Profile_Position == 2) // правый край
  {
    end_shift= WindowBarsPerChart()/5;
    if(Profile_Type == VolumeProfile)
    {
    
    volrange =  (int)MathRound((end_shift*arrvol*1.0*zoom) /(calc_max_volume*100));
    drawrange = last_date - volrange * Period_To_Minutes() * 60;
    if (drawrange < LastTime[NumberRates-1])
    {
      end_shift = ArrayBsearch(LastTime,drawrange);
      drawrange=LastTime[end_shift];
    }
    DrawVPLine(arrprice, next_price, last_date, drawrange, arrvol, mymax_volume, val, vah, last_date);
    }
    
    
    if(Profile_Type == AskBidProfile || Profile_Type==DeltaProfile)
    {
    

    volrange =  (int)MathRound((end_shift*arrask*(-ask_direction)*1.0*zoom) /(calc_max_volume*100));
    drawrange = last_date - volrange * Period_To_Minutes() * 60;
    shift_vp = (int)(Period_To_Minutes() * 60+end_shift*1.0*zoom *Period_To_Minutes() * 60/100); 
    if(ask_direction==-1 && bid_direction==1) { shift_vp=0; }
    DrawABPLine(arrprice, next_price, last_date-shift_vp, drawrange-shift_vp, -arrask*(-ask_direction),  mymax_ask,mymax_bid, last_date,"ask",bidcolor,askcolor);
    
    
    volrange =  (int)MathRound((end_shift*(-arrbid)*(-bid_direction)*1.0*zoom) /(calc_max_volume*100));
    drawrange = last_date - volrange * Period_To_Minutes() * 60;
    shift_vp = (int)(Period_To_Minutes() * 60+end_shift*1.0*zoom *Period_To_Minutes() * 60/100); 
    if(ask_direction==-1 && bid_direction==1) { shift_vp=0; }    
    DrawABPLine(arrprice+_Point/4, next_price+_Point/4, last_date-shift_vp, drawrange-shift_vp, arrbid*(-bid_direction), mymax_ask,mymax_bid, last_date,"bid",bidcolor,askcolor);
    
    }
  }
  else
  if (Profile_Position == 1) // левый край
  {
    end_shift = WindowBarsPerChart()/5;
    
    if(Profile_Type == VolumeProfile)
    {
    
    volrange =  (int)MathRound((end_shift*arrvol*1.0*zoom) /(calc_max_volume*100));
    
    //Print(WindowFirstVisibleBar()," + ",volrange," = ",NumberRates);
    if ( (NumberRates - WindowFirstVisibleBar() + volrange-1)  < NumberRates)
    {
      drawrange = LastTime[NumberRates - WindowFirstVisibleBar() + volrange-1];
    } else
    {
      drawrange = LastTime[NumberRates-WindowFirstVisibleBar()-1] + volrange * Period_To_Minutes() * 60; 
    }
    DrawVPLine(arrprice, next_price, LastTime[NumberRates-WindowFirstVisibleBar()-1], drawrange, arrvol, mymax_volume, val, vah, last_date);
    }
    
    
    if(Profile_Type == AskBidProfile || Profile_Type==DeltaProfile)
    {
    
    volrange =  (int)MathRound((end_shift*(-arrask)*(-ask_direction)*1.0*zoom) /(calc_max_volume*100));
    shift_vp1 = (int)(Period_To_Minutes() * 60+end_shift*1.0*zoom *Period_To_Minutes() * 60/100);     
    if(ask_direction==1 && bid_direction==-1) { shift_vp1=0; }        
    if ( (NumberRates - WindowFirstVisibleBar() + volrange-1)  < NumberRates)
    {
      drawrange = LastTime[NumberRates - WindowFirstVisibleBar() + volrange-1];

    } else
    {
      drawrange = (datetime)(LastTime[NumberRates-WindowFirstVisibleBar()-1] - (-volrange) * Period_To_Minutes() * 60); 

    }
    
    DrawABPLine(arrprice, next_price, LastTime[NumberRates-WindowFirstVisibleBar()-1]+shift_vp1, drawrange+shift_vp1, -arrask*(-ask_direction), mymax_ask,mymax_bid, last_date,"ask",bidcolor,askcolor);


    volrange =  (int)MathRound((end_shift*(arrbid)*(-bid_direction)*1.0*zoom) /(calc_max_volume*100));
    shift_vp1 = (int)MathRound(Period_To_Minutes() * 60+end_shift*1.0*zoom *Period_To_Minutes() * 60/100);     
    if(ask_direction==1 && bid_direction==-1) { shift_vp1=0; }            
    if ( (NumberRates - WindowFirstVisibleBar() + volrange-1)  < NumberRates)
    {
      drawrange = LastTime[NumberRates - WindowFirstVisibleBar() + volrange-1];
    } else
    {
      drawrange = (datetime)(LastTime[NumberRates-WindowFirstVisibleBar()-1] - (volrange) * Period_To_Minutes() * 60); 
    }
    DrawABPLine(arrprice+_Point/4, next_price, LastTime[NumberRates-WindowFirstVisibleBar()-1]+shift_vp1, drawrange+shift_vp1, arrbid*(-bid_direction), mymax_ask,mymax_bid, last_date,"bid",bidcolor,askcolor);
    }
    
  }

}

if (Show_Sum_Values)
{
   int forexshift=Forex_shift;
   if (Forex_auto_shift) forexshift=forex_shift_auto;
if (Profile_Position == 0)
{
    if(Profile_Type == VolumeProfile)
    {
          time_s  = ArrayBsearch(LastTime,last_Start_time);
          total_name = "VPLine_P" + "_TOTALV_"+ (string)LastTime[time_s]+"_"+HASH_IND; 
          ObjectCreate(0,total_name,OBJ_TEXT,0,LastTime[time_s],prices[0]-_Point*2+forexshift*_Point);        
          ObjectSetInteger(0,total_name,OBJPROP_FONTSIZE,Font_Size);
          ObjectSetString(0,total_name,OBJPROP_FONT,"Arial");
          ObjectSetString(0,total_name,OBJPROP_TEXT,IntegerToString((int)total_volume));
          ObjectSetInteger(0,total_name,OBJPROP_COLOR,VolumeLine_Max_Volume);            
          ObjectSetInteger(0,total_name,OBJPROP_TIME,LastTime[time_s]);          
          ObjectSetDouble(0,total_name,OBJPROP_PRICE,prices[0]-_Point*2+forexshift*_Point);      
          ObjectSetInteger(0,total_name,OBJPROP_ALIGN,ALIGN_LEFT);
          ObjectSetInteger(0,total_name,OBJPROP_READONLY,1);
          ObjectSetInteger(0,total_name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);          
       
    }
    if(Profile_Type == AskBidProfile || Profile_Type==DeltaProfile)
    {
          time_s  = ArrayBsearch(LastTime,last_Start_time);
          total_name = "VPLine_P" + "_TOTALA_"+ (string)LastTime[time_s]+"_"+HASH_IND; 
          ObjectCreate(0,total_name,OBJ_TEXT,0,LastTime[time_s],prices[ArraySize(prices)-1]+_Point*5+forexshift*_Point);        
          ObjectSetInteger(0,total_name,OBJPROP_FONTSIZE,Font_Size);
          ObjectSetString(0,total_name,OBJPROP_FONT,"Arial");
          ObjectSetString(0,total_name,OBJPROP_TEXT,IntegerToString((int)total_ask));
          ObjectSetInteger(0,total_name,OBJPROP_COLOR,AskColor_AskBidProfile);            
          ObjectSetInteger(0,total_name,OBJPROP_TIME,LastTime[time_s]);          
          ObjectSetDouble(0,total_name,OBJPROP_PRICE,prices[ArraySize(prices)-1]+_Point*5+forexshift*_Point);                
          ObjectSetInteger(0,total_name,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);          
          ObjectSetInteger(0,total_name,OBJPROP_ALIGN,ALIGN_LEFT);
          ObjectSetInteger(0,total_name,OBJPROP_READONLY,1);          
          
          total_name = "VPLine_P" + "_TOTALB_"+ (string)LastTime[time_s]+"_"+HASH_IND; 
          ObjectCreate(0,total_name,OBJ_TEXT,0,LastTime[time_s],prices[0]-_Point*2+forexshift*_Point);
          ObjectSetInteger(0,total_name,OBJPROP_FONTSIZE,Font_Size);
          ObjectSetString(0,total_name,OBJPROP_FONT,"Arial");
          ObjectSetString(0,total_name,OBJPROP_TEXT,IntegerToString((int)total_bid));
          ObjectSetInteger(0,total_name,OBJPROP_COLOR,BidColor_AskBidProfile);            
          ObjectSetInteger(0,total_name,OBJPROP_TIME,LastTime[time_s]);          
          ObjectSetDouble(0,total_name,OBJPROP_PRICE,prices[0]-_Point*2+forexshift*_Point);
          ObjectSetInteger(0,total_name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
          ObjectSetInteger(0,total_name,OBJPROP_ALIGN,ALIGN_LEFT);
          ObjectSetInteger(0,total_name,OBJPROP_READONLY,1);          
    }
    
} // Profile_Position=0

if (Profile_Position == 1)
{
    if(Profile_Type == VolumeProfile)
    {
    
          
          total_name = "VPLine_P" + "_TOTALV_"+"_"+HASH_IND; 
          ObjectCreate(0,total_name,OBJ_TEXT,0,LastTime[NumberRates-WindowFirstVisibleBar()-1],prices[0]-_Point*2+forexshift*_Point);        
          ObjectSetInteger(0,total_name,OBJPROP_FONTSIZE,Font_Size);
          ObjectSetString(0,total_name,OBJPROP_FONT,"Arial");

          ObjectSetString(0,total_name,OBJPROP_TEXT," "+IntegerToString((int)total_volume));
          ObjectSetInteger(0,total_name,OBJPROP_COLOR,VolumeLine_Max_Volume);            
          ObjectSetInteger(0,total_name,OBJPROP_TIME,LastTime[NumberRates-WindowFirstVisibleBar()-1]);          
          ObjectSetDouble(0,total_name,OBJPROP_PRICE,prices[0]-_Point*2+forexshift*_Point);      
          ObjectSetInteger(0,total_name,OBJPROP_ALIGN,ALIGN_LEFT);
          ObjectSetInteger(0,total_name,OBJPROP_READONLY,1);
          ObjectSetInteger(0,total_name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);          
          
       
    }
    if(Profile_Type == AskBidProfile || Profile_Type==DeltaProfile)
    {

          total_name = "VPLine_P" + "_TOTALA_"+"_"+HASH_IND; 
          ObjectCreate(0,total_name,OBJ_TEXT,0,LastTime[NumberRates-WindowFirstVisibleBar()-1]+shift_vp1,prices[ArraySize(prices)-1]+_Point*5+forexshift*_Point);        
          ObjectSetInteger(0,total_name,OBJPROP_FONTSIZE,Font_Size);
          ObjectSetString(0,total_name,OBJPROP_FONT,"Arial");
          ObjectSetString(0,total_name,OBJPROP_TEXT,IntegerToString((int)total_ask));
          ObjectSetInteger(0,total_name,OBJPROP_COLOR,AskColor_AskBidProfile);            
          ObjectSetInteger(0,total_name,OBJPROP_TIME,LastTime[NumberRates-WindowFirstVisibleBar()-1]+shift_vp1);
          ObjectSetDouble(0,total_name,OBJPROP_PRICE,prices[ArraySize(prices)-1]+_Point*5+forexshift*_Point);                
          ObjectSetInteger(0,total_name,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);          
          ObjectSetInteger(0,total_name,OBJPROP_ALIGN,ALIGN_LEFT);
          ObjectSetInteger(0,total_name,OBJPROP_READONLY,1);          
         

          total_name = "VPLine_P" + "_TOTALB_"+"_"+HASH_IND; 
          ObjectCreate(0,total_name,OBJ_TEXT,0,LastTime[NumberRates-WindowFirstVisibleBar()-1]+shift_vp1,prices[0]-_Point*2+forexshift*_Point);
          ObjectSetInteger(0,total_name,OBJPROP_FONTSIZE,Font_Size);
          ObjectSetString(0,total_name,OBJPROP_FONT,"Arial");
          ObjectSetString(0,total_name,OBJPROP_TEXT,IntegerToString((int)total_bid));
          ObjectSetInteger(0,total_name,OBJPROP_COLOR,BidColor_AskBidProfile);            
          ObjectSetInteger(0,total_name,OBJPROP_TIME,LastTime[NumberRates-WindowFirstVisibleBar()-1]+shift_vp1);          
          ObjectSetDouble(0,total_name,OBJPROP_PRICE,prices[0]-_Point*2+forexshift*_Point);
          ObjectSetInteger(0,total_name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
          ObjectSetInteger(0,total_name,OBJPROP_ALIGN,ALIGN_LEFT);
          ObjectSetInteger(0,total_name,OBJPROP_READONLY,1);          
    }

} // Profile_position=1

if (Profile_Position == 2)
{
    if(Profile_Type == VolumeProfile)
    {
    
          
          total_name = "VPLine_P" + "_TOTALV_"+"_"+HASH_IND; 
          
          ObjectCreate(0,total_name,OBJ_TEXT,0,last_date,prices[0]-_Point*2+forexshift*_Point);        
          ObjectSetInteger(0,total_name,OBJPROP_FONTSIZE,Font_Size);
          ObjectSetString(0,total_name,OBJPROP_FONT,"Arial");

          ObjectSetString(0,total_name,OBJPROP_TEXT,IntegerToString((int)total_volume)+"   ");
          ObjectSetInteger(0,total_name,OBJPROP_COLOR,VolumeLine_Max_Volume);            
          ObjectSetInteger(0,total_name,OBJPROP_TIME,last_date);          
          ObjectSetDouble(0,total_name,OBJPROP_PRICE,prices[0]-_Point*2+forexshift*_Point);      
          ObjectSetInteger(0,total_name,OBJPROP_ALIGN,ALIGN_LEFT);
          ObjectSetInteger(0,total_name,OBJPROP_READONLY,1);
          ObjectSetInteger(0,total_name,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);          
       
    }
    if(Profile_Type == AskBidProfile || Profile_Type==DeltaProfile)
    {

          total_name = "VPLine_P" + "_TOTALA_"+"_"+HASH_IND; 
          ObjectCreate(0,total_name,OBJ_TEXT,0,last_date-shift_vp,prices[ArraySize(prices)-1]+_Point*5+forexshift*_Point);        
          ObjectSetInteger(0,total_name,OBJPROP_FONTSIZE,Font_Size);
          ObjectSetString(0,total_name,OBJPROP_FONT,"Arial");
          ObjectSetString(0,total_name,OBJPROP_TEXT,IntegerToString((int)total_ask));
          ObjectSetInteger(0,total_name,OBJPROP_COLOR,AskColor_AskBidProfile);            
          ObjectSetInteger(0,total_name,OBJPROP_TIME,last_date-shift_vp);
          ObjectSetDouble(0,total_name,OBJPROP_PRICE,prices[ArraySize(prices)-1]+_Point*5+forexshift*_Point);                
          ObjectSetInteger(0,total_name,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);          
          ObjectSetInteger(0,total_name,OBJPROP_ALIGN,ALIGN_LEFT);
          ObjectSetInteger(0,total_name,OBJPROP_READONLY,1);          
          
          total_name = "VPLine_P" + "_TOTALB_"+"_"+HASH_IND; 
          ObjectCreate(0,total_name,OBJ_TEXT,0,last_date-shift_vp,prices[0]-_Point*2+forexshift*_Point);
          ObjectSetInteger(0,total_name,OBJPROP_FONTSIZE,Font_Size);
          ObjectSetString(0,total_name,OBJPROP_FONT,"Arial");
          ObjectSetString(0,total_name,OBJPROP_TEXT,IntegerToString((int)total_bid));
          ObjectSetInteger(0,total_name,OBJPROP_COLOR,BidColor_AskBidProfile);            
          ObjectSetInteger(0,total_name,OBJPROP_TIME,last_date-shift_vp);          
          ObjectSetDouble(0,total_name,OBJPROP_PRICE,prices[0]-_Point*2+forexshift*_Point);
          ObjectSetInteger(0,total_name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
          ObjectSetInteger(0,total_name,OBJPROP_ALIGN,ALIGN_LEFT);
          ObjectSetInteger(0,total_name,OBJPROP_READONLY,1);          
       
    }
    
}



} // Show_Sum_Value

}

void DrawVPLine(double mypr, double mynext_price, datetime mydrawtime, datetime mydrawrange, double myvol, double mymaxvol, double Val, double Vah, datetime mylastdate)
{  
   int showvol=(int)myvol;
   int forexshift=Forex_shift;
   if (Forex_auto_shift) forexshift=forex_shift_auto;
   
   double myprice = mypr+forexshift*_Point;
   string rec_name="VPLine_P"+DoubleToString(mypr)+"_vp"+""+DoubleToString(mydrawtime,0)+"_"+HASH_IND;
   if (Profile_Position>0 || (Profile_Period==0))
   {
     rec_name="VPLine_P"+DoubleToString(mypr)+"_"+HASH_IND;
   }
   //ObjectCreate(rec_name,OBJ_RECTANGLE,0,mydrawtime,myprice,mydrawrange,mynext_price);
   ObjectGetInteger(0,rec_name,OBJPROP_COLOR);// 
   int Error=GetLastError();               // Получение кода ошибки   
   if (Error!=4202) { ObjectDelete(0,rec_name);  }
   
   ObjectCreate(0,rec_name,OBJ_TREND,0,mydrawtime,myprice,mydrawrange,myprice);
   ObjectSetInteger(0,rec_name,OBJPROP_RAY, false);
   
   if ( (myvol*1.0 / mymaxvol) >= Max_Volume_k)
   {
     ObjectSetInteger(0,rec_name,OBJPROP_COLOR,VolumeLine_Max_Volume); 
/*     if (Draw_POC_Continious == true)
     {
       ObjectSet(rec_name,OBJPROP_TIME2,mylastdate);
       ObjectSet(rec_name,OBJPROP_STYLE,Continious_line_style);
     
     }*/
   } else
   {
       color newcolor = VolumeLine_VolumeProfile_Color;
       //ObjectSetInteger(0,rec_name,OBJPROP_COLOR,newcolor);      
       if (((Val+forexshift*_Point) <= myprice) && (myprice <= (Vah+forexshift*_Point)))
       { 
         // inside VA
         ObjectSetInteger(0,rec_name,OBJPROP_COLOR,VolumeLine_VolumeArea_Color);      
       } else
       {
         ObjectSetInteger(0,rec_name,OBJPROP_COLOR,VolumeLine_VolumeProfile_Color); 
       }
       
   }
   if(LineColor_Width<1 || LineColor_Width>3) { LineColor_Width=1; }
   ObjectSetInteger(0,rec_name,OBJPROP_WIDTH,LineColor_Width); 
   ObjectSetInteger(0,rec_name,OBJPROP_BACK,Draw_as_Background);
   ObjectSetString(0,rec_name, OBJPROP_TEXT, "Price: "+DoubleToString(NormalizeDouble(myprice,_Digits),_Digits)+"\nVolume: "+DoubleToString(showvol,0)+"\nWeight: "+DoubleToString(showvol*100.0/mymaxvol,2)+"%");
   ObjectSetInteger(0,rec_name,OBJPROP_SELECTABLE,false);       
   ObjectSetInteger(0,rec_name,OBJPROP_TIMEFRAMES,Custom_Timeframe);
   
      if ( (myvol*1.0 / mymaxvol) == 1 && Print_Max_Volume)
      {
        rec_name = "VPLine_P" + "_MAX_"+ DoubleToString(mydrawtime,0)+"_"+HASH_IND;
         if (Profile_Position>0 || (Profile_Period==0))
         {
           rec_name="VPLine_P" + "_MAX_"+"_"+HASH_IND;
         }
        
//        if(Profile_Position == 0)
//        {
          //ObjectCreate(rec_name,OBJ_ARROW_RIGHT_PRICE,0,mydrawrange,myprice);        
          ObjectCreate(0,rec_name,OBJ_TEXT,0,mydrawrange,myprice);        
          ObjectSetString(0,rec_name,OBJPROP_TEXT,DoubleToString(mymaxvol ,0));
          ObjectSetString(0,rec_name,OBJPROP_FONT,"Arial");
          ObjectSetInteger(0,rec_name,OBJPROP_FONTSIZE,Font_Size);
          ObjectSetInteger(0,rec_name,OBJPROP_COLOR,VolumeLine_Max_Volume);            
      }
}
int DrawABPLine(double mypr, double mynext_price, datetime mydrawtime, datetime mydrawrange, double myval, double myaskdel,double mybiddel, datetime mylastdate, string t,  color BidColor, color AskColor)
{  
   int showvol=(int)myval;
   int forexshift=Forex_shift;
   if (Forex_auto_shift) forexshift=forex_shift_auto;
   double myprice = mypr+forexshift*_Point;

   string rec_name="VPLine_P"+DoubleToString(myprice)+"_"+t+IntegerToString(Save_Amount_Of_Profiles)+""+DoubleToString(mydrawtime,0)+"_hash"+HASH_IND;
   if (Profile_Position>0)
   {
     rec_name="VPLine_P"+DoubleToString(myprice)+t+"_hash"+HASH_IND;
   }

   ObjectGetInteger(0,rec_name,OBJPROP_COLOR);// 
   int Error=GetLastError();               // Получение кода ошибки   
   if (Error!=4202) { ObjectDelete(0,rec_name);  }
   if(myaskdel==0) myaskdel=1;
   if(mybiddel==0) mybiddel=1;
   ObjectCreate(0,rec_name,OBJ_TREND,0,mydrawtime,myprice,mydrawrange,myprice);
   ObjectSetInteger(0,rec_name,OBJPROP_RAY, false);
   if(t == "bid") 
   {
      ObjectSetInteger(0,rec_name,OBJPROP_COLOR,BidColor); 
      ObjectSetInteger(0,rec_name,OBJPROP_WIDTH,LineColor_Width);
      if(Profile_Type == AskBidProfile) { ObjectSetString(0,rec_name, OBJPROP_TEXT,"Price: "+DoubleToString(NormalizeDouble(myprice,_Digits),_Digits)+"\nBid: "+DoubleToString(-MathAbs(showvol))+"\nWeight: "+DoubleToString(MathAbs((showvol)*100.0/mybiddel),2)+"%"); }
      if(Profile_Type == DeltaProfile) { ObjectSetString(0,rec_name, OBJPROP_TEXT, "Price: "+DoubleToString(NormalizeDouble(myprice,_Digits),_Digits)+"\nDelta-: "+DoubleToString(-MathAbs(showvol))+"\nWeight: "+DoubleToString(MathAbs((showvol)*100.0/mybiddel),2)+"%"); }      
   } else
   {
      ObjectSetInteger(0,rec_name,OBJPROP_COLOR,AskColor); 
      ObjectSetInteger(0,rec_name,OBJPROP_WIDTH,LineColor_Width);
      if(Profile_Type == AskBidProfile) { ObjectSetString(0,rec_name,  OBJPROP_TEXT,"Price: "+DoubleToString(NormalizeDouble(myprice,_Digits),_Digits)+"\nAsk: "+DoubleToString(MathAbs(showvol))+"\nWeight: "+DoubleToString(MathAbs((-showvol)*100.0/myaskdel),2)+"%");       }
      if(Profile_Type == DeltaProfile) { ObjectSetString(0,rec_name,  OBJPROP_TEXT,"Price: "+DoubleToString(NormalizeDouble(myprice,_Digits),_Digits)+"\nDelta+: "+DoubleToString(MathAbs(showvol))+"\nWeight: "+DoubleToString(MathAbs((-showvol)*100.0/myaskdel),2)+"%");       }      
      
   }
   
   ObjectSetInteger(0,rec_name,OBJPROP_BACK,Draw_as_Background);
   ObjectSetInteger(0,rec_name,OBJPROP_SELECTABLE,false);       
   ObjectSetInteger(0,rec_name,OBJPROP_TIMEFRAMES,Custom_Timeframe);

   return 0;   
}

int check_VA(double& val,double& vah, double max_volume_price,double max_volume_index,double &ps[], double &vol[])
{
  int i=0;
  double total_volume=0;
  double deviation_volume=0;
  double calculate=0;
  double v_above=0, v_bellow=0;
  int i_above=ArraySize(vol)-1; 
  int i_bellow=0;
  
  for (i=0; i<ArraySize(vol); i++)
  {
    total_volume=total_volume + vol[i];
  }
  
  deviation_volume = 0.318 * total_volume;

  while(calculate < deviation_volume)
  {
     vah=ps[i_above];
     val=ps[i_bellow];                   
     if (v_above <= v_bellow)
     {
       v_above = v_above + vol[i_above];
       i_above--;
       
     }  else
     {
       v_bellow = v_bellow + vol[i_bellow];
       
       i_bellow++;
       
     }
     calculate = v_above+v_bellow;
  }

  return (0);
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

int ConvertResponseToArrays(string &st, double& td[],double& askd[],double& bidd[], string de1, string de2, string& msg, datetime& Server_StartTime, datetime& Server_StopTime) { 
{ 

  int    i=0, np, dp, dp3;
  string stp,dtp,dtv,mAsk,mBid;
  //datetime indexx;

  ArrayResize(td, 0);
  ArrayResize(askd, 0);
  ArrayResize(bidd, 0);  
  
  np=StringFind(st, de1);
  

  if(np>0)
  {
      stp=StringSubstr(st, 0, np);
      msg=stp;
      st=StringSubstr(st, np+1);
  }
  np=StringFind(st, de1);
  if(np>0)
  {
      stp=StringSubstr(st, 0, np); 
      
      dp=StringFind(stp, de2);
      dtp=StringSubstr(stp,0,dp);
      //mmin_price=StrToDouble(dtp); 
      stp=StringSubstr(stp, dp+1);
      dp=StringFind(stp, de2);
      dtp=StringSubstr(stp,0,dp);
      Server_StartTime=StringToTime(dtp); 
      dtp=StringSubstr(stp, dp+1);
      Server_StopTime=StringToTime(dtp); 
      st=StringSubstr(st, np+1);
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
    
//    Print(stp);
    if(StringSubstr(stp,0,4) == "#end") { break; }
    dp=StringFind(stp, de2);
    if(dp<0)
    {
      // неправильный формат или хз что
      dtp="0";
      mAsk="0";      
      mBid="0";

    } else 
    {
      dtp=StringSubstr(stp, 0, dp);
      dtv=StringSubstr(stp, dp+1);
      //Print("stp=",stp,"dp=",dp," dtp=",dtp," dtv=",dtv);
      dp3=StringFind(dtv,de2);     
      if(dp3<0)
      {
         dtp="0";mAsk="0";mBid="0";
      } else {
         mAsk=StringSubstr(dtv, 0,dp3);
         mBid=StringSubstr(dtv,dp3+1);
      }

    }
    
    
    ArrayResize(td, i+1);
    ArrayResize(askd, i+1);
    ArrayResize(bidd, i+1);
    
    td[i]= StringToDouble(dtp);
    askd[i]= StringToDouble(mAsk);
    bidd[i]= StringToDouble(mBid)*(ReverseChart_SET ? -1: 1);
    i++;    
    }
  }
  return(ArraySize(td));

}

void SortDictionary(double &keys[], double &values[],  double &values2[])
{
   double keyCopy[];
   double valueCopy[];
   double value2Copy[];
   ArrayCopy(keyCopy, keys);
   ArrayCopy(valueCopy, values);
   ArrayCopy(value2Copy, values2);
   ArraySort(keys);
   for (int i = 0; i < MathMin(ArraySize(keys), ArraySize(values)); i++)
   {
      //values[i] = valueCopy[ArrayBsearch(keyCopy, keys[i])];
      values[ArrayBsearch(keys, keyCopy[i])] = valueCopy[i];
      values2[ArrayBsearch(keys, keyCopy[i])] = value2Copy[i];      
   }
}

void ReversePrices(double &keys[],bool no_reverse=false,int multiple=1)
{
  for (int i = 0; i < ArraySize(keys); i++)
  {
     if (no_reverse == false)
     {
       keys[i] = NormalizeDouble(1/keys[i],_Digits);
     }
     keys[i] = multiple * keys[i];
  }
}

double get_forex_shift()
{
  double forex_shift_low=0;
  double forex_shift_high=0;
  double forex_auto=0;
  if (ArraySize(LastTime) == 0) return 0;
  
  int futuresminimum = ArrayMinimum(PriceData);
  int futuresmaximum = ArrayMaximum(PriceData);
  double minprice=PriceData[futuresminimum];
  double maxprice=PriceData[futuresmaximum];

  
  double futures_minimum = minprice; //(ReverseChart_SET ? 1/(minprice) : (minprice))*PriceMultiplier;
  double futures_maximum = maxprice; //(ReverseChart_SET ? 1/(maxprice) : (maxprice))*PriceMultiplier;
  
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
  forex_auto = forex_shift_low;
  if (forex_maximum > /* MT5 */ forex_minimum) forex_auto = forex_shift_high;
  return forex_auto;

}

bool ButtonCreate(const long              chart_ID=0,// ID графика 
                  string                  name="Button",// имя кнопки 
                  const int               sub_window=0,// номер подокна 
                  const int               xx=0,                      // координата по оси X 
                  const int               yy=0,                      // координата по оси Y 
                  const int               width=50,                 // ширина кнопки 
                  const int               height=18,                // высота кнопки 
                  const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // угол графика для привязки 
                  const string            text="Button",            // текст 
                  const string            font="Arial",             // шрифт 
                  const int               font_size=10,             // размер шрифта 
                  const color             clr=clrBlack,             // цвет текста 
                  const color             active_clr=C'236,233,216',  // цвет фона 
                  const color             inactive_clr=C'236,233,216',  // цвет фона                   
                  const color             border_clr=clrNONE,       // цвет границы 
                  const bool              state=false,              // нажата/отжата 
                  const bool              back=false,               // на заднем плане 
                  const bool              selection=false,          // выделить для перемещений 
                  const bool              hidden=true,              // скрыт в списке объектов 
                  const long              z_order=0,                // приоритет на нажатие мышью 
                  const string            toltip="") 
  { 
   ResetLastError(); 
   if(ObjectCreate(chart_ID,name,OBJ_BUTTON,sub_window,0,0)) 
     { 
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);     //--- включим (true) или отключим (false) режим перемещения кнопки мышью 
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
      ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner); 
      ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);//--- установим угол графика, относительно которого будут определяться координаты точки 
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);                //--- установим цвет текста       
     } 
   if (state)
   {
      ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,active_clr);         //--- установим цвет фона 
   } else { ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,inactive_clr); }
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,Information_Corner);
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,xx); 
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,yy); 
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);              //--- установим размер кнопки 
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height); 
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);                 //--- установим текст 
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);                 //--- установим шрифт текста 
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);       //--- установим размер шрифта 
   ObjectSetInteger(chart_ID,name,OBJPROP_STATE,state);       
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,false);                //--- отобразим на переднем (false) или заднем (true) плане 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,false);            //--- скроем (true) или отобразим (false) имя графического объекта в списке объектов 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);           //--- установим приоритет на получение события нажатия мыши на графике 
   ObjectSetString(chart_ID,name,OBJPROP_TOOLTIP,toltip);                 //--- установим текст    
   return(true); 
}  
