import { useCallback, useState } from 'react';
import type { Address, Hex } from 'viem';
import { useAccount, usePublicClient, useWriteContract } from 'wagmi';

import { CONTRACTS, CITREA_CHAIN_ID } from '@/config/contracts';
import { HELIX_VAULT_ABI } from '@/lib/contracts';
import { useQueryClient } from '@tanstack/react-query';

type WithdrawPhase = 'idle' | 'withdrawing';

export type WithdrawResult = {
  withdraw: (amount: bigint) => Promise<void>;
  isWithdrawing: boolean;
  txHash: Hex | undefined;
  error: Error | null;
};

export function useWithdraw(vaultAddress: Address = CONTRACTS.helixVault): WithdrawResult {
  const { address } = useAccount();
  const publicClient = usePublicClient({ chainId: CITREA_CHAIN_ID });
  const queryClient = useQueryClient();
  const { writeContractAsync } = useWriteContract();
  const [phase, setPhase] = useState<WithdrawPhase>('idle');
  const [txHash, setTxHash] = useState<Hex | undefined>();
  const [error, setError] = useState<Error | null>(null);

  const withdraw = useCallback(
    async (amount: bigint) => {
      if (!address) {
        const nextError = new Error('Connect your wallet before withdrawing.');
        setError(nextError);
        throw nextError;
      }

      if (amount <= 0n) {
        const nextError = new Error('Withdraw amount must be greater than zero.');
        setError(nextError);
        throw nextError;
      }

      if (!publicClient) {
        const nextError = new Error('Citrea client is not ready.');
        setError(nextError);
        throw nextError;
      }

      setError(null);

      try {
        setPhase('withdrawing');
        const withdrawHash = await writeContractAsync({
          address: vaultAddress,
          abi: HELIX_VAULT_ABI,
          functionName: 'withdraw',
          args: [amount, address, address],
          chainId: CITREA_CHAIN_ID,
        });

        setTxHash(withdrawHash);
        await publicClient.waitForTransactionReceipt({ hash: withdrawHash });
        await queryClient.invalidateQueries();
      } catch (cause) {
        const nextError = cause instanceof Error ? cause : new Error('Withdraw failed.');
        setError(nextError);
        throw nextError;
      } finally {
        setPhase('idle');
      }
    },
    [address, publicClient, queryClient, vaultAddress, writeContractAsync],
  );

  return {
    withdraw,
    isWithdrawing: phase === 'withdrawing',
    txHash,
    error,
  };
}
