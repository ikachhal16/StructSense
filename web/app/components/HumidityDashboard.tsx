"use client";

import { useEffect, useMemo, useRef, useState } from "react";

/* Simulated puck telemetry. Every location is its own random walk around a damp
   South Florida baseline; "Simulate water intrusion" pushes one puck past the 60
   percent EPA alert line and then lets a dehumidifier pull it back down. */

type Reading = { t: number; humidity: number; temperatureF: number };
type Puck = { id: string; name: string; baseline: number; readings: Reading[]; storm: number };
type Crossing = { at: number; puck: string; direction: "above" | "below"; humidity: number };

const ALERT = 60;
const TICK_MS = 1000;
const MAX_POINTS = 300;
const WINDOWS = [
  { label: "Last 60 seconds", seconds: 60 },
  { label: "Last 2 minutes", seconds: 120 },
  { label: "Last 5 minutes", seconds: 300 },
];

function seedPuck(id: string, name: string, baseline: number, now: number): Puck {
  const readings: Reading[] = [];
  let humidity = baseline;
  let temperatureF = 78 + (baseline - 50) / 6;
  for (let i = 120; i >= 1; i--) {
    humidity += (Math.random() - 0.5) * 0.8 + (baseline - humidity) * 0.05;
    temperatureF += (Math.random() - 0.5) * 0.2;
    readings.push({ t: now - i * TICK_MS, humidity, temperatureF });
  }
  return { id, name, baseline, readings, storm: 0 };
}

function step(puck: Puck, now: number): Puck {
  const last = puck.readings[puck.readings.length - 1];
  let humidity = last.humidity + (Math.random() - 0.5) * 0.9;
  let temperatureF = last.temperatureF + (Math.random() - 0.5) * 0.2;
  let storm = puck.storm;
  if (storm > 0) {
    humidity += 1.4 * storm;
    temperatureF -= 0.04 * storm;
    storm = Math.max(0, storm - 0.025);
  } else {
    humidity += (puck.baseline - humidity) * 0.03;
  }
  humidity = Math.min(98, Math.max(30, humidity));
  temperatureF = Math.min(92, Math.max(66, temperatureF));
  const readings = [...puck.readings, { t: now, humidity, temperatureF }].slice(-MAX_POINTS);
  return { ...puck, readings, storm };
}

