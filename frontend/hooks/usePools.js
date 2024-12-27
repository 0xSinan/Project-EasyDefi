import { useReadContract } from "wagmi";
import { contractAddress, contractAbi } from "../constants/contract";

export function usePools() {
  const {
    data: poolsFetched,
    isPending: isPendingPools,
    error: errorPools,
    refetch: refetchPools,
  } = useReadContract({
    address: contractAddress,
    abi: contractAbi,
    functionName: "getPoolsList",
    watch: true,
  });

  const {
    data: poolShares,
    isPending: isPendingPoolShares,
    error: errorPoolShares,
    refetch: refetchPoolShares,
  } = useReadContract({
    address: contractAddress,
    abi: contractAbi,
    functionName: "totalPoolShares",
    watch: true,
  });

  return {
    poolsFetched,
    isPendingPools,
    errorPools,
    refetchPools,
    poolShares,
    isPendingPoolShares,
    errorPoolShares,
    refetchPoolShares,
  };
}
