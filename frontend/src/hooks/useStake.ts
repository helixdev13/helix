import { useCallback, useState } from 'react';
import type { Address, Hex } from 'viem';
import { useAccount, usePublicClient, useWriteContract } from 'wagmi';

import { CONTRACTS, CITREA_CHAIN_ID } from '@/config/contracts';
import { HELIX_VAULT_ABI, REWARD_DISTRIBUTOR_ABI } from '@/lib/contracts';
import { useQueryClient } from '@tanstack/react-query';

type StakePhase = 'idle' | 'approving' | 'staking';

export type StakeResult = {
  stake: (amount: bigint) => Promise<void>;
  isApproving: boolean;
  isStaking: boolean;
  txHash: Hex | undefined;
  error: Error | null;
};

export function useStake(
  vaultAddress: Address = CONTRACTS.helixVault,
  distributorAddress: Address = CONTRACTS.rewardDistributor,
  stakeAllowance: bigint = 0n,
): StakeResult {
  const { address } = useAccount();
  const publicClient = usePublicClient({ chainId: CITREA_CHAIN_ID });
  const queryClient = useQueryClient();
  const { writeContractAsync } = useWriteContract();
  const [phase, setPhase] = useState<StakePhase>('idle');
  const [txHash, setTxHash] = useState<Hex | undefined>();
  const [error, setError] = useState<Error | null>(null);

  const stake = useCallback(
    async (amount: bigint) => {
      if (!address) {
        const nextError = new Error('Connect your wallet before staking.');
        setError(nextError);
        throw nextError;
      }

      if (amount <= 0n) {
        const nextError = new Error('Stake amount must be greater than zero.');
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
        if (stakeAllowance < amount) {
          setPhase('approving');
          const approveHash = await writeContractAsync({
            address: vaultAddress,
            abi: HELIX_VAULT_ABI,
            functionName: 'approve',
            args: [distributorAddress, amount],
            chainId: CITREA_CHAIN_ID,
          });

          setTxHash(approveHash);
          await publicClient.waitForTransactionReceipt({ hash: approveHash });
          await queryClient.invalidateQueries();
        }

        setPhase('staking');
        const stakeHash = await writeContractAsync({
          address: distributorAddress,
          abi: REWARD_DISTRIBUTOR_ABI,
          functionName: 'stake',
          args: [amount],
          chainId: CITREA_CHAIN_ID,
        });

        setTxHash(stakeHash);
        await publicClient.waitForTransactionReceipt({ hash: stakeHash });
        await queryClient.invalidateQueries();
      } catch (cause) {
        const nextError = cause instanceof Error ? cause : new Error('Stake failed.');
        setError(nextError);
        throw nextError;
      } finally {
        setPhase('idle');
      }
    },
    [address, distributorAddress, publicClient, queryClient, stakeAllowance, vaultAddress, writeContractAsync],
  );

  return {
    stake,
    isApproving: phase === 'approving',
    isStaking: phase === 'staking',
    txHash,
    error,
  };
}
