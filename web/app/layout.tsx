import type { Metadata } from "next";
import { Archivo, Inter } from "next/font/google";
import "./globals.css";
import SiteFooter from "./components/SiteFooter";
import SiteNav from "./components/SiteNav";

const archivo = Archivo({
  variable: "--font-archivo",
  subsets: ["latin"],
  weight: ["500", "600", "700", "800"],
});

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "StructSense",
  description:
    "StructSense is a pocket first-aid kit for home resiliency: phone-sensor triage for hidden water damage, plus South Florida post-storm resources and a live humidity dashboard.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={`${archivo.variable} ${inter.variable} antialiased`}>
      <body className="min-h-screen">
        <SiteNav />
        {children}
        <SiteFooter />
      </body>
    </html>
  );
}
