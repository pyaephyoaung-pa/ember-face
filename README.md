# Ember Face

A Garmin Connect IQ watch face for the Venu 4 (41mm / 45mm), written in Monkey C.

- Bezel tick ring with a highlighted current second
- Large `HH:MM` time (12h/24h follows device setting)
- Four progress rings: steps, heart rate, floors, battery
- Date and phone-connection indicator
- Dimmed, burn-in-safe always-on mode

## Build

Requires the Connect IQ SDK and the Venu 4 device files (install via SDK Manager).

```bash
# one-time: generate a developer key (keep it private, it is git-ignored)
openssl genrsa -out key.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform DER -in key.pem -out developer_key.der -nocrypt

SDK=$(cat ~/Library/Application\ Support/Garmin/ConnectIQ/current-sdk.cfg)
$SDK/bin/monkeyc -d venu445mm -f monkey.jungle -o EmberFace.prg -y developer_key.der -w
$SDK/bin/connectiq          # start the simulator, wait a few seconds
$SDK/bin/monkeydo EmberFace.prg venu445mm
```

To sideload to a watch, copy the `.prg` to `GARMIN/APPS/` over USB.
