'use client';

import { useAccount } from 'wagmi';

import { ConnectWalletButton } from '@/components/ConnectWalletButton';
import { GradientButton } from '@/components/GradientButton';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { CONTRACTS } from '@/config/contracts';
import { useCompound, useCompoundHistory, useStrategyState } from '@/hooks';
import { formatBps, formatCountdown, formatHlx, formatTimestamp, formatUsdce } from '@/lib/format';

function formatExplorerHash(hash: string) {
  return `${hash.slice(0, 10)}…${hash.slice(-8)}`;
}

function Metric({
  label,
  value,
  helper,
}: {
  label: string;
  value: string;
  helper: string;
}) {
  return (
    <div className="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-surface-2)] p-4">
      <div className="text-[11px] uppercase tracking-[0.22em] text-[var(--text-muted)]">{label}</div>
      <div className="mt-1 text-base font-semibold text-[#43c5ff]">{value}</div>
      <div className="mt-1 text-xs text-[var(--text-secondary)]">{helper}</div>
    </div>
  );
}

export function CompoundPanel() {
  const { address } = useAccount();
  const connected = Boolean(address);

  const strategyState = useStrategyState();
  const compound = useCompound();
  const history = useCompoundHistory();

  const readyToCompound =
    strategyState.cooldownRemaining === 0n && !compound.isCompounding && !strategyState.rebalancePaused;
  const totalProfit = history.compounds.reduce((sum, entry) => sum + entry.profit, 0n);
  const totalHlx = history.compounds.reduce((sum, entry) => sum + entry.hlxMinted, 0n);
  const totalTreasury = history.compounds.reduce((sum, entry) => sum + entry.treasuryFee, 0n);

  const latestTxHash = compound.txHash;

  return (
    <div className="space-y-6">
      <section className="space-y-3">
        <div className="flex flex-wrap items-center gap-2">
          <Badge className="bg-[#ff4f96]/15 text-[#ff8ab9] border-[#ff4f96]/25">Public compounding</Badge>
          <Badge
            className={[
              readyToCompound
                ? 'bg-emerald-500/15 text-emerald-300 border-emerald-500/25'
                : 'bg-[#222936] text-[#ffcf66] border-[var(--border-subtle)]',
              'border',
            ].join(' ')}
          >
            {readyToCompound ? 'Ready' : 'Cooldown'}
          </Badge>
        </div>
        <div className="space-y-2">
          <h2 className="text-3xl font-bold tracking-tight text-[var(--text-primary)]">Compound Dashboard</h2>
          <p className="max-w-3xl text-sm leading-6 text-[var(--text-secondary)]">
            Anyone can compound to earn the HLX bounty when the cooldown has elapsed.
          </p>
        </div>
      </section>

      <Card>
        <CardHeader className="space-y-2">
          <CardDescription>Compound action</CardDescription>
          <CardTitle>Trigger the next harvest</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {strategyState.isLoading ? (
            <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
              <Skeleton className="h-24 rounded-xl" />
              <Skeleton className="h-24 rounded-xl" />
              <Skeleton className="h-24 rounded-xl" />
              <Skeleton className="h-24 rounded-xl" />
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
              <Metric
                label="Last compound"
                value={formatTimestamp(strategyState.lastCompoundTimestamp)}
                helper="Most recent successful compound"
              />
              <Metric
                label="Cooldown"
                value={
                  strategyState.cooldownRemaining > 0n
                    ? formatCountdown(strategyState.cooldownRemaining)
                    : 'Ready'
                }
                helper="Countdown until the next harvest"
              />
              <Metric
                label="Performance fee"
                value={formatBps(strategyState.performanceFeeBps)}
                helper={`Bounty ${formatBps(strategyState.bountyBps)} to caller`}
              />
              <Metric
                label="Reward ratio"
                value={formatBps(strategyState.rewardRatioBps)}
                helper="Converted to HLX rewards from the performance fee"
              />
            </div>
          )}

          <div className="text-sm text-[var(--text-secondary)]">
            Minimum profit threshold:{' '}
            <span className="font-semibold text-[var(--text-primary)]">
              {formatUsdce(strategyState.minimumProfitThreshold)} USDC.e
            </span>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            {connected ? (
              <GradientButton
                className="min-w-[220px]"
                disabled={!readyToCompound}
                onClick={() => void compound.compound()}
              >
                {compound.isCompounding
                  ? 'Compounding...'
                  : strategyState.cooldownRemaining > 0n
                    ? 'Cooldown Active'
                    : 'Compound Now'}
              </GradientButton>
            ) : (
              <ConnectWalletButton className="min-w-[220px]" />
            )}

            {latestTxHash ? (
              <a
                href={`https://explorer.citrea.xyz/tx/${latestTxHash}`}
                target="_blank"
                rel="noreferrer"
                className="text-sm font-medium text-[#ff8ab9] underline-offset-4 hover:underline"
              >
                View on Explorer
              </a>
            ) : null}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="space-y-2">
          <CardDescription>Compound history</CardDescription>
          <CardTitle>Last 20 compounds</CardTitle>
        </CardHeader>
        <CardContent>
          {history.isLoading ? (
            <div className="space-y-3">
              <Skeleton className="h-10 w-full rounded-xl" />
              <Skeleton className="h-10 w-full rounded-xl" />
              <Skeleton className="h-10 w-full rounded-xl" />
            </div>
          ) : history.compounds.length === 0 ? (
            <div className="rounded-xl border border-dashed border-[var(--border-subtle)] bg-[var(--bg-surface-2)] px-4 py-6 text-sm text-[var(--text-secondary)]">
              No compounds have been executed yet.
            </div>
          ) : (
            <div className="-mx-5 overflow-x-auto px-5 pb-1 sm:mx-0 sm:px-0">
              <table className="min-w-[760px] w-full border-separate border-spacing-y-2">
                <thead>
                  <tr className="text-left text-xs uppercase tracking-[0.2em] text-[var(--text-muted)]">
                    <th className="px-3 py-2">Time</th>
                    <th className="px-3 py-2">Profit</th>
                    <th className="px-3 py-2">Fee</th>
                    <th className="px-3 py-2">HLX Minted</th>
                    <th className="px-3 py-2">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {history.compounds.map((entry, index) => (
                    <tr key={`${entry.transactionHash}-${entry.blockNumber}`} className="rounded-xl">
                      <td className={['px-3 py-3 text-sm', index % 2 === 0 ? 'bg-[var(--bg-surface)]' : 'bg-[var(--bg-surface-2)]', 'rounded-l-xl text-[var(--text-primary)]'].join(' ')}>
                        {formatTimestamp(entry.timestamp)}
                      </td>
                      <td className={['px-3 py-3 text-sm', index % 2 === 0 ? 'bg-[var(--bg-surface)]' : 'bg-[var(--bg-surface-2)]', 'text-[var(--text-primary)]'].join(' ')}>
                        {formatUsdce(entry.profit)} USDC.e
                      </td>
                      <td className={['px-3 py-3 text-sm', index % 2 === 0 ? 'bg-[var(--bg-surface)]' : 'bg-[var(--bg-surface-2)]', 'text-[var(--text-primary)]'].join(' ')}>
                        {formatUsdce(entry.performanceFee)} USDC.e
                      </td>
                      <td className={['px-3 py-3 text-sm', index % 2 === 0 ? 'bg-[var(--bg-surface)]' : 'bg-[var(--bg-surface-2)]', 'text-[var(--text-primary)]'].join(' ')}>
                        {formatHlx(entry.hlxMinted)} HLX
                      </td>
                      <td className={['rounded-r-xl px-3 py-3 text-sm', index % 2 === 0 ? 'bg-[var(--bg-surface)]' : 'bg-[var(--bg-surface-2)]'].join(' ')}>
                        <div className="flex flex-col gap-1">
                          <Badge
                            className={[
                              entry.reinvested
                                ? 'bg-emerald-500/15 text-emerald-300 border-emerald-500/25'
                                : 'bg-[#222936] text-[#ffcf66] border-[var(--border-subtle)]',
                              'border self-start',
                            ].join(' ')}
                          >
                            {entry.reinvested ? 'Reinvested' : 'Skipped'}
                          </Badge>
                          <a
                            href={`https://explorer.citrea.xyz/tx/${entry.transactionHash}`}
                            target="_blank"
                            rel="noreferrer"
                            className="text-xs font-medium text-[#ff8ab9] underline-offset-4 hover:underline"
                          >
                            {formatExplorerHash(entry.transactionHash)}
                          </a>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
        <Metric label="Total compounds" value={`${history.compounds.length}`} helper="Executed harvests" />
        <Metric label="Total profit" value={`${formatUsdce(totalProfit)} USDC.e`} helper="Harvested profit" />
        <Metric label="HLX minted" value={`${formatHlx(totalHlx)} HLX`} helper="Minted to callers and rewards" />
        <Metric
          label="Treasury fees"
          value={`${formatUsdce(totalTreasury)} USDC.e`}
          helper={`Reward distributor ${CONTRACTS.rewardDistributor.slice(0, 10)}...`}
        />
      </div>
    </div>
  );
}
