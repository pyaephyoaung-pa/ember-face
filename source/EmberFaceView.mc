import Toybox.ActivityMonitor;
import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Ember Face — AMOLED watch face (Venu 4)
// Layout: ticks bezel · big HH:MM · 4 progress rings · date
class EmberFaceView extends WatchUi.WatchFace {

    // Colors
    private const C_BG      = 0x000000;
    private const C_ORANGE  = 0xFF6A2B;
    private const C_RED     = 0xE0341C;
    private const C_AMBER   = 0xFFA21F;
    private const C_DIM     = 0x3A1D14;
    private const C_WHITE   = 0xFFFFFF;
    private const C_GREY    = 0x8C8C8C;
    private const C_TICK    = 0x555555;

    private var _lowPower as Boolean = false;

    function initialize() {
        WatchFace.initialize();
    }

    function onEnterSleep() as Void {
        _lowPower = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _lowPower = false;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(C_BG, C_BG);
        dc.clear();

        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        if (_lowPower) {
            drawLowPower(dc, w, h);
            return;
        }

        var clock = System.getClockTime();

        drawTicks(dc, w, h, clock.sec);
        drawTime(dc, w, h, clock);
        drawComplications(dc, w, h);
        drawDate(dc, w, h);
        drawPhoneDot(dc, w, h);
    }

