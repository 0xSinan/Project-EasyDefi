"use client";

import { Button } from "../components/ui/button";
import { useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { parseEther } from "viem";
import { ERC20Abi, contractAddress } from "../constants/contract";
import TransactionInformations from "./Informations";
import { useEffect } from "react";

const ApproveButton = ({ token, amount, symbol, onApprovalSuccess }) => {
  const { data: hash, isPending, error, writeContract } = useWriteContract();
  const { isLoading, isSuccess } = useWaitForTransactionReceipt({ hash });

  const handleApprove = async () => {
    await writeContract({
      address: token,
      abi: ERC20Abi,
      functionName: "approve",
      args: [contractAddress, parseEther(amount)],
    });
  };

  useEffect(() => {
    let timeoutId;
    if (isSuccess) {
      timeoutId = setTimeout(() => {
        onApprovalSuccess?.();
      }, 100);
    }
    return () => {
      if (timeoutId) clearTimeout(timeoutId);
    };
  }, [isSuccess, onApprovalSuccess]);

  return (
    <>
      <TransactionInformations
        hash={hash}
        isLoading={isLoading}
        isSuccess={isSuccess}
        error={error}
        type="approval"
      />

      {!isPending && !isLoading ? (
        <Button
          onClick={handleApprove}
          className="w-full py-8 text-lg rounded-xl font-semibold bg-gradient-button hover:bg-gradient-button-hover text-white border-none shadow-md"
        >
          Approve {symbol}
        </Button>
      ) : (
        <Button
          disabled
          className="w-full py-8 text-lg rounded-xl font-semibold bg-gradient-button opacity-70 text-white border-none shadow-md"
        >
          Approving {symbol}...
        </Button>
      )}
    </>
  );
};

export default ApproveButton;
