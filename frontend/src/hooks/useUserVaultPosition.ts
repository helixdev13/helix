import type { Address } from 'viem';
import { useAccount, useReadContract, useReadContracts } from 'wagmi';

import { CONTRACTS, CITREA_CHAIN_ID, TOKENS } from '@/config/contracts';
import { HELIX_VAULT_ABI, HLX_TOKEN_ABI } from '@/lib/contracts';

export type VaultPosition = {
  shares: bigint;
  sharesInUsdce: bigint;
  usdceBalance: bigint;
  usdceAllowance: bigint;
};

export type VaultPositionResult = VaultPosition & {
  isLoading: boolean;
  isError: boolean;
  error: Error | null;
};

export function useUserVaultPosition(
  vaultAddress: Address = CONTRACTS.helixVault,
  userAddress?: Address,
): VaultPositionResult {
  const { address: connectedAddress } = useAccount();
  const account = userAddress ?? connectedAddress;
  const enabled = Boolean(account);

  const { data, isLoading, isError, error } = useReadContracts({
    allowFailure: false,
    contracts: enabled
      ? [
          {
            chainId: CITREA_CHAIN_ID,
            address: vaultAddress,
            abi: HELIX_VAULT_ABI,
            functionName: 'balanceOf',
            args: [account as Address],
          },
          {
            chainId: CITREA_CHAIN_ID,
            address: TOKENS.usdce,
            abi: HLX_TOKEN_ABI,
            functionName: 'balanceOf',
            args: [account as Address],
          },
          {
            chainId: CITREA_CHAIN_ID,
            address: TOKENS.usdce,
            abi: HLX_TOKEN_ABI,
            functionName: 'allowance',
            args: [account as Address, vaultAddress],
          },
        ]
      : [],
    query: {
      enabled,
      refetchInterval: 30_000,
    },
  });

  const [shares = 0n, usdceBalance = 0n, usdceAllowance = 0n] = (data ?? []) as Array<
    bigint | undefined
  >;

  const sharesInUsdceResult = useReadContract({
    address: vaultAddress,
    abi: HELIX_VAULT_ABI,
    functionName: 'convertToAssets',
    args: [shares],
    chainId: CITREA_CHAIN_ID,
    query: {
      enabled: enabled && shares > 0n,
      refetchInterval: 30_000,
    },
  });
  const sharesInUsdce = (sharesInUsdceResult.data ?? 0n) as bigint;

  return {
    shares,
    sharesInUsdce,
    usdceBalance,
    usdceAllowance,
    isLoading: enabled ? isLoading : false,
    isError,
    error: error ?? null,
  } satisfies VaultPositionResult;
}
