import Link from "next/link";

const LINKS = [
  { href: "/", label: "Home", short: "Home" },
  { href: "/hub", label: "Resilience Hub", short: "Hub" },
  { href: "/dashboard", label: "Dashboard", short: "Dashboard" },
];

export default function SiteNav() {
  return (
    <header className="sticky top-0 z-30 border-b border-line-soft bg-panel/95 backdrop-blur-sm">
      <div className="mx-auto flex max-w-7xl items-center justify-between gap-6 px-5 py-3 sm:px-8">
        <Link href="/" className="flex items-center gap-2.5 font-display text-xl font-bold text-ink" aria-label="StructSense home">
          <span aria-hidden="true" className="grid h-8 w-8 place-items-center rounded-md bg-clinical text-white">
            <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M3 11.5 12 4l9 7.5" />
              <path d="M5.5 10v9h13v-9" />
              <path d="M9 19v-5h6v5" />
            </svg>
          </span>
          StructSense
        </Link>
        <nav aria-label="Main navigation" className="flex items-center gap-0.5 text-[15px] font-semibold text-body sm:gap-1">
          {LINKS.map((link) => (
            <Link key={link.href} href={link.href} className={`rounded-md px-2 py-1.5 transition hover:bg-clinical-soft hover:text-clinical-deep sm:px-3 ${link.href === "/" ? "hidden sm:inline" : ""}`}>
              <span className="sm:hidden">{link.short}</span>
              <span className="hidden sm:inline">{link.label}</span>
            </Link>
          ))}
        </nav>
      </div>
    </header>
  );
}
