import { useAccount, useReadContract } from "wagmi";
import { contractAddress, contractAbi } from "../constants/contract";

export function useUserShares() {
  const { address } = useAccount();

  const {
    data: userShares,
    isPending: isPendingUserShares,
    error: errorUserShares,
    refetch: refetchUserShares,
  } = useReadContract({
    address: contractAddress,
    abi: contractAbi,
    functionName: "shares",
    args: [address ?? "0x0", 1],
    enabled: Boolean(address),
  });

  const shares = userShares === 0n ? null : userShares;

  return {
    userShares: shares,
    isPendingUserShares,
    errorUserShares,
    refetchUserShares,
  };
}
