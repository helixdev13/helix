import { useCallback, useState } from 'react';
import type { Address, Hex } from 'viem';
import { useAccount, usePublicClient, useWriteContract } from 'wagmi';

import { CONTRACTS, CITREA_CHAIN_ID, TOKENS } from '@/config/contracts';
import { HELIX_VAULT_ABI, HLX_TOKEN_ABI } from '@/lib/contracts';
import { useUserVaultPosition } from '@/hooks/useUserVaultPosition';
import { useQueryClient } from '@tanstack/react-query';

type DepositPhase = 'idle' | 'approving' | 'depositing';

export type DepositResult = {
  deposit: (amount: bigint) => Promise<void>;
  isApproving: boolean;
  isDepositing: boolean;
  txHash: Hex | undefined;
  error: Error | null;
};

export function useDeposit(vaultAddress: Address = CONTRACTS.helixVault): DepositResult {
  const { address } = useAccount();
  const publicClient = usePublicClient({ chainId: CITREA_CHAIN_ID });
  const queryClient = useQueryClient();
  const { writeContractAsync } = useWriteContract();
  const { usdceAllowance } = useUserVaultPosition(vaultAddress, address);
  const [phase, setPhase] = useState<DepositPhase>('idle');
  const [txHash, setTxHash] = useState<Hex | undefined>();
  const [error, setError] = useState<Error | null>(null);

  const deposit = useCallback(
    async (amount: bigint) => {
      if (!address) {
        const nextError = new Error('Connect your wallet before depositing.');
        setError(nextError);
        throw nextError;
      }

      if (amount <= 0n) {
        const nextError = new Error('Deposit amount must be greater than zero.');
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
        if (usdceAllowance < amount) {
          setPhase('approving');
          const approveHash = await writeContractAsync({
            address: TOKENS.usdce,
            abi: HLX_TOKEN_ABI,
            functionName: 'approve',
            args: [vaultAddress, amount],
            chainId: CITREA_CHAIN_ID,
          });

          setTxHash(approveHash);
          await publicClient.waitForTransactionReceipt({ hash: approveHash });
          await queryClient.invalidateQueries();
        }

        setPhase('depositing');
        const depositHash = await writeContractAsync({
          address: vaultAddress,
          abi: HELIX_VAULT_ABI,
          functionName: 'deposit',
          args: [amount, address],
          chainId: CITREA_CHAIN_ID,
        });

        setTxHash(depositHash);
        await publicClient.waitForTransactionReceipt({ hash: depositHash });
        await queryClient.invalidateQueries();
      } catch (cause) {
        const nextError = cause instanceof Error ? cause : new Error('Deposit failed.');
        setError(nextError);
        throw nextError;
      } finally {
        setPhase('idle');
      }
    },
    [address, publicClient, queryClient, usdceAllowance, vaultAddress, writeContractAsync],
  );

  return {
    deposit,
    isApproving: phase === 'approving',
    isDepositing: phase === 'depositing',
    txHash,
    error,
  };
}
