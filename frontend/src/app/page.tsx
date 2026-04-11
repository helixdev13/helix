'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useRouter } from 'next/navigation';
import { useAccount } from 'wagmi';

import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { formatBps, formatCountdown, formatHlx, formatTimestamp, formatUsdce } from '@/lib/format';
import {
  useStrategyState,
  useUserRewards,
  useUserVaultPosition,
  useVaultState,
} from '@/hooks';

function WalletButton({ label = 'Connect Wallet' }: { label?: string }) {
  return (
    <ConnectButton.Custom>
      {({ account, chain, mounted, openAccountModal, openChainModal, openConnectModal }) => {
        if (!mounted) {
          return (
            <Button type="button" className="min-w-[180px]" disabled>
              {label}
            </Button>
          );
        }

        const connected = Boolean(account && chain);
        const primaryLabel = !connected
          ? label
          : chain?.unsupported
            ? 'Switch to Citrea'
            : 'Open Account';

        return (
          <Button
            type="button"
            className="min-w-[180px]"
            onClick={() => {
              if (!connected) {
                openConnectModal();
                return;
              }

              if (chain?.unsupported) {
                openChainModal();
                return;
              }

              openAccountModal();
            }}
          >
            {primaryLabel}
          </Button>
        );
      }}
    </ConnectButton.Custom>
  );
}

function SectionMetric({
  label,
  value,
  helper,
}: {
  label: string;
  value: string;
  helper?: string;
}) {
  return (
    <div className="rounded-2xl border border-white/10 bg-slate-950/40 px-4 py-3">
      <div className="text-[11px] uppercase tracking-[0.24em] text-slate-400">{label}</div>
      <div className="mt-1 text-lg font-semibold text-white">{value}</div>
      {helper ? <div className="mt-1 text-xs text-slate-400">{helper}</div> : null}
    </div>
  );
}

function SectionMetricSkeleton() {
  return (
    <div className="rounded-2xl border border-white/10 bg-slate-950/40 px-4 py-3">
      <Skeleton className="h-3 w-20" />
      <Skeleton className="mt-2 h-6 w-28" />
      <Skeleton className="mt-2 h-3 w-32" />
    </div>
  );
}

