using Toybox.Application as App;
using Toybox.System as Sys;

var screenShape;

class NBAApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    	screenShape = Sys.getDeviceSettings().screenShape;
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new NBAView() ];
    }

}