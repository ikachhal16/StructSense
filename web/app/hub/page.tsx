import type { Metadata } from "next";
import Disclaimer from "../components/Disclaimer";
import StormChecklist from "../components/StormChecklist";

export const metadata: Metadata = {
  title: "South Florida Resilience Hub | StructSense",
  description: "A 72-hour post-storm checklist, who to call, and official mold, flood and insurance resources for Broward County homes.",
};

const CONTACTS = [
  { name: "Florida State Assistance Information Line", value: "800-342-3557", note: "Statewide emergency information during a declared event." },
  { name: "Broward County Emergency Hotline", value: "311", note: "County services, shelter status and debris pickup. Dial 954-831-4000 from outside the county." },
  { name: "FEMA Helpline", value: "800-621-3362", note: "Disaster assistance applications and status." },
  { name: "Florida Poison Information Center", value: "800-222-1222", note: "Generator exhaust, cleaning-chemical and floodwater exposure questions." },
];

const RESOURCES = [
  {
    group: "Mold and indoor air",
    items: [
      { label: "EPA: A Brief Guide to Mold, Moisture and Your Home", href: "https://www.epa.gov/mold/brief-guide-mold-moisture-and-your-home", note: "The source for the 24 to 48 hour drying window and the 30 to 50 percent humidity target." },
      { label: "CDC: Mold after a disaster", href: "https://www.cdc.gov/mold-health/about/flood.html", note: "Cleanup steps, what to throw away, and who should stay out of the house." },
      { label: "Florida Department of Health: Mold", href: "https://www.floridahealth.gov/environmental-health/mold/index.html", note: "State guidance plus the licensed mold assessor and remediator lookup." },
      { label: "Florida DBPR: verify a mold assessor or remediator license", href: "https://www.myfloridalicense.com/wl11.asp", note: "Florida licenses both roles. Check before you pay a contractor." },
    ],
  },
  {
    group: "Flood recovery and money",
    items: [
      { label: "DisasterAssistance.gov", href: "https://www.disasterassistance.gov/", note: "Register for FEMA individual assistance after a federal declaration." },
      { label: "National Flood Insurance Program: how to file a claim", href: "https://www.floodsmart.gov/how-do-i-start-my-claim", note: "Start the claim, document damage and meet the adjuster." },
      { label: "Broward County Emergency Management", href: "https://www.broward.org/Emergency/Pages/Default.aspx", note: "Local alerts, shelters, sandbag sites and recovery centers." },
      { label: "Florida Division of Emergency Management", href: "https://www.floridadisaster.org/", note: "Statewide declarations and recovery programs." },
    ],
  },
  {
    group: "Health and asthma",
    items: [
      { label: "Florida Health CHARTS asthma profile", href: "https://www.flhealthcharts.gov/ChartsDashboards/rdPage.aspx?rdReport=Asthma.AsthmaProfile", note: "County-level asthma emergency department and hospitalization rates." },
      { label: "Florida Asthma Program", href: "https://www.floridahealth.gov/diseases-and-conditions/asthma/index.html", note: "Asthma-friendly home checklists and school resources." },
      { label: "National Academies: Damp Indoor Spaces and Health (2004)", href: "https://nap.nationalacademies.org/catalog/11011/damp-indoor-spaces-and-health", note: "The evidence review linking indoor dampness to asthma symptoms." },
    ],
  },
];

export default function HubPage() {
  return (
    <main>
      <section className="border-b border-line-soft bg-panel">
        <div className="mx-auto grid max-w-7xl gap-10 px-5 py-14 sm:px-8 lg:grid-cols-[1.3fr_1fr] lg:items-end">
          <div>
            <h1 className="font-display text-4xl font-extrabold tracking-tight text-ink sm:text-5xl">South Florida Climate Resilience Hub</h1>
            <p className="mt-5 max-w-2xl text-lg leading-8 text-body">
              Everything a Broward County household needs in the first 72 hours after water gets in: the order to do things, the
              numbers to call, and the official pages that back every claim on this site. Built for the communities of Florida&rsquo;s
              25th congressional district, from Weston and Davie to Pembroke Pines, Hollywood and Miramar.
            </p>
          </div>
          <div className="rounded-lg border border-line-soft bg-canvas p-5">
            <h2 className="font-display text-xl font-bold text-ink">Why 72 hours</h2>
            <p className="mt-2 text-[15px] leading-6 text-body">
              The EPA and FEMA both say wet building materials usually will not grow mold if they are dried within 24 to 48 hours.
              In South Florida humidity, that window is the whole game. The checklist below is ordered around it.
            </p>
          </div>
        </div>
      </section>

      <section id="checklist" className="mx-auto max-w-7xl px-5 py-14 sm:px-8">
        <h2 className="font-display text-3xl font-bold text-ink">Post-storm checklist</h2>
        <div className="mt-6">
          <StormChecklist />
        </div>
      </section>

      <section id="contacts" className="border-y border-line-soft bg-panel">
        <div className="mx-auto max-w-7xl px-5 py-14 sm:px-8">
          <h2 className="font-display text-3xl font-bold text-ink">Who to call</h2>
          <dl className="mt-6 grid gap-5 md:grid-cols-2 xl:grid-cols-4">
            {CONTACTS.map((contact) => (
              <div key={contact.name} className="rounded-lg border border-line-soft bg-canvas p-5">
                <dt className="font-display text-lg font-bold text-ink">{contact.name}</dt>
                <dd className="mt-2 font-display text-2xl font-bold tabular-nums text-clinical-deep">{contact.value}</dd>
                <dd className="mt-2 text-[15px] leading-6 text-muted">{contact.note}</dd>
              </div>
            ))}
          </dl>
        </div>
      </section>

      <section id="resources" className="mx-auto max-w-7xl px-5 py-14 sm:px-8">
        <h2 className="font-display text-3xl font-bold text-ink">Official resources</h2>
        <div className="mt-6 grid gap-8 lg:grid-cols-3">
          {RESOURCES.map((group) => (
            <div key={group.group}>
              <h3 className="font-display text-xl font-bold text-ink">{group.group}</h3>
              <ul className="mt-3 divide-y divide-line-soft border-y border-line-soft">
                {group.items.map((item) => (
                  <li key={item.href} className="py-3">
                    <a href={item.href} target="_blank" rel="noopener noreferrer" className="font-semibold text-clinical-deep underline underline-offset-4 hover:text-clinical">
                      {item.label}
                    </a>
                    <p className="mt-1 text-[15px] leading-6 text-muted">{item.note}</p>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
        <div className="mt-10">
          <Disclaimer />
        </div>
      </section>
    </main>
  );
}
