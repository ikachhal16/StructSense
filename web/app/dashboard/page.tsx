import type { Metadata } from "next";
import Disclaimer from "../components/Disclaimer";
import HumidityDashboard from "../components/HumidityDashboard";

export const metadata: Metadata = {
  title: "Disaster Triage Dashboard | StructSense",
  description: "Live crawlspace humidity from Bluetooth sensor pucks, with an alert whenever a reading crosses the 60 percent EPA line.",
};

export default function DashboardPage() {
  return (
    <main className="mx-auto max-w-7xl px-5 py-10 sm:px-8">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-4xl font-extrabold tracking-tight text-ink">Disaster Triage Dashboard</h1>
          <p className="mt-3 max-w-2xl text-[15px] leading-7 text-body">
            Humidity pucks left in the spaces you cannot watch. Anything over 60 percent relative humidity is flagged, because the
            EPA says wet materials usually start growing mold within 24 to 48 hours at that level.
          </p>
        </div>
        <div className="max-w-md">
          <Disclaimer compact />
        </div>
      </div>
      <div className="mt-8">
        <HumidityDashboard />
      </div>
    </main>
  );
}
