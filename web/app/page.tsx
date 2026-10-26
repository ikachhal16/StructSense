import Link from "next/link";
import Disclaimer from "./components/Disclaimer";
import HeroVisual from "./components/HeroVisual";

const SENSORS = [
  {
    title: "Acoustic check",
    hardware: "Speaker and microphone",
    does: "Plays a 40 to 100 Hz sweep into the wall and measures how much comes back. A dry, hollow cavity rings; drywall and insulation holding water damp the tone.",
    cannot: "It is comparative only. The app always measures a dry reference spot on the same wall first, then the suspect spot, and judges the difference.",
  },
  {
    title: "Magnetic sweep",
    hardware: "Magnetometer",
    does: "Maps steel studs, nail plates, screw lines and iron pipes as you slide the phone across the wall. Framing tells you where water travels and where to open up.",
    cannot: "Copper and PVC are invisible to it, so a clean sweep is not proof of an empty wall.",
  },
  {
    title: "Humidity puck",
    hardware: "Bluetooth Low Energy",
    does: "Connects to any sensor that speaks the standard Environmental Sensing profile and streams temperature and humidity from a crawlspace, closet or attic you cannot keep watching.",
    cannot: "A puck reads the air, not the wall. It tells you a room is staying wet, not which stud bay the water is in.",
  },
];

const FACTS = [
  { value: "25.91 in", label: "Rain in 24 hours in Fort Lauderdale, April 2023, the most ever recorded in Florida.", source: "NWS Miami" },
  { value: "24 to 48 h", label: "Window to dry wet building materials before mold usually starts.", source: "EPA, FEMA" },
  { value: "811 per 100k", label: "Florida emergency department visits for asthma among children 0 to 17, 2022.", source: "Florida Health CHARTS" },
  { value: "Under 60%", label: "Indoor humidity ceiling to keep mold from growing, ideally 30 to 50 percent.", source: "EPA" },
];

