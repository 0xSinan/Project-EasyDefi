const BPS_DIVIDER = 10000n;

export const getAmountOut = (amountIn, reserveIn, reserveOut, fee) => {
  if (!amountIn || !reserveIn || !reserveOut || !fee) return 0n;

  const _amountIn = BigInt(amountIn);
  const _reserveIn = BigInt(reserveIn);
  const _reserveOut = BigInt(reserveOut);
  const _fee = BigInt(fee);

  const amountInWithFee = _amountIn * (BPS_DIVIDER - _fee);
  const numerator = amountInWithFee * _reserveOut;
  const denominator = _reserveIn * BPS_DIVIDER + amountInWithFee;

  return numerator / denominator;
};