export default function HumidityDashboard() {
  const [pucks, setPucks] = useState<Puck[]>([]);
  const [crossings, setCrossings] = useState<Crossing[]>([]);
  const [windowSeconds, setWindowSeconds] = useState(120);
  const [showTable, setShowTable] = useState(false);
  const [now, setNow] = useState(0);
  const mounted = useRef(false);

  useEffect(() => {
    const start = Date.now();
    setNow(start);
    setPucks([
      seedPuck("crawlspace", "Crawlspace, north", 56, start),
      seedPuck("garage", "Garage wall cavity", 51, start),
      seedPuck("laundry", "Laundry closet", 48, start),
    ]);
    mounted.current = true;
    const id = window.setInterval(() => {
      const tick = Date.now();
      setNow(tick);
      setPucks((prev) => {
        const next = prev.map((puck) => step(puck, tick));
        const events: Crossing[] = [];
        next.forEach((puck, index) => {
          const before = prev[index].readings[prev[index].readings.length - 1].humidity;
          const after = puck.readings[puck.readings.length - 1].humidity;
          if (before < ALERT && after >= ALERT) events.push({ at: tick, puck: puck.name, direction: "above", humidity: after });
          if (before >= ALERT && after < ALERT) events.push({ at: tick, puck: puck.name, direction: "below", humidity: after });
        });
        if (events.length) setCrossings((log) => [...events, ...log].slice(0, 12));
        return next;
      });
    }, TICK_MS);
    return () => window.clearInterval(id);
  }, []);

  const triggerStorm = (id: string) => setPucks((prev) => prev.map((puck) => (puck.id === id ? { ...puck, storm: 1 } : puck)));

  const latest = pucks.map((puck) => puck.readings[puck.readings.length - 1]);
  const anyAlert = latest.some((reading) => reading && reading.humidity >= ALERT);
  const peak = latest.length ? latest.reduce((best, reading) => (reading.humidity > best.humidity ? reading : best), latest[0]) : null;
  const peakPuck = peak ? pucks[latest.indexOf(peak)] : null;

  if (!pucks.length) {
    return <div className="h-96 rounded-lg border border-line-soft bg-panel" aria-busy="true" />;
  }

  return (
    <div>
      <div className="flex flex-wrap items-center gap-3">
        <label className="flex items-center gap-2 text-[15px] font-semibold text-body">
          Time window
          <select
            value={windowSeconds}
            onChange={(event) => setWindowSeconds(Number(event.target.value))}
            className="rounded-md border border-line bg-panel px-2.5 py-1.5 text-[15px] font-medium text-ink"
          >
            {WINDOWS.map((option) => (
              <option key={option.seconds} value={option.seconds}>{option.label}</option>
            ))}
          </select>
        </label>
        <button
          type="button"
          onClick={() => setShowTable((value) => !value)}
          className="rounded-md border border-line bg-panel px-3 py-1.5 text-[15px] font-semibold text-body transition hover:border-clinical hover:text-clinical-deep"
        >
          {showTable ? "Show charts" : "Show table"}
        </button>
      </div>
      <p className="mt-3 text-[15px] text-muted">Simulated pucks, one reading per second. Live hardware uses the same Bluetooth Environmental Sensing profile the iOS app reads.</p>

      <div
        role="status"
        aria-live="polite"
        className={`mt-5 flex items-center gap-3 rounded-lg border px-4 py-3 text-[15px] font-semibold ${anyAlert ? "alert-flash border-alert-deep text-ink" : "border-ok/40 bg-ok-soft text-ink"}`}
      >
        {anyAlert ? (
          <>
            <svg aria-hidden="true" viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 3 2.5 20h19L12 3Z" /><path d="M12 10v4" /><path d="M12 17.5h.01" /></svg>
            <span>Humidity above 60 percent at {pucks.filter((_, i) => latest[i].humidity >= ALERT).map((p) => p.name).join(", ")}. Mold can start on wet materials within 24 to 48 hours. Run a dehumidifier and find the water source.</span>
          </>
        ) : (
          <>
            <svg aria-hidden="true" viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="m5 12.5 4.5 4.5L19 7.5" /></svg>
            <span>All pucks under the 60 percent EPA alert line.</span>
          </>
        )}
      </div>

      <div className="mt-6 grid gap-5 lg:grid-cols-[1.1fr_2fr]">
        <div className="rounded-lg border border-line-soft bg-panel p-5">
          <p className="text-[15px] font-semibold text-body">Highest humidity right now</p>
          <p className={`mt-1 font-body text-6xl font-semibold leading-none ${peak && peak.humidity >= ALERT ? "text-alert-deep" : "text-ink"}`}>
            {peak ? peak.humidity.toFixed(0) : "–"}<span className="text-3xl">%</span>
          </p>
          <p className="mt-2 text-[15px] text-muted">{peakPuck?.name}. EPA target is under 60 percent, ideally 30 to 50.</p>
          <div className="mt-5 h-2.5 w-full overflow-hidden rounded-full bg-clinical-soft" aria-hidden="true">
            <div
              className={`h-full rounded-full transition-[width] duration-700 ${peak && peak.humidity >= ALERT ? "bg-alert" : "bg-clinical"}`}
              style={{ width: `${peak ? Math.min(100, peak.humidity) : 0}%` }}
            />
          </div>
          <div className="mt-6 space-y-3">
            {pucks.map((puck) => {
              const current = puck.readings[puck.readings.length - 1];
              const minuteAgo = puck.readings[Math.max(0, puck.readings.length - 61)];
              const delta = current.humidity - minuteAgo.humidity;
              return (
                <div key={puck.id} className="flex items-center justify-between gap-3 border-t border-line-soft pt-3">
                  <div>
                    <p className="text-[15px] font-semibold text-ink">{puck.name}</p>
                    <p className="text-sm text-muted">{current.temperatureF.toFixed(0)} °F · {delta >= 0 ? "+" : ""}{delta.toFixed(1)} pts vs a minute ago</p>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="font-body text-2xl font-semibold text-ink">{current.humidity.toFixed(0)}%</span>
                    <button
                      type="button"
                      onClick={() => triggerStorm(puck.id)}
                      className="rounded-md border border-alert/70 bg-alert-soft px-2.5 py-1 text-sm font-semibold text-alert-deep transition hover:bg-alert hover:text-ink"
                    >
                      Simulate water intrusion
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        <div className="grid gap-5">
          {showTable ? (
            <ReadingsTable pucks={pucks} windowSeconds={windowSeconds} now={now} />
          ) : (
            pucks.map((puck) => <HumidityChart key={puck.id} puck={puck} windowSeconds={windowSeconds} now={now} />)
          )}
        </div>
      </div>

      <div className="mt-6 rounded-lg border border-line-soft bg-panel p-5">
        <h3 className="font-display text-lg font-bold text-ink">Threshold crossings</h3>
        {crossings.length === 0 ? (
          <p className="mt-2 text-[15px] text-muted">None yet. Crossings of the 60 percent line in either direction are logged here with the time.</p>
        ) : (
          <ul className="mt-2 divide-y divide-line-soft">
            {crossings.map((event) => (
              <li key={`${event.at}-${event.puck}`} className="flex flex-wrap items-center gap-x-4 py-2 text-[15px]">
                <span className="tabular-nums text-muted">{new Date(event.at).toLocaleTimeString()}</span>
                <span className="font-semibold text-ink">{event.puck}</span>
                <span className={event.direction === "above" ? "text-alert-deep" : "text-ok"}>
                  {event.direction === "above" ? "rose above" : "fell below"} 60% ({event.humidity.toFixed(0)}%)
                </span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}

const CHART = { width: 720, height: 190, left: 44, right: 56, top: 14, bottom: 28 };
const Y_MIN = 30;
const Y_MAX = 100;

function HumidityChart({ puck, windowSeconds, now }: { puck: Puck; windowSeconds: number; now: number }) {
  const [hoverIndex, setHoverIndex] = useState<number | null>(null);
  const svgRef = useRef<SVGSVGElement | null>(null);
  const [drawn, setDrawn] = useState(false);

  useEffect(() => {
    const id = window.requestAnimationFrame(() => setDrawn(true));
    return () => window.cancelAnimationFrame(id);
  }, []);

  const visible = useMemo(() => puck.readings.filter((reading) => reading.t >= now - windowSeconds * 1000), [puck.readings, now, windowSeconds]);
  const plotWidth = CHART.width - CHART.left - CHART.right;
  const plotHeight = CHART.height - CHART.top - CHART.bottom;
  const x = (t: number) => CHART.left + ((t - (now - windowSeconds * 1000)) / (windowSeconds * 1000)) * plotWidth;
  const y = (humidity: number) => CHART.top + (1 - (Math.min(Y_MAX, Math.max(Y_MIN, humidity)) - Y_MIN) / (Y_MAX - Y_MIN)) * plotHeight;

  const linePath = visible.map((reading, i) => `${i === 0 ? "M" : "L"}${x(reading.t).toFixed(1)},${y(reading.humidity).toFixed(1)}`).join(" ");
  const areaPath = visible.length
    ? `${linePath} L${x(visible[visible.length - 1].t).toFixed(1)},${(CHART.top + plotHeight).toFixed(1)} L${x(visible[0].t).toFixed(1)},${(CHART.top + plotHeight).toFixed(1)} Z`
    : "";
  const last = visible[visible.length - 1];
  const hovered = hoverIndex !== null ? visible[hoverIndex] : null;
  const over = last ? last.humidity >= ALERT : false;

  const onMove = (event: React.PointerEvent<SVGSVGElement>) => {
    const svg = svgRef.current;
    if (!svg || !visible.length) return;
    const rect = svg.getBoundingClientRect();
    const px = ((event.clientX - rect.left) / rect.width) * CHART.width;
    const t = now - windowSeconds * 1000 + ((px - CHART.left) / plotWidth) * windowSeconds * 1000;
    let best = 0;
    let bestDistance = Infinity;
    visible.forEach((reading, i) => {
      const distance = Math.abs(reading.t - t);
      if (distance < bestDistance) { bestDistance = distance; best = i; }
    });
    setHoverIndex(best);
  };

  const ticks = [40, 60, 80, 100];

  return (
    <figure className="rounded-lg border border-line-soft bg-panel p-4">
      <figcaption className="flex flex-wrap items-baseline justify-between gap-2">
        <span className="font-display text-lg font-bold text-ink">{puck.name}</span>
        <span className="text-[15px] text-muted">Relative humidity, percent</span>
      </figcaption>
      <svg
        ref={svgRef}
        viewBox={`0 0 ${CHART.width} ${CHART.height}`}
        className="mt-2 w-full touch-none"
        role="img"
        aria-label={`${puck.name} humidity over the ${windowSeconds} second window, currently ${last ? last.humidity.toFixed(0) : "unknown"} percent`}
        onPointerMove={onMove}
        onPointerLeave={() => setHoverIndex(null)}
      >
        {ticks.map((tick) => (
          <g key={tick}>
            <line x1={CHART.left} x2={CHART.width - CHART.right} y1={y(tick)} y2={y(tick)} stroke="#e2e8f0" strokeWidth="1" />
            <text x={CHART.left - 8} y={y(tick) + 4} textAnchor="end" fontSize="11" fill="#475569" style={{ fontVariantNumeric: "tabular-nums" }}>{tick}</text>
          </g>
        ))}
        <line x1={CHART.left} x2={CHART.width - CHART.right} y1={y(ALERT)} y2={y(ALERT)} stroke="#b45309" strokeWidth="1.5" strokeDasharray="5 4" />
        <text x={CHART.width - CHART.right + 6} y={y(ALERT) + 4} fontSize="11" fill="#b45309">60% alert</text>
        <line x1={CHART.left} x2={CHART.width - CHART.right} y1={CHART.top + plotHeight} y2={CHART.top + plotHeight} stroke="#cbd5e1" strokeWidth="1" />
        <text x={CHART.left} y={CHART.height - 8} fontSize="11" fill="#475569">{windowSeconds}s ago</text>
        <text x={CHART.width - CHART.right} y={CHART.height - 8} fontSize="11" fill="#475569" textAnchor="end">now</text>

        {areaPath && <path d={areaPath} fill={over ? "#f59e0b" : "#0284c7"} fillOpacity="0.1" />}
        {linePath && (
          <path
            d={linePath}
            fill="none"
            stroke={over ? "#f59e0b" : "#0284c7"}
            strokeWidth="2"
            strokeLinejoin="round"
            strokeLinecap="round"
            pathLength={1}
            style={{ strokeDasharray: 1, strokeDashoffset: drawn ? 0 : 1, transition: "stroke-dashoffset 1.2s ease-out, stroke 0.4s" }}
          />
        )}
        {last && (
          <g>
            <circle cx={x(last.t)} cy={y(last.humidity)} r="6" fill="#ffffff" />
            <circle cx={x(last.t)} cy={y(last.humidity)} r="4" fill={over ? "#f59e0b" : "#0284c7"} />
            <text x={x(last.t) + 10} y={y(last.humidity) + 4} fontSize="12" fontWeight="600" fill="#0f172a">{last.humidity.toFixed(0)}%</text>
          </g>
        )}
        {hovered && (
          <g>
            <line x1={x(hovered.t)} x2={x(hovered.t)} y1={CHART.top} y2={CHART.top + plotHeight} stroke="#475569" strokeWidth="1" />
            <circle cx={x(hovered.t)} cy={y(hovered.humidity)} r="6" fill="#ffffff" />
            <circle cx={x(hovered.t)} cy={y(hovered.humidity)} r="4" fill={hovered.humidity >= ALERT ? "#f59e0b" : "#0284c7"} />
          </g>
        )}
      </svg>
      <div className="mt-1 min-h-6 text-[15px] text-body" aria-live="polite">
        {hovered ? (
          <span>
            <strong className="text-ink">{hovered.humidity.toFixed(1)}%</strong> humidity · {hovered.temperatureF.toFixed(1)} °F · {new Date(hovered.t).toLocaleTimeString()}
          </span>
        ) : (
          <span className="text-muted">Hover or touch the chart to read a point.</span>
        )}
      </div>
    </figure>
  );
}

function ReadingsTable({ pucks, windowSeconds, now }: { pucks: Puck[]; windowSeconds: number; now: number }) {
  const rows = pucks.flatMap((puck) =>
    puck.readings
      .filter((reading) => reading.t >= now - windowSeconds * 1000)
      .filter((_, i) => i % 5 === 0)
      .map((reading) => ({ puck: puck.name, ...reading }))
  ).sort((a, b) => b.t - a.t);

  return (
    <div className="overflow-x-auto rounded-lg border border-line-soft bg-panel">
      <table className="w-full text-[15px]">
        <caption className="px-4 py-3 text-left font-display text-lg font-bold text-ink">Readings, every fifth second</caption>
        <thead>
          <tr className="border-y border-line-soft text-left text-muted">
            <th className="px-4 py-2 font-semibold">Time</th>
            <th className="px-4 py-2 font-semibold">Puck</th>
            <th className="px-4 py-2 text-right font-semibold">Humidity</th>
            <th className="px-4 py-2 text-right font-semibold">Temperature</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={`${row.puck}-${row.t}`} className="border-b border-line-soft">
              <td className="px-4 py-1.5 tabular-nums text-body">{new Date(row.t).toLocaleTimeString()}</td>
              <td className="px-4 py-1.5 text-ink">{row.puck}</td>
              <td className={`px-4 py-1.5 text-right tabular-nums ${row.humidity >= ALERT ? "font-semibold text-alert-deep" : "text-ink"}`}>{row.humidity.toFixed(1)}%</td>
              <td className="px-4 py-1.5 text-right tabular-nums text-ink">{row.temperatureF.toFixed(1)} °F</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
