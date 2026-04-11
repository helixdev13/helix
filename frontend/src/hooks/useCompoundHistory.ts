import { useQuery } from '@tanstack/react-query';
import type { Address, Hex } from 'viem';
import { parseAbiItem } from 'viem';
import { usePublicClient } from 'wagmi';

import { CONTRACTS, CITREA_CHAIN_ID } from '@/config/contracts';

export type CompoundEntry = {
  blockNumber: bigint;
  transactionHash: Hex;
  profit: bigint;
  performanceFee: bigint;
  treasuryFee: bigint;
  hlxMinted: bigint;
  bounty: bigint;
  reinvestAmount: bigint;
  reinvested: boolean;
  timestamp: bigint;
};

const compoundExecutedEvent = parseAbiItem(
  'event CompoundExecuted(address indexed strategy, uint256 profit, uint256 performanceFee, uint256 treasuryFee, uint256 hlxMinted, uint256 bounty, uint256 reinvestAmount, bool reinvested)',
);

export type CompoundHistoryResult = {
  compounds: CompoundEntry[];
  isLoading: boolean;
  error: Error | null;
};

export function useCompoundHistory(strategyAddress: Address = CONTRACTS.strategy): CompoundHistoryResult {
  const publicClient = usePublicClient({ chainId: CITREA_CHAIN_ID });

  const { data, isLoading, error } = useQuery({
    queryKey: ['compound-history', strategyAddress],
    queryFn: async () => {
      if (!publicClient) {
        return [] as CompoundEntry[];
      }

      const logs = await publicClient.getLogs({
        address: strategyAddress,
        event: compoundExecutedEvent,
        fromBlock: 0n,
        toBlock: 'latest',
      });

      const recentLogs = [...logs]
        .sort((a, b) => {
          const blockDelta = Number(b.blockNumber - a.blockNumber);
          if (blockDelta !== 0) {
            return blockDelta;
          }

          return Number((b.logIndex ?? 0) - (a.logIndex ?? 0));
        })
        .slice(0, 20);

      const timestamps = new Map<bigint, bigint>();
      await Promise.all(
        [...new Set(recentLogs.map((log) => log.blockNumber))].map(async (blockNumber) => {
          const block = await publicClient.getBlock({ blockNumber });
          timestamps.set(blockNumber, block.timestamp);
        }),
      );

      return recentLogs.map((log) => ({
        blockNumber: log.blockNumber,
        transactionHash: (log.transactionHash ?? '0x') as Hex,
        profit: log.args.profit ?? 0n,
        performanceFee: log.args.performanceFee ?? 0n,
        treasuryFee: log.args.treasuryFee ?? 0n,
        hlxMinted: log.args.hlxMinted ?? 0n,
        bounty: log.args.bounty ?? 0n,
        reinvestAmount: log.args.reinvestAmount ?? 0n,
        reinvested: log.args.reinvested ?? false,
        timestamp: timestamps.get(log.blockNumber) ?? 0n,
      }));
    },
    enabled: Boolean(publicClient),
    refetchInterval: 60_000,
  });

  return {
    compounds: data ?? [],
    isLoading,
    error: error instanceof Error ? error : error ? new Error('Failed to load compound history.') : null,
  };
}
