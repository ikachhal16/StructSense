export const DISCLAIMER =
  "StructSense acts as a preliminary structural triage tool. It does not replace a licensed professional structural engineer.";

export default function Disclaimer({ compact = false }: { compact?: boolean }) {
  return (
    <p
      role="note"
      className={`flex items-start gap-3 rounded-md border border-alert/60 bg-alert-soft text-ink ${compact ? "px-3 py-2 text-sm leading-5" : "px-4 py-3 text-[15px] leading-6"}`}
    >
      <svg aria-hidden="true" viewBox="0 0 24 24" width="20" height="20" className="mt-0.5 shrink-0 text-alert-deep" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M12 3 2.5 20h19L12 3Z" />
        <path d="M12 10v4" />
        <path d="M12 17.5h.01" />
      </svg>
      <span>{DISCLAIMER}</span>
    </p>
  );
}