function NavigationCard({
  emoji,
  title,
  description,
  onClick,
}: {
  emoji: string;
  title: string;
  description: string;
  onClick: () => void;
}) {
  return (
    <Card className="border-white/10 bg-white/5 transition-transform duration-200 hover:-translate-y-0.5 hover:bg-white/10">
      <CardContent className="flex h-full flex-col gap-4 p-6">
        <div className="flex h-10 w-10 items-center justify-center rounded-2xl border border-emerald-400/20 bg-emerald-400/10 text-lg">
          {emoji}
        </div>
        <div className="space-y-1">
          <h3 className="text-lg font-semibold text-white">{title}</h3>
          <p className="text-sm leading-6 text-slate-400">{description}</p>
        </div>
        <div className="mt-auto">
          <Button variant="outline" className="w-full" onClick={onClick}>
            Open
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

export default function Home() {
  const router = useRouter();
  const { isConnected } = useAccount();
  const vaultState = useVaultState();
  const strategyState = useStrategyState();
  const userPosition = useUserVaultPosition();
  const userRewards = useUserRewards();

  const depositCapRemaining =
    vaultState.depositCap > vaultState.totalAssets
      ? vaultState.depositCap - vaultState.totalAssets
      : 0n;
  const vaultStatus = vaultState.paused
    ? 'Paused'
    : vaultState.withdrawOnly
      ? 'Withdraw Only'
      : 'Active';
  const vaultStatusVariant = vaultState.paused || vaultState.withdrawOnly ? 'secondary' : 'default';
  const cooldownLabel =
    strategyState.cooldownRemaining > 0n
      ? formatCountdown(strategyState.cooldownRemaining)
      : 'Ready';

  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top,_rgba(52,211,153,0.13),_transparent_28%),linear-gradient(180deg,_#020617_0%,_#0f172a_52%,_#111827_100%)] text-slate-100">
      <div className="mx-auto flex min-h-screen w-full max-w-7xl flex-col gap-8 px-6 py-10 sm:px-8 lg:px-10">
        <section className="rounded-[2rem] border border-white/10 bg-white/5 p-6 shadow-2xl backdrop-blur-xl sm:p-8">
          <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
            <div className="space-y-4">
              <div className="flex flex-wrap items-center gap-2">
                <Badge variant="outline">Citrea mainnet</Badge>
                <Badge variant="outline">USDC.e / wcBTC</Badge>
              </div>
              <div className="space-y-3">
                <h1 className="text-4xl font-semibold tracking-tight text-white sm:text-5xl">
                  Helix
                </h1>
                <p className="max-w-3xl text-base leading-7 text-slate-300 sm:text-lg">
                  Citrea Yield Optimizer — Deposit USDC.e, earn trading fees + HLX rewards
                </p>
              </div>
            </div>
            <WalletButton />
          </div>
        </section>

        <section className="grid gap-6 xl:grid-cols-3">
          <Card className="border-white/10 bg-white/5 xl:col-span-1">
            <CardHeader>
              <div className="flex items-start justify-between gap-4">
                <div>
                  <CardDescription>Vault overview</CardDescription>
                  <CardTitle className="mt-1">Helix USDC.e Smart Vault</CardTitle>
                </div>
                {vaultState.isLoading ? (
                  <Skeleton className="h-6 w-20 rounded-full" />
                ) : (
                  <Badge variant={vaultStatusVariant}>{vaultStatus}</Badge>
                )}
              </div>
            </CardHeader>
            <CardContent className="grid gap-3">
              {vaultState.isLoading ? (
                <>
                  <SectionMetricSkeleton />
                  <SectionMetricSkeleton />
                  <SectionMetricSkeleton />
                </>
              ) : (
                <>
                  <SectionMetric
                    label="TVL"
                    value={`${formatUsdce(vaultState.totalAssets)} USDC.e`}
                    helper="Total assets in the vault"
                  />
                  <SectionMetric
                    label="Deposit cap remaining"
                    value={`${formatUsdce(depositCapRemaining)} USDC.e`}
                    helper={`${formatBps(vaultState.maxAllocationBps)} max allocation`}
                  />
                  <SectionMetric
                    label="Strategy allocation"
                    value={
                      vaultState.totalAssets > 0n
                        ? `${((vaultState.totalStrategyAssets * 10000n) / vaultState.totalAssets) / 100n}%`
                        : '0%'
                    }
                    helper={vaultState.strategy !== '0x0000000000000000000000000000000000000000' ? 'Strategy attached' : 'No strategy attached'}
                  />
                </>
              )}
              <Button variant="outline" className="mt-1 w-full" onClick={() => router.push('/vault')}>
                Go to Vault
              </Button>
            </CardContent>
          </Card>

          <Card className="border-white/10 bg-white/5 xl:col-span-1">
            <CardHeader>
              <CardDescription>Your position</CardDescription>
              <CardTitle className="mt-1">Wallet and vault shares</CardTitle>
            </CardHeader>
            <CardContent className="grid gap-3">
              {!isConnected ? (
                <div className="rounded-2xl border border-dashed border-white/15 bg-slate-950/40 p-5">
                  <div className="text-sm font-medium text-white">Connect Wallet to View Position</div>
                  <p className="mt-2 text-sm leading-6 text-slate-400">
                    See your deposits, vault shares, staked shares, and claimable HLX rewards.
                  </p>
                  <div className="mt-4">
                    <WalletButton label="Connect Wallet" />
                  </div>
                </div>
              ) : userPosition.isLoading || userRewards.isLoading ? (
                <>
                  <SectionMetricSkeleton />
                  <SectionMetricSkeleton />
                  <SectionMetricSkeleton />
                  <SectionMetricSkeleton />
                </>
              ) : (
                <>
                  <SectionMetric
                    label="Deposited"
                    value={`${formatUsdce(userPosition.sharesInUsdce)} USDC.e`}
                    helper={`${userPosition.shares} vault shares`}
                  />
                  <SectionMetric
                    label="Claimable HLX"
                    value={`${formatHlx(userRewards.earnedHlx)} HLX`}
                    helper="Rewards accrued from compound fees"
                  />
                  <SectionMetric
                    label="HLX wallet balance"
                    value={`${formatHlx(userRewards.hlxBalance)} HLX`}
                    helper="Wallet balance"
                  />
                  <SectionMetric
                    label="Staked shares"
                    value={`${formatHlx(userRewards.stakedShares)} shares`}
                    helper="Vault shares staked in the rewards pool"
                  />
                </>
              )}
              <Button variant="outline" className="mt-1 w-full" onClick={() => router.push('/earn')}>
                View Details
              </Button>
            </CardContent>
          </Card>

          <Card className="border-white/10 bg-white/5 xl:col-span-1">
            <CardHeader>
              <CardDescription>Compound status</CardDescription>
              <CardTitle className="mt-1">Public trigger dashboard</CardTitle>
            </CardHeader>
            <CardContent className="grid gap-3">
              {strategyState.isLoading ? (
                <>
                  <SectionMetricSkeleton />
                  <SectionMetricSkeleton />
                  <SectionMetricSkeleton />
                </>
              ) : (
                <>
                  <SectionMetric
                    label="Last compound"
                    value={formatTimestamp(strategyState.lastCompoundTimestamp)}
                    helper="Most recent successful compound"
                  />
                  <SectionMetric
                    label="Cooldown remaining"
                    value={cooldownLabel}
                    helper="Anyone can compound when ready"
                  />
                  <SectionMetric
                    label="Performance fee"
                    value={formatBps(strategyState.performanceFeeBps)}
                    helper={`Bounty ${formatBps(strategyState.bountyBps)} of fee`}
                  />
                </>
              )}
              <Button variant="outline" className="mt-1 w-full" onClick={() => router.push('/compound')}>
                Go to Compound
              </Button>
            </CardContent>
          </Card>
        </section>

        <section className="grid gap-4 md:grid-cols-3">
          <NavigationCard
            emoji="↕"
            title="Deposit & Withdraw"
            description="Manage USDC.e positions in the vault."
            onClick={() => router.push('/vault')}
          />
          <NavigationCard
            emoji="HLX"
            title="Stake & Earn HLX"
            description="Stake vault shares and claim HLX rewards."
            onClick={() => router.push('/earn')}
          />
          <NavigationCard
            emoji="◎"
            title="Compound Dashboard"
            description="Monitor compound timing and trigger new harvests."
            onClick={() => router.push('/compound')}
          />
        </section>
      </div>
    </main>
  );
}
