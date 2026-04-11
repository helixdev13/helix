'use client';

import { useAccount } from 'wagmi';

import { ConnectButton } from '@rainbow-me/rainbowkit';

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
    <div className="rounded-2xl border border-[#F0E8E8] bg-[#FFF8F6] px-4 py-3">
      <div className="text-[11px] uppercase tracking-[0.22em] text-[#999999]">{label}</div>
      <div className="mt-1 text-base font-semibold text-[#333333]">{value}</div>
      <div className="mt-1 text-xs text-[#666666]">{helper}</div>
    </div>
  );
}

function ConnectPrompt({ label }: { label: string }) {
  return (
    <ConnectButton.Custom>
      {({ mounted, openConnectModal }) => {
        if (!mounted) {
          return (
            <GradientButton className="min-w-[220px]" disabled>
              {label}
            </GradientButton>
          );
        }

        return (
          <GradientButton
            className="min-w-[220px]"
            onClick={(event) => {
              event.stopPropagation();
              openConnectModal();
            }}
          >
            {label}
          </GradientButton>
        );
      }}
    </ConnectButton.Custom>
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
          <Badge variant="outline">Public compounding</Badge>
          <Badge variant={readyToCompound ? 'default' : 'secondary'}>
            {readyToCompound ? 'Ready' : 'Cooldown'}
          </Badge>
        </div>
        <div className="space-y-2">
          <h2 className="text-3xl font-semibold tracking-tight text-[#333333]">Compound Dashboard</h2>
          <p className="max-w-3xl text-sm leading-6 text-[#666666]">
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
            <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
              <Skeleton className="h-24" />
              <Skeleton className="h-24" />
              <Skeleton className="h-24" />
              <Skeleton className="h-24" />
            </div>
          ) : (
            <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
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

          <div className="text-sm text-[#666666]">
            Minimum profit threshold:{' '}
            <span className="font-semibold text-[#333333]">
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
              <ConnectPrompt label="Connect Wallet to Compound" />
            )}

            {latestTxHash ? (
              <a
                href={`https://explorer.citrea.xyz/tx/${latestTxHash}`}
                target="_blank"
                rel="noreferrer"
                className="text-sm font-medium text-[#D4797F] underline-offset-4 hover:underline"
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
              <Skeleton className="h-10 w-full" />
              <Skeleton className="h-10 w-full" />
              <Skeleton className="h-10 w-full" />
            </div>
          ) : history.compounds.length === 0 ? (
            <div className="rounded-2xl border border-dashed border-[#F0E8E8] bg-[#FFF8F6] px-4 py-6 text-sm text-[#666666]">
              No compounds have been executed yet.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-[760px] w-full border-separate border-spacing-y-2">
                <thead>
                  <tr className="text-left text-xs uppercase tracking-[0.2em] text-[#999999]">
                    <th className="px-3 py-2">Time</th>
                    <th className="px-3 py-2">Profit</th>
                    <th className="px-3 py-2">Fee</th>
                    <th className="px-3 py-2">HLX Minted</th>
                    <th className="px-3 py-2">Status</th>
                    <th className="px-3 py-2">Transaction</th>
                  </tr>
                </thead>
                <tbody>
                  {history.compounds.map((entry) => (
                    <tr key={`${entry.transactionHash}-${entry.blockNumber}`} className="rounded-2xl">
                      <td className="rounded-l-2xl bg-[#FFF8F6] px-3 py-3 text-sm text-[#333333]">
                        {formatTimestamp(entry.timestamp)}
                      </td>
                      <td className="bg-[#FFF8F6] px-3 py-3 text-sm text-[#333333]">
                        {formatUsdce(entry.profit)} USDC.e
                      </td>
                      <td className="bg-[#FFF8F6] px-3 py-3 text-sm text-[#333333]">
                        {formatUsdce(entry.performanceFee)} USDC.e
                      </td>
                      <td className="bg-[#FFF8F6] px-3 py-3 text-sm text-[#333333]">
                        {formatHlx(entry.hlxMinted)} HLX
                      </td>
                      <td className="bg-[#FFF8F6] px-3 py-3 text-sm">
                        <Badge variant={entry.reinvested ? 'default' : 'secondary'}>
                          {entry.reinvested ? 'Reinvested' : 'Skipped'}
                        </Badge>
                      </td>
                      <td className="rounded-r-2xl bg-[#FFF8F6] px-3 py-3 text-sm">
                        <a
                          href={`https://explorer.citrea.xyz/tx/${entry.transactionHash}`}
                          target="_blank"
                          rel="noreferrer"
                          className="font-medium text-[#D4797F] underline-offset-4 hover:underline"
                        >
                          {formatExplorerHash(entry.transactionHash)}
                        </a>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
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
