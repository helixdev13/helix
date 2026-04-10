import type { Address } from 'viem';
import { useAccount, useReadContracts } from 'wagmi';

import { CONTRACTS } from '@/config/contracts';
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

export function useUserRewards(
  vaultAddress: Address = CONTRACTS.helixVault,
  distributorAddress: Address = CONTRACTS.rewardDistributor,
  userAddress?: Address,
): UserRewardsState {
  const { address: connectedAddress } = useAccount();
  const account = userAddress ?? connectedAddress;
  const enabled = Boolean(account);

  const { data } = useReadContracts({
    allowFailure: false,
    contracts: enabled
      ? [
          {
            address: distributorAddress,
            abi: REWARD_DISTRIBUTOR_ABI,
            functionName: 'balanceOf',
            args: [account as Address],
          },
          {
            address: distributorAddress,
            abi: REWARD_DISTRIBUTOR_ABI,
            functionName: 'earned',
            args: [account as Address],
          },
          {
            address: CONTRACTS.hlxToken,
            abi: HLX_TOKEN_ABI,
            functionName: 'balanceOf',
            args: [account as Address],
          },
          {
            address: vaultAddress,
            abi: HELIX_VAULT_ABI,
            functionName: 'allowance',
            args: [account as Address, distributorAddress],
          },
          {
            address: distributorAddress,
            abi: REWARD_DISTRIBUTOR_ABI,
            functionName: 'rewardRate',
          },
          {
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
  } as UserRewardsState;
}
