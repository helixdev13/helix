import { useCallback, useState } from 'react';
import type { Address, Hex } from 'viem';
import { useAccount, usePublicClient, useWriteContract } from 'wagmi';

import { CONTRACTS, CITREA_CHAIN_ID } from '@/config/contracts';
import { REWARD_DISTRIBUTOR_ABI } from '@/lib/contracts';
import { useQueryClient } from '@tanstack/react-query';

type UnstakePhase = 'idle' | 'unstaking';

export type UnstakeResult = {
  unstake: (amount: bigint) => Promise<void>;
  isUnstaking: boolean;
  txHash: Hex | undefined;
  error: Error | null;
};

export function useUnstake(distributorAddress: Address = CONTRACTS.rewardDistributor): UnstakeResult {
  const { address } = useAccount();
  const publicClient = usePublicClient({ chainId: CITREA_CHAIN_ID });
  const queryClient = useQueryClient();
  const { writeContractAsync } = useWriteContract();
  const [phase, setPhase] = useState<UnstakePhase>('idle');
  const [txHash, setTxHash] = useState<Hex | undefined>();
  const [error, setError] = useState<Error | null>(null);

  const unstake = useCallback(
    async (amount: bigint) => {
      if (!address) {
        const nextError = new Error('Connect your wallet before unstaking.');
        setError(nextError);
        throw nextError;
      }

      if (amount <= 0n) {
        const nextError = new Error('Unstake amount must be greater than zero.');
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
        setPhase('unstaking');
        const unstakeHash = await writeContractAsync({
          address: distributorAddress,
          abi: REWARD_DISTRIBUTOR_ABI,
          functionName: 'withdraw',
          args: [amount],
          chainId: CITREA_CHAIN_ID,
        });

        setTxHash(unstakeHash);
        await publicClient.waitForTransactionReceipt({ hash: unstakeHash });
        await queryClient.invalidateQueries();
      } catch (cause) {
        const nextError = cause instanceof Error ? cause : new Error('Unstake failed.');
        setError(nextError);
        throw nextError;
      } finally {
        setPhase('idle');
      }
    },
    [address, distributorAddress, publicClient, queryClient, writeContractAsync],
  );

  return {
    unstake,
    isUnstaking: phase === 'unstaking',
    txHash,
    error,
  };
}
