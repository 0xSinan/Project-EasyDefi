import Image from "next/image";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import {
  NavigationMenu,
  NavigationMenuItem,
  NavigationMenuList,
  NavigationMenuLink,
} from "../components/ui/navigation-menu";
import { cn } from "../lib/utils";
import Link from "next/link";

const Header = () => {
  return (
    <div className="border-b bg-gradient-brand-light">
      <div className="flex h-16 items-center px-4 container mx-auto">
        <Link href="/" className="mr-8 hover:opacity-80">
          <Image
            src="/images/easydefi-logo.png"
            alt="Easy DeFi"
            width={58}
            height={58}
            priority
          />
        </Link>
        <NavigationMenu className="mx-6">
          <NavigationMenuList className="gap-16">
            <NavigationMenuItem>
              <Link href="/trade" legacyBehavior passHref>
                <NavigationMenuLink
                  className={cn(
                    "text-lg font-semibold hover:text-brand-pink-dark"
                  )}
                >
                  Trade
                </NavigationMenuLink>
              </Link>
            </NavigationMenuItem>
            <NavigationMenuItem>
              <Link href="/pool" legacyBehavior passHref>
                <NavigationMenuLink
                  className={cn(
                    "text-lg font-semibold hover:text-brand-pink-dark"
                  )}
                >
                  Pool
                </NavigationMenuLink>
              </Link>
            </NavigationMenuItem>
            <NavigationMenuItem>
              <Link href="/dashboard" legacyBehavior passHref>
                <NavigationMenuLink
                  className={cn(
                    "text-lg font-semibold hover:text-brand-pink-dark"
                  )}
                >
                  Dashboard
                </NavigationMenuLink>
              </Link>
            </NavigationMenuItem>
            <NavigationMenuItem>
              <NavigationMenuLink
                className={cn(
                  "text-lg font-semibold hover:text-brand-pink-dark opacity-50 cursor-not-allowed"
                )}
              >
                Earn to Learn
              </NavigationMenuLink>
            </NavigationMenuItem>
            <NavigationMenuItem>
              <NavigationMenuLink
                className={cn(
                  "text-lg font-semibold hover:text-brand-pink-dark opacity-50 cursor-not-allowed"
                )}
              >
                Partners
              </NavigationMenuLink>
            </NavigationMenuItem>
          </NavigationMenuList>
        </NavigationMenu>
        <div className="ml-auto">
          <ConnectButton />
        </div>
      </div>
    </div>
  );
};

export default Header;
