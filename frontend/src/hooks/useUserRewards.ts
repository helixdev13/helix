import type { Address } from 'viem';
import { useAccount, useReadContracts } from 'wagmi';

import { CONTRACTS, CITREA_CHAIN_ID } from '@/config/contracts';
import {
  HELIX_VAULT_ABI,
  HLX_TOKEN_ABI,
  REWARD_DISTRIBUTOR_ABI,
} from '@/lib/contracts';

export type UserRewardsState = {
  stakedShares: bigint;
  earnedHlx: bigint;
  hlxBalance: bigint;
  stakeAllowance: bigint;
  rewardRate: bigint;
  periodFinish: bigint;
};

export type UserRewardsResult = UserRewardsState & {
  isLoading: boolean;
  isError: boolean;
  error: Error | null;
};

export function useUserRewards(
  vaultAddress: Address = CONTRACTS.helixVault,
  distributorAddress: Address = CONTRACTS.rewardDistributor,
  userAddress?: Address,
): UserRewardsResult {
  const { address: connectedAddress } = useAccount();
  const account = userAddress ?? connectedAddress;
  const enabled = Boolean(account);

  const { data, isLoading, isError, error } = useReadContracts({
    allowFailure: false,
    contracts: enabled
      ? [
          {
            chainId: CITREA_CHAIN_ID,
            address: distributorAddress,
            abi: REWARD_DISTRIBUTOR_ABI,
            functionName: 'balanceOf',
            args: [account as Address],
          },
          {
            chainId: CITREA_CHAIN_ID,
            address: distributorAddress,
            abi: REWARD_DISTRIBUTOR_ABI,
            functionName: 'earned',
            args: [account as Address],
          },
          {
            chainId: CITREA_CHAIN_ID,
            address: CONTRACTS.hlxToken,
            abi: HLX_TOKEN_ABI,
            functionName: 'balanceOf',
            args: [account as Address],
          },
          {
            chainId: CITREA_CHAIN_ID,
            address: vaultAddress,
            abi: HELIX_VAULT_ABI,
            functionName: 'allowance',
            args: [account as Address, distributorAddress],
          },
          {
            chainId: CITREA_CHAIN_ID,
            address: distributorAddress,
            abi: REWARD_DISTRIBUTOR_ABI,
            functionName: 'rewardRate',
          },
          {
            chainId: CITREA_CHAIN_ID,
            address: distributorAddress,
            abi: REWARD_DISTRIBUTOR_ABI,
            functionName: 'periodFinish',
          },
        ]
      : [],
    query: {
      enabled,
      refetchInterval: 30_000,
    },
  });

  const [
    stakedShares = 0n,
    earnedHlx = 0n,
    hlxBalance = 0n,
    stakeAllowance = 0n,
    rewardRate = 0n,
    periodFinish = 0n,
  ] = data ?? [];

  return {
    stakedShares,
    earnedHlx,
    hlxBalance,
    stakeAllowance,
    rewardRate,
    periodFinish,
    isLoading: enabled ? isLoading : false,
    isError,
    error: error ?? null,
  };
}
