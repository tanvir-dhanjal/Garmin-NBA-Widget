using Toybox.WatchUi as Ui;
using Toybox.Communications as Comm;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Time.Gregorian as Calendar;

class NBAView extends Ui.View {
	private var colorMap = {};

	private var boldFont;
    private var lightFont;
    private var semiBoldFont;

	private var screenWidth;
    private var screenHeight;

	var apiKey = "XX";
	var gameStats = [];
	var index = 0;
	var state = 0;

    function initialize() {
        View.initialize();

		colorMap.put("ATL", ["Hawks", Graphics.createColor(255, 225, 58, 62)]); // Atlanta Hawks (Red)
		colorMap.put("BOS", ["Celtics", Graphics.createColor(255, 0, 122, 61)]); // Boston Celtics (Green)
		colorMap.put("BKN", ["Nets", Graphics.createColor(255, 0, 0, 0)]); // Brooklyn Nets (Black)
		colorMap.put("CHA", ["Hornets", Graphics.createColor(255, 29, 17, 96)]); // Charlotte Hornets (Purple)
		colorMap.put("CHI", ["Bulls", Graphics.createColor(255, 206, 17, 65)]); // Chicago Bulls (Red)
		colorMap.put("CLE", ["Cavaliers", Graphics.createColor(255, 134, 0, 56)]); // Cleveland Cavaliers (Wine)
		colorMap.put("DAL", ["Mavericks", Graphics.createColor(255, 0, 83, 188)]); // Dallas Mavericks (Blue)
		colorMap.put("DEN", ["Nuggets", Graphics.createColor(255, 13, 34, 64)]); // Denver Nuggets (Navy Blue)
		colorMap.put("DET", ["Pistons", Graphics.createColor(255, 200, 16, 46)]); // Detroit Pistons (Red)
		colorMap.put("GSW", ["Warriors", Graphics.createColor(255, 253, 185, 39)]); // Golden State Warriors (Yellow)
		colorMap.put("HOU", ["Rockets", Graphics.createColor(255, 206, 17, 65)]); // Houston Rockets (Red)
		colorMap.put("IND", ["Pacers", Graphics.createColor(255, 0, 45, 98)]); // Indiana Pacers (Navy Blue)
		colorMap.put("LAC", ["Clippers", Graphics.createColor(255, 200, 16, 46)]); // LA Clippers (Red)
		colorMap.put("LAL", ["Lakers", Graphics.createColor(255, 85, 37, 130)]); // Los Angeles Lakers (Purple)
		colorMap.put("MEM", ["Grizzlies", Graphics.createColor(255, 93, 118, 169)]); // Memphis Grizzlies (Navy Blue)
		colorMap.put("MIA", ["Heat", Graphics.createColor(255, 152, 0, 46)]); // Miami Heat (Red)
		colorMap.put("MIL", ["Bucks", Graphics.createColor(255, 0, 71, 27)]); // Milwaukee Bucks (Green)
		colorMap.put("MIN", ["Timberwolves", Graphics.createColor(255, 12, 35, 64)]); // Minnesota Timberwolves (Navy Blue)
		colorMap.put("NOP", ["Pelicans", Graphics.createColor(255, 0, 43, 92)]); // New Orleans Pelicans (Navy Blue)
		colorMap.put("NYK", ["Knicks", Graphics.createColor(255, 0, 107, 182)]); // New York Knicks (Blue)
		colorMap.put("OKC", ["Thunder", Graphics.createColor(255, 0, 125, 195)]); // Oklahoma City Thunder (Blue)
		colorMap.put("ORL", ["Magic", Graphics.createColor(255, 0, 125, 197)]); // Orlando Magic (Blue)
		colorMap.put("PHI", ["76ers", Graphics.createColor(255, 0, 107, 182)]); // Philadelphia 76ers (Blue)
		colorMap.put("PHX", ["Suns", Graphics.createColor(255, 229, 96, 32)]); // Phoenix Suns (Orange)
		colorMap.put("POR", ["Trail Blazers", Graphics.createColor(255, 224, 58, 62)]); // Portland Trail Blazers (Red)
		colorMap.put("SAC", ["Kings", Graphics.createColor(255, 91, 43, 130)]); // Sacramento Kings (Purple)
		colorMap.put("SAS", ["Spurs", Graphics.createColor(255, 6, 25, 34)]); // San Antonio Spurs (Black)
		colorMap.put("TOR", ["Raptors", Graphics.createColor(255, 206, 17, 65)]); // Toronto Raptors (Red)
		colorMap.put("UTA", ["Jazz", Graphics.createColor(255, 0, 43, 92)]); // Utah Jazz (Navy Blue)
		colorMap.put("WAS", ["Wizards", Graphics.createColor(255, 0, 43, 92)]); // Washington Wizards (Navy Blue)


		boldFont = Application.loadResource(Rez.Fonts.BoldFont);
        lightFont = Application.loadResource(Rez.Fonts.LightFont);
		semiBoldFont = Application.loadResource(Rez.Fonts.SemiBoldFont);
    }

