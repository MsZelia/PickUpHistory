package
{
   import utils.*;
   
   public class PickUpHistoryConfig
   {
      
      private static var _config:Object;
      
      public static const STATE_HIDDEN:String = "hidden";
      
      public static const STATE_SHOWN:String = "shown";
      
      public static const DEFAULT_FORMAT:String = "{pickedUpCount} picked up | {lastPickedUpItemName} ({lastPickedUpItemCount})";
      
      public function PickUpHistoryConfig()
      {
         super();
      }
      
      public static function get() : Object
      {
         return _config;
      }
      
      public static function init(jsonObject:*) : Object
      {
         var config:* = jsonObject;
         config.x = Parser.parseNumber(config.x,0);
         config.y = Parser.parseNumber(config.y,0);
         config.width = Parser.parseNumber(config.width,0);
         config.textSize = Parser.parseNumber(config.textSize,18);
         config.textFont = Boolean(config.textFont) ? config.textFont : "$MAIN_Font";
         config.textAlign = Boolean(config.textAlign) ? config.textAlign.toLowerCase() : "left";
         config.textColor = Parser.parseNumber(config.textColor,16777215);
         config.textShadow = Parser.parseBoolean(config.textShadow,true);
         config.background = Parser.parseBoolean(config.background,false);
         config.backgroundColor = Parser.parseNumber(config.backgroundColor,2236962);
         config.alpha = Parser.parseNumber(config.alpha,1);
         config.blendMode = Boolean(config.blendMode) ? config.blendMode.toLowerCase() : "normal";
         config.textBlendMode = Boolean(config.textBlendMode) ? config.textBlendMode.toLowerCase() : "normal";
         config.debug = Boolean(config.debug);
         config.ignoreItemPickups = [].concat(config.ignoreItemPickups);
         config.format = Boolean(config.format) ? config.format : DEFAULT_FORMAT;
         config.HUDModesState = getState(config.HUDModesState);
         if(!config.HUDModes)
         {
            config.HUDModes = [];
         }
         _config = config;
         return _config;
      }
      
      private static function getState(data:Object) : String
      {
         if(!data)
         {
            return STATE_HIDDEN;
         }
         if(data.toLowerCase() == STATE_SHOWN)
         {
            return STATE_SHOWN;
         }
         return STATE_HIDDEN;
      }
   }
}

