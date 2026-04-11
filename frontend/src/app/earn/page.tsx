'use client';

import Link from 'next/link';
import { useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { parseUnits } from 'viem';
import { useAccount, useReadContract } from 'wagmi';

import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { CONTRACTS, CITREA_CHAIN_ID } from '@/config/contracts';
import { HELIX_VAULT_ABI } from '@/lib/contracts';
import { formatHlx, formatTimestamp, formatUsdce, truncateAddress } from '@/lib/format';
import { useClaimRewards } from '@/hooks/useClaimRewards';
import { useStake } from '@/hooks/useStake';
import { useUnstake } from '@/hooks/useUnstake';
import { useUserRewards } from '@/hooks/useUserRewards';
import { useUserVaultPosition } from '@/hooks/useUserVaultPosition';

function safeParseShares(value: string) {
  const normalized = value.replaceAll(',', '').trim();

  if (!normalized || normalized === '.') {
    return 0n;
  }

  try {
    return parseUnits(normalized, 18);
  } catch {
    return 0n;
  }
}

function Spinner() {
  return <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />;
}

function RewardCard({
  label,
  value,
  accent = false,
  loading,
}: {
  label: string;
  value: string;
  accent?: boolean;
  loading?: boolean;
}) {
  return (
    <Card>
      <CardContent className="pt-6">
        <div className="text-[11px] uppercase tracking-[0.28em] text-slate-400">{label}</div>
        {loading ? (
          <Skeleton className="mt-3 h-8 w-32" />
        ) : (
          <div className={['mt-3 text-2xl font-semibold', accent ? 'text-emerald-300' : 'text-white'].join(' ')}>
            {value}
          </div>
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

export default function EarnPage() {
  const router = useRouter();
  const { isConnected } = useAccount();
  const userRewards = useUserRewards();
  const userPosition = useUserVaultPosition();
  const { stake, isApproving, isStaking, txHash: stakeTxHash, error: stakeError } = useStake();
  const { unstake, isUnstaking, txHash: unstakeTxHash, error: unstakeError } = useUnstake();
  const {
    claimRewards,
    isClaiming,
    txHash: claimTxHash,
    error: claimError,
  } = useClaimRewards();
  const [activeTab, setActiveTab] = useState('stake');
  const [stakeInput, setStakeInput] = useState('');
  const [unstakeInput, setUnstakeInput] = useState('');

  const stakeAmount = useMemo(() => safeParseShares(stakeInput), [stakeInput]);
  const unstakeAmount = useMemo(() => safeParseShares(unstakeInput), [unstakeInput]);

  const { data: stakedSharesInUsdce = 0n, isLoading: stakedValueLoading } = useReadContract({
    address: CONTRACTS.helixVault,
    abi: HELIX_VAULT_ABI,
    functionName: 'convertToAssets',
    args: [userRewards.stakedShares],
    chainId: CITREA_CHAIN_ID,
    query: {
      enabled: isConnected && userRewards.stakedShares > 0n,
      refetchInterval: 30_000,
    },
  });

  const weeklyReward = userRewards.rewardRate * 604_800n;
  const hasRewards = userRewards.earnedHlx > 0n;
  const stakeAllowanceInsufficient = userRewards.stakeAllowance < stakeAmount;

  const stakeDisabled =
    !isConnected ||
    stakeAmount <= 0n ||
    stakeAmount > userPosition.shares ||
    isApproving ||
    isStaking;

  const unstakeDisabled =
    !isConnected ||
    unstakeAmount <= 0n ||
    unstakeAmount > userRewards.stakedShares ||
    userRewards.stakedShares === 0n ||
    isUnstaking;

  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top,_rgba(34,197,94,0.12),_transparent_28%),linear-gradient(180deg,_#020617_0%,_#0f172a_52%,_#111827_100%)] px-4 py-8 text-slate-100 sm:px-6 lg:px-8">
      <div className="mx-auto flex w-full max-w-7xl flex-col gap-6">
        <div className="flex flex-col gap-4 rounded-[2rem] border border-white/10 bg-white/5 p-6 shadow-2xl backdrop-blur-xl lg:flex-row lg:items-center lg:justify-between">
          <div className="space-y-2">
            <p className="text-xs uppercase tracking-[0.35em] text-emerald-300">HLX rewards</p>
            <h1 className="text-3xl font-semibold tracking-tight text-white sm:text-4xl">
              Earn HLX Rewards
            </h1>
            <p className="mt-2 text-sm text-slate-300 sm:text-base">
              Stake your vault shares to earn HLX
            </p>
          </div>

          <div className="flex flex-col items-start gap-3 sm:flex-row sm:items-center">
            <Button variant="outline" onClick={() => router.push('/vault')}>
              Back to vault
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

        {!isConnected ? (
          <Card>
            <CardContent className="flex flex-col items-start gap-4 p-6">
              <p className="text-sm text-slate-300">Connect Wallet to Start Earning.</p>
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
            </CardContent>
          </Card>
        ) : (
          <>
            <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
              <RewardCard
                label="Staked shares"
                value={formatHlx(userRewards.stakedShares)}
                loading={userRewards.isLoading}
              />
              <RewardCard
                label="Staked value"
                value={formatUsdce(stakedSharesInUsdce)}
                loading={userRewards.isLoading || stakedValueLoading}
              />
              <RewardCard
                label="Claimable HLX"
                value={formatHlx(userRewards.earnedHlx)}
                accent
                loading={userRewards.isLoading}
              />
              <RewardCard
                label="HLX wallet balance"
                value={formatHlx(userRewards.hlxBalance)}
                loading={userRewards.isLoading}
              />
              <RewardCard
                label="Reward rate / week"
                value={formatHlx(weeklyReward)}
                accent
                loading={userRewards.isLoading}
              />
              <RewardCard
                label="Reward period end"
                value={formatTimestamp(userRewards.periodFinish)}
                loading={userRewards.isLoading}
              />
            </div>

            <div className="grid gap-6 xl:grid-cols-[1.15fr_0.85fr]">
              <Card>
                <CardHeader>
                  <CardTitle>Stake and unstake</CardTitle>
                  <CardDescription>Move vault shares in and out of the HLX rewards pool.</CardDescription>
                </CardHeader>
                <CardContent>
                  <Tabs value={activeTab} onValueChange={setActiveTab} defaultValue="stake" className="space-y-4">
                    <TabsList>
                      <TabsTrigger value="stake">Stake</TabsTrigger>
                      <TabsTrigger value="unstake">Unstake</TabsTrigger>
                    </TabsList>

                    <TabsContent value="stake" className="space-y-4">
                      <div className="grid gap-4 lg:grid-cols-[1fr_auto]">
                        <div className="space-y-2">
                          <div className="flex items-center justify-between">
                            <label className="text-sm font-medium text-slate-200">Vault shares</label>
                            <Button
                              type="button"
                              variant="ghost"
                              onClick={() => setStakeInput(formatHlx(userPosition.shares))}
                            >
                              Max
                            </Button>
                          </div>
                          <Input
                            inputMode="decimal"
                            placeholder="0.00"
                            value={stakeInput}
                            onChange={(event) => setStakeInput(event.target.value)}
                          />
                        </div>
                        <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                          <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">
                            Available vault shares
                          </div>
                          <div className="mt-2 text-lg font-semibold text-white">
                            {formatHlx(userPosition.shares)}
                          </div>
                        </div>
                      </div>

                      {stakeError ? <p className="text-sm text-red-300">{stakeError.message}</p> : null}
                      {stakeTxHash ? (
                        <p className="text-xs text-slate-400">Last transaction: {truncateAddress(stakeTxHash)}</p>
                      ) : null}

                      <Button
                        onClick={async () => {
                          await stake(stakeAmount);
                          setStakeInput('');
                        }}
                        disabled={stakeDisabled}
                        className="min-w-[180px]"
                      >
                        {isApproving ? (
                          <span className="flex items-center gap-2">
                            <Spinner />
                            Approving...
                          </span>
                        ) : isStaking ? (
                          <span className="flex items-center gap-2">
                            <Spinner />
                            Staking...
                          </span>
                        ) : stakeAllowanceInsufficient ? (
                          'Approve & Stake'
                        ) : (
                          'Stake'
                        )}
                      </Button>
                    </TabsContent>

                    <TabsContent value="unstake" className="space-y-4">
                      <div className="grid gap-4 lg:grid-cols-[1fr_auto]">
                        <div className="space-y-2">
                          <div className="flex items-center justify-between">
                            <label className="text-sm font-medium text-slate-200">Staked shares</label>
                            <Button
                              type="button"
                              variant="ghost"
                              onClick={() => setUnstakeInput(formatHlx(userRewards.stakedShares))}
                            >
                              Max
                            </Button>
                          </div>
                          <Input
                            inputMode="decimal"
                            placeholder="0.00"
                            value={unstakeInput}
                            onChange={(event) => setUnstakeInput(event.target.value)}
                          />
                        </div>
                        <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                          <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">
                            Available staked shares
                          </div>
                          <div className="mt-2 text-lg font-semibold text-white">
                            {formatHlx(userRewards.stakedShares)}
                          </div>
                        </div>
                      </div>

                      {unstakeError ? <p className="text-sm text-red-300">{unstakeError.message}</p> : null}
                      {unstakeTxHash ? (
                        <p className="text-xs text-slate-400">Last transaction: {truncateAddress(unstakeTxHash)}</p>
                      ) : null}

                      <Button
                        onClick={async () => {
                          await unstake(unstakeAmount);
                          setUnstakeInput('');
                        }}
                        disabled={unstakeDisabled}
                        className="min-w-[180px]"
                      >
                        {isUnstaking ? (
                          <span className="flex items-center gap-2">
                            <Spinner />
                            Unstaking...
                          </span>
                        ) : (
                          'Unstake'
                        )}
                      </Button>
                    </TabsContent>
                  </Tabs>
                </CardContent>
              </Card>

              <div className="space-y-6">
                <Card>
                  <CardHeader>
                    <CardTitle>Claim HLX</CardTitle>
                    <CardDescription>Claim accumulated HLX rewards at any time.</CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <Badge variant={hasRewards ? 'default' : 'secondary'} className="w-fit">
                      {hasRewards ? 'Claim ready' : 'No rewards yet'}
                    </Badge>
                    <div className="rounded-2xl border border-emerald-400/20 bg-emerald-400/5 p-5">
                      <div className="text-[11px] uppercase tracking-[0.25em] text-emerald-200/80">
                        Pending HLX
                      </div>
                      <div className="mt-2 text-3xl font-semibold text-emerald-300">
                        {formatHlx(userRewards.earnedHlx)}
                      </div>
                    </div>

                    {claimError ? <p className="text-sm text-red-300">{claimError.message}</p> : null}
                    {claimTxHash ? (
                      <p className="text-xs text-slate-400">Last transaction: {truncateAddress(claimTxHash)}</p>
                    ) : null}

                    <Button
                      onClick={claimRewards}
                      disabled={!hasRewards || isClaiming}
                      className="min-w-[180px]"
                    >
                      {isClaiming ? (
                        <span className="flex items-center gap-2">
                          <Spinner />
                          Claiming...
                        </span>
                      ) : (
                        'Claim HLX'
                      )}
                    </Button>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle>How rewards work</CardTitle>
                    <CardDescription>Helix pays HLX to stakers from compound fees.</CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-3 text-sm leading-6 text-slate-300">
                    <p>Vault shares are staked to earn HLX rewards from compound fees.</p>
                    <p>Rewards accumulate over time based on your share of the staking pool.</p>
                    <p>You can unstake at any time.</p>
                  </CardContent>
                </Card>
              </div>
            </div>

            <Card>
              <CardHeader>
                <CardTitle>Reward details</CardTitle>
                <CardDescription>Live reward state from the deployed distributor.</CardDescription>
              </CardHeader>
              <CardContent>
                {userRewards.isLoading ? (
                  <SectionSkeleton />
                ) : (
                  <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
                    <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                      <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">Staked shares</div>
                      <div className="mt-2 text-lg font-semibold text-white">
                        {formatHlx(userRewards.stakedShares)}
                      </div>
                    </div>
                    <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                      <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">Share value</div>
                      <div className="mt-2 text-lg font-semibold text-white">
                        {formatUsdce(stakedSharesInUsdce)}
                      </div>
                    </div>
                    <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                      <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">HLX balance</div>
                      <div className="mt-2 text-lg font-semibold text-white">
                        {formatHlx(userRewards.hlxBalance)}
                      </div>
                    </div>
                    <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                      <div className="text-[11px] uppercase tracking-[0.25em] text-slate-400">Period finish</div>
                      <div className="mt-2 text-lg font-semibold text-white">
                        {formatTimestamp(userRewards.periodFinish)}
                      </div>
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          </>
        )}

        <div className="flex justify-center gap-3 pb-6 text-sm text-slate-400">
          <Link href="/" className="hover:text-white">
            Home
          </Link>
          <span>•</span>
          <Link href="/vault" className="hover:text-white">
            Vault
          </Link>
        </div>
      </div>
    </main>
  );
}
