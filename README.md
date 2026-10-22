# Train Connect

The Swift package used by [Train Buddy](https://github.com/ICE-Buddy/ICE-Buddy-macOS). The package directory and existing product names remain compatible with clients of DBConnect.

| Product | Responsibility |
| --- | --- |
| `TrainConnect` | Operator-neutral journey, stop, telemetry and snapshot contracts; shared JSON transport and provider selection |
| `DBConnect` | ICE Portal wire models and physical ICE trainset identification |
| `SNCFConnect` | TGV Portal wire models and vehicle artwork |
| `OnboardConnect` | ÖBB Railnet, ČD Passengera and DB Zugportal adapters, mapped into common value models |
| `DBTimetable` | Existing, separate cloud timetable integration; not used to infer the train a passenger is on |

Use `CombinedDataController.loadSnapshot` for the UI. Each snapshot contains a journey and optional telemetry from **one provider**. Successful snapshots are shared for five seconds; overlapping polls are coalesced. Provider races finish once, suppress duplicate/late callbacks, and deliver their result on the main queue. Empty provider lists and malformed/empty responses are terminal errors.

`loadTrip` and `loadTrainStatus` remain available to existing clients. `TrainTrip.serviceNumber` and `serviceName` give international names to the legacy `vzn` identifier. Wire DTOs and display strings stay inside their operator modules. Missing forecasts, telemetry and vehicle series stay unknown. A journey without speed remains usable. Dates carry explicit timezone offsets; the Railnet adapter unrolls its clock-only timetable across midnight using the local service timezone.

## Onboard support

| Adapter | Journey | Telemetry | Endpoint |
| --- | --- | --- | --- |
| ICE | Yes | Speed, position, connectivity | `https://iceportal.de/api1/rs/` |
| TGV | Yes | Speed (m/s), position, optional connection statistics | `https://wifi.sncf/router/api/` |
| ÖBB Railnet | Yes | Speed (km/h), position when supplied | `https://railnet.oebb.at/assets/media/fis/combined.json` |
| ČD | Scheduled calls | Speed (km/h), position | `http://cdwifi.cz/portal/api/` |
| DB Regio | Yes | Unavailable | `https://zugportal.de/@prd/zupo-travel-information/api/public/ri/journey` |

These are onboard portals, not universal coverage guarantees for an operator's entire fleet. The app probes responses rather than matching SSID capitalization. Clients using ČD need a narrowly scoped App Transport Security exception for `cdwifi.cz`; Train Buddy includes it. No general insecure-network exception is needed.

The additional endpoint contracts and trimmed CC0 response fixtures were checked against [KPublicTransport](https://invent.kde.org/libraries/kpublictransport/-/tree/8fbc956f419b388e9559e12be077c8ab312c7052/src/onboard/data) on 2026-10-22. See [data provenance](DATA_SOURCES.md). Parser/fixture validation does not replace checking the integration on the actual train.

## Vehicle identification

A service number, physical trainset number, vehicle series, and fleet availability are distinct. A recognized `series` reported by ICE Portal takes priority. Otherwise, normalize the portal's physical `tzn`: `Tz`, `TZN`, `ICE`, raw digits, leading zeroes and whitespace are accepted. Do not pass the timetable service number as `tzn`.

ICE 3neo is BR 408; the ordered allocation extends through 8090. ICE 4 fallback allocations are 9001–9050, 9201–9237 and 9451–9500, rather than every number from 9001 to 9999. ICE L can be recognized from an explicit series 105/ICE L; no trainset-number allocation is guessed. Legacy family ranges remain fallback heuristics, not a list of active vehicles, deliveries or retirements. Unrecognized values retain the supplied identifier and get neutral artwork, not an invented ICE 1 identity.

Every known ICE family and TGV family has packaged artwork. New operator/unknown images are original schematic SVG illustrations; they do not assert a specific vehicle class.

## API diagnostics

`APIDiagnostics.shared.makeReport(applicationVersion:build:isDemo:)` exports a versioned JSON report. The shared JSON transport records a maximum of 40 recent results, retained only in process memory for up to 15 minutes. Operator adapters also record responses that decode but fail semantic validation.

The report includes static, catalogued endpoints; status codes; byte counts; elapsed time; fixed error categories; safe schema field paths; and numeric URL-loading error codes. It also includes app/build and macOS versions and whether demo mode is active. Arbitrary URL hosts/paths, query values, credentials, headers, raw responses, localized errors, dynamic dictionary keys and error descriptions are not retained. Unknown endpoints and coding keys are redacted. Expected failed probes for operators whose Wi-Fi is not present are not, by themselves, evidence of an app bug.

The recorder has no network sender or disk persistence. Train Buddy provides explicit preview, email-draft and file-export actions. The person decides whether to share a report.

## Development

```sh
swift test --package-path DBConnect
```

Run the command from the app repository, or use `swift test` inside this package. Tests cover identification, all five demo adapters, packaged artwork, timezone/midnight conversion, stop identity, cancellation, visible small delays, malformed HTTP responses and provider completion behavior. No live train or account is required.