    // ---------- Always-on (burn-in safe: dim, small, few pixels) ----------
    private function drawLowPower(dc as Dc, w as Number, h as Number) as Void {
        var clock = System.getClockTime();
        var text = formatHour(clock.hour) + ":" + clock.min.format("%02d");
        dc.setColor(C_GREY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2, Graphics.FONT_NUMBER_MEDIUM, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ---------- Bezel ticks ----------
    private function drawTicks(dc as Dc, w as Number, h as Number, sec as Number) as Void {
        var cx = w / 2;
        var cy = h / 2;
        var rOuter = w * 0.485;

        for (var i = 0; i < 60; i++) {
            var a = Math.toRadians(i * 6 - 90);
            var major = (i % 5 == 0);
            var rInner = rOuter - (major ? w * 0.035 : w * 0.018);
            var cs = Math.cos(a);
            var sn = Math.sin(a);

            if (i == sec) {
                dc.setColor(C_ORANGE, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(major ? 5 : 4);
                rInner = rOuter - w * 0.04;
            } else {
                dc.setColor(major ? C_WHITE : C_TICK, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(major ? 3 : 1);
            }
            dc.drawLine(cx + rInner * cs, cy + rInner * sn,
                        cx + rOuter * cs, cy + rOuter * sn);
        }
        dc.setPenWidth(1);
    }

    // ---------- Big time ----------
    private function drawTime(dc as Dc, w as Number, h as Number, clock as System.ClockTime) as Void {
        var font = Graphics.FONT_NUMBER_HOT;
        var hh = formatHour(clock.hour);
        var mm = clock.min.format("%02d");

        var hw = dc.getTextWidthInPixels(hh, font);
        var cw = dc.getTextWidthInPixels(":", font);
        var mw = dc.getTextWidthInPixels(mm, font);
        var total = hw + cw + mw;
        var x = (w - total) / 2;
        var y = h / 2;
        var just = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(C_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, hh, just);

        // Colon: two squares centered on the digits' vertical middle
        dc.setColor(C_RED, Graphics.COLOR_TRANSPARENT);
        var dot = (w * 0.022).toNumber();
        var colonX = x + hw + (cw - dot) / 2;
        dc.fillRectangle(colonX, y - h * 0.05 - dot / 2, dot, dot);
        dc.fillRectangle(colonX, y + h * 0.05 - dot / 2, dot, dot);

        dc.setColor(C_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + hw + cw, y, font, mm, just);
    }

    // ---------- 4 progress rings ----------
    private function drawComplications(dc as Dc, w as Number, h as Number) as Void {
        var r = w * 0.075;
        var xl = w * 0.30;
        var xr = w * 0.70;
        var yt = h * 0.285;
        var yb = h * 0.715;

        // Steps (top-left)
        var am = ActivityMonitor.getInfo();
        var steps = (am != null && am.steps != null) ? am.steps : 0;
        var goal = (am != null && am.stepGoal != null && am.stepGoal > 0) ? am.stepGoal : 10000;
        drawRing(dc, xl, yt, r, steps.toFloat() / goal, C_ORANGE);
        drawValue(dc, xl, yt, formatSteps(steps));

        // Heart rate (top-right)
        var hr = getHeartRate();
        var hrPct = (hr != null) ? (hr.toFloat() / 190.0) : 0.0;
        drawRing(dc, xr, yt, r, hrPct, C_RED);
        drawValue(dc, xr, yt, (hr != null) ? hr.toString() : "--");

        // Floors (bottom-left)
        var floors = (am != null && am.floorsClimbed != null) ? am.floorsClimbed : 0;
        var floorGoal = (am != null && am.floorsClimbedGoal != null && am.floorsClimbedGoal > 0)
            ? am.floorsClimbedGoal : 10;
        drawRing(dc, xl, yb, r, floors.toFloat() / floorGoal, C_AMBER);
        drawValue(dc, xl, yb, floors.toString());

        // Battery (bottom-right)
        var batt = System.getSystemStats().battery;
        drawRing(dc, xr, yb, r, batt / 100.0, (batt < 20) ? C_RED : C_ORANGE);
        drawValue(dc, xr, yb, batt.format("%d"));
    }

    // Progress ring starting from 12 o'clock, clockwise
    private function drawRing(dc as Dc, cx as Numeric, cy as Numeric, r as Numeric,
                              pct as Float, color as Number) as Void {
        var pen = (r * 0.28).toNumber();
        if (pen < 4) { pen = 4; }
        dc.setPenWidth(pen);

        dc.setColor(C_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, r);

        if (pct > 1.0) { pct = 1.0; }
        if (pct > 0.01) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            if (pct >= 0.995) {
                dc.drawCircle(cx, cy, r);
            } else {
                var endDeg = 90 - (360 * pct).toNumber();
                dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, 90, endDeg);
            }
        }
        dc.setPenWidth(1);
    }

    private function drawValue(dc as Dc, cx as Numeric, cy as Numeric, text as String) as Void {
        dc.setColor(C_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, Graphics.FONT_XTINY, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ---------- Date ----------
    private function drawDate(dc as Dc, w as Number, h as Number) as Void {
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var text = info.day_of_week.toString().toUpper() + " " + info.day.format("%02d");
        dc.setColor(C_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.88, Graphics.FONT_SMALL, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ---------- Phone connection dot (top center) ----------
    private function drawPhoneDot(dc as Dc, w as Number, h as Number) as Void {
        var connected = System.getDeviceSettings().phoneConnected;
        dc.setColor(connected ? C_ORANGE : C_DIM, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(w / 2, h * 0.14, w * 0.015);
    }

    // ---------- Helpers ----------
    private function formatHour(hour as Number) as String {
        if (System.getDeviceSettings().is24Hour) {
            return hour.format("%02d");
        }
        var h12 = hour % 12;
        if (h12 == 0) { h12 = 12; }
        return h12.format("%d");
    }

    private function formatSteps(steps as Number) as String {
        if (steps >= 1000) {
            return (steps / 1000.0).format("%.1f") + "k";
        }
        return steps.toString();
    }

    private function getHeartRate() as Number or Null {
        var info = Activity.getActivityInfo();
        if (info != null && info.currentHeartRate != null) {
            return info.currentHeartRate;
        }
        var it = ActivityMonitor.getHeartRateHistory(1, true);
        var sample = it.next();
        if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
            return sample.heartRate;
        }
        return null;
    }
}
