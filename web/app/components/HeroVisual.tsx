"use client";

import { useEffect, useState } from "react";

/* Animated acoustic comparison: the reference trace draws first, then the suspect
   trace draws under it, then the verdict arrives. It loops so the landing page
   always shows the tool doing its job. */

const WIDTH = 560;
const HEIGHT = 300;
const LEFT = 46;
const RIGHT = 20;
const TOP = 22;
const BOTTOM = 34;
const BINS = 30;
const DB_MIN = -45;
const DB_MAX = -15;

function series(base: number, dip: number, seed: number) {
  const out: number[] = [];
  for (let i = 0; i < BINS; i++) {
    const ramp = i < 3 ? -12 * (3 - i) / 3 : 0;
    const wobble = Math.sin(i * 0.9 + seed) * 1.4 + Math.sin(i * 2.3 + seed * 2) * 0.6;
    out.push(base + ramp + wobble - dip * Math.min(1, i / 6));
  }
  return out;
}

const REFERENCE = series(-24, 0, 1.3);
const SUSPECT = series(-24, 7.5, 2.9);

function mean(values: number[]) {
  const settled = values.slice(3);
  return settled.reduce((a, b) => a + b, 0) / settled.length;
}

export default function HeroVisual() {
  const [stage, setStage] = useState(0);

  useEffect(() => {
    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduced) {
      setStage(3);
      return;
    }
    let cancelled = false;
    const run = async () => {
      while (!cancelled) {
        setStage(0);
        await wait(500);
        setStage(1);
        await wait(2200);
        setStage(2);
        await wait(2200);
        setStage(3);
        await wait(3600);
      }
    };
    run();
    return () => { cancelled = true; };
  }, []);

  const plotWidth = WIDTH - LEFT - RIGHT;
  const plotHeight = HEIGHT - TOP - BOTTOM;
  const x = (i: number) => LEFT + (i / (BINS - 1)) * plotWidth;
  const y = (db: number) => TOP + (1 - (db - DB_MIN) / (DB_MAX - DB_MIN)) * plotHeight;
  const path = (values: number[]) => values.map((v, i) => `${i === 0 ? "M" : "L"}${x(i).toFixed(1)},${y(v).toFixed(1)}`).join(" ");

  const delta = mean(SUSPECT) - mean(REFERENCE);
  const ticks = [-40, -30, -20];

  return (
    <div className="rounded-xl border border-line-soft bg-panel p-5 shadow-sm">
      <div className="flex flex-wrap items-baseline justify-between gap-2">
        <p className="font-display text-lg font-bold text-ink">Acoustic check, garage north wall</p>
        <p className="text-[15px] text-muted">Microphone level, dBFS, over 3 seconds</p>
      </div>
      <svg viewBox={`0 0 ${WIDTH} ${HEIGHT}`} className="mt-3 w-full" role="img" aria-label="Two loudness traces: the reference spot holds steady while the suspect spot drops about seven decibels, indicating absorption by wet drywall.">
        {ticks.map((tick) => (
          <g key={tick}>
            <line x1={LEFT} x2={WIDTH - RIGHT} y1={y(tick)} y2={y(tick)} stroke="#e2e8f0" strokeWidth="1" />
            <text x={LEFT - 8} y={y(tick) + 4} textAnchor="end" fontSize="11" fill="#475569" style={{ fontVariantNumeric: "tabular-nums" }}>{tick}</text>
          </g>
        ))}
        <line x1={LEFT} x2={WIDTH - RIGHT} y1={TOP + plotHeight} y2={TOP + plotHeight} stroke="#cbd5e1" strokeWidth="1" />
        <text x={LEFT} y={HEIGHT - 10} fontSize="11" fill="#475569">0 s</text>
        <text x={WIDTH - RIGHT} y={HEIGHT - 10} fontSize="11" fill="#475569" textAnchor="end">3 s</text>

        <path d={path(REFERENCE)} fill="none" stroke="#0284c7" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" pathLength={1} style={{ strokeDasharray: 1, strokeDashoffset: stage >= 1 ? 0 : 1, transition: stage >= 1 ? "stroke-dashoffset 2s linear" : "none" }} />
        <path d={path(SUSPECT)} fill="none" stroke="#f59e0b" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" pathLength={1} style={{ strokeDasharray: 1, strokeDashoffset: stage >= 2 ? 0 : 1, transition: stage >= 2 ? "stroke-dashoffset 2s linear" : "none" }} />

        <g style={{ opacity: stage >= 2 ? 1 : 0, transition: "opacity 0.4s 1.8s" }}>
          <text x={x(BINS - 1) - 4} y={y(REFERENCE[BINS - 1]) - 8} fontSize="12" fontWeight="600" fill="#0f172a" textAnchor="end">{mean(REFERENCE).toFixed(0)} dB</text>
          <text x={x(BINS - 1) - 4} y={y(SUSPECT[BINS - 1]) + 16} fontSize="12" fontWeight="600" fill="#0f172a" textAnchor="end">{mean(SUSPECT).toFixed(0)} dB</text>
        </g>
      </svg>
      <div className="mt-2 flex flex-wrap items-center gap-x-5 gap-y-1 text-[15px] text-body">
        <span className="flex items-center gap-2"><span aria-hidden="true" className="inline-block h-0.5 w-5 rounded bg-clinical" />Reference spot, known dry</span>
        <span className="flex items-center gap-2"><span aria-hidden="true" className="inline-block h-0.5 w-5 rounded bg-alert" />Suspect spot, below the window</span>
      </div>
      <div
        className={`mt-4 rounded-lg border border-alert/70 bg-alert-soft px-4 py-3 ${stage >= 3 ? "rise-in" : "invisible"}`}
        aria-live="polite"
      >
        <p className="font-display text-lg font-bold text-ink">Possible saturated drywall</p>
        <p className="mt-1 text-[15px] leading-6 text-body">
          The suspect spot absorbed {Math.abs(delta).toFixed(1)} dB more of the tone than the reference. Wet drywall damps low frequencies. Confirm with a pin moisture meter or a licensed inspector.
        </p>
      </div>
    </div>
  );
}

function wait(ms: number) {
  return new Promise<void>((resolve) => setTimeout(resolve, ms));
}
