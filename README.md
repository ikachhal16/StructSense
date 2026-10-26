# StructSense

A pocket first-aid kit for home resiliency. StructSense helps South Florida households find hidden water damage with the sensors already in a phone, and gives them the checklist, contacts and evidence they need in the first 72 hours after a storm.

Two parts live in this repository:

- `ios/` — SwiftUI app (iOS 16+) with three triage tools and a shareable report.
- `web/` — Next.js site with the consumer landing page, the South Florida Climate Resilience Hub and a live humidity dashboard.

Both carry the same transparency disclaimer: *StructSense acts as a preliminary structural triage tool. It does not replace a licensed professional structural engineer.*

## iOS app

| Tool | Frameworks | What it does |
|---|---|---|
| Acoustic check | AVFoundation (`AVAudioEngine`, `AVAudioSourceNode`, input tap) | Plays a 40 to 100 Hz sweep through the speaker and measures microphone level in 100 ms bins for 3 seconds. Always compares a dry reference spot against the suspect spot; the difference, smoothed with an exponential moving average, drives the verdict and a confidence score. |
| Magnetic sweep | Core Motion (`CMDeviceMotion.magneticField`) | Streams the calibrated field at 50 Hz, keeps a median baseline of quiet samples, and flags spikes above 4 standard deviations or 8 µT. Green to red indicator, anomaly log. |
| Humidity puck | Core Bluetooth | Scans for peripherals, connects to any that expose the Bluetooth SIG Environmental Sensing Service (0x181A) and reads Temperature (0x2A6E) and Humidity (0x2A6F). A simulated puck with a water-intrusion button demonstrates the 60 percent alert without hardware. |
| Report | SwiftUI `ShareLink` | Collects the saved results and notes into plain text for an inspector, insurer or FEMA. |

### Building

The Xcode project is generated from `ios/project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen) and committed, so it opens directly:

```sh
cd ios
xcodegen generate   # only needed after adding or removing Swift files
open StructSense.xcodeproj
```

Run on a physical device. The simulator has no magnetometer, no Bluetooth radio and a poor speaker-to-microphone path, so only the simulated puck is meaningful there.

## Web app

```sh
cd web
npm install
npm run dev
```

Routes:

- `/` — landing page with the animated acoustic comparison, the three sensors and the health-equity section.
- `/hub` — 72-hour post-storm checklist (saved on-device), who to call in Broward County, and official EPA, CDC, FEMA and Florida Department of Health links.
- `/dashboard` — three simulated pucks streaming once a second, small-multiple humidity charts with hover readout and table view, a flashing alert when any reading crosses 60 percent, and a threshold-crossing log.

Stack: Next.js 16 App Router, TypeScript, Tailwind CSS 4. No backend; the dashboard simulation runs in the browser.

## Sources behind the numbers

- Fort Lauderdale 25.91 inches of rain in 24 hours, April 2023: National Weather Service Miami.
- 24 to 48 hour drying window and the under-60-percent humidity target: EPA, *A Brief Guide to Mold, Moisture and Your Home*; FEMA flood cleanup guidance.
- Dampness and mold associated with asthma symptoms: National Academies, *Damp Indoor Spaces and Health* (2004).
- Florida emergency department visits for asthma, ages 0 to 17, 811.2 per 100,000 in 2022: Florida Health CHARTS.
