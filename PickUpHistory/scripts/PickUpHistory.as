package
{
   import Shared.*;
   import Shared.AS3.*;
   import Shared.AS3.Data.*;
   import Shared.AS3.Events.*;
   import com.adobe.serialization.json.*;
   import fl.motion.*;
   import flash.display.*;
   import flash.events.*;
   import flash.filters.*;
   import flash.geom.*;
   import flash.net.*;
   import flash.system.*;
   import flash.text.*;
   import flash.ui.*;
   import flash.utils.*;
   import scaleform.gfx.*;
   import utils.*;
   
   public class PickUpHistory extends MovieClip
   {
      
      public static const MOD_NAME:String = "PickUpHistory";
      
      public static const MOD_VERSION:String = "1.0.2";
      
      public static const FULL_MOD_NAME:String = MOD_NAME + " " + MOD_VERSION;
      
      public static const CONFIG_FILE:String = "../PickUpHistoryConfig.json";
      
      public static const CONFIG_RELOAD_TIME:uint = 5500;
      
      private static const TITLE_HUDMENU:String = "HUDMenu";
      
      private static const HUDTOOLS_MENU_HIDE:String = MOD_NAME + "_HIDE";
      
      private static const HUDTOOLS_MENU_RESET_HISTORY:String = MOD_NAME + "_RESET_HISTORY";
      
      private static const HUDTOOLS_MENU_INCREASE_COUNTER:String = MOD_NAME + "_INCREASE_COUNTER";
      
      private static const HUDTOOLS_MENU_INCREASE_1:String = MOD_NAME + "_INCREASE_1";
      
      private static const HUDTOOLS_MENU_INCREASE_5:String = MOD_NAME + "_INCREASE_5";
      
      private static const HUDTOOLS_MENU_INCREASE_25:String = MOD_NAME + "_INCREASE_25";
      
      private static const HUDTOOLS_MENU_INCREASE_100:String = MOD_NAME + "_INCREASE_100";
      
      private static const HUDTOOLS_MENU_INCREASE_250:String = MOD_NAME + "_INCREASE_250";
      
      private static const HUDTOOLS_MENU_DECREASE_COUNTER:String = MOD_NAME + "_DECREASE_COUNTER";
      
      private static const HUDTOOLS_MENU_DECREASE_1:String = MOD_NAME + "_DECREASE_1";
      
      private static const HUDTOOLS_MENU_DECREASE_5:String = MOD_NAME + "_DECREASE_5";
      
      private static const HUDTOOLS_MENU_DECREASE_25:String = MOD_NAME + "_DECREASE_25";
      
      private static const HUDTOOLS_MENU_DECREASE_100:String = MOD_NAME + "_DECREASE_100";
      
      private static const HUDTOOLS_MENU_DECREASE_250:String = MOD_NAME + "_DECREASE_250";
      
      private static const STRING_PICKED_UP_COUNT:String = "{pickedUpCount}";
      
      private static const STRING_LAST_ITEM_NAME:String = "{lastPickedUpItemName}";
      
      private static const STRING_LAST_ITEM_COUNT:String = "{lastPickedUpItemCount}";
      
      private var topLevel:* = null;
      
      private var display_tf:TextField;
      
      private var displayText:String = FULL_MOD_NAME;
      
      private var configTimer:Timer;
      
      private var lastConfig:String;
      
      private var lastConfigUpdateTime:Number = 0;
      
      private var lastProcessingTime:Number = 0;
      
      private var forceHide:Boolean = false;
      
      private var hudTools:SharedHUDTools;
      
      private var HUDModeData:*;
      
      private var PlayerInventoryData:*;
      
      private var invMap:Dictionary = new Dictionary();
      
      private var pickUpHistory:int = 0;
      
      private var hudMode:String = "";
      
      private var previousHudMode:String = "";
      
      private var lastStashModeTimestamp:Number = 0;
      
      private var lastContainerName:String = "";
      
      public function PickUpHistory()
      {
         super();
         addEventListener(Event.ADDED_TO_STAGE,this.addedToStageHandler,false,0,true);
      }
      
      public static function toString(param1:Object) : String
      {
         return new JSONEncoder(param1).getString();
      }
      
      public static function ShowHUDMessage(param1:String) : void
      {
         GlobalFunc.ShowHUDMessage("[" + FULL_MOD_NAME + "] " + param1);
      }
      
      public function addedToStageHandler(param1:Event) : *
      {
         removeEventListener(Event.ADDED_TO_STAGE,this.addedToStageHandler);
         addEventListener(Event.REMOVED_FROM_STAGE,this.removedFromStageHandler,false,0,true);
         this.topLevel = stage.getChildAt(0);
         if(Boolean(this.topLevel))
         {
            if(getQualifiedClassName(this.topLevel) == TITLE_HUDMENU)
            {
               this.hudTools = new SharedHUDTools(MOD_NAME);
               this.hudTools.RegisterMenu(this.onBuildMenu,this.onSelectMenu);
               this.HUDModeData = BSUIDataManager.GetDataFromClient("HUDModeData");
               this.PlayerInventoryData = BSUIDataManager.GetDataFromClient("PlayerInventoryData");
               BSUIDataManager.Subscribe("HUDModeData",this.updateVisibility);
               BSUIDataManager.Subscribe("PlayerInventoryData",this.updateInventory);
               this.initConfigTimer();
            }
            else
            {
               ShowHUDMessage("Error: mod must be loaded by HUDMenu!");
            }
         }
         else
         {
            ShowHUDMessage("Not added to stage: " + getQualifiedClassName(this.topLevel));
         }
      }
      
      public function removedFromStageHandler(param1:Event) : *
      {
         removeEventListener(Event.REMOVED_FROM_STAGE,this.removedFromStageHandler);
         BSUIDataManager.Unsubscribe("HUDModeData",this.updateVisibility);
         BSUIDataManager.Unsubscribe("PlayerInventoryData",this.updateInventory);
         if(this.configTimer)
         {
            this.configTimer.removeEventListener(TimerEvent.TIMER,this.loadConfig);
         }
         if(this.hudtools)
         {
            this.hudtools.Shutdown();
         }
      }
      
      public function initConfigTimer() : void
      {
         this.configTimer = new Timer(CONFIG_RELOAD_TIME);
         this.configTimer.addEventListener(TimerEvent.TIMER,this.loadConfig,false,0,true);
         this.configTimer.start();
      }
      
      public function onBuildMenu(parentItem:String = null) : *
      {
         try
         {
            if(parentItem == MOD_NAME)
            {
               if(false)
               {
                  this.hudTools.AddMenuItem(HUDTOOLS_MENU_DECREASE_COUNTER,"Decrease counter",true,true,250);
                  this.hudTools.AddMenuItem(HUDTOOLS_MENU_INCREASE_COUNTER,"Increase counter",true,true,250);
               }
               this.hudTools.AddMenuItem(HUDTOOLS_MENU_RESET_HISTORY,"Reset counter",true,false,250);
               this.hudTools.AddMenuItem(HUDTOOLS_MENU_HIDE,"Force Hide",true,false,250);
            }
            else if(parentItem == HUDTOOLS_MENU_INCREASE_COUNTER)
            {
               this.hudTools.AddMenuItem(HUDTOOLS_MENU_INCREASE_1,"+1",true,false,250);
               this.hudTools.AddMenuItem(HUDTOOLS_MENU_INCREASE_5,"+5",true,false,250);
               this.hudTools.AddMenuItem(HUDTOOLS_MENU_INCREASE_25,"+25",true,false,250);
               this.hudTools.AddMenuItem(HUDTOOLS_MENU_INCREASE_100,"+100",true,false,250);
               this.hudTools.AddMenuItem(HUDTOOLS_MENU_INCREASE_250,"+250",true,false,250);
            }
            else if(parentItem == HUDTOOLS_MENU_DECREASE_COUNTER)
            {
               this.hudTools.AddMenuItem(HUDTOOLS_MENU_DECREASE_1,"-1",true,false,250);
               this.hudTools.AddMenuItem(HUDTOOLS_MENU_DECREASE_5,"-5",true,false,250);
               this.hudTools.AddMenuItem(HUDTOOLS_MENU_DECREASE_25,"-25",true,false,250);
               this.hudTools.AddMenuItem(HUDTOOLS_MENU_DECREASE_100,"-100",true,false,250);
               this.hudTools.AddMenuItem(HUDTOOLS_MENU_DECREASE_250,"-250",true,false,250);
            }
         }
         catch(e:Error)
         {
         }
      }
      
      public function onSelectMenu(selectItem:String) : *
      {
         var increment:int = 0;
         try
         {
            if(selectItem == HUDTOOLS_MENU_HIDE)
            {
               this.forceHide = !this.forceHide;
               this.updateVisibility(this.HUDModeData);
            }
            else if(selectItem == HUDTOOLS_MENU_RESET_HISTORY)
            {
               increment = -this.pickUpHistory;
            }
            else if(selectItem == HUDTOOLS_MENU_INCREASE_1)
            {
               increment = 1;
            }
            else if(selectItem == HUDTOOLS_MENU_INCREASE_5)
            {
               increment = 5;
            }
            else if(selectItem == HUDTOOLS_MENU_INCREASE_25)
            {
               increment = 25;
            }
            else if(selectItem == HUDTOOLS_MENU_INCREASE_100)
            {
               increment = 100;
            }
            else if(selectItem == HUDTOOLS_MENU_INCREASE_250)
            {
               increment = 250;
            }
            else if(selectItem == HUDTOOLS_MENU_DECREASE_1)
            {
               increment = -1;
            }
            else if(selectItem == HUDTOOLS_MENU_DECREASE_5)
            {
               increment = -5;
            }
            else if(selectItem == HUDTOOLS_MENU_DECREASE_25)
            {
               increment = -25;
            }
            else if(selectItem == HUDTOOLS_MENU_DECREASE_100)
            {
               increment = -100;
            }
            else if(selectItem == HUDTOOLS_MENU_DECREASE_250)
            {
               increment = -250;
            }
            if(increment != 0)
            {
               this.pickUpHistory += increment;
               this.updateInventory(this.PlayerInventoryData);
            }
         }
         catch(e:Error)
         {
         }
      }
      
      public function loadConfig() : void
      {
         var loaderComplete:Function;
         var ioErrorHandler:Function;
         var url:URLRequest = null;
         var loader:URLLoader = null;
         try
         {
            loaderComplete = function(param1:Event):void
            {
               var jsonData:Object;
               var line:uint;
               try
               {
                  if(lastConfig != loader.data)
                  {
                     jsonData = new JSONDecoder(loader.data,false).getValue();
                     PickUpHistoryConfig.init(jsonData);
                     initTextField();
                     lastConfigUpdateTime = getTimer();
                     lastConfig = loader.data;
                  }
               }
               catch(e:JSONParseError)
               {
                  line = e.text.substr(0,e.location).match(/\n/g).length + 1;
                  ShowHUDMessage("Error parsing config: " + e.message + " in line " + line);
               }
               catch(e:Error)
               {
                  ShowHUDMessage("Error initializing config: " + e);
               }
            };
            ioErrorHandler = function(e:IOErrorEvent):void
            {
               ShowHUDMessage("Error loading config: " + e.text);
            };
            url = new URLRequest(CONFIG_FILE);
            loader = new URLLoader();
            loader.load(url);
            loader.addEventListener(Event.COMPLETE,loaderComplete,false,0,true);
            loader.addEventListener(IOErrorEvent.IO_ERROR,ioErrorHandler,false,0,true);
         }
         catch(e:Error)
         {
            ShowHUDMessage("Error loading config: " + e);
         }
      }
      
      private function initTextField() : void
      {
         if(!this.display_tf)
         {
            this.display_tf = new TextField();
            this.display_tf.text = this.displayText;
            addChild(this.display_tf);
         }
         this.display_tf.x = config.x;
         this.display_tf.y = config.y;
         this.display_tf.width = config.width;
         this.display_tf.background = config.background;
         this.display_tf.backgroundColor = config.backgroundColor;
         TextFieldEx.setTextAutoSize(this.display_tf,TextFieldEx.TEXTAUTOSZ_SHRINK);
         this.display_tf.autoSize = config.textAlign;
         this.display_tf.wordWrap = false;
         this.display_tf.multiline = true;
         this.display_tf.visible = true;
         var textFormat:TextFormat = new TextFormat(config.textFont,config.textSize,config.textColor);
         textFormat.align = config.textAlign;
         this.display_tf.defaultTextFormat = textFormat;
         this.display_tf.setTextFormat(textFormat);
         this.display_tf.filters = config.textShadow ? [new DropShadowFilter(2,45,0,1,1,1,1,BitmapFilterQuality.HIGH)] : [];
         this.alpha = config.alpha;
         this.blendMode = config.blendMode;
         this.display_tf.blendMode = config.textBlendMode;
      }
      
      public function get isSFEDefined() : Boolean
      {
         return this.topLevel.__SFCodeObj != null && this.topLevel.__SFCodeObj.call != null;
      }
      
      public function get isReloadable() : Boolean
      {
         return true;
      }
      
      public function get config() : Object
      {
         return PickUpHistoryConfig.get();
      }
      
      public function get elapsedTime() : Number
      {
         return getTimer() / 1000;
      }
      
      public function get timeSinceLastConfigUpdate() : Number
      {
         return (getTimer() - this.lastConfigUpdateTime) / 1000;
      }
      
      public function get isInBookMenu() : Boolean
      {
         return Boolean(this.HUDModeData.data) && Boolean(this.HUDModeData.data.hudMode) && this.HUDModeData.data.hudMode == "BookMode";
      }
      
      public function get isInWorkbenchMenu() : Boolean
      {
         return Boolean(this.HUDModeData.data) && Boolean(this.HUDModeData.data.hudMode) && this.HUDModeData.data.hudMode == HUDModes.INSPECT_MODE;
      }
      
      public function get isInStashMenu() : Boolean
      {
         return Boolean(this.HUDModeData.data) && Boolean(this.HUDModeData.data.hudMode) && this.HUDModeData.data.hudMode == HUDModes.CONTAINER_MODE;
      }
      
      public function get isPreviousStashMenu() : Boolean
      {
         return getTimer() - this.lastStashModeTimestamp < 500;
      }
      
      public function get isInActivateMenu() : Boolean
      {
         return Boolean(this.HUDModeData.data) && Boolean(this.HUDModeData.data.hudMode) && this.HUDModeData.data.hudMode == HUDModes.ACTIVATE_TYPE;
      }
      
      public function get isInPipboyMenu() : Boolean
      {
         return Boolean(this.HUDModeData.data) && Boolean(this.HUDModeData.data.hudMode) && this.HUDModeData.data.hudMode == HUDModes.PIPBOY;
      }
      
      public function get containerName() : String
      {
         try
         {
            return this.topLevel.CenterGroup_mc.QuickContainerWidget_mc.ListHeaderAndBracket_mc.ContainerName_mc.textField_tf.text;
         }
         catch(error:*)
         {
         }
         return "";
      }
      
      public function get isQuickContainerVisible() : Boolean
      {
         try
         {
            return this.topLevel.CenterGroup_mc.QuickContainerWidget_mc.visible;
         }
         catch(error:*)
         {
         }
         return false;
      }
      
      public function updateVisibility(event:*) : void
      {
         try
         {
            if(this.hudMode != this.HUDModeData.data.hudMode)
            {
               if(this.previousHudMode == HUDModes.CONTAINER_MODE)
               {
                  this.lastStashModeTimestamp = getTimer();
               }
               this.previousHudMode = this.hudMode;
               this.hudMode = this.HUDModeData.data.hudMode;
            }
            if(this.hudMode != HUDModes.ACTIVATE_TYPE)
            {
               this.lastContainerName = "";
            }
            this.visible = !this.forceHide && this.isValidHUDMode();
            this.updateInventory(this.PlayerInventoryData);
         }
         catch(error:*)
         {
            ShowHUDMessage("Error updateVisibility: " + error);
         }
      }
      
      public function updateInventory(event:*) : void
      {
         var t1:Number;
         var inv:Array;
         var len:int;
         var isCountPickups:Boolean;
         var item:Object;
         var i:int;
         var debug:Boolean;
         var newContainerName:String;
         var isQCVisible:Boolean;
         var newItems:Array = [];
         try
         {
            if(event && event.data && event.data.InventoryList)
            {
               t1 = Number(getTimer());
               inv = event.data.InventoryList;
               len = inv.length;
               debug = Boolean(config) && Boolean(config.debug);
               isCountPickups = t1 > 30000;
               if(isCountPickups && (this.isInPipboyMenu || this.isInWorkbenchMenu || this.isInStashMenu || this.isPreviousStashMenu || this.isInBookMenu))
               {
                  isCountPickups = false;
               }
               i = 0;
               if(!isCountPickups)
               {
                  while(i < len)
                  {
                     item = inv[i];
                     if(!this.invMap[item.serverHandleID] || this.invMap[item.serverHandleID] < item.count)
                     {
                        this.invMap[item.serverHandleID] = item.count;
                     }
                     i++;
                  }
               }
               else
               {
                  newContainerName = this.containerName;
                  isQCVisible = this.isQuickContainerVisible;
                  while(i < len)
                  {
                     item = inv[i];
                     if(!this.invMap[item.serverHandleID])
                     {
                        if(this.lastContainerName == "" || newContainerName != this.lastContainerName)
                        {
                           newItems.push({
                              "text":item.text,
                              "count":item.count
                           });
                           if(isQCVisible)
                           {
                              this.lastContainerName = newContainerName;
                           }
                        }
                        this.invMap[item.serverHandleID] = item.count;
                     }
                     else if(this.invMap[item.serverHandleID] < item.count)
                     {
                        if(this.lastContainerName == "" || newContainerName != this.lastContainerName)
                        {
                           newItems.push({
                              "text":item.text,
                              "count":item.count - this.invMap[item.serverHandleID]
                           });
                           if(isQCVisible)
                           {
                              this.lastContainerName = newContainerName;
                           }
                        }
                        this.invMap[item.serverHandleID] = item.count;
                     }
                     i++;
                  }
               }
               i = 0;
               while(i < newItems.length)
               {
                  if(config && ArrayUtils.indexOfCaseInsensitiveString(config.ignoreItemPickups,newItems[i].text) == -1)
                  {
                     ++this.pickUpHistory;
                     this.lastProcessingTime = getTimer() - t1;
                     this.displayText = config.format.replace(STRING_LAST_ITEM_NAME,newItems[i].text).replace(STRING_LAST_ITEM_COUNT,newItems[i].count);
                  }
                  i++;
               }
               this.display_tf.text = this.displayText.replace(STRING_PICKED_UP_COUNT,this.pickUpHistory);
               if(debug)
               {
                  this.display_tf.text += "\nProcessingTime: " + this.lastProcessingTime + "ms @" + int(this.elapsedTime) + "s\nisInActivateMenu: " + this.isInActivateMenu + "\nisInWorkbenchMenu: " + this.isInWorkbenchMenu + "\nisInStashMenu: " + this.isInStashMenu + "\nisPreviousStashMenu: " + this.isPreviousStashMenu + "\nhudMode: " + this.hudMode + "\npreviousHudMode: " + this.previousHudMode + "\ncontainerName: " + this.containerName + "\nlastContainerName: " + this.lastContainerName + "\nisQuickContainerVisible: " + this.isQuickContainerVisible + "\n";
               }
            }
         }
         catch(error:*)
         {
            ShowHUDMessage("Error updateInventory: " + error);
         }
      }
      
      public function isValidHUDMode() : Boolean
      {
         if(config)
         {
            if(config.HUDModesState == PickUpHistoryConfig.STATE_HIDDEN)
            {
               return config.HUDModes.indexOf(this.HUDModeData.data.hudMode) == -1;
            }
            return config.HUDModes.indexOf(this.HUDModeData.data.hudMode) != -1;
         }
         return true;
      }
   }
}

