'use client';

import Link from 'next/link';
import { useMemo } from 'react';
import { useRouter } from 'next/navigation';

import { ConnectButton } from '@rainbow-me/rainbowkit';

import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { formatBps, formatCountdown, formatHlx, formatTimestamp, formatUsdce, truncateAddress } from '@/lib/format';
import { useCompound } from '@/hooks/useCompound';
import { useCompoundHistory } from '@/hooks/useCompoundHistory';
import { useStrategyState } from '@/hooks/useStrategyState';

function Spinner() {
  return <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />;
}

function CompactStat({
  label,
  value,
  loading,
}: {
  label: string;
  value: string;
  loading?: boolean;
}) {
  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
      <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">{label}</div>
      {loading ? <Skeleton className="mt-2 h-7 w-28" /> : <div className="mt-2 text-lg font-semibold text-white">{value}</div>}
    </div>
  );
}

function formatExplorerUrl(hash: string) {
  return `https://explorer.citrea.xyz/tx/${hash}`;
}

export default function CompoundPage() {
  const router = useRouter();
  const strategyState = useStrategyState();
  const { compounds, isLoading: historyLoading, error: historyError } = useCompoundHistory();
  const { compound, isCompounding, txHash, error } = useCompound();

  const cumulative = useMemo(() => {
    return compounds.reduce(
      (acc, entry) => ({
        totalCompounds: acc.totalCompounds + 1n,
        totalProfit: acc.totalProfit + entry.profit,
        totalHlxMinted: acc.totalHlxMinted + entry.hlxMinted,
        totalTreasuryFees: acc.totalTreasuryFees + entry.treasuryFee,
      }),
      {
        totalCompounds: 0n,
        totalProfit: 0n,
        totalHlxMinted: 0n,
        totalTreasuryFees: 0n,
      },
    );
  }, [compounds]);

  const cooldownReady = strategyState.cooldownRemaining <= 0n;
  const cooldownBadgeClasses = cooldownReady
    ? 'border-emerald-400/20 bg-emerald-400/10 text-emerald-200'
    : 'border-amber-400/20 bg-amber-400/10 text-amber-200';

  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top,_rgba(34,197,94,0.12),_transparent_28%),linear-gradient(180deg,_#020617_0%,_#0f172a_52%,_#111827_100%)] px-4 py-8 text-slate-100 sm:px-6 lg:px-8">
      <div className="mx-auto flex w-full max-w-7xl flex-col gap-6">
        <div className="flex flex-col gap-4 rounded-[2rem] border border-white/10 bg-white/5 p-6 shadow-2xl backdrop-blur-xl lg:flex-row lg:items-center lg:justify-between">
          <div className="space-y-2">
            <p className="text-xs uppercase tracking-[0.35em] text-emerald-300">Compound dashboard</p>
            <h1 className="text-3xl font-semibold tracking-tight text-white sm:text-4xl">
              Compound Dashboard
            </h1>
            <p className="mt-2 text-sm text-slate-300 sm:text-base">
              Anyone can compound to earn HLX bounty
            </p>
          </div>

          <div className="flex flex-col items-start gap-3 sm:flex-row sm:items-center">
            <Button variant="outline" onClick={() => router.push('/')}>Home</Button>
            <Button variant="outline" onClick={() => router.push('/vault')}>Vault</Button>
            <Button variant="outline" onClick={() => router.push('/earn')}>Earn</Button>
          </div>
        </div>

        <div className="grid gap-6 xl:grid-cols-[0.95fr_1.05fr]">
          <Card>
            <CardHeader>
              <CardTitle>Compound action</CardTitle>
              <CardDescription>Trigger compound when the cooldown has expired.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="rounded-2xl border border-white/10 bg-white/5 p-5">
                <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">Cooldown</div>
                <Badge className={['mt-3 w-fit', cooldownBadgeClasses].join(' ')} variant="outline">
                  {cooldownReady
                    ? 'Ready'
                    : `${formatCountdown(strategyState.cooldownRemaining)} remaining`}
                </Badge>
              </div>

              {txHash ? (
              <div className="rounded-2xl border border-emerald-400/20 bg-emerald-400/5 p-4 text-sm">
                  <div className="text-[11px] uppercase tracking-[0.25em] text-emerald-200/80">Last compound tx</div>
                  <a
                    href={formatExplorerUrl(txHash)}
                    target="_blank"
                    rel="noreferrer"
                    className="mt-2 block break-all text-emerald-200 hover:text-emerald-100"
                  >
                    {truncateAddress(txHash, 6)}
                  </a>
                </div>
              ) : null}

              {error ? <p className="text-sm text-red-300">{error.message}</p> : null}

              <ConnectButton.Custom>
                {({ account, chain, openChainModal, openConnectModal, mounted }) => {
                  const connected = Boolean(mounted && account && chain);
                  const label = !connected
                    ? 'Connect wallet'
                    : chain?.unsupported
                      ? 'Switch to Citrea'
                      : cooldownReady
                        ? 'Compound Now'
                        : 'Cooldown active';

                  return (
                    <Button
                      onClick={() => {
                        if (!connected) {
                          openConnectModal();
                          return;
                        }

                        if (chain?.unsupported) {
                          openChainModal();
                          return;
                        }

                        if (!cooldownReady || isCompounding) {
                          return;
                        }

                        void compound();
                      }}
                      disabled={!cooldownReady || isCompounding || !connected}
                      className="min-w-[180px]"
                    >
                      {isCompounding ? (
                        <span className="flex items-center gap-2">
                          <Spinner />
                          Compounding...
                        </span>
                      ) : (
                        label
                      )}
                    </Button>
                  );
                }}
              </ConnectButton.Custom>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Current config</CardTitle>
              <CardDescription>Live auto-compound settings from the deployed strategy.</CardDescription>
            </CardHeader>
            <CardContent className="grid gap-3 md:grid-cols-2">
              <CompactStat label="Performance fee" value={formatBps(strategyState.performanceFeeBps)} loading={strategyState.isLoading} />
              <CompactStat label="Reward ratio" value={`${formatBps(strategyState.rewardRatioBps)} → HLX`} loading={strategyState.isLoading} />
              <CompactStat label="Bounty" value={`${formatBps(strategyState.bountyBps)} of fee → caller`} loading={strategyState.isLoading} />
              <CompactStat label="Minimum profit threshold" value={formatUsdce(strategyState.minimumProfitThreshold)} loading={strategyState.isLoading} />
              <CompactStat label="Cooldown period" value={formatCountdown(strategyState.compoundCooldown)} loading={strategyState.isLoading} />
              <CompactStat label="Fee recipient" value={strategyState.feeRecipient} loading={strategyState.isLoading} />
            </CardContent>
          </Card>
        </div>

        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          <CompactStat label="Total compounds" value={cumulative.totalCompounds.toString()} loading={historyLoading} />
          <CompactStat label="Total profit harvested" value={formatUsdce(cumulative.totalProfit)} loading={historyLoading} />
          <CompactStat label="Total HLX minted" value={formatHlx(cumulative.totalHlxMinted)} loading={historyLoading} />
          <CompactStat label="Treasury fees" value={formatUsdce(cumulative.totalTreasuryFees)} loading={historyLoading} />
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Compound history</CardTitle>
            <CardDescription>Last 20 CompoundExecuted events from the deployed strategy.</CardDescription>
          </CardHeader>
          <CardContent>
            {historyError ? <p className="mb-4 text-sm text-red-300">{historyError.message}</p> : null}

            {historyLoading ? (
              <div className="space-y-3">
                <Skeleton className="h-11 w-full" />
                <Skeleton className="h-11 w-full" />
                <Skeleton className="h-11 w-full" />
              </div>
            ) : compounds.length === 0 ? (
              <div className="rounded-2xl border border-white/10 bg-white/5 p-5 text-sm text-slate-300">
                No compounds have been executed yet.
              </div>
            ) : (
              <div className="overflow-x-auto rounded-2xl border border-white/10">
                <div className="min-w-[980px]">
                  <div className="grid grid-cols-[1.2fr_1fr_1fr_1fr_1fr_1fr_0.8fr_1.2fr] gap-3 border-b border-white/10 bg-white/[0.03] px-4 py-3 text-[11px] uppercase tracking-[0.22em] text-slate-400">
                    <div>Time</div>
                    <div>Profit</div>
                    <div>Fee</div>
                    <div>Treasury</div>
                    <div>HLX Minted</div>
                    <div>Bounty</div>
                    <div>Reinvested</div>
                    <div>Explorer</div>
                  </div>
                  {compounds.map((compound, index) => (
                    <div
                      key={`${compound.transactionHash}-${index}`}
                      className="grid grid-cols-[1.2fr_1fr_1fr_1fr_1fr_1fr_0.8fr_1.2fr] gap-3 px-4 py-3 text-sm odd:bg-white/[0.02] even:bg-white/[0.05]"
                    >
                      <div className="text-slate-300">{formatTimestamp(compound.timestamp)}</div>
                      <div className="font-medium text-white">{formatUsdce(compound.profit)}</div>
                      <div className="text-slate-200">{formatUsdce(compound.performanceFee)}</div>
                      <div className="text-slate-200">{formatUsdce(compound.treasuryFee)}</div>
                      <div className="text-emerald-200">{formatHlx(compound.hlxMinted)}</div>
                      <div className="text-slate-200">{formatUsdce(compound.bounty)}</div>
                      <div>
                        <Badge
                          variant={compound.reinvested ? 'default' : 'secondary'}
                          className={compound.reinvested ? 'bg-emerald-400/15 text-emerald-200 border-emerald-400/20' : ''}
                        >
                          {compound.reinvested ? '✓' : '✕'}
                        </Badge>
                      </div>
                      <a
                        href={formatExplorerUrl(compound.transactionHash)}
                        target="_blank"
                        rel="noreferrer"
                        className="text-emerald-200 hover:text-emerald-100"
                      >
                        View on Explorer
                      </a>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>How compounding works</CardTitle>
            <CardDescription>Operator notes for the bounty flow.</CardDescription>
          </CardHeader>
          <CardContent className="grid gap-3 text-sm leading-6 text-slate-300 md:grid-cols-3">
            <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
              Compound profits harvest HLX and treasury fees from the strategy.
            </div>
            <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
              Anyone can call compound once the cooldown expires and earn the bounty.
            </div>
            <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
              The deployed strategy remains disabled-by-default until deliberate enablement.
            </div>
          </CardContent>
        </Card>

        <div className="flex justify-center pb-6 text-sm text-slate-400">
          <Link href="/" className="hover:text-white">
            Back to home
          </Link>
        </div>
      </div>
    </main>
  );
}
