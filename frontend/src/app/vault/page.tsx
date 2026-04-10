'use client';

import Link from 'next/link';
import { useMemo, useState } from 'react';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { parseUnits } from 'viem';
import { useAccount, useReadContract } from 'wagmi';

import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { CONTRACTS, CITREA_CHAIN_ID } from '@/config/contracts';
import { HELIX_VAULT_ABI } from '@/lib/contracts';
import {
  formatBps,
  formatCountdown,
  formatHlx,
  formatTimestamp,
  formatUsdce,
  truncateAddress,
} from '@/lib/format';
import { useDeposit } from '@/hooks/useDeposit';
import { useStrategyState } from '@/hooks/useStrategyState';
import { useUserVaultPosition } from '@/hooks/useUserVaultPosition';
import { useVaultState } from '@/hooks/useVaultState';
import { useWithdraw } from '@/hooks/useWithdraw';

function safeParseUsdce(value: string) {
  const normalized = value.replaceAll(',', '').trim();

  if (!normalized || normalized === '.') {
    return 0n;
  }

  try {
    return parseUnits(normalized, 6);
  } catch {
    return 0n;
  }
}

function Spinner() {
  return <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />;
}

function StatCard({
  label,
  value,
  loading,
}: {
  label: string;
  value: string;
  loading?: boolean;
}) {
  return (
    <Card>
      <CardContent className="pt-6">
        <div className="text-[11px] uppercase tracking-[0.28em] text-slate-400">{label}</div>
        {loading ? (
          <Skeleton className="mt-3 h-8 w-32" />
        ) : (
          <div className="mt-3 text-2xl font-semibold text-white">{value}</div>
        )}
      </CardContent>
    </Card>
  );
}

function SectionSkeleton() {
  return (
    <Card>
      <CardHeader>
        <Skeleton className="h-5 w-40" />
        <Skeleton className="h-4 w-64" />
      </CardHeader>
      <CardContent className="space-y-4">
        <Skeleton className="h-11 w-full" />
        <Skeleton className="h-11 w-full" />
        <Skeleton className="h-11 w-40" />
      </CardContent>
    </Card>
  );
}

