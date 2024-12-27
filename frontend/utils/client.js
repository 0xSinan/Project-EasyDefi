import { createPublicClient, http } from "viem";
import { hardhat, sepolia, baseSepolia } from "viem/chains";

const RPC_URL =
  "https://base-sepolia.g.alchemy.com/v2/vxz68BNmu4mmylbpscUiS_BszkE_TnUz";

export const publicClient = createPublicClient({
  chain: baseSepolia,
  transport: http(RPC_URL),
});
