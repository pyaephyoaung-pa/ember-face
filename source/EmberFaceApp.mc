import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class EmberFaceApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new EmberFaceView() ];
    }

    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }
}
