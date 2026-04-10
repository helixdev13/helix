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

export function useUserVaultPosition(
  vaultAddress: Address = CONTRACTS.helixVault,
  userAddress?: Address,
): VaultPosition {
  const { address: connectedAddress } = useAccount();
  const account = userAddress ?? connectedAddress;
  const enabled = Boolean(account);

  const { data } = useReadContracts({
    allowFailure: false,
    contracts: enabled
      ? [
          {
            address: vaultAddress,
            abi: HELIX_VAULT_ABI,
            functionName: 'balanceOf',
            args: [account as Address],
          },
          {
            address: TOKENS.usdce,
            abi: HLX_TOKEN_ABI,
            functionName: 'balanceOf',
            args: [account as Address],
          },
          {
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

  const [shares = 0n, usdceBalance = 0n, usdceAllowance = 0n] = data ?? [];

  const { data: sharesInUsdce = 0n } = useReadContract({
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

  return {
    shares,
    sharesInUsdce,
    usdceBalance,
    usdceAllowance,
  } satisfies VaultPosition;
}
