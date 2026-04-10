import { useEffect, useState } from 'react';
import type { Address } from 'viem';
import { zeroAddress } from 'viem';
import { useReadContract } from 'wagmi';

import { CONTRACTS, CITREA_CHAIN_ID } from '@/config/contracts';
import { HELIX_LENS_ABI } from '@/lib/contracts';

export type StrategyState = {
  performanceFeeBps: number;
  rewardRatioBps: number;
  bountyBps: number;
  compoundCooldown: bigint;
  lastCompoundTimestamp: bigint;
  cooldownRemaining: bigint;
  hlxToken: Address;
  rewardDistributor: Address;
  totalIdle: bigint;
  totalDeployedAssets: bigint;
  totalAssets: bigint;
  rebalancePaused: boolean;
};

export type StrategyStateResult = StrategyState & {
  isLoading: boolean;
  isError: boolean;
  error: Error | null;
};

function useUnixTime(): bigint {
  const [now, setNow] = useState(() => BigInt(Math.floor(Date.now() / 1000)));

  useEffect(() => {
    const interval = window.setInterval(() => {
      setNow(BigInt(Math.floor(Date.now() / 1000)));
    }, 1000);

    return () => window.clearInterval(interval);
  }, []);

  return now;
}

export function useStrategyState(vaultAddress: Address = CONTRACTS.helixVault): StrategyStateResult {
  const now = useUnixTime();

  const { data, isLoading, isError, error } = useReadContract({
    address: CONTRACTS.helixLens,
    abi: HELIX_LENS_ABI,
    functionName: 'getCompoundStrategyView',
    args: [vaultAddress],
    chainId: CITREA_CHAIN_ID,
    query: {
      refetchInterval: 30_000,
    },
  });

  const view = data as StrategyState | undefined;
  const cooldownDeadline = (view?.lastCompoundTimestamp ?? 0n) + (view?.compoundCooldown ?? 0n);
  const cooldownRemaining = cooldownDeadline > now ? cooldownDeadline - now : 0n;

  return {
    performanceFeeBps: view?.performanceFeeBps ?? 0,
    rewardRatioBps: view?.rewardRatioBps ?? 0,
    bountyBps: view?.bountyBps ?? 0,
    compoundCooldown: view?.compoundCooldown ?? 0n,
    lastCompoundTimestamp: view?.lastCompoundTimestamp ?? 0n,
    cooldownRemaining,
    totalIdle: view?.totalIdle ?? 0n,
    totalDeployedAssets: view?.totalDeployedAssets ?? 0n,
    totalAssets: view?.totalAssets ?? 0n,
    hlxToken: view?.hlxToken ?? zeroAddress,
    rewardDistributor: view?.rewardDistributor ?? zeroAddress,
    rebalancePaused: view?.rebalancePaused ?? false,
    isLoading,
    isError,
    error: error ?? null,
  } satisfies StrategyStateResult;
}
