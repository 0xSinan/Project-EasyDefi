"use client";

import { useEffect } from "react";
import { TOKENS } from "../constants/contract";
import { useAccount } from "wagmi";
import { formatUnits } from "viem";
import { Button } from "../components/ui/button";
import { Alert, AlertDescription, AlertTitle } from "../components/ui/alert";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "./ui/card";
import { Coins, ArrowRight, PiggyBank } from "lucide-react";
import Link from "next/link";
import Image from "next/image";
import NotConnected from "./NotConnected";
import { useUserBalances } from "../hooks/useUserBalances";
import { useUserShares } from "../hooks/useUserShares";

const UserInfo = () => {
  const { address, isConnected } = useAccount();
  const { userBalanceA, userBalanceB, refetchBalanceA, refetchBalanceB } =
    useUserBalances();
  const { userShares, refetchUserShares } = useUserShares();

  useEffect(() => {
    if (address) {
      refetchBalanceA();
      refetchBalanceB();
      refetchUserShares();
    }
  }, [address, refetchBalanceA, refetchBalanceB, refetchUserShares]);

  if (!isConnected) {
    return <NotConnected />;
  }

  const hasIdleALY = userBalanceA && Number(formatUnits(userBalanceA, 18)) > 0;
  const hasLPPosition = userShares && Number(formatUnits(userShares, 18)) > 0;

  return (
    <div className="container mx-auto p-6 space-y-6">
      <h1 className="text-4xl font-bold bg-clip-text">Dashboard</h1>

      {hasIdleALY && (
        <Alert className="rounded-3xl bg-gradient-brand border-none">
          <div className="flex items-center justify-between w-full">
            <div className="flex items-start gap-4">
              <Coins className="h-10 w-10 text-brand-pink-dark mt-1" />
              <div className="space-y-1">
                <AlertTitle className="text-lg font-semibold">
                  Earn 2.94% APR on your idle ALY
                </AlertTitle>
                <AlertDescription>
                  <p>
                    You have {Number(formatUnits(userBalanceA, 18)).toFixed(2)}{" "}
                    ALY tokens not generating rewards.{" "}
                    <span className="font-medium">
                      Start earning passive income by converting to sALY!
                    </span>
                  </p>
                </AlertDescription>
              </div>
            </div>
            <Link href="/trade">
              <Button className="bg-gradient-button hover:bg-gradient-button-hover text-white border-none shadow-md rounded-2xl">
                Start Earning <ArrowRight className="h-4 w-4" />
              </Button>
            </Link>
          </div>
        </Alert>
      )}

      <Card className="rounded-3xl shadow-sm hover:shadow-md transition-shadow bg-gradient-brand-light">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <PiggyBank className="h-6 w-6 text-brand-pink-dark" />
            Active LP Positions
          </CardTitle>
          <CardDescription>Your active liquidity positions</CardDescription>
        </CardHeader>
        <CardContent>
          {hasLPPosition ? (
            <div className="space-y-4">
              <div className="flex items-center justify-between p-4 bg-white rounded-xl">
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <div className="flex -space-x-2">
                      <Image
                        src={TOKENS.ALYRA.logo}
                        alt="ALY"
                        width={24}
                        height={24}
                        className="rounded-full border-2 border-white"
                      />
                      <Image
                        src={TOKENS.LIQUID_ALYRA.logo}
                        alt="sALY"
                        width={24}
                        height={24}
                        className="rounded-full border-2 border-white"
                      />
                    </div>
                    <p className="font-semibold">ALY/sALY Pool</p>
                  </div>
                  <p className="text-sm text-gray-500">
                    {Number(formatUnits(userShares, 18)).toFixed(6)} LP Tokens
                  </p>
                </div>
                <Link href="/pool">
                  <Button variant="outline" className="rounded-2xl">
                    Manage
                  </Button>
                </Link>
              </div>
            </div>
          ) : (
            <div className="text-center py-8 text-gray-500">
              No active LP positions
            </div>
          )}
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card className="rounded-3xl shadow-sm hover:shadow-md transition-shadow bg-white">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Image
                src={TOKENS.ALYRA.logo}
                alt="ALY"
                width={48}
                height={48}
                className="rounded-full"
              />
              ALY Balance
            </CardTitle>
          </CardHeader>
          <CardContent className="text-2xl font-bold">
            {userBalanceA
              ? Number(formatUnits(userBalanceA, 18)).toFixed(2)
              : "0"}{" "}
            ALY
          </CardContent>
        </Card>

        <Card className="rounded-3xl shadow-sm hover:shadow-md transition-shadow bg-white">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Image
                src={TOKENS.LIQUID_ALYRA.logo}
                alt="sALY"
                width={48}
                height={48}
                className="rounded-full"
              />
              sALY Balance
            </CardTitle>
          </CardHeader>
          <CardContent className="text-2xl font-bold">
            {userBalanceB
              ? Number(formatUnits(userBalanceB, 18)).toFixed(2)
              : "0"}{" "}
            sALY
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default UserInfo;