export default function HomePage() {
  return (
    <main>
      <section className="border-b border-line-soft bg-panel">
        <div className="mx-auto grid max-w-7xl items-center gap-10 px-5 py-14 sm:px-8 lg:grid-cols-[1fr_1.05fr] lg:py-20">
          <div>
            <h1 className="font-display text-4xl font-extrabold leading-[1.05] tracking-tight text-ink sm:text-5xl lg:text-6xl">
              A pocket first-aid kit for home resiliency.
            </h1>
            <p className="mt-6 max-w-xl text-lg leading-8 text-body">
              After a South Florida storm, water hides inside walls for days before anything shows. StructSense turns the sensors
              already in your phone into a triage kit: find the wet spots, map the framing, watch the humidity, and hand a clear
              report to the people who can fix it.
            </p>
            <div className="mt-8 rounded-xl border border-clinical/40 bg-clinical-soft p-5">
              <h2 className="font-display text-xl font-bold text-ink">Run a structural check</h2>
              <ol className="mt-3 list-decimal space-y-2 pl-5 text-[15px] leading-6 text-body">
                <li>Sweep the wall with the magnetometer to map studs and pipes.</li>
                <li>Press the phone flat on a dry spot, then on the suspect spot. The app compares them.</li>
                <li>Leave a humidity puck in the lowest room and watch the 60 percent line.</li>
                <li>Share the report with your insurer, FEMA or an inspector.</li>
              </ol>
              <div className="mt-5 flex flex-wrap gap-3">
                <Link href="/hub" className="rounded-md bg-clinical px-5 py-2.5 text-[15px] font-bold text-white transition hover:bg-clinical-deep">
                  Open the post-storm checklist
                </Link>
                <Link href="/dashboard" className="rounded-md border border-clinical px-5 py-2.5 text-[15px] font-bold text-clinical-deep transition hover:bg-panel">
                  See the live dashboard
                </Link>
              </div>
            </div>
            <div className="mt-6">
              <Disclaimer compact />
            </div>
          </div>
          <HeroVisual />
        </div>
      </section>

      <section id="sensors" className="mx-auto max-w-7xl px-5 py-16 sm:px-8">
        <h2 className="font-display text-3xl font-bold text-ink sm:text-4xl">Three sensors you already own, and what each one can honestly tell you</h2>
        <div className="mt-8 grid gap-6 lg:grid-cols-3">
          {SENSORS.map((sensor) => (
            <article key={sensor.title} className="rounded-lg border border-line-soft bg-panel p-6">
              <h3 className="font-display text-2xl font-bold text-ink">{sensor.title}</h3>
              <p className="mt-1 text-[15px] font-semibold text-clinical-deep">{sensor.hardware}</p>
              <p className="mt-4 text-[15px] leading-7 text-body">{sensor.does}</p>
              <p className="mt-3 border-t border-line-soft pt-3 text-[15px] leading-7 text-muted">{sensor.cannot}</p>
            </article>
          ))}
        </div>
      </section>

      <section id="health" className="border-y border-line-soft bg-panel">
        <div className="mx-auto grid max-w-7xl gap-10 px-5 py-16 sm:px-8 lg:grid-cols-[1.1fr_1fr] lg:items-start">
          <div>
            <h2 className="font-display text-3xl font-bold text-ink sm:text-4xl">Hidden moisture becomes mold. Mold reaches children&rsquo;s lungs first.</h2>
            <p className="mt-5 text-lg leading-8 text-body">
              Broward County sits a few feet above sea level on porous limestone, with summer humidity that rarely drops below
              70 percent outdoors. When a storm pushes water into a wall, the cavity stays wet long after the floor dries.
            </p>
            <p className="mt-4 text-[15px] leading-7 text-body">
              The National Academies&rsquo; review of damp indoor spaces found sufficient evidence that indoor dampness and mold are
              associated with cough, wheeze and asthma symptoms in people who already have asthma, and with upper respiratory
              symptoms in otherwise healthy people. In a county where rentals, older block homes and multi-generational
              households are common, the families least able to open a wall on a hunch are the ones most exposed.
            </p>
            <p className="mt-4 text-[15px] leading-7 text-body">
              StructSense exists so that a hunch becomes a measurement. A free check that says &ldquo;this wall absorbs more
              sound than the one next to it, and the closet has been over 60 percent for two days&rdquo; is enough to justify a
              moisture meter, a landlord call or a remediation claim.
            </p>
          </div>
          <dl className="grid gap-4 sm:grid-cols-2">
            {FACTS.map((fact) => (
              <div key={fact.value} className="rounded-lg border border-line-soft bg-canvas p-5">
                <dt className="font-body text-3xl font-semibold text-ink">{fact.value}</dt>
                <dd className="mt-2 text-[15px] leading-6 text-body">{fact.label}</dd>
                <dd className="mt-2 text-sm font-semibold text-muted">{fact.source}</dd>
              </div>
            ))}
          </dl>
        </div>
      </section>

      <section id="privacy" className="mx-auto max-w-7xl px-5 py-16 sm:px-8">
        <div className="grid gap-8 lg:grid-cols-[1fr_1fr]">
          <div>
            <h2 className="font-display text-3xl font-bold text-ink">Everything is processed on the phone</h2>
            <p className="mt-4 text-[15px] leading-7 text-body">
              Audio from the acoustic check is reduced to loudness numbers on the device and never recorded. Magnetometer and
              puck readings stay in the app until you tap Share. There is no account, no cloud and no ad network. The iOS app is
              built with SwiftUI, AVFoundation, Core Motion and Core Bluetooth, and the source is published in the same repository
              as this site.
            </p>
          </div>
          <div>
            <h2 className="font-display text-3xl font-bold text-ink">Built for the first 72 hours</h2>
            <p className="mt-4 text-[15px] leading-7 text-body">
              The Resilience Hub holds a checklist ordered around the 24 to 48 hour drying window, the phone numbers that matter in
              Broward County, and links to the official EPA, CDC, FEMA and Florida Department of Health pages every claim on this
              site comes from.
            </p>
            <Link href="/hub" className="mt-4 inline-block font-semibold text-clinical-deep underline underline-offset-4 hover:text-clinical">
              Go to the Resilience Hub
            </Link>
          </div>
        </div>
      </section>
    </main>
  );
}
