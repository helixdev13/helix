'use client';

import type { ReactNode } from 'react';
import { useState } from 'react';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount } from 'wagmi';
import { parseUnits } from 'viem';

import { GradientButton } from '@/components/GradientButton';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import {
  useClaimRewards,
  useCompound,
  useDeposit,
  useStake,
  useStrategyState,
  useUnstake,
  useUserRewards,
  useUserVaultPosition,
  useVaultState,
  useWithdraw,
} from '@/hooks';
import { formatHlx, formatUsdce } from '@/lib/format';

function parseAmount(value: string, decimals: number) {
  const trimmed = value.trim();
  if (!trimmed) {
    return 0n;
  }

  try {
    return parseUnits(trimmed, decimals);
  } catch {
    return 0n;
  }
}

function Metric({
  label,
  value,
  isLoading = false,
}: {
  label: string;
  value: string;
  isLoading?: boolean;
}) {
  return (
    <div className="rounded-2xl border border-[#F0E8E8] bg-[#FFF8F6] px-4 py-3">
      <div className="text-[11px] uppercase tracking-[0.22em] text-[#999999]">{label}</div>
      {isLoading ? <Skeleton className="mt-1 h-5 w-24" /> : <div className="mt-1 text-base font-semibold text-[#333333]">{value}</div>}
    </div>
  );
}

function ActionCard({
  title,
  description,
  children,
}: {
  title: string;
  description: string;
  children: ReactNode;
}) {
  return (
    <div className="rounded-2xl border border-[#F0E8E8] bg-[#FFF8F6] p-5 sm:p-6">
      <div className="mb-3 space-y-1">
        <div className="text-sm font-semibold text-[#333333]">{title}</div>
        <div className="text-xs leading-5 text-[#666666]">{description}</div>
      </div>
      {children}
    </div>
  );
}

