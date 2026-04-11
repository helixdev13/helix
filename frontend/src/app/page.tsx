'use client';

import { useEffect, useState } from 'react';

import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { CONTRACTS, TOKENS } from '@/config/contracts';
import { CompoundPanel } from '@/components/CompoundPanel';
import { VaultRow } from '@/components/VaultRow';
import { formatBps, formatUsdce, truncateAddress } from '@/lib/format';
import { useVaultState } from '@/hooks';

type DashboardTab = 'vaults' | 'compound';

function tabFromHash(hash: string): DashboardTab {
  return hash.replace('#', '') === 'compound' ? 'compound' : 'vaults';
}

function Metric({
  label,
  value,
  helper,
  isLoading = false,
}: {
  label: string;
  value: string;
  helper: string;
  isLoading?: boolean;
}) {
  return (
    <Card>
      <CardContent className="space-y-2 p-5">
        <div className="text-[11px] uppercase tracking-[0.22em] text-[#999999]">{label}</div>
        {isLoading ? (
          <>
            <Skeleton className="h-6 w-32" />
            <Skeleton className="h-4 w-44" />
          </>
        ) : (
          <>
            <div className="text-xl font-semibold text-[#333333]">{value}</div>
            <div className="text-sm text-[#666666]">{helper}</div>
          </>
        )}
      </CardContent>
    </Card>
  );
}

export default function Home() {
  const [activeTab, setActiveTab] = useState<DashboardTab>('vaults');
  const vaultState = useVaultState();

  useEffect(() => {
    const syncFromHash = () => setActiveTab(tabFromHash(window.location.hash));
    syncFromHash();
    window.addEventListener('hashchange', syncFromHash);
    return () => window.removeEventListener('hashchange', syncFromHash);
  }, []);

  const capRemaining =
    vaultState.depositCap > vaultState.totalAssets
      ? vaultState.depositCap - vaultState.totalAssets
      : 0n;
  const statusLabel = vaultState.paused
    ? 'Paused'
    : vaultState.withdrawOnly
      ? 'Withdraw Only'
      : 'Active';
  const strategyAllocation =
    vaultState.totalAssets > 0n
      ? formatBps(Number((vaultState.totalStrategyAssets * 10_000n) / vaultState.totalAssets))
      : '0%';

  return (
    <main className="bg-[radial-gradient(circle_at_top,_rgba(232,160,184,0.12),_transparent_30%),linear-gradient(180deg,#FAFAFA_0%,#FFF8F6_100%)]">
      <div className="mx-auto w-full max-w-[1000px] px-4 py-8 sm:px-6 lg:px-8 lg:py-10">
        {activeTab === 'vaults' ? (
          <div className="space-y-6">
            <section className="space-y-4">
              <div className="flex flex-wrap items-center gap-2">
                <Badge variant="outline">Vaults</Badge>
                <Badge variant={vaultState.paused || vaultState.withdrawOnly ? 'secondary' : 'default'}>
                  {statusLabel}
                </Badge>
              </div>
              <div className="space-y-2">
                <h1 className="text-4xl font-semibold tracking-tight text-[#333333]">Helix Vaults</h1>
                <p className="max-w-3xl text-base leading-7 text-[#666666]">
                  Single-asset USDC.e vaults on Citrea. Deposit, withdraw, and stake shares from one screen.
                </p>
              </div>
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
                <Metric
                  label="TVL"
                  value={`${formatUsdce(vaultState.totalAssets)} USDC.e`}
                helper="Total assets currently in the vault"
                isLoading={vaultState.isLoading}
              />
              <Metric
                label="Deposit cap remaining"
                value={`${formatUsdce(capRemaining)} USDC.e`}
                helper="Room left before the cap is reached"
                isLoading={vaultState.isLoading}
              />
              <Metric
                label="Strategy allocation"
                value={strategyAllocation}
                helper={`${formatUsdce(vaultState.totalStrategyAssets)} USDC.e deployed to strategy`}
                isLoading={vaultState.isLoading}
              />
              </div>
            </section>

            <VaultRow />
          </div>
        ) : (
          <CompoundPanel />
        )}

        <footer className="mt-10 border-t border-[#F0E8E8] pt-6 text-sm text-[#666666]">
          <div className="text-[#333333]">Built on Citrea</div>
          <div className="mt-2 flex flex-wrap gap-x-4 gap-y-2">
            <span>Vault {truncateAddress(CONTRACTS.helixVault)}</span>
            <span>Strategy {truncateAddress(CONTRACTS.strategy)}</span>
            <span>HLX {truncateAddress(CONTRACTS.hlxToken)}</span>
            <span>Rewards {truncateAddress(CONTRACTS.rewardDistributor)}</span>
            <span>USDC.e {truncateAddress(TOKENS.usdce)}</span>
            <span>wcBTC {truncateAddress(TOKENS.wcbtc)}</span>
          </div>
        </footer>
      </div>
    </main>
  );
}
