import { useAccount, useReadContract } from "wagmi";
import { TOKENS, ERC20Abi } from "../constants/contract";

export function useUserBalances() {
  const { address } = useAccount();

  const { data: userBalanceA, refetch: refetchBalanceA } = useReadContract({
    address: TOKENS.ALYRA.address,
    abi: ERC20Abi,
    functionName: "balanceOf",
    args: [address ?? "0x0"],
    enabled: Boolean(address),
  });

  const { data: userBalanceB, refetch: refetchBalanceB } = useReadContract({
    address: TOKENS.LIQUID_ALYRA.address,
    abi: ERC20Abi,
    functionName: "balanceOf",
    args: [address ?? "0x0"],
    enabled: Boolean(address),
  });

  return {
    userBalanceA,
    userBalanceB,
    refetchBalanceA,
    refetchBalanceB,
  };
}
