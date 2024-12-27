"use client";

import { usePathname } from "next/navigation";
import Header from "./Header";
import Footer from "./Footer";

export default function Layout({ children }) {
  const pathname = usePathname();
  const showHeader = pathname !== "/";
  const showFooter = pathname !== "/";

  return (
    <div className="min-h-screen flex flex-col">
      {showHeader && <Header />}
      <main className={`${showHeader ? "pt-16" : ""} flex-grow`}>
        {children}
      </main>
      {showFooter && <Footer />}
    </div>
  );
}
