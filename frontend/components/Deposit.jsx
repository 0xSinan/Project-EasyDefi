"use client";

import { useEffect, useState } from "react";
import { parseEther, formatUnits } from "viem";
import {
  useWriteContract,
  useWaitForTransactionReceipt,
  useReadContract,
  useAccount,
} from "wagmi";
import { contractAddress, contractAbi, ERC20Abi } from "../constants/contract";
import TransactionInformations from "./Informations";
import Image from "next/image";
import ApproveButton from "./ApproveButton";
import { Button } from "./ui/button";

const Deposit = ({ onSuccess, selectedPool }) => {
  const { address } = useAccount();
  const [amountA, setAmountA] = useState("");
  const [amountB, setAmountB] = useState("");
  const [depositState, setDepositState] = useState("initial");
  const { data: hash, isPending, error, writeContract } = useWriteContract();
  const { isLoading, isSuccess } = useWaitForTransactionReceipt({ hash });

  const { data: allowanceA, refetch: refetchAllowanceA } = useReadContract({
    address: selectedPool?.tokenA,
    abi: ERC20Abi,
    functionName: "allowance",
    args: [address ?? "0x0", contractAddress],
    enabled: Boolean(address && selectedPool?.tokenA),
  });

  const { data: allowanceB, refetch: refetchAllowanceB } = useReadContract({
    address: selectedPool?.tokenB,
    abi: ERC20Abi,
    functionName: "allowance",
    args: [address ?? "0x0", contractAddress],
    enabled: Boolean(address && selectedPool?.tokenB),
  });

  const calculateOptimalAmounts = (amount, isTokenA) => {
    if (!amount || !selectedPool?.reserveA || !selectedPool?.reserveB)
      return "0";

    const amountBigInt = parseEther(amount);
    let quotient;

    if (isTokenA) {
      quotient = (amountBigInt * selectedPool.reserveB) / selectedPool.reserveA;
    } else {
      quotient = (amountBigInt * selectedPool.reserveA) / selectedPool.reserveB;
    }

    return formatUnits(quotient, 18);
  };

  const handleAmountChange = (value, isTokenA) => {
    if (isTokenA) {
      setAmountA(value);
      setAmountB(value ? calculateOptimalAmounts(value, true) : "");
    } else {
      setAmountB(value);
      setAmountA(value ? calculateOptimalAmounts(value, false) : "");
    }
  };

  const deposit = async () => {
    if (amountA && amountB && selectedPool) {
      writeContract({
        address: contractAddress,
        abi: contractAbi,
        functionName: "addLiquidity",
        args: [
          selectedPool.tokenA,
          selectedPool.tokenB,
          parseEther(amountA),
          parseEther(amountB),
        ],
      });
    }
  };

  useEffect(() => {
    if (!amountA || !amountB) {
      setDepositState("initial");
    } else if (allowanceA !== undefined && allowanceB !== undefined) {
      try {
        const amountABigInt = parseEther(amountA);
        const amountBBigInt = parseEther(amountB);

        if (amountABigInt > allowanceA) {
          setDepositState("needsAllowanceA");
        } else if (amountBBigInt > allowanceB) {
          setDepositState("needsAllowanceB");
        } else {
          setDepositState("ready");
        }
      } catch (err) {
        console.error("Error checking allowance:", err);
      }
    }
  }, [amountA, amountB, allowanceA, allowanceB]);

  return (
    <>
      <TransactionInformations
        hash={hash}
        isLoading={isLoading}
        isSuccess={isSuccess}
        error={error}
        onSuccess={onSuccess}
        type={depositState.includes("Allowance") ? "approval" : "deposit"}
      />

      <div className="space-y-4">
        <div className="space-y-2">
          <div className="flex items-center justify-between mb-2">
            <span className="font-medium">Amount</span>
          </div>
          <div className="p-4 bg-gray-50 rounded-xl">
            <div className="flex items-center justify-between gap-2">
              <input
                type="number"
                placeholder="0"
                onChange={(e) => handleAmountChange(e.target.value, true)}
                value={amountA}
                className="bg-transparent text-xl font-bold focus:outline-none w-full [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
              />
              <div className="flex items-center space-x-2">
                <Image
                  src="/images/tokens/alyra-logo.png"
                  alt="Token A"
                  width={24}
                  height={24}
                  className="rounded-full"
                />
                <span className="font-medium">ALY</span>
              </div>
            </div>
          </div>
        </div>

        <div className="space-y-2">
          <div className="flex items-center justify-between mb-2">
            <span className="font-medium">Amount</span>
          </div>
          <div className="p-4 bg-gray-50 rounded-xl">
            <div className="flex items-center justify-between gap-2">
              <input
                type="number"
                placeholder="0"
                onChange={(e) => handleAmountChange(e.target.value, false)}
                value={amountB}
                className="bg-transparent text-xl font-bold focus:outline-none w-full [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
              />
              <div className="flex items-center space-x-2">
                <Image
                  src="/images/tokens/salyra-logo.png"
                  alt="Token B"
                  width={24}
                  height={24}
                  className="rounded-full"
                />
                <span className="font-medium">sALY</span>
              </div>
            </div>
          </div>
        </div>

        {depositState === "needsAllowanceA" ? (
          <ApproveButton
            token={selectedPool.tokenA}
            amount={amountA}
            symbol="ALY"
            onApprovalSuccess={async () => {
              await refetchAllowanceA();
            }}
          />
        ) : depositState === "needsAllowanceB" ? (
          <ApproveButton
            token={selectedPool.tokenB}
            amount={amountB}
            symbol="sALY"
            onApprovalSuccess={async () => {
              await refetchAllowanceB();
            }}
          />
        ) : !isPending && !isLoading ? (
          <Button
            onClick={deposit}
            className="w-full py-8 text-lg rounded-xl font-semibold bg-gradient-button hover:bg-gradient-button-hover text-white border-none shadow-md"
          >
            Add Liquidity
          </Button>
        ) : (
          <Button
            disabled
            className="w-full py-8 text-lg rounded-xl font-semibold bg-gradient-button opacity-70 text-white border-none shadow-md"
          >
            Adding Liquidity...
          </Button>
        )}
      </div>
    </>
  );
};

export default Deposit;