export default function VaultPage() {
  const { isConnected } = useAccount();
  const vaultState = useVaultState();
  const strategyState = useStrategyState();
  const userPosition = useUserVaultPosition();
  const { deposit, isApproving, isDepositing, txHash: depositTxHash, error: depositError } =
    useDeposit();
  const { withdraw, isWithdrawing, txHash: withdrawTxHash, error: withdrawError } = useWithdraw();
  const [activeTab, setActiveTab] = useState('deposit');
  const [depositInput, setDepositInput] = useState('');
  const [withdrawInput, setWithdrawInput] = useState('');

  const depositAmount = useMemo(() => safeParseUsdce(depositInput), [depositInput]);
  const withdrawAmount = useMemo(() => safeParseUsdce(withdrawInput), [withdrawInput]);

  const { data: previewShares, isLoading: previewLoading } = useReadContract({
    address: CONTRACTS.helixVault,
    abi: HELIX_VAULT_ABI,
    functionName: 'previewDeposit',
    args: [depositAmount],
    chainId: CITREA_CHAIN_ID,
    query: {
      enabled: isConnected && depositAmount > 0n,
      refetchInterval: 30_000,
    },
  });

  const remainingCap =
    vaultState.depositCap > vaultState.totalAssets ? vaultState.depositCap - vaultState.totalAssets : 0n;
  const allocationBps =
    vaultState.totalAssets > 0n
      ? Number((vaultState.totalStrategyAssets * 10_000n) / vaultState.totalAssets)
      : 0;
  const statusLabel = vaultState.paused
    ? 'Paused'
    : vaultState.withdrawOnly
      ? 'Withdraw only'
      : 'Active';
  const statusVariant = vaultState.paused || vaultState.withdrawOnly ? 'secondary' : 'default';

  const depositDisabled =
    !isConnected ||
    vaultState.paused ||
    vaultState.withdrawOnly ||
    depositAmount <= 0n ||
    depositAmount > userPosition.usdceBalance ||
    depositAmount > remainingCap ||
    isApproving ||
    isDepositing;

  const withdrawDisabled =
    !isConnected ||
    withdrawAmount <= 0n ||
    withdrawAmount > userPosition.sharesInUsdce ||
    (vaultState.withdrawOnly && userPosition.shares === 0n) ||
    isWithdrawing;

  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top,_rgba(34,197,94,0.12),_transparent_28%),linear-gradient(180deg,_#020617_0%,_#0f172a_52%,_#111827_100%)] px-4 py-8 text-slate-100 sm:px-6 lg:px-8">
      <div className="mx-auto flex w-full max-w-7xl flex-col gap-6">
        <div className="flex flex-col gap-4 rounded-[2rem] border border-white/10 bg-white/5 p-6 shadow-2xl backdrop-blur-xl lg:flex-row lg:items-center lg:justify-between">
          <div className="space-y-2">
            <div className="flex flex-wrap items-center gap-3">
              <p className="text-xs uppercase tracking-[0.35em] text-emerald-300">Citrea mainnet</p>
              <Badge variant={statusVariant}>{statusLabel}</Badge>
            </div>
            <div>
              <h1 className="text-3xl font-semibold tracking-tight text-white sm:text-4xl">
                Helix USDC.e Smart Vault
              </h1>
              <p className="mt-2 text-sm text-slate-300 sm:text-base">
                Vault {truncateAddress(CONTRACTS.helixVault)} on Citrea
              </p>
            </div>
          </div>

          <div className="flex flex-col items-start gap-3 sm:flex-row sm:items-center">
            <Button variant="outline" onClick={() => globalThis.history.back()}>
              Back
            </Button>
            <ConnectButton.Custom>
              {({ account, chain, openAccountModal, openChainModal, openConnectModal, mounted }) => {
                const connected = Boolean(mounted && account && chain);
                const label = !connected
                  ? 'Connect wallet'
                  : chain?.unsupported
                    ? 'Switch to Citrea'
                    : 'Open account';

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

                      openAccountModal();
                    }}
                  >
                    {label}
                  </Button>
                );
              }}
            </ConnectButton.Custom>
          </div>
        </div>

        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          <StatCard
            label="TVL"
            value={formatUsdce(vaultState.totalAssets)}
            loading={vaultState.isLoading}
          />
          <StatCard
            label="Deposit cap remaining"
            value={formatUsdce(remainingCap)}
            loading={vaultState.isLoading}
          />
          <StatCard
            label="Strategy allocation"
            value={`${formatBps(allocationBps)} of assets`}
            loading={vaultState.isLoading}
          />
          <Card>
            <CardContent className="pt-6">
              <div className="text-[11px] uppercase tracking-[0.28em] text-slate-400">Status</div>
              {vaultState.isLoading ? (
                <Skeleton className="mt-3 h-8 w-28" />
              ) : (
                <Badge className="mt-3" variant={statusVariant}>
                  {statusLabel}
                </Badge>
              )}
            </CardContent>
          </Card>
        </div>

        <div className="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]">
          <Card>
            <CardHeader>
              <CardTitle>Your position</CardTitle>
              <CardDescription>Vault shares and approval state for the connected wallet.</CardDescription>
            </CardHeader>
            <CardContent>
              {isConnected ? (
                userPosition.isLoading ? (
                  <div className="grid gap-3 sm:grid-cols-3">
                    <Skeleton className="h-24 rounded-2xl" />
                    <Skeleton className="h-24 rounded-2xl" />
                    <Skeleton className="h-24 rounded-2xl" />
                  </div>
                ) : (
                  <div className="grid gap-3 sm:grid-cols-3">
                    <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                      <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">Shares</div>
                      <div className="mt-2 text-lg font-semibold text-white">{formatHlx(userPosition.shares)}</div>
                    </div>
                    <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                      <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">Shares in USDC.e</div>
                      <div className="mt-2 text-lg font-semibold text-white">
                        {formatUsdce(userPosition.sharesInUsdce)}
                      </div>
                    </div>
                    <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                      <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">Wallet USDC.e</div>
                      <div className="mt-2 text-lg font-semibold text-white">
                        {formatUsdce(userPosition.usdceBalance)}
                      </div>
                    </div>
                  </div>
                )
              ) : (
                <div className="rounded-2xl border border-white/10 bg-white/5 p-5 text-sm text-slate-300">
                  Connect your wallet to view your vault shares and balances.
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Strategy info</CardTitle>
              <CardDescription>Compounding settings and cooldown status.</CardDescription>
            </CardHeader>
            <CardContent>
              {strategyState.isLoading ? (
                <SectionSkeleton />
              ) : (
                <div className="grid gap-3">
                  <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                    <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">Performance fee</div>
                    <div className="mt-2 text-lg font-semibold text-white">
                      {formatBps(strategyState.performanceFeeBps)}
                    </div>
                  </div>
                  <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                    <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">Reward ratio</div>
                    <div className="mt-2 text-lg font-semibold text-white">
                      {formatBps(strategyState.rewardRatioBps)}
                    </div>
                  </div>
                  <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                    <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">Last compound</div>
                    <div className="mt-2 text-lg font-semibold text-white">
                      {formatTimestamp(strategyState.lastCompoundTimestamp)}
                    </div>
                  </div>
                  <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                    <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">Cooldown remaining</div>
                    <div className="mt-2 text-lg font-semibold text-white">
                      {strategyState.cooldownRemaining > 0n
                        ? formatCountdown(strategyState.cooldownRemaining)
                        : 'Ready now'}
                    </div>
                  </div>
                  {strategyState.rebalancePaused ? (
                    <Badge variant="secondary" className="w-fit">
                      Rebalance paused
                    </Badge>
                  ) : null}
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Deposit and withdraw</CardTitle>
            <CardDescription>Use the vault tabs to add or remove USDC.e.</CardDescription>
          </CardHeader>
          <CardContent>
            {!isConnected ? (
              <div className="flex flex-col items-start gap-4 rounded-2xl border border-white/10 bg-white/5 p-5">
                <p className="text-sm text-slate-300">Connect your wallet to deposit USDC.e or withdraw shares.</p>
                <ConnectButton.Custom>
                  {({ account, chain, openAccountModal, openChainModal, openConnectModal, mounted }) => {
                    const connected = Boolean(mounted && account && chain);
                    const label = !connected
                      ? 'Connect wallet'
                      : chain?.unsupported
                        ? 'Switch to Citrea'
                        : 'Open account';

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

                          openAccountModal();
                        }}
                      >
                        {label}
                      </Button>
                    );
                  }}
                </ConnectButton.Custom>
              </div>
            ) : (
              <Tabs value={activeTab} onValueChange={setActiveTab} defaultValue="deposit" className="space-y-4">
                <TabsList>
                  <TabsTrigger value="deposit">Deposit</TabsTrigger>
                  <TabsTrigger value="withdraw">Withdraw</TabsTrigger>
                </TabsList>

                <TabsContent value="deposit" className="space-y-4">
                  <div className="grid gap-4 lg:grid-cols-[1fr_auto]">
                    <div className="space-y-2">
                      <div className="flex items-center justify-between">
                        <label className="text-sm font-medium text-slate-200">USDC.e amount</label>
                        <Button
                          type="button"
                          variant="ghost"
                          onClick={() => setDepositInput(formatUsdce(userPosition.usdceBalance))}
                        >
                          Max
                        </Button>
                      </div>
                      <Input
                        inputMode="decimal"
                        placeholder="0.00"
                        value={depositInput}
                        onChange={(event) => setDepositInput(event.target.value)}
                      />
                    </div>
                    <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                      <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">Estimated shares</div>
                      {previewLoading ? (
                        <Skeleton className="mt-2 h-8 w-28" />
                      ) : (
                        <div className="mt-2 text-lg font-semibold text-white">
                          {depositAmount > 0n ? formatHlx((previewShares as bigint | undefined) ?? 0n) : '0'}
                        </div>
                      )}
                    </div>
                  </div>

                  {depositError ? <p className="text-sm text-red-300">{depositError.message}</p> : null}
                  {depositTxHash ? (
                    <p className="text-xs text-slate-400">Last transaction: {truncateAddress(depositTxHash)}</p>
                  ) : null}

                  <Button
                    onClick={async () => {
                      await deposit(depositAmount);
                      setDepositInput('');
                    }}
                    disabled={depositDisabled}
                    className="min-w-[180px]"
                  >
                    {isApproving ? (
                      <span className="flex items-center gap-2">
                        <Spinner />
                        Approving...
                      </span>
                    ) : isDepositing ? (
                      <span className="flex items-center gap-2">
                        <Spinner />
                        Depositing...
                      </span>
                    ) : userPosition.usdceAllowance < depositAmount ? (
                      'Approve & Deposit'
                    ) : (
                      'Deposit'
                    )}
                  </Button>
                </TabsContent>

                <TabsContent value="withdraw" className="space-y-4">
                  <div className="grid gap-4 lg:grid-cols-[1fr_auto]">
                    <div className="space-y-2">
                      <div className="flex items-center justify-between">
                        <label className="text-sm font-medium text-slate-200">USDC.e amount</label>
                        <Button
                          type="button"
                          variant="ghost"
                          onClick={() => setWithdrawInput(formatUsdce(userPosition.sharesInUsdce))}
                        >
                          Max
                        </Button>
                      </div>
                      <Input
                        inputMode="decimal"
                        placeholder="0.00"
                        value={withdrawInput}
                        onChange={(event) => setWithdrawInput(event.target.value)}
                      />
                    </div>
                    <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                      <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">Available to withdraw</div>
                      <div className="mt-2 text-lg font-semibold text-white">
                        {formatUsdce(userPosition.sharesInUsdce)}
                      </div>
                    </div>
                  </div>

                  {withdrawError ? <p className="text-sm text-red-300">{withdrawError.message}</p> : null}
                  {withdrawTxHash ? (
                    <p className="text-xs text-slate-400">Last transaction: {truncateAddress(withdrawTxHash)}</p>
                  ) : null}

                  <Button
                    onClick={async () => {
                      await withdraw(withdrawAmount);
                      setWithdrawInput('');
                    }}
                    disabled={withdrawDisabled}
                    className="min-w-[180px]"
                  >
                    {isWithdrawing ? (
                      <span className="flex items-center gap-2">
                        <Spinner />
                        Withdrawing...
                      </span>
                    ) : (
                      'Withdraw'
                    )}
                  </Button>
                </TabsContent>
              </Tabs>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Vault details</CardTitle>
            <CardDescription>Addresses and current vault configuration.</CardDescription>
          </CardHeader>
          <CardContent>
            {vaultState.isLoading ? (
              <SectionSkeleton />
            ) : (
              <div className="grid gap-3 md:grid-cols-2">
                <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                  <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">Asset</div>
                  <div className="mt-2 break-all text-sm font-medium text-white">{vaultState.asset}</div>
                </div>
                <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                  <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">Strategy</div>
                  <div className="mt-2 break-all text-sm font-medium text-white">{vaultState.strategy}</div>
                </div>
                <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                  <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">Deposit cap</div>
                  <div className="mt-2 text-sm font-medium text-white">{formatUsdce(vaultState.depositCap)}</div>
                </div>
                <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                  <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">Vault shares held</div>
                  <div className="mt-2 text-sm font-medium text-white">
                    {formatHlx(userPosition.shares)}
                  </div>
                </div>
              </div>
            )}
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
