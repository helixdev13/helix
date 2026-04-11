'use client';

import type { ReactNode } from 'react';
import { useEffect, useState } from 'react';

import { parseUnits } from 'viem';
import { useAccount } from 'wagmi';

import { CONTRACTS } from '@/config/contracts';
import { ConnectWalletButton } from '@/components/ConnectWalletButton';
import { GradientButton } from '@/components/GradientButton';
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
  tone = 'default',
  isLoading = false,
}: {
  label: string;
  value: string;
  helper?: string;
  tone?: 'default' | 'accent';
  isLoading?: boolean;
}) {
  return (
    <div>
      <div className="text-[11px] uppercase tracking-[0.22em] text-[var(--text-muted)]">{label}</div>
      {isLoading ? (
        <Skeleton className="mt-2 h-5 w-24 rounded-lg" />
      ) : (
        <div className={['mt-2 text-sm font-semibold leading-tight tabular-nums', tone === 'accent' ? 'text-[#42c3ff]' : 'text-[var(--text-primary)]'].join(' ')}>
          {value}
        </div>
      )}
      {helper ? <div className="mt-1 text-xs text-[var(--text-secondary)]">{helper}</div> : null}
    </div>
  );
}

function ActionCard({ title, description, children }: { title: string; description: string; children: ReactNode }) {
  return (
    <div className="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-surface)] p-4 transition-[border-color,background-color] duration-200 hover:border-[rgba(255,255,255,0.08)] sm:p-5">
      <div className="mb-3 space-y-1">
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
    <div className="grid gap-3 lg:grid-cols-2">
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
              className="h-10 w-full"
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
              className="h-10 w-full"
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
              className="h-10 w-full"
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
              className="h-10 w-full"
              variant="outline"
              disabled={unstakeAmount <= 0n || unstake.isUnstaking}
              onClick={() => void unstake.unstake(unstakeAmount)}
            >
              {unstake.isUnstaking ? 'Unstaking...' : 'Unstake'}
            </Button>
          </div>

          <div className="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-surface-2)] p-4">
            <div className="text-xs uppercase tracking-[0.2em] text-[var(--text-muted)]">Claim HLX</div>
            <div className="mt-2 text-sm text-[var(--text-secondary)]">Claim your accrued HLX rewards from compound fees.</div>
            <div className="mt-4 flex flex-wrap items-center gap-3">
              <GradientButton
                className="h-10"
                disabled={userRewards.earnedHlx <= 0n || claimRewards.isClaiming}
                onClick={() => void claimRewards.claimRewards()}
              >
                {claimRewards.isClaiming ? 'Claiming...' : 'Claim HLX'}
              </GradientButton>
              <div className="text-sm text-[var(--text-secondary)]">
                Earned: <span className="font-semibold tabular-nums text-[var(--text-primary)]">{formatHlx(userRewards.earnedHlx)} HLX</span>
              </div>
            </div>
          </div>
        </div>
      </ActionCard>

      <div className="lg:col-span-2">
        <div className="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-surface)] px-5 py-4 text-sm text-[var(--text-secondary)]">
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
    <div className="rounded-xl border border-dashed border-[var(--border-subtle)] bg-[var(--bg-surface-2)] p-5 lg:col-span-2">
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
  const [expandedContentMounted, setExpandedContentMounted] = useState(false);
  const [expandedContentOpen, setExpandedContentOpen] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (expanded) {
      setExpandedContentMounted(true);
      const frame = window.requestAnimationFrame(() => {
        setExpandedContentOpen(true);
      });
      return () => window.cancelAnimationFrame(frame);
    } else {
      setExpandedContentOpen(false);
      const timeout = window.setTimeout(() => setExpandedContentMounted(false), 260);
      return () => window.clearTimeout(timeout);
    }
  }, [expanded]);

  const connected = mounted && Boolean(address);

  const vaultState = useVaultState();
  const strategyState = useStrategyState();
  const userRewards = useUserRewards();
  const compound = useCompound();

  const isHarvesting = compound.isCompounding;
  const harvestDisabled =
    strategyState.cooldownRemaining > 0n || isHarvesting || strategyState.rebalancePaused;

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
        className="group cursor-pointer border-t border-[var(--divider)] outline-none transition-[background-color,border-color] duration-200 ease-out hover:bg-[rgba(255,255,255,0.02)] focus:outline-none focus-visible:outline-none"
      >
        <td className="px-6 py-5 align-top">
          <div className="flex items-center gap-3">
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-[#ff4f96]/15 text-[#ff8ab9] transition-[background-color,color,transform] duration-200 group-hover:scale-105 group-hover:bg-[#ff4f96]/20 group-hover:text-[#ffd1e1]">
              <span
                className={[
                  'text-lg transition-transform duration-300 ease-[cubic-bezier(0.22,1,0.36,1)]',
                  expanded ? 'rotate-180' : 'rotate-0',
                ].join(' ')}
              >
                ▾
              </span>
            </div>
            <div className="min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <span className="rounded-full bg-[#ff4f96]/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-[0.22em] text-[#ff8ab9]">
                  Auto
                </span>
                <span className="text-[11px] text-[var(--text-muted)]">JuiceSwap on Citrea</span>
              </div>
              <div className="mt-1 text-[17px] font-semibold leading-tight tracking-[-0.01em] text-[var(--text-primary)]">
                Helix USDC.e Vault
              </div>
            </div>
          </div>
        </td>

        <td className="px-4 py-5 align-top">
          <MetricCell label="APY" value="—" tone="accent" />
        </td>

        <td className="px-4 py-5 align-top">
          <MetricCell
            label="Earn"
            value={`${formatHlx(userRewards.earnedHlx)} HLX`}
            isLoading={!mounted || userRewards.isLoading}
          />
        </td>

        <td className="px-4 py-5 align-top">
          <div>
            <div className="text-[11px] uppercase tracking-[0.22em] text-[var(--text-muted)]">Platform</div>
            <div className="mt-2 text-sm font-semibold text-[var(--text-primary)]">JuiceSwap</div>
            <div className="mt-1 text-xs text-[var(--text-secondary)]">Citrea</div>
          </div>
        </td>

        <td className="px-4 py-5 align-top">
          <MetricCell
            label="TVL"
            value={`${formatUsdce(vaultState.totalAssets)} USDC.e`}
            isLoading={vaultState.isLoading}
          />
        </td>

        <td className="px-6 py-5 align-top text-right">
          <div className="flex items-center justify-end gap-2 opacity-90 transition-opacity group-hover:opacity-100">
            {connected ? (
              <GradientButton
                className="h-8 px-3 text-[12px] opacity-80 transition-opacity group-hover:opacity-100"
                disabled={harvestDisabled}
                onClick={(event) => {
                  event.stopPropagation();
                  void compound.compound();
                }}
              >
                {isHarvesting ? 'Harvesting...' : 'Harvest'}
              </GradientButton>
            ) : (
              <div onClick={(event) => event.stopPropagation()}>
                <ConnectWalletButton className="w-full sm:w-auto sm:min-w-[132px]" />
              </div>
            )}
          </div>
        </td>
      </tr>

      {expanded || expandedContentMounted ? (
        <tr>
          <td colSpan={6} className="border-t border-[var(--divider)] bg-[var(--bg-surface-2)] p-0">
            <div
              className={[
                'overflow-hidden transition-[max-height,opacity,transform] duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] will-change-[max-height,opacity,transform]',
                expandedContentOpen ? 'max-h-[900px] opacity-100 translate-y-0' : 'max-h-0 opacity-0 -translate-y-1',
              ].join(' ')}
              aria-hidden={!expanded}
            >
              <div className="px-5 py-5 sm:px-6">
                <div onClick={(event) => event.stopPropagation()}>
                  {connected ? <VaultExpandedSection userRewards={userRewards} /> : <ConnectPromptCard />}
                </div>
              </div>
            </div>
          </td>
        </tr>
      ) : null}
    </>
  );
}
