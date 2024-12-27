"use client";

import { useEffect, useState } from "react";
import {
  contractAbi,
  contractAddress,
  TOKENS,
  ERC20Abi,
} from "../constants/contract";
import { Button } from "./ui/button";
import { Select, SelectItem, SelectContent, SelectTrigger } from "./ui/select";
import {
  useWriteContract,
  useWaitForTransactionReceipt,
  useReadContract,
  useAccount,
} from "wagmi";
import { parseEther, formatUnits } from "viem";
import { getAmountOut } from "../utils/getAmountOut";
import TransactionInformations from "./Informations";
import { usePools } from "../hooks/usePools";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import Image from "next/image";
import ApproveButton from "./ApproveButton";
import { ArrowUpDown } from "lucide-react";

const Swap = () => {
  const [isMounted, setIsMounted] = useState(false);

  useEffect(() => {
    setIsMounted(true);
  }, []);

  const { address, isConnected } = useAccount();
  const [amountIn, setAmountIn] = useState("");
  const [selectedTokenIn, setSelectedTokenIn] = useState("ALYRA");
  const [selectedTokenOut, setSelectedTokenOut] = useState("LIQUID_ALYRA");
  const [calculatedAmountOut, setCalculatedAmountOut] = useState(null);
  const [swapState, setSwapState] = useState("initial");

  const { data: hash, isPending, error, writeContract } = useWriteContract();
  const { isLoading: txLoading, isSuccess: txSuccess } =
    useWaitForTransactionReceipt({ hash });

  const { poolsFetched } = usePools();
  const currentPool = poolsFetched?.find(
    (pool) =>
      (pool.tokenA === TOKENS[selectedTokenIn].address &&
        pool.tokenB === TOKENS[selectedTokenOut].address) ||
      (pool.tokenA === TOKENS[selectedTokenOut].address &&
        pool.tokenB === TOKENS[selectedTokenIn].address)
  );

  const { data: allowance, refetch: refetchAllowance } = useReadContract({
    address: TOKENS[selectedTokenIn].address,
    abi: ERC20Abi,
    functionName: "allowance",
    args: [address ?? "0x0", contractAddress],
    enabled: Boolean(address && TOKENS[selectedTokenIn].address),
  });

  useEffect(() => {
    if (!amountIn) {
      setSwapState("initial");
    } else if (allowance !== undefined) {
      try {
        const amountInBigInt = parseEther(amountIn);
        if (amountInBigInt > allowance) {
          setSwapState("needsAllowance");
        } else {
          setSwapState("ready");
        }
      } catch (err) {
        console.error("Error checking allowance:", err);
      }
    }
  }, [amountIn, allowance, selectedTokenIn]);

  const handleAmountInChange = async (value) => {
    setAmountIn(value);
    if (!value || !currentPool) {
      setCalculatedAmountOut(null);
      return;
    }

    try {
      const isTokenInA = TOKENS[selectedTokenIn].address === currentPool.tokenA;

      const reserveIn = isTokenInA
        ? currentPool.reserveA
        : currentPool.reserveB;
      const reserveOut = isTokenInA
        ? currentPool.reserveB
        : currentPool.reserveA;

      const amountOut = getAmountOut(
        parseEther(value),
        reserveIn,
        reserveOut,
        currentPool.fee
      );

      if (amountOut) {
        const formatted = formatUnits(amountOut, 18);
        setCalculatedAmountOut(formatted);
      } else {
        setCalculatedAmountOut(null);
      }
    } catch (error) {
      console.error("Error calculating amount out:", error);
      setCalculatedAmountOut(null);
    }
  };

  const handleTokenInChange = (value) => {
    if (value === selectedTokenOut) {
      setSelectedTokenOut(selectedTokenIn);
    }
    setSelectedTokenIn(value);
    setAmountIn("");
    setCalculatedAmountOut(null);
  };

  const handleSwap = async () => {
    if (!amountIn) return;

    writeContract({
      address: contractAddress,
      abi: contractAbi,
      functionName: "swap",
      args: [
        TOKENS[selectedTokenIn].address,
        TOKENS[selectedTokenOut].address,
        parseEther(amountIn),
      ],
    });
  };

  useEffect(() => {
    if (txSuccess) {
      setAmountIn("");
      setCalculatedAmountOut(null);
      writeContract.reset?.();
    }
  }, [txSuccess]);

  return (
    <div className="flex gap-6 py-10">
      {isMounted && (
        <TransactionInformations
          hash={hash}
          isLoading={txLoading}
          isSuccess={txSuccess}
          error={error}
          type="swap"
          show={swapState === "ready" && (txLoading || txSuccess || error)}
        />
      )}

      <div className="flex-1">
        <div className="w-full max-w-md mx-auto p-4 rounded-3xl border shadow-lg bg-white">
          <div className="space-y-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">From</label>
              <div className="p-4 bg-gray-50 rounded-xl">
                <div className="flex items-center justify-between gap-2">
                  <input
                    type="number"
                    placeholder="0"
                    value={amountIn}
                    onChange={(e) => handleAmountInChange(e.target.value)}
                    className="bg-transparent text-2xl font-bold focus:outline-none [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                  />
                  <Select
                    value={selectedTokenIn}
                    onValueChange={handleTokenInChange}
                  >
                    <SelectTrigger className="w-[120px]">
                      <TokenOption
                        symbol={TOKENS[selectedTokenIn].symbol}
                        logo={TOKENS[selectedTokenIn].logo}
                      />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="ALYRA">
                        <TokenOption symbol="ALY" logo={TOKENS.ALYRA.logo} />
                      </SelectItem>
                      <SelectItem value="LIQUID_ALYRA">
                        <TokenOption
                          symbol="sALY"
                          logo={TOKENS.LIQUID_ALYRA.logo}
                        />
                      </SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </div>

            <div className="flex justify-center -my-2 relative z-10">
              <Button
                variant="ghost"
                size="icon"
                onClick={() => {
                  setSelectedTokenIn(selectedTokenOut);
                  setSelectedTokenOut(selectedTokenIn);
                  setAmountIn("");
                  setCalculatedAmountOut(null);
                }}
                className="h-8 w-8 rounded-full bg-gray-100 hover:bg-gray-200"
              >
                <ArrowUpDown className="h-4 w-4" />
              </Button>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">To</label>
              <div className="p-4 bg-gray-50 rounded-xl">
                <div className="flex items-center justify-between gap-2">
                  <input
                    type="text"
                    placeholder="0"
                    value={calculatedAmountOut || ""}
                    readOnly
                    className="bg-transparent text-2xl font-bold focus:outline-none"
                  />
                  <div className="flex items-center gap-2 px-4 py-2 bg-white rounded-lg">
                    <TokenOption
                      symbol={TOKENS[selectedTokenOut].symbol}
                      logo={TOKENS[selectedTokenOut].logo}
                    />
                  </div>
                </div>
              </div>
            </div>

            {!isConnected ? (
              <div className="w-full">
                <ConnectButton.Custom>
                  {({ openConnectModal }) => (
                    <Button
                      onClick={openConnectModal}
                      className="w-full py-8 text-lg rounded-xl font-semibold bg-gradient-button hover:bg-gradient-button-hover text-white border-none shadow-md"
                    >
                      Connect Wallet
                    </Button>
                  )}
                </ConnectButton.Custom>
              </div>
            ) : swapState === "needsAllowance" && !isPending && !txLoading ? (
              <ApproveButton
                token={TOKENS[selectedTokenIn].address}
                amount={amountIn}
                symbol={TOKENS[selectedTokenIn].symbol}
                onApprovalSuccess={async () => {
                  await refetchAllowance();
                }}
              />
            ) : !isPending && !txLoading ? (
              <Button
                onClick={handleSwap}
                className="w-full py-8 text-lg rounded-xl font-semibold bg-gradient-button hover:bg-gradient-button-hover text-white border-none shadow-md"
              >
                Swap
              </Button>
            ) : (
              <Button
                disabled
                className="w-full py-8 text-lg rounded-xl font-semibold bg-gradient-button opacity-70 text-white border-none shadow-md"
              >
                Swapping...
              </Button>
            )}

            <div className="pt-4 space-y-2 border-t">
              <div className="flex justify-between items-center text-sm text-gray-600">
                <span>Exchange Rate</span>
                <span>
                  {amountIn && calculatedAmountOut ? (
                    <>
                      1 {TOKENS[selectedTokenIn].symbol} ={" "}
                      {(Number(calculatedAmountOut) / Number(amountIn)).toFixed(
                        6
                      )}{" "}
                      {TOKENS[selectedTokenOut].symbol}
                    </>
                  ) : (
                    "-"
                  )}
                </span>
              </div>
              <div className="flex justify-between items-center text-sm text-gray-600">
                <span>Fee</span>
                <span>
                  {currentPool
                    ? `${Number(formatUnits(currentPool.fee, 2)).toFixed(2)}%`
                    : "-"}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="w-[400px] p-6 bg-white rounded-3xl border">
        <RightPanel />
      </div>
    </div>
  );
};

const RightPanel = () => (
  <div className="space-y-6">
    <h2 className="text-lg font-semibold">How to swap tokens?</h2>
    <div className="space-y-4">
      <Step number={1} text="Enter the amount you want to swap" />
      <Step number={2} text="Make sure you have enough balance" />
      <Step number={3} text="Click approve if needed" />
      <Step number={4} text="Click swap and confirm the transaction" />
    </div>
  </div>
);

const Step = ({ number, text }) => (
  <div className="flex gap-4">
    <div
      className={`flex-none w-8 h-8 rounded-full flex items-center justify-center font-semibold text-white ${
        number === 1
          ? "bg-gradient-button"
          : number === 2
          ? "bg-gradient-button"
          : number === 3
          ? "bg-gradient-button"
          : "bg-gradient-button"
      }`}
    >
      {number}
    </div>
    <p className="text-gray-600">{text}</p>
  </div>
);

const TokenOption = ({ symbol, logo }) => (
  <div className="flex items-center gap-2">
    <Image
      src={logo || "/images/tokens/eth-logo.png"}
      alt={symbol}
      width={18}
      height={18}
      className="rounded-full"
    />
    <span>{symbol}</span>
  </div>
);

export default Swap;
