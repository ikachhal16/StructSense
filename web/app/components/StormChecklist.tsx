"use client";

import { useEffect, useState } from "react";

type Task = { id: string; text: string; detail?: string };
type Phase = { title: string; window: string; tasks: Task[] };

const PHASES: Phase[] = [
  {
    title: "Before you go back in",
    window: "Hour 0",
    tasks: [
      { id: "power", text: "Confirm the power is off at the breaker before stepping into standing water.", detail: "If the panel itself is wet, wait for the utility or an electrician." },
      { id: "gas", text: "Smell for gas and listen for hissing. Leave and call the gas company if you notice either." },
      { id: "ppe", text: "Put on an N95 mask, gloves and boots. Floodwater carries sewage and mold spores." },
      { id: "photos", text: "Photograph every room and the water line on the walls before you move anything.", detail: "Insurers and FEMA ask for this. Include serial numbers on appliances." },
    ],
  },
  {
    title: "Stop the moisture",
    window: "Hours 1 to 24",
    tasks: [
      { id: "water", text: "Get standing water out with a pump or wet vacuum, then open windows if the outside air is drier." },
      { id: "wetstuff", text: "Carry soaked rugs, mattresses, upholstered furniture and cardboard outside." },
      { id: "drywall", text: "Mark the water line on drywall. Anything that stayed wet past 48 hours usually has to be cut out.", detail: "StructSense's acoustic check helps you decide where to look first." },
      { id: "fans", text: "Run fans and a dehumidifier. Aim for indoor humidity under 60 percent, ideally 30 to 50." },
    ],
  },
  {
    title: "Prevent the mold",
    window: "Hours 24 to 72",
    tasks: [
      { id: "claim", text: "Open the insurance claim and, if a federal disaster was declared, register with FEMA.", detail: "Both can be started from a phone; the links are below." },
      { id: "cavities", text: "Sweep suspect walls with the magnetometer and acoustic tools to find wet cavities behind intact paint." },
      { id: "puck", text: "Leave a humidity puck in the crawlspace or lowest room and watch the dashboard for readings over 60 percent." },
      { id: "kids", text: "Keep children and anyone with asthma out of rooms that smell musty until they are dry and cleaned." },
    ],
  },
];

const STORAGE_KEY = "structsense.checklist.v1";

export default function StormChecklist() {
  const [done, setDone] = useState<Record<string, boolean>>({});
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    try {
      const saved = window.localStorage.getItem(STORAGE_KEY);
      if (saved) setDone(JSON.parse(saved));
    } catch {
      // Storage can be blocked; the list still works without persistence.
    }
    setLoaded(true);
  }, []);

  useEffect(() => {
    if (!loaded) return;
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(done));
    } catch {
      // Ignore storage failures.
    }
  }, [done, loaded]);

  const total = PHASES.reduce((n, phase) => n + phase.tasks.length, 0);
  const completed = Object.values(done).filter(Boolean).length;

  return (
    <div>
      <div className="flex flex-wrap items-end justify-between gap-4">
        <p className="text-[15px] text-muted">
          Your progress is saved on this device only. {completed} of {total} done.
        </p>
        <button
          type="button"
          onClick={() => setDone({})}
          className="rounded-md border border-line px-3 py-1.5 text-sm font-semibold text-body transition hover:border-clinical hover:text-clinical-deep"
        >
          Reset list
        </button>
      </div>
      <div className="mt-3 h-2 w-full overflow-hidden rounded-full bg-line-soft" aria-hidden="true">
        <div className="h-full rounded-full bg-clinical transition-[width] duration-500" style={{ width: `${(completed / total) * 100}%` }} />
      </div>
      <div className="mt-8 grid gap-6 lg:grid-cols-3">
        {PHASES.map((phase) => (
          <section key={phase.title} className="rounded-lg border border-line-soft bg-panel p-5">
            <h3 className="font-display text-xl font-bold text-ink">{phase.title}</h3>
            <p className="mt-1 text-[15px] font-semibold text-clinical-deep">{phase.window}</p>
            <ul className="mt-4 space-y-3">
              {phase.tasks.map((task) => {
                const checked = Boolean(done[task.id]);
                return (
                  <li key={task.id}>
                    <label className="flex cursor-pointer gap-3">
                      <input
                        type="checkbox"
                        checked={checked}
                        onChange={(event) => setDone((prev) => ({ ...prev, [task.id]: event.target.checked }))}
                        className="mt-1 h-4 w-4 shrink-0 accent-clinical"
                      />
                      <span className={`text-[15px] leading-6 ${checked ? "text-muted line-through" : "text-body"}`}>
                        {task.text}
                        {task.detail && <span className="mt-0.5 block text-sm leading-5 text-muted no-underline">{task.detail}</span>}
                      </span>
                    </label>
                  </li>
                );
              })}
            </ul>
          </section>
        ))}
      </div>
    </div>
  );
}
