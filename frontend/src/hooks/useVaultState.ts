import type { Address } from 'viem';
import { zeroAddress } from 'viem';
import { useReadContract } from 'wagmi';

import { CONTRACTS, CITREA_CHAIN_ID } from '@/config/contracts';
import { HELIX_LENS_ABI } from '@/lib/contracts';

export type VaultState = {
  asset: Address;
  strategy: Address;
  totalAssets: bigint;
  totalIdle: bigint;
  totalStrategyAssets: bigint;
  depositCap: bigint;
  maxAllocationBps: number;
  paused: boolean;
  withdrawOnly: boolean;
};

export type VaultStateResult = VaultState & {
  isLoading: boolean;
  isError: boolean;
  error: Error | null;
};

export function useVaultState(vaultAddress: Address = CONTRACTS.helixVault): VaultStateResult {
  const { data, isLoading, isError, error } = useReadContract({
    address: CONTRACTS.helixLens,
    abi: HELIX_LENS_ABI,
    functionName: 'getVaultView',
    args: [vaultAddress],
    chainId: CITREA_CHAIN_ID,
    query: {
      refetchInterval: 30_000,
    },
  });

  const view = data as VaultState | undefined;

  return {
    totalAssets: view?.totalAssets ?? 0n,
    totalIdle: view?.totalIdle ?? 0n,
    totalStrategyAssets: view?.totalStrategyAssets ?? 0n,
    depositCap: view?.depositCap ?? 0n,
    maxAllocationBps: view?.maxAllocationBps ?? 0,
    paused: view?.paused ?? false,
    withdrawOnly: view?.withdrawOnly ?? false,
    asset: view?.asset ?? zeroAddress,
    strategy: view?.strategy ?? zeroAddress,
    isLoading,
    isError,
    error: error ?? null,
  } satisfies VaultStateResult;
}