function ConnectPrompt({ label }: { label: string }) {
  return (
    <ConnectButton.Custom>
      {({ mounted, openConnectModal }) => {
        if (!mounted) {
          return (
            <GradientButton className="w-full" disabled>
              {label}
            </GradientButton>
          );
        }

        return (
          <GradientButton
            className="w-full"
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

export function VaultRow() {
  const { address } = useAccount();
  const connected = Boolean(address);
  const [expanded, setExpanded] = useState(false);
  const [depositValue, setDepositValue] = useState('');
  const [withdrawValue, setWithdrawValue] = useState('');
  const [stakeValue, setStakeValue] = useState('');
  const [unstakeValue, setUnstakeValue] = useState('');

  const vaultState = useVaultState();
  const strategyState = useStrategyState();
  const userPosition = useUserVaultPosition();
  const userRewards = useUserRewards();
  const deposit = useDeposit();
  const withdraw = useWithdraw();
  const stake = useStake();
  const unstake = useUnstake();
  const claimRewards = useClaimRewards();
  const compound = useCompound();

  const depositAmount = parseAmount(depositValue, 6);
  const withdrawAmount = parseAmount(withdrawValue, 6);
  const stakeAmount = parseAmount(stakeValue, 6);
  const unstakeAmount = parseAmount(unstakeValue, 6);

  const latestTxHash =
    deposit.txHash ??
    withdraw.txHash ??
    stake.txHash ??
    unstake.txHash ??
    claimRewards.txHash ??
    compound.txHash;
  const latestError =
    deposit.error ??
    withdraw.error ??
    stake.error ??
    unstake.error ??
    claimRewards.error ??
    compound.error;

  const isHarvesting = compound.isCompounding;
  const harvestDisabled =
    strategyState.cooldownRemaining > 0n || isHarvesting || strategyState.rebalancePaused;

  const statusLabel = vaultState.paused
    ? 'Paused'
    : vaultState.withdrawOnly
      ? 'Withdraw Only'
      : 'Active';

  return (
    <Card className="overflow-hidden">
      <CardContent className="p-0">
        <div
          role="button"
          tabIndex={0}
          onClick={() => setExpanded((current) => !current)}
          onKeyDown={(event) => {
            if (event.key === 'Enter' || event.key === ' ') {
              event.preventDefault();
              setExpanded((current) => !current);
            }
          }}
          className="flex cursor-pointer flex-col gap-4 border-b border-[#F0E8E8] px-5 py-5 sm:px-6 lg:flex-row lg:items-center lg:justify-between"
        >
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-[#FFF1F5] text-[#D4797F]">
              <span
                className={[
                  'text-lg transition-transform duration-200',
                  expanded ? 'rotate-180' : 'rotate-0',
                ].join(' ')}
              >
                ▾
              </span>
            </div>
            <div>
              <div className="flex flex-wrap items-center gap-2">
                <h3 className="text-lg font-semibold text-[#333333]">Helix USDC.e Vault</h3>
                <Badge variant={vaultState.paused || vaultState.withdrawOnly ? 'secondary' : 'default'}>
                  {statusLabel}
                </Badge>
              </div>
              <p className="mt-1 text-sm text-[#666666]">Single-asset smart vault on Citrea</p>
            </div>
          </div>

          <div className="grid flex-1 grid-cols-1 gap-3 text-left sm:grid-cols-2 xl:grid-cols-4 lg:max-w-3xl lg:gap-4">
            <Metric
              label="APY"
              value="—"
            />
            <Metric
              label="TVL"
              value={`${formatUsdce(vaultState.totalAssets)} USDC.e`}
              isLoading={vaultState.isLoading}
            />
            <Metric
              label="Earned HLX"
              value={`${formatHlx(userRewards.earnedHlx)} HLX`}
              isLoading={!connected || userRewards.isLoading}
            />
            <div className="flex items-center justify-end gap-2">
              {connected ? (
                <GradientButton
                  className="w-full sm:w-auto"
                  disabled={harvestDisabled}
                  onClick={(event) => {
                    event.stopPropagation();
                    void compound.compound();
                  }}
                >
                  {isHarvesting
                    ? 'Harvesting...'
                    : strategyState.cooldownRemaining > 0n
                      ? 'Cooldown'
                      : 'Harvest'}
                </GradientButton>
              ) : (
                <ConnectPrompt label="Connect to Harvest" />
              )}
            </div>
          </div>
        </div>

        {expanded ? (
          <div
            className="grid gap-4 px-5 py-5 sm:px-6 lg:grid-cols-2"
            onClick={(event) => event.stopPropagation()}
          >
            {!connected ? (
              <div className="rounded-2xl border border-dashed border-[#F0E8E8] bg-[#FFF8F6] p-6 lg:col-span-2">
                <div className="text-lg font-semibold text-[#333333]">Connect to Deposit</div>
                <p className="mt-2 max-w-2xl text-sm leading-6 text-[#666666]">
                  Connect your wallet to deposit, withdraw, stake, unstake, and claim HLX rewards.
                </p>
                <div className="mt-4 max-w-[220px]">
                  <ConnectPrompt label="Connect to Deposit" />
                </div>
              </div>
            ) : (
              <>
                <ActionCard
                  title="Deposit & Withdraw"
                  description="Approval happens automatically when needed."
                >
                  <div className="space-y-4">
                    <div className="space-y-2">
                      <div className="flex items-center justify-between gap-3">
                        <label className="text-xs uppercase tracking-[0.2em] text-[#999999]">
                          Deposit USDC.e
                        </label>
                        <Button
                          type="button"
                          variant="ghost"
                          className="h-auto px-0 py-0 text-xs text-[#D4797F]"
                          onClick={() => setDepositValue(formatUsdce(userPosition.usdceBalance))}
                        >
                          Max
                        </Button>
                      </div>
                      <Input
                        type="text"
                        inputMode="decimal"
                        value={depositValue}
                        onChange={(event) => setDepositValue(event.target.value)}
                        placeholder="0.00"
                      />
                      <GradientButton
                        className="w-full"
                        disabled={depositAmount <= 0n || deposit.isApproving || deposit.isDepositing}
                        onClick={() => void deposit.deposit(depositAmount)}
                      >
                        {deposit.isApproving
                          ? 'Approving...'
                          : deposit.isDepositing
                            ? 'Depositing...'
                            : 'Deposit'}
                      </GradientButton>
                    </div>

                    <div className="space-y-2">
                      <div className="flex items-center justify-between gap-3">
                        <label className="text-xs uppercase tracking-[0.2em] text-[#999999]">
                          Withdraw USDC.e
                        </label>
                        <Button
                          type="button"
                          variant="ghost"
                          className="h-auto px-0 py-0 text-xs text-[#D4797F]"
                          onClick={() => setWithdrawValue(formatUsdce(userPosition.sharesInUsdce))}
                        >
                          Max
                        </Button>
                      </div>
                      <Input
                        type="text"
                        inputMode="decimal"
                        value={withdrawValue}
                        onChange={(event) => setWithdrawValue(event.target.value)}
                        placeholder="0.00"
                      />
                      <Button
                        type="button"
                        className="w-full"
                        variant="outline"
                        disabled={withdrawAmount <= 0n || withdraw.isWithdrawing}
                        onClick={() => void withdraw.withdraw(withdrawAmount)}
                      >
                        {withdraw.isWithdrawing ? 'Withdrawing...' : 'Withdraw'}
                      </Button>
                    </div>
                  </div>
                </ActionCard>

                <ActionCard title="Stake & Rewards" description="Stake vault shares to earn HLX rewards.">
                  <div className="space-y-4">
                    <div className="space-y-2">
                      <div className="flex items-center justify-between gap-3">
                        <label className="text-xs uppercase tracking-[0.2em] text-[#999999]">
                          Stake vault shares
                        </label>
                        <Button
                          type="button"
                          variant="ghost"
                          className="h-auto px-0 py-0 text-xs text-[#D4797F]"
                          onClick={() => setStakeValue(formatHlx(userPosition.shares))}
                        >
                          Max
                        </Button>
                      </div>
                      <Input
                        type="text"
                        inputMode="decimal"
                        value={stakeValue}
                        onChange={(event) => setStakeValue(event.target.value)}
                        placeholder="0.00"
                      />
                      <GradientButton
                        className="w-full"
                        disabled={stakeAmount <= 0n || stake.isApproving || stake.isStaking}
                        onClick={() => void stake.stake(stakeAmount)}
                      >
                        {stake.isApproving
                          ? 'Approving...'
                          : stake.isStaking
                            ? 'Staking...'
                            : 'Stake'}
                      </GradientButton>
                    </div>

                    <div className="space-y-2">
                      <div className="flex items-center justify-between gap-3">
                        <label className="text-xs uppercase tracking-[0.2em] text-[#999999]">
                          Unstake shares
                        </label>
                        <Button
                          type="button"
                          variant="ghost"
                          className="h-auto px-0 py-0 text-xs text-[#D4797F]"
                          onClick={() => setUnstakeValue(formatHlx(userRewards.stakedShares))}
                        >
                          Max
                        </Button>
                      </div>
                      <Input
                        type="text"
                        inputMode="decimal"
                        value={unstakeValue}
                        onChange={(event) => setUnstakeValue(event.target.value)}
                        placeholder="0.00"
                      />
                      <Button
                        type="button"
                        className="w-full"
                        variant="outline"
                        disabled={unstakeAmount <= 0n || unstake.isUnstaking}
                        onClick={() => void unstake.unstake(unstakeAmount)}
                      >
                        {unstake.isUnstaking ? 'Unstaking...' : 'Unstake'}
                      </Button>
                    </div>

                    <div className="rounded-2xl border border-[#F0E8E8] bg-white p-5">
                      <div className="text-xs uppercase tracking-[0.2em] text-[#999999]">Claim HLX</div>
                      <div className="mt-2 text-sm text-[#666666]">
                        Claim your accrued HLX rewards from compound fees.
                      </div>
                      <div className="mt-4 flex flex-wrap items-center gap-3">
                        <GradientButton
                          disabled={userRewards.earnedHlx <= 0n || claimRewards.isClaiming}
                          onClick={() => void claimRewards.claimRewards()}
                        >
                          {claimRewards.isClaiming ? 'Claiming...' : 'Claim HLX'}
                        </GradientButton>
                        <div className="text-sm text-[#666666]">
                          Earned: <span className="font-semibold text-[#333333]">{formatHlx(userRewards.earnedHlx)} HLX</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </ActionCard>
              </>
            )}

            <div className="lg:col-span-2">
              <div className="rounded-2xl border border-[#F0E8E8] bg-white px-5 py-5 text-sm text-[#666666]">
                <span className="font-medium text-[#333333]">Latest transaction:</span>{' '}
                {latestTxHash ? (
                  <a
                    href={`https://explorer.citrea.xyz/tx/${latestTxHash}`}
                    target="_blank"
                    rel="noreferrer"
                    className="font-medium text-[#D4797F] underline-offset-4 hover:underline"
                  >
                    {latestTxHash}
                  </a>
                ) : (
                  'No recent transaction'
                )}
              </div>
              {latestError ? (
                <div className="mt-3 rounded-2xl border border-[#F3C4CF] bg-[#FFF5F8] p-4 text-sm text-[#B85C7D]">
                  {latestError.message}
                </div>
              ) : null}
            </div>
          </div>
        ) : null}
      </CardContent>
    </Card>
  );
}
