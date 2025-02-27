export const contractAddress = process.env.NEXT_PUBLIC_CONTRACT_ADDRESS;
export const contractAbi = JSON.parse(process.env.NEXT_PUBLIC_CONTRACT_ABI);
export const ERC20Abi = JSON.parse(process.env.NEXT_PUBLIC_ERC20_ABI);
export const TOKENS = {
  ALYRA: {
    address: process.env.NEXT_PUBLIC_ALYRA_ADDRESS,
    symbol: "ALY",
    logo: "/images/tokens/alyra-logo.png",
  },
  LIQUID_ALYRA: {
    address: process.env.NEXT_PUBLIC_LIQUID_ALYRA_ADDRESS,
    symbol: "sALY",
    logo: "/images/tokens/salyra-logo.png",
  },
};