    // Load your resources here
    function onLayout(dc) {
    	setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    	makeApiRequest();
    }

	// set up the response callback function
    function onReceive(responseCode, data) {
       if (responseCode == 200) {
		   System.println("Request Successful" + data); 
		   state = 1;

		   var gameData = data["data"];
		   gameStats = new[gameData.size()]; 
		   for(var i = 0; i < gameData.size(); i += 1) {
			    gameStats[i] = new[6];
                gameStats[i][0] = gameData[i]["home_team"]["abbreviation"];
				gameStats[i][1] = gameData[i]["visitor_team"]["abbreviation"];
				gameStats[i][2] = gameData[i]["home_team_score"];
				gameStats[i][3] = gameData[i]["visitor_team_score"];
				gameStats[i][4] = gameData[i]["time"];
				gameStats[i][5] = gameData[i]["period"];
								
				if(gameStats[i][5] == 0) {
					gameStats[i][4] = "Scheduled";
				}
           }
       }
       else {
		   state = 2;
           System.println("Response: " + responseCode);           
       }
    }

    function makeApiRequest() {
	   // Get Current Date
	   var now = Calendar.info(Time.now(), Calendar.FORMAT_SHORT);
	   var todayDate = now.year.format("%4d") + "-" + now.month.format("%02d") + "-" + now.day.format("%02d");

	   // Make API Call
	   var url = "http://api.balldontlie.io/v1/games?dates[]=" + todayDate; 
	   var params = {};
       var options = {                                             
           :method => Communications.HTTP_REQUEST_METHOD_GET,      
           :headers => {"Authorization" => apiKey}, 
           :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
       };

       var responseCallback = method(:onReceive);                  
       Communications.makeWebRequest(url, params, options, responseCallback);
    }

	
	function timerCallback() {
    	Ui.requestUpdate();
	}

    // Update the view
    function onUpdate(dc) {
		var myTimer = new Timer.Timer();
    	myTimer.start(method(:timerCallback), 4000, false);


		if(gameStats.size() > 0) {
			var currGame = gameStats[index];

			dc.clear();
			screenWidth = dc.getWidth();
        	screenHeight = dc.getHeight();
			
			// Draw Rectangles
			dc.setColor(colorMap[currGame[0]][1], Graphics.COLOR_WHITE);
			dc.fillRectangle(0, 0, screenWidth / 2, screenHeight);

			dc.setColor(colorMap[currGame[1]][1], Graphics.COLOR_WHITE);
			dc.fillRectangle(screenWidth / 2, 0, screenWidth,  screenHeight);

			var x = screenWidth / 2;
			var y = screenHeight / 2 ;

			var titleA = dc.getTextDimensions(currGame[0], Graphics.FONT_LARGE);
			dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
			dc.drawText(
				x - 40,
				y - titleA[1] - 20,
				Graphics.FONT_LARGE,
				currGame[0],
				Graphics.TEXT_JUSTIFY_RIGHT 
			);

			dc.drawText(
				x - 40,
				y - 30,
				semiBoldFont,
				colorMap[currGame[0]][0],
				Graphics.TEXT_JUSTIFY_RIGHT 
			);

			dc.drawText(
				x - 40,
				y + 10,
				boldFont,
				currGame[2],
				Graphics.TEXT_JUSTIFY_RIGHT 
			);

			
			var titleB = dc.getTextDimensions(currGame[1], Graphics.FONT_LARGE);
			dc.drawText(
				x + 40,
				y - titleB[1] - 20,
				Graphics.FONT_LARGE,
				currGame[1],
				Graphics.TEXT_JUSTIFY_LEFT
			);

			dc.drawText(
				x + 40,
				y - 30,
				semiBoldFont,
				colorMap[currGame[1]][0],
				Graphics.TEXT_JUSTIFY_LEFT
			);

			dc.drawText(
				x + 40,
				y + 10,
				boldFont,
				currGame[3],
				Graphics.TEXT_JUSTIFY_LEFT 
			);
		
			dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
			dc.drawText(
				x,
				screenHeight - 60,
				Graphics.FONT_SYSTEM_XTINY,
				currGame[4],
				Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
			);

			index = (index + 1) % gameStats.size();
		}  else {
			screenWidth = dc.getWidth();
        	screenHeight = dc.getHeight();

			var label = "Loading..";
			if(state == 1) {
				label = "No Game\nScheduled";
			} else if(state == 2) {
				label = "Please\nRetry Later";
			}
			
			dc.clear();
			dc.setColor(Graphics.COLOR_WHITE, Graphics.createColor(255, 29, 66, 138));
			dc.drawText(
				screenWidth / 2,
				screenHeight / 2,
				Graphics.FONT_XTINY,
				label,
				Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
			);
		}
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
  	function onHide() {
		gameStats = [];
    }    
}
