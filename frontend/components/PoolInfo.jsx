"use client";

import { useState } from "react";
import { useAccount } from "wagmi";
import { formatUnits } from "viem";
import Image from "next/image";
import { Button } from "./ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "./ui/dialog";
import {
  Accordion,
  AccordionItem,
  AccordionTrigger,
  AccordionContent,
} from "./ui/accordion";
import Deposit from "./Deposit";
import Withdraw from "./Withdraw";
import { useUserShares } from "../hooks/useUserShares";
import { usePools } from "../hooks/usePools";
import Events from "./Events";
import { PiggyBank, Settings, Activity } from "lucide-react";

const PoolInfo = () => {
  const { isConnected } = useAccount();
  const [isDepositOpen, setIsDepositOpen] = useState(false);
  const [isWithdrawOpen, setIsWithdrawOpen] = useState(false);
  const [selectedPool, setSelectedPool] = useState(null);
  const { userShares, refetchUserShares } = useUserShares();
  const { poolsFetched, isPendingPools, refetchPools } = usePools();
  const [eventsKey, setEventsKey] = useState(0);

  const handleSuccess = async () => {
    await refetchPools();
    await refetchUserShares();
    setEventsKey((prev) => prev + 1);
  };

  const renderPoolCard = (pool, showWithdraw = false) => (
    <div
      key={pool.tokenA}
      className="p-6 bg-white rounded-3xl border shadow-sm hover:shadow-md transition-shadow"
    >
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-4">
          <div className="flex -space-x-2">
            <Image
              src="/images/tokens/alyra-logo.png"
              alt="Token A"
              width={40}
              height={40}
              className="rounded-full border-2 border-white"
            />
            <Image
              src="/images/tokens/salyra-logo.png"
              alt="Token B"
              width={40}
              height={40}
              className="rounded-full border-2 border-white"
            />
          </div>
          <div>
            <h3 className="text-lg font-bold">ALY/sALY</h3>
          </div>
        </div>

        <div className="flex items-center space-x-8">
          <div>
            <p className="text-sm text-gray-500">TVL</p>
            <p className="font-bold">
              ${" "}
              {(
                Number(formatUnits(pool.reserveA, 18)) +
                Number(formatUnits(pool.reserveB, 18))
              ).toFixed(2)}
            </p>
          </div>
          <div>
            <p className="text-sm text-gray-500">APR</p>
            <p className="font-bold text-green-500">
              {(Number(formatUnits(pool.fee, 2)) * 365).toFixed(2)}%
            </p>
          </div>
          <div className="flex space-x-2">
            <Button
              className="rounded-2xl"
              variant="outline"
              onClick={() => {
                setSelectedPool(pool);
                setIsDepositOpen(true);
              }}
            >
              Deposit
            </Button>
            {showWithdraw && (
              <Button
                className="rounded-2xl"
                variant="outline"
                onClick={() => {
                  setSelectedPool(pool);
                  setIsWithdrawOpen(true);
                }}
              >
                Withdraw
              </Button>
            )}
          </div>
        </div>
      </div>
    </div>
  );

  return (
    <div className="container mx-auto p-6 space-y-6">
      <h1 className="text-4xl font-bold bg-clip-text">Liquidity Pool</h1>

      <div className="mb-12">
        <div className="flex items-center gap-2 mb-4">
          <div className="p-2 rounded-xl bg-gradient-brand">
            <PiggyBank className="h-6 w-6 text-white" />
          </div>
          <h2 className="text-xl font-bold">Available Pairs</h2>
        </div>
        <div className="space-y-4">
          {isPendingPools ? (
            <div className="text-center py-8 text-gray-500">
              Loading pools...
            </div>
          ) : (
            poolsFetched?.map((pool) => renderPoolCard(pool))
          )}
        </div>
      </div>

      {isConnected && userShares && (
        <div>
          <div className="flex items-center gap-2 mb-4">
            <div className="p-2 rounded-xl bg-gradient-button">
              <Settings className="h-6 w-6 text-white" />
            </div>
            <h2 className="text-xl font-bold">My Positions</h2>
          </div>
          <div className="space-y-4">
            {isPendingPools ? (
              <div className="text-center py-8 text-gray-500">
                Loading pools...
              </div>
            ) : (
              poolsFetched?.map((pool) => renderPoolCard(pool, true))
            )}
          </div>
        </div>
      )}

      <div className="mt-12">
        <Accordion type="single" collapsible>
          <AccordionItem value="events" className="border-none">
            <AccordionTrigger className="hover:no-underline">
              <div className="flex items-center gap-2">
                <div className="p-2 rounded-xl bg-gradient-button-hover">
                  <Activity className="h-6 w-6 text-white" />
                </div>
                <h2 className="text-xl font-bold">Recent Pool Activity</h2>
              </div>
            </AccordionTrigger>
            <AccordionContent>
              <div className="pt-4">
                <Events key={eventsKey} type="all" limit={5} />
              </div>
            </AccordionContent>
          </AccordionItem>
        </Accordion>
      </div>

      <Dialog open={isDepositOpen} onOpenChange={setIsDepositOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Deposit Liquidity</DialogTitle>
          </DialogHeader>
          <Deposit
            onSuccess={() => {
              handleSuccess();
              setIsDepositOpen(false);
            }}
            selectedPool={selectedPool}
          />
        </DialogContent>
      </Dialog>

      <Dialog open={isWithdrawOpen} onOpenChange={setIsWithdrawOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Withdraw Liquidity</DialogTitle>
          </DialogHeader>
          <Withdraw
            onSuccess={() => {
              handleSuccess();
              setIsWithdrawOpen(false);
            }}
            selectedPool={selectedPool}
          />
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default PoolInfo;
