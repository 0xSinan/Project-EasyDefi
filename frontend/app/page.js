import Image from "next/image";
import { Button } from "../components/ui/button";
import Link from "next/link";

export default function Home() {
  return (
    <div className="min-h-screen w-full flex flex-col items-center justify-center gap-6 bg-gradient-brand">
      <div className="text-center space-y-2 mb-2">
        <h1 className="text-5xl font-bold text-white">
          Earn Passive Income with Your Tokens
        </h1>
        <p className="text-xl text-white/90">
          Convert your tokens to their liquid equivalent and start earning
        </p>
      </div>
      <Image
        src="/images/easydefi-logo.png"
        alt="EasyDeFi Logo"
        width={400}
        height={400}
        className="animate-fade-in"
        priority
      />
      <Button
        asChild
        className="text-lg px-8 py-6 bg-gradient-button hover:bg-gradient-button-hover text-white border-none shadow-md"
      >
        <Link href="/trade">Enter App</Link>
      </Button>
    </div>
  );
}
