'use client';

import type { ReactNode } from 'react';
import { useEffect, useState } from 'react';

import { useAccount } from 'wagmi';
import { parseUnits } from 'viem';

import { ConnectWalletButton } from '@/components/ConnectWalletButton';
import { GradientButton } from '@/components/GradientButton';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
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
import { CONTRACTS } from '@/config/contracts';
import { formatHlx, formatUsdce } from '@/lib/format';

type UserRewardsState = ReturnType<typeof useUserRewards>;

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

function MetricCell({
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
    <div>
      <div className="text-[11px] uppercase tracking-[0.22em] text-[var(--text-muted)]">{label}</div>
      {isLoading ? (
        <Skeleton className="mt-2 h-5 w-24" />
      ) : (
        <div className="mt-2 text-sm font-semibold text-[var(--text-primary)]">{value}</div>
      )}
      <div className="mt-1 text-xs text-[var(--text-secondary)]">{helper}</div>
    </div>
  );
}

function ActionCard({ title, description, children }: { title: string; description: string; children: ReactNode }) {
  return (
    <div className="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-surface)] p-5 sm:p-6">
      <div className="mb-4 space-y-1">
        <div className="text-sm font-semibold text-[var(--text-primary)]">{title}</div>
        <div className="text-xs leading-5 text-[var(--text-secondary)]">{description}</div>
      </div>
      {children}
    </div>
  );
}

function VaultExpandedSection({ userRewards }: { userRewards: UserRewardsState }) {
  const [depositValue, setDepositValue] = useState('');
  const [withdrawValue, setWithdrawValue] = useState('');
  const [stakeValue, setStakeValue] = useState('');
  const [unstakeValue, setUnstakeValue] = useState('');

  const userPosition = useUserVaultPosition();
  const deposit = useDeposit(CONTRACTS.helixVault, userPosition.usdceAllowance);
  const withdraw = useWithdraw();
  const stake = useStake(CONTRACTS.helixVault, CONTRACTS.rewardDistributor, userRewards.stakeAllowance);
  const unstake = useUnstake();
  const claimRewards = useClaimRewards();

  const depositAmount = parseAmount(depositValue, 6);
  const withdrawAmount = parseAmount(withdrawValue, 6);
  const stakeAmount = parseAmount(stakeValue, 6);
  const unstakeAmount = parseAmount(unstakeValue, 6);

  const latestTxHash =
    deposit.txHash ?? withdraw.txHash ?? stake.txHash ?? unstake.txHash ?? claimRewards.txHash;
  const latestError =
    deposit.error ?? withdraw.error ?? stake.error ?? unstake.error ?? claimRewards.error;

  return (
    <div className="grid gap-4 lg:grid-cols-2">
      <ActionCard title="Deposit & Withdraw" description="Approval happens automatically when needed.">
        <div className="space-y-4">
          <div className="space-y-2">
            <div className="flex items-center justify-between gap-3">
              <label className="text-xs uppercase tracking-[0.2em] text-[var(--text-muted)]">Deposit USDC.e</label>
              <Button
                type="button"
                variant="ghost"
                className="h-auto px-0 py-0 text-xs text-[#ff8ab9]"
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
              {deposit.isApproving ? 'Approving...' : deposit.isDepositing ? 'Depositing...' : 'Deposit'}
            </GradientButton>
          </div>

          <div className="space-y-2">
            <div className="flex items-center justify-between gap-3">
              <label className="text-xs uppercase tracking-[0.2em] text-[var(--text-muted)]">Withdraw USDC.e</label>
              <Button
                type="button"
                variant="ghost"
                className="h-auto px-0 py-0 text-xs text-[#ff8ab9]"
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
              <label className="text-xs uppercase tracking-[0.2em] text-[var(--text-muted)]">Stake vault shares</label>
              <Button
                type="button"
                variant="ghost"
                className="h-auto px-0 py-0 text-xs text-[#ff8ab9]"
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
              {stake.isApproving ? 'Approving...' : stake.isStaking ? 'Staking...' : 'Stake'}
            </GradientButton>
          </div>

          <div className="space-y-2">
            <div className="flex items-center justify-between gap-3">
              <label className="text-xs uppercase tracking-[0.2em] text-[var(--text-muted)]">Unstake shares</label>
              <Button
                type="button"
                variant="ghost"
                className="h-auto px-0 py-0 text-xs text-[#ff8ab9]"
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

          <div className="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-surface-2)] p-5">
            <div className="text-xs uppercase tracking-[0.2em] text-[var(--text-muted)]">Claim HLX</div>
            <div className="mt-2 text-sm text-[var(--text-secondary)]">Claim your accrued HLX rewards from compound fees.</div>
            <div className="mt-4 flex flex-wrap items-center gap-3">
              <GradientButton
                disabled={userRewards.earnedHlx <= 0n || claimRewards.isClaiming}
                onClick={() => void claimRewards.claimRewards()}
              >
                {claimRewards.isClaiming ? 'Claiming...' : 'Claim HLX'}
              </GradientButton>
              <div className="text-sm text-[var(--text-secondary)]">
                Earned: <span className="font-semibold text-[var(--text-primary)]">{formatHlx(userRewards.earnedHlx)} HLX</span>
              </div>
            </div>
          </div>
        </div>
      </ActionCard>

      <div className="lg:col-span-2">
        <div className="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-surface)] px-5 py-5 text-sm text-[var(--text-secondary)]">
          <span className="font-medium text-[var(--text-primary)]">Latest transaction:</span>{' '}
          {latestTxHash ? (
            <a
              href={`https://explorer.citrea.xyz/tx/${latestTxHash}`}
              target="_blank"
              rel="noreferrer"
              className="font-medium text-[#ff8ab9] underline-offset-4 hover:underline"
            >
              {latestTxHash}
            </a>
          ) : (
            'No recent transaction'
          )}
        </div>
        {latestError ? (
          <div className="mt-3 rounded-xl border border-[#ff4f96]/20 bg-[#2b1820] p-4 text-sm text-[#ff9abb]">
            {latestError.message}
          </div>
        ) : null}
      </div>
    </div>
  );
}

