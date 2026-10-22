# Data sources and artwork

Checked on 2026-10-22.

- ICE 3neo designation, BR 408 and 90-train order: [Deutsche Bahn](https://www.bahn.de/service/ueber-uns/zugtypen/ice-3neo), [Siemens order announcement](https://press.siemens.com/global/en/pressrelease/deutsche-bahn-orders-additional-17-ice-3neo-trains-siemens-mobility).
- ICE L is a locomotive-hauled Talgo train, with BR 105 locomotives: [Deutsche Bahn vehicle facts](https://www.bahn.de/service/ueber-uns/zugtypen/ICE-L). The locomotive class is not presented as the series of every coach.
- Older ICE fallback family allocations originate in this repository. They classify reported trainsets; they are not an authoritative live fleet register. The portal's recognized vehicle series overrides the fallback.
- Additional onboard endpoint schemas were researched in KPublicTransport, commit `8fbc956f419b388e9559e12be077c8ab312c7052`, in `src/onboard/data/{oebb,ceskedrahy,deutschebahn-zugportal}.json` and the corresponding response samples. Swift adapters were implemented independently against those wire contracts.
- `Sources/OnboardConnect/TestData/{railnet,cd-journey,cd-status,db-regio}.json` are trimmed examples from KPublicTransport's `autotests/data/onboard-{journey,position}/`. Those JSON response files are declared **CC0-1.0, copyright none** in upstream [`.reuse/dep5`](https://invent.kde.org/libraries/kpublictransport/-/blob/8fbc956f419b388e9559e12be077c8ab312c7052/.reuse/dep5). They are historical parser examples, not current travel information.
- Existing ICE/TGV PNG illustrations and author attribution remain from upstream. New Railjet, ČD, regional, generic and ICE L SVG illustrations were authored for this change; they are schematic operator/family representations, not scale drawings of individual vehicles.

For future fleet changes, prefer adding a recognized explicitly reported series. Expand a fallback number allocation only with a cited source and add a case to the identification test. Never infer a physical vehicle from the public train/service number.
