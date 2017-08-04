using Toybox.WatchUi as Ui;
using Toybox.Communications as Comm;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Application as App;

class NBAView extends Ui.View {
	
	var baseURL = "http://data.nba.net";
	var timer,base,screenHeight,screenWidth;
	var linksMap;
	var currentGameMap=[];
	var numGames=0;

    function initialize() {
        View.initialize();
        base = new Rez.Drawables.NBABase();
        screenHeight = Sys.getDeviceSettings().screenHeight;
        screenWidth = Sys.getDeviceSettings().screenWidth;
    }

    // Load your resources here
    function onLayout(dc) {
    
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
        if(App.getApp().getProperty("gameData")!=null){
          	currentGameMap = App.getApp().getProperty("gameData");
          	numGames = App.getApp().getProperty("noOfGames").toNumber();
            Ui.requestUpdate();
        } 
    	getLinks();
    }

    // Update the view
    function onUpdate(dc) {
    	dc.clear();
    	base.draw(dc);
    	dc.setColor( Gfx.COLOR_BLACK,Gfx.COLOR_WHITE);
    	dc.drawLine(1, 1, 1, screenHeight);
    	dc.drawLine(1, 1, screenWidth, 1);
    	dc.setColor( Gfx.COLOR_WHITE,Gfx.COLOR_BLACK);
    	dc.drawText(8,(70 + ((screenHeight-70)/2) -25), Gfx.FONT_LARGE,"NBA", Gfx.TEXT_JUSTIFY_LEFT);
    	dc.drawText(15,(70 + ((screenHeight-70)/2) -15)+18, Gfx.FONT_MEDIUM,"Live", Gfx.TEXT_JUSTIFY_LEFT);
    	dc.drawLine(70, 0, 70, screenHeight);
    	
    	if (currentGameMap!=null || (linksMap!=null && linksMap instanceof Dictionary)) {
    		if(currentGameMap==null || currentGameMap.size()==0){
    			printMessage(70+((screenWidth-70)/2), 0+((screenHeight-0)/2)-5,dc,"LOADING.....");
    			return;
    		}
    		
    		
    		if(numGames==0){
    			printMessage(70+((screenWidth-70)/2), 0+((screenHeight-0)/2)-5,dc,"NO GAME");
    			return;
    		}
    	
    		// if number of games more than 3 then put only active games in map
    		var swapindex=0;
			for(var i = 3;i < numGames;i++){
				if(swapindex<3 && currentGameMap[i].get("statusNum")==2){
					while(swapindex < 3 && currentGameMap[swapindex].get("statusNum")==2){
						swapindex++;
					}
					if(swapindex<3){
						currentGameMap[swapindex]= currentGameMap[i];
						swapindex++;
					}
				}
			}
   
    		// If live or past number of games in same day are less than or equal to 3
			if(currentGameMap!=null && currentGameMap.size()>0 && numGames <= 3){
				if(currentGameMap.size()>0){
					printGame(70,0, screenWidth, screenHeight/3,currentGameMap[0],dc);
				}else{
					printGame(70,0, screenWidth, screenHeight/3,null,dc);
				}
				if(currentGameMap.size()>1){
					printGame(70,screenHeight/3, screenWidth, 2*(screenHeight/3),currentGameMap[1],dc);
				}else{
					printGame(70,screenHeight/3, screenWidth, 2*(screenHeight/3),null,dc);
				}
				if(currentGameMap.size()>2){
					printGame(70,2*(screenHeight/3), screenWidth, screenHeight,currentGameMap[2],dc);
				}else{
					printGame(70,2*(screenHeight/3), screenWidth, screenHeight,null,dc);
				}
			}
    	}
    	linksMap=null;
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
  	function onHide() {

    }
    
    // Make an API call to home page and get all links
	function getLinks() {
		var homeURL = baseURL+ "/10s/prod/v1/today.json";
        Comm.makeWebRequest(homeURL,null,{"Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED},method(:onReceiveLinks));
    }
    
 
     // Receive the data from the web request of get all links
    function onReceiveLinks(responseCode, data) {
        if (responseCode == 200) {
            linksMap = data["links"];
            getCurrentScoreboard();
        } 
    }
    
    // Make an API call to get current scoreboard
    function getCurrentScoreboard() {
		var homeURL = baseURL+ linksMap.get("todayScoreboard");
        Comm.makeWebRequest(homeURL,null,{"Content-Type" => Comm.REQUEST_CONTENT_TYPE_JSON},method(:onReceiveCurrentScorecard));
    }
    
    // Receive the data from the web request of get all links
    function onReceiveCurrentScorecard(responseCode, data) {
    	try {
    		if (responseCode == 200) {
        		numGames = data["numGames"];
            	currentGameMap = data["games"];
            	for(var i =0;i<currentGameMap.size();i++){
    				currentGameMap[i].remove("watch");
    				currentGameMap[i].remove("tickets");
    			}
            	App.getApp().clearProperties();
            	App.getApp().setProperty("gameData", currentGameMap);
            	App.getApp().setProperty("noOfGames", numGames);
            	Ui.requestUpdate();
        	} 
		}catch(ex){
			getLinks();
		}
        
    }
    
    // Function to print the game with clock and series.
    function printGame(x1,y1,x2,y2,gameInfo,dc){
    	if(gameInfo != null) {
    		dc.setColor( Gfx.COLOR_WHITE,Gfx.COLOR_BLACK);
    		dc.drawLine(x1,y2,x2,y2);
    		var homeTeam = gameInfo.get("hTeam");
    		var visitorTeam = gameInfo.get("vTeam");
    		var homeScore = homeTeam.get("score");
    		var visitorScore = visitorTeam.get("score");
    		if(homeScore==null || homeScore.length()==0){homeScore=0;}
    		if(visitorScore == null || visitorScore.length()==0){visitorScore=0;}
    		
    		var mid = (y2-y1)/2;
    		
    		dc.setColor( Gfx.COLOR_WHITE,Gfx.COLOR_BLACK);
    		dc.drawText(x1+5,y1+3, Gfx.FONT_TINY,homeTeam.get("triCode"), Gfx.TEXT_JUSTIFY_LEFT);
    		dc.drawText(x1+5,y1+3+mid, Gfx.FONT_TINY,visitorTeam.get("triCode"), Gfx.TEXT_JUSTIFY_LEFT);
    		dc.drawText(x1+40,y1+3, Gfx.FONT_SYSTEM_SMALL,homeScore, Gfx.TEXT_JUSTIFY_LEFT);
    		dc.drawText(x1+40,y1+3+mid, Gfx.FONT_SYSTEM_SMALL,visitorScore, Gfx.TEXT_JUSTIFY_LEFT);
    	
    		if(gameInfo.hasKey("tags") && gameInfo.hasKey("playoffs")){
    			var playoff = gameInfo.get("playoffs");
    			var seriesText = playoff.get("seriesSummaryText");
    			var seriesDisplay=seriesText;
    			
    			if(seriesText.find("leads")){
    				seriesDisplay= seriesText.substring(seriesText.find("lead")+5,seriesText.length()) + " (" + seriesText.substring(0,3) + ")"; 
    			}
    			if (Sys.SCREEN_SHAPE_RECTANGLE == screenShape) {
    				dc.drawText(x1+65,y1+3, Gfx.FONT_XTINY,seriesDisplay, Gfx.TEXT_JUSTIFY_LEFT);
    			}
    		} 
    		
    		if(gameInfo.get("period").get("current")!=0 && gameInfo.get("isGameActivated")==true){
    			var gameQuarter = "Q" + gameInfo.get("period").get("current");
    			dc.drawText(x1+65,y1+3+mid, Gfx.FONT_SYSTEM_XTINY,gameQuarter, Gfx.TEXT_JUSTIFY_LEFT);
    			dc.drawText(x1+85,y1+3+mid, Gfx.FONT_SYSTEM_XTINY,gameInfo.get("clock"), Gfx.TEXT_JUSTIFY_LEFT);
    		}
    		else if(gameInfo.get("statusNum")==3){
    			dc.drawText(x1+65,y1+3+mid, Gfx.FONT_SYSTEM_XTINY,"Final", Gfx.TEXT_JUSTIFY_LEFT);
    		}
    		else{
    			var startTime = gameInfo.get("startTimeUTC");
    			var startDate = gameInfo.get("startDateEastern");
    			var clockTime = Sys.getClockTime();
    			var localGameTime = convertUTCToLocal(startTime ,clockTime.timeZoneOffset);
    			if (Sys.SCREEN_SHAPE_RECTANGLE == screenShape) {
    				dc.drawText(x1+55,y1+3+mid, Gfx.FONT_SYSTEM_XTINY, startDate.substring(4,6) + "-" + startDate.substring(6,8) + "@" + localGameTime, Gfx.TEXT_JUSTIFY_LEFT);
    			}else{
    				dc.drawText(x1+60,y1+3+mid-30, Gfx.FONT_SYSTEM_XTINY,"Start" , Gfx.TEXT_JUSTIFY_LEFT);
    				dc.drawText(x1+60,y1+3+mid-15, Gfx.FONT_SYSTEM_XTINY, startDate.substring(4,6) + "-" + startDate.substring(6,8) , Gfx.TEXT_JUSTIFY_LEFT);
    				dc.drawText(x1+60,y1+3+mid, Gfx.FONT_SYSTEM_XTINY, "@" + localGameTime, Gfx.TEXT_JUSTIFY_LEFT);
    			}
    		}
    	}
    	if(gameInfo==null){
    		dc.setColor( Gfx.COLOR_WHITE,Gfx.COLOR_BLACK);
    		dc.drawLine(x1,y2,x2,y2);
    		dc.drawText(x1+10,y1+((y2-y1)/2) -10, Gfx.FONT_TINY,"- No other game.", Gfx.TEXT_JUSTIFY_LEFT);
    	}
    }
    
    // Print Message in the middle
    function printMessage(x,y,dc,msg){
    	dc.setColor( Gfx.COLOR_WHITE,Gfx.COLOR_BLACK);
    	dc.drawText(x,y, Gfx.FONT_SYSTEM_XTINY,msg, Gfx.TEXT_JUSTIFY_CENTER);
    }
    
    // Function to return local date from UTC date.
    function convertUTCToLocal(startTime ,offset){
    	var outTime;
    	var hour = startTime.substring(startTime.find("T")+1,startTime.find("T")+3).toNumber();
    	var min = startTime.substring(startTime.find("T")+4,startTime.find("T")+6);
 		var hourOffset=(offset/60)/60;
 		
    	if(offset>0){
    		if(hour+hourOffset>24){
    			hour= (hour+hourOffset)-24;
    		}else{
    			hour = hour+hourOffset;
    		}
    	}else{
    		if(hour-(-1*hourOffset)<0){
    			hour= 24-((-1*hourOffset)-hour)-hour;
    		}else{
    			hour = hour-hourOffset;
    		}
    	}
    	outTime = hour + ":" +  min;
    	return outTime;
    }
    
}
