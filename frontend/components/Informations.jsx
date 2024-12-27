import { useEffect } from "react";
import { useToast } from "../hooks/use-toast";

export default function TransactionInformations({
  hash,
  isLoading,
  isSuccess,
  error,
  onSuccess,
  type = "transaction",
}) {
  const { toast } = useToast();

  useEffect(() => {
    if (hash && isLoading) {
      toast({
        title: getTitle(type, "submitted"),
        description: (
          <a
            href={`https://sepolia.basescan.org/tx/${hash}`}
            target="_blank"
            rel="noopener noreferrer"
            className="underline"
          >
            View on BaseScan
          </a>
        ),
        variant: "default",
      });
    }

    if (isSuccess) {
      toast({
        title: getTitle(type, "success"),
        description: (
          <a
            href={`https://sepolia.basescan.org/tx/${hash}`}
            target="_blank"
            rel="noopener noreferrer"
            className="underline"
          >
            View on BaseScan
          </a>
        ),
        variant: "success",
      });
      onSuccess?.();
    }

    if (error) {
      toast({
        title: getTitle(type, "error"),
        description: error.shortMessage || error.message,
        variant: "destructive",
      });
    }
  }, [hash, isLoading, isSuccess, error, type, onSuccess]);

  return null;
}

function getTitle(type, status) {
  switch (status) {
    case "submitted":
      return `${type === "approval" ? "Approval" : "Transaction"} Submitted`;
    case "success":
      switch (type) {
        case "approval":
          return "Approval Confirmed";
        case "deposit":
          return "Liquidity Successfully Added";
        case "withdraw":
          return "Liquidity Successfully Removed";
        case "swap":
          return "Swap Successful";
        default:
          return "Transaction Confirmed";
      }
    case "error":
      switch (type) {
        case "approval":
          return "Approval Failed";
        case "deposit":
          return "Liquidity Provision Failed";
        case "withdraw":
          return "Liquidity Removal Failed";
        case "swap":
          return "Swap Failed";
        default:
          return "Transaction Failed";
      }
    default:
      return "Transaction";
  }
}
