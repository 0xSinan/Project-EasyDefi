"use client";

import { Button } from "./ui/button";
import { useState } from "react";
import { parseEther, formatUnits } from "viem";
import { useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { contractAddress, contractAbi } from "../constants/contract";
import { useUserShares } from "../hooks/useUserShares";
import TransactionInformations from "./Informations";

const Withdraw = ({ onSuccess, selectedPool }) => {
  const { userShares } = useUserShares();
  const [shares, setShares] = useState("");
  const { data: hash, isPending, error, writeContract } = useWriteContract();
  const { isLoading, isSuccess } = useWaitForTransactionReceipt({ hash });

  const withdraw = async () => {
    if (shares && selectedPool) {
      writeContract({
        address: contractAddress,
        abi: contractAbi,
        functionName: "removeLiquidity",
        args: [selectedPool.tokenA, selectedPool.tokenB, parseEther(shares)],
      });
    }
  };

  const handleMaxClick = () => {
    if (userShares) {
      setShares(formatUnits(userShares, 18));
    }
  };

  return (
    <>
      <TransactionInformations
        hash={hash}
        isLoading={isLoading}
        isSuccess={isSuccess}
        error={error}
        onSuccess={onSuccess}
        type="withdraw"
      />
      <div className="space-y-4">
        <div className="p-4 bg-gray-50 rounded-xl">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <span className="font-medium">My Shares</span>
            </div>
            <span className="text-xl font-bold">
              {userShares
                ? Number(formatUnits(userShares, 18)).toFixed(6)
                : "0"}
            </span>
          </div>
        </div>
        <div className="space-y-2">
          <div className="flex items-center justify-between mb-2">
            <span className="font-medium">Amount to Withdraw</span>
            <Button
              variant="outline"
              size="sm"
              onClick={handleMaxClick}
              className="text-sm"
            >
              Max
            </Button>
          </div>
          <div className="p-4 bg-gray-50 rounded-xl">
            <div className="flex items-center justify-between gap-2">
              <input
                type="number"
                placeholder="0"
                onChange={(e) => setShares(e.target.value)}
                value={shares}
                className="bg-transparent text-xl font-bold focus:outline-none w-full [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
              />
            </div>
          </div>
        </div>

        {!isPending && !isLoading ? (
          <Button
            onClick={withdraw}
            className="w-full py-8 text-lg rounded-xl font-semibold bg-gradient-button hover:bg-gradient-button-hover text-white border-none shadow-md"
          >
            Remove Liquidity
          </Button>
        ) : (
          <Button
            disabled
            className="w-full py-8 text-lg rounded-xl font-semibold bg-gradient-button opacity-70 text-white border-none shadow-md"
          >
            Removing Liquidity...
          </Button>
        )}
      </div>
    </>
  );
};

export default Withdraw;
