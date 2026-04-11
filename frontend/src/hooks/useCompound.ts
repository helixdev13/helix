import { useCallback, useState } from 'react';
import type { Address, Hex } from 'viem';
import { useAccount, usePublicClient, useWriteContract } from 'wagmi';

import { CONTRACTS, CITREA_CHAIN_ID } from '@/config/contracts';
import { STRATEGY_ABI } from '@/lib/contracts';
import { useQueryClient } from '@tanstack/react-query';

type CompoundPhase = 'idle' | 'compounding';

export type CompoundResult = {
  compound: () => Promise<void>;
  isCompounding: boolean;
  txHash: Hex | undefined;
  error: Error | null;
};

export function useCompound(strategyAddress: Address = CONTRACTS.strategy): CompoundResult {
  const { address } = useAccount();
  const publicClient = usePublicClient({ chainId: CITREA_CHAIN_ID });
  const queryClient = useQueryClient();
  const { writeContractAsync } = useWriteContract();
  const [phase, setPhase] = useState<CompoundPhase>('idle');
  const [txHash, setTxHash] = useState<Hex | undefined>();
  const [error, setError] = useState<Error | null>(null);

  const compound = useCallback(async () => {
    if (!address) {
      const nextError = new Error('Connect your wallet before compounding.');
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
      setPhase('compounding');
      const compoundHash = await writeContractAsync({
        address: strategyAddress,
        abi: STRATEGY_ABI,
        functionName: 'compound',
        chainId: CITREA_CHAIN_ID,
      });

      setTxHash(compoundHash);
      await publicClient.waitForTransactionReceipt({ hash: compoundHash });
      await queryClient.invalidateQueries();
    } catch (cause) {
      const nextError = cause instanceof Error ? cause : new Error('Compound failed.');
      setError(nextError);
      throw nextError;
    } finally {
      setPhase('idle');
    }
  }, [address, publicClient, queryClient, strategyAddress, writeContractAsync]);

  return {
    compound,
    isCompounding: phase === 'compounding',
    txHash,
    error,
  };
}
