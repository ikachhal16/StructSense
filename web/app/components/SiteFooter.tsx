import Link from "next/link";
import Disclaimer from "./Disclaimer";

export default function SiteFooter() {
  return (
    <footer className="border-t border-line-soft bg-panel">
      <div className="mx-auto max-w-7xl px-5 py-10 sm:px-8">
        <Disclaimer />
        <div className="mt-8 flex flex-col gap-6 text-[15px] text-muted md:flex-row md:items-start md:justify-between">
          <div className="max-w-xl">
            <p className="font-display text-lg font-bold text-ink">StructSense</p>
            <p className="mt-2 leading-6">
              Phone-sensor triage for hidden water damage, built for South Florida homes. All sensor processing happens on the phone.
              Nothing you measure is uploaded unless you choose to share a report.
            </p>
          </div>
          <nav aria-label="Footer navigation" className="flex flex-wrap gap-x-6 gap-y-2 font-semibold text-body">
            <Link href="/" className="hover:text-clinical-deep">Home</Link>
            <Link href="/hub" className="hover:text-clinical-deep">Resilience Hub</Link>
            <Link href="/dashboard" className="hover:text-clinical-deep">Dashboard</Link>
            <a href="https://www.epa.gov/mold" target="_blank" rel="noopener noreferrer" className="hover:text-clinical-deep">EPA mold guidance</a>
          </nav>
        </div>
      </div>
    </footer>
  );
}
