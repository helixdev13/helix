import { useCallback, useState } from 'react';
import type { Address, Hex } from 'viem';
import { useAccount, usePublicClient, useWriteContract } from 'wagmi';

import { CONTRACTS, CITREA_CHAIN_ID } from '@/config/contracts';
import { REWARD_DISTRIBUTOR_ABI } from '@/lib/contracts';
import { useQueryClient } from '@tanstack/react-query';

type ClaimPhase = 'idle' | 'claiming';

export type ClaimRewardsResult = {
  claimRewards: () => Promise<void>;
  isClaiming: boolean;
  txHash: Hex | undefined;
  error: Error | null;
};

export function useClaimRewards(
  distributorAddress: Address = CONTRACTS.rewardDistributor,
): ClaimRewardsResult {
  const { address } = useAccount();
  const publicClient = usePublicClient({ chainId: CITREA_CHAIN_ID });
  const queryClient = useQueryClient();
  const { writeContractAsync } = useWriteContract();
  const [phase, setPhase] = useState<ClaimPhase>('idle');
  const [txHash, setTxHash] = useState<Hex | undefined>();
  const [error, setError] = useState<Error | null>(null);

  const claimRewards = useCallback(async () => {
    if (!address) {
      const nextError = new Error('Connect your wallet before claiming rewards.');
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
      setPhase('claiming');
      const claimHash = await writeContractAsync({
        address: distributorAddress,
        abi: REWARD_DISTRIBUTOR_ABI,
        functionName: 'claimRewards',
        chainId: CITREA_CHAIN_ID,
      });

      setTxHash(claimHash);
      await publicClient.waitForTransactionReceipt({ hash: claimHash });
      await queryClient.invalidateQueries();
    } catch (cause) {
      const nextError = cause instanceof Error ? cause : new Error('Claim rewards failed.');
      setError(nextError);
      throw nextError;
    } finally {
      setPhase('idle');
    }
  }, [address, distributorAddress, publicClient, queryClient, writeContractAsync]);

  return {
    claimRewards,
    isClaiming: phase === 'claiming',
    txHash,
    error,
  };
}