function ConnectPromptCard() {
  return (
    <div className="rounded-xl border border-dashed border-[var(--border-subtle)] bg-[var(--bg-surface-2)] p-6 lg:col-span-2">
      <div className="text-lg font-semibold text-[var(--text-primary)]">Connect to Deposit</div>
      <p className="mt-2 max-w-2xl text-sm leading-6 text-[var(--text-secondary)]">
        Connect your wallet to deposit, withdraw, stake, unstake, and claim HLX rewards.
      </p>
      <div className="mt-4 max-w-[220px]">
        <ConnectWalletButton className="w-full" />
      </div>
    </div>
  );
}

export function VaultRow() {
  const { address } = useAccount();
  const [mounted, setMounted] = useState(false);
  const [expanded, setExpanded] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  const connected = mounted && Boolean(address);

  const vaultState = useVaultState();
  const strategyState = useStrategyState();
  const userRewards = useUserRewards();
  const compound = useCompound();

  const isHarvesting = compound.isCompounding;
  const harvestDisabled =
    strategyState.cooldownRemaining > 0n || isHarvesting || strategyState.rebalancePaused;

  const statusLabel = vaultState.paused
    ? 'Paused'
    : vaultState.withdrawOnly
      ? 'Withdraw Only'
      : 'Active';

  return (
    <>
      <tr
        role="button"
        tabIndex={0}
        onClick={() => setExpanded((current) => !current)}
        onKeyDown={(event) => {
          if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            setExpanded((current) => !current);
          }
        }}
        className="cursor-pointer border-t border-[var(--divider)] transition-colors hover:bg-[var(--bg-surface-2)]"
      >
        <td className="px-6 py-5 align-top">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-[#ff4f96]/15 text-[#ff8ab9]">
              <span className={[
                'text-lg transition-transform duration-200',
                expanded ? 'rotate-180' : 'rotate-0',
              ].join(' ')}>
                ▾
              </span>
            </div>
            <div className="min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <span className="rounded-full bg-[#ff4f96]/15 px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.22em] text-[#ff8ab9]">
                  Auto
                </span>
                <span className="text-xs text-[var(--text-muted)]">Single Asset</span>
                <Badge variant={vaultState.paused || vaultState.withdrawOnly ? 'secondary' : 'default'}>{statusLabel}</Badge>
              </div>
              <div className="mt-1 truncate text-base font-semibold text-[var(--text-primary)]">Helix USDC.e Vault</div>
              <p className="mt-0.5 text-sm text-[var(--text-secondary)]">Single-asset smart vault on Citrea</p>
            </div>
          </div>
        </td>

        <td className="px-4 py-5 align-top">
          <MetricCell label="APY" value="—" helper="Pending live strategy performance" />
        </td>

        <td className="px-4 py-5 align-top">
          <MetricCell
            label="Earn"
            value={`${formatHlx(userRewards.earnedHlx)} HLX`}
            helper="Claimable rewards"
            isLoading={!mounted || userRewards.isLoading}
          />
        </td>

        <td className="px-4 py-5 align-top">
          <MetricCell
            label="TVL"
            value={`${formatUsdce(vaultState.totalAssets)} USDC.e`}
            helper="Vault assets"
            isLoading={vaultState.isLoading}
          />
        </td>

        <td className="px-6 py-5 align-top text-right">
          <div className="flex items-center justify-end gap-2">
            {connected ? (
              <GradientButton
                className="h-10 px-4"
                disabled={harvestDisabled}
                onClick={(event) => {
                  event.stopPropagation();
                  void compound.compound();
                }}
              >
                {isHarvesting ? 'Harvesting...' : strategyState.cooldownRemaining > 0n ? 'Cooldown' : 'Harvest'}
              </GradientButton>
            ) : (
              <div onClick={(event) => event.stopPropagation()}>
                <ConnectWalletButton className="w-full sm:w-auto sm:min-w-[170px]" />
              </div>
            )}
          </div>
        </td>
      </tr>

      {expanded ? (
        <tr>
          <td colSpan={5} className="border-t border-[var(--divider)] bg-[var(--bg-surface-2)] px-5 py-5 sm:px-6">
            <div onClick={(event) => event.stopPropagation()}>
              {connected ? <VaultExpandedSection userRewards={userRewards} /> : <ConnectPromptCard />}
            </div>
          </td>
        </tr>
      ) : null}
    </>
  );
}
