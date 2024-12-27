"use client";

import { useState } from "react";
import { contractAbi, contractAddress, ERC20Abi } from "../constants/contract";
import { Input } from "./ui/input";
import { Button } from "./ui/button";
import { useWriteContract } from "wagmi";
import { parseEther } from "viem";

const CreatePool = () => {
  const [tokenA, setTokenA] = useState("");
  const [tokenB, setTokenB] = useState("");
  const [poolFee, setPoolFee] = useState("");

  const { data: hash, isPending, error, writeContract } = useWriteContract();

  const create = async () => {
    writeContract({
      address: contractAddress,
      abi: contractAbi,
      functionName: "createPool",
      args: [tokenA, tokenB, poolFee],
    });
  };

  const approveA = async () => {
    writeContract({
      address: tokenA,
      abi: ERC20Abi,
      functionName: "approve",
      args: [contractAddress, parseEther("1000")],
    });
  };

  const approveB = async () => {
    writeContract({
      address: tokenB,
      abi: ERC20Abi,
      functionName: "approve",
      args: [contractAddress, parseEther("1000")],
    });
  };

  return (
    <>
      <Input onChange={(e) => setTokenA(e.target.value)} value={tokenA} />
      <Button onClick={approveA}>ApproveA</Button>
      <Input onChange={(e) => setTokenB(e.target.value)} value={tokenB} />
      <Button onClick={approveB}>ApproveB</Button>
      <Input onChange={(e) => setPoolFee(e.target.value)} value={poolFee} />
      <Button onClick={create}>Create Pool</Button>
    </>
  );
};

export default CreatePool;
