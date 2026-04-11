'use client';

import dynamic from 'next/dynamic';
import { useEffect, useRef, useState } from 'react';

import { Input } from '@/components/ui/input';
import { CONTRACTS, TOKENS } from '@/config/contracts';
import { VaultRow } from '@/components/VaultRow';
import { formatUsdce, truncateAddress } from '@/lib/format';
import { useVaultState } from '@/hooks';

const CompoundPanel = dynamic(
  () => import('@/components/CompoundPanel').then((mod) => mod.CompoundPanel),
  { ssr: false },
);

type DashboardTab = 'vaults' | 'compound';
type VaultFilter = 'all' | 'single';

function tabFromHash(hash: string): DashboardTab {
  return hash.replace('#', '') === 'compound' ? 'compound' : 'vaults';
}

function SearchIcon() {
  return (
    <svg aria-hidden="true" viewBox="0 0 20 20" className="h-4 w-4 text-[var(--text-muted)]">
      <path
        d="M8.5 3.5a5 5 0 1 0 0 10 5 5 0 0 0 0-10Zm0-1.5a6.5 6.5 0 1 1 0 13 6.5 6.5 0 0 1 0-13Zm4.75 10.44 3.1 3.1-1.06 1.06-3.1-3.1 1.06-1.06Z"
        fill="currentColor"
      />
    </svg>
  );
}

function ChevronDownIcon() {
  return (
    <svg aria-hidden="true" viewBox="0 0 20 20" className="h-4 w-4 text-[var(--text-muted)]">
      <path d="M5 7.5 10 12.5 15 7.5" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.6" />
    </svg>
  );
}

export default function Home() {
  const [activeTab, setActiveTab] = useState<DashboardTab>('vaults');
  const [vaultFilter, setVaultFilter] = useState<VaultFilter>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [sortLabel, setSortLabel] = useState('Default');
  const [sortOpen, setSortOpen] = useState(false);
  const sortRef = useRef<HTMLDivElement>(null);
  const vaultState = useVaultState();

  useEffect(() => {
    const syncFromHash = () => setActiveTab(tabFromHash(window.location.hash));
    syncFromHash();
    window.addEventListener('hashchange', syncFromHash);
    return () => window.removeEventListener('hashchange', syncFromHash);
  }, []);

  useEffect(() => {
    function handlePointerDown(event: PointerEvent) {
      if (!sortRef.current?.contains(event.target as Node)) {
        setSortOpen(false);
      }
    }

    if (sortOpen) {
      document.addEventListener('pointerdown', handlePointerDown);
    }

    return () => document.removeEventListener('pointerdown', handlePointerDown);
  }, [sortOpen]);

  const statusLabel = vaultState.paused
    ? 'Paused'
    : vaultState.withdrawOnly
      ? 'Withdraw Only'
      : 'Active';
  const searchNormalized = searchQuery.trim().toLowerCase();
  const vaultMatchesSearch =
    searchNormalized.length === 0 ||
    ['helix', 'usdc.e', 'usdc', 'vault', 'single', 'citrea'].some((term) =>
      term.includes(searchNormalized),
    );

  return (
    <main className="min-h-full bg-[var(--bg-page)]">
      <div className="mx-auto w-full max-w-[1200px] px-6 py-8">
        {activeTab === 'vaults' ? (
          <div className="space-y-6">
            <div className="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-surface)] px-6 py-3.5">
              <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
                <div className="text-sm text-[var(--text-secondary)]">
                  Vault Status:{' '}
                  <span className="font-semibold text-[var(--text-primary)]">{statusLabel}</span>
                </div>
                <div className="flex flex-wrap items-center gap-6">
                  <div className="text-sm text-[var(--text-secondary)]">
                    TVL{' '}
                    <span className="font-semibold text-[var(--text-primary)]">
                      {formatUsdce(vaultState.totalAssets)} USDC.e
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="h-5 w-5 rounded-full bg-[#ff4f96]" />
                    <span className="text-sm font-semibold text-[var(--text-primary)]">—</span>
                    <span className="text-xs text-[var(--text-muted)]">HLX</span>
                  </div>
                </div>
              </div>
            </div>

            <section className="space-y-4">
              <div>
                <h2 className="text-[23px] font-semibold tracking-tight text-[#43c5ff]">Vaults</h2>
              </div>

              <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
                <div className="flex flex-wrap items-center gap-2">
                  <button
                    type="button"
                    onClick={() => setVaultFilter('all')}
                    className={[
                      'rounded-lg px-3.5 py-1.5 text-[13px] font-semibold transition-colors',
                      vaultFilter === 'all'
                        ? 'bg-[#ff4f96] text-white'
                        : 'bg-transparent text-[var(--text-muted)] hover:text-[var(--text-secondary)]',
                    ].join(' ')}
                  >
                    All
                  </button>
                  <button
                    type="button"
                    onClick={() => setVaultFilter('single')}
                    className={[
                      'rounded-lg px-3.5 py-1.5 text-[13px] font-semibold transition-colors',
                      vaultFilter === 'single'
                        ? 'bg-[#ff4f96] text-white'
                        : 'bg-transparent text-[var(--text-muted)] hover:text-[var(--text-secondary)]',
                    ].join(' ')}
                  >
                    Single
                  </button>
                </div>

                <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
                  <div className="relative w-full sm:w-auto">
                    <div className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2">
                      <SearchIcon />
                    </div>
                    <Input
                      value={searchQuery}
                      onChange={(event) => setSearchQuery(event.target.value)}
                      placeholder="Search Vault"
                      className="w-full min-w-[200px] pl-10 sm:w-[220px]"
                    />
                  </div>
                  <div ref={sortRef} className="relative">
                    <button
                      type="button"
                      className="flex h-10 items-center gap-2 rounded-lg border border-[var(--border-subtle)] bg-[var(--bg-surface-2)] px-4 text-sm text-[var(--text-secondary)] transition-colors hover:bg-[#2a3040] hover:text-[var(--text-primary)]"
                      onClick={() => setSortOpen((current) => !current)}
                    >
                      {sortLabel}
                      <ChevronDownIcon />
                    </button>
                    {sortOpen ? (
                      <div className="absolute right-0 top-full z-20 mt-2 w-48 rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-surface)] p-2 shadow-[0_12px_32px_rgba(0,0,0,0.35)]">
                        {['Default', 'APY', 'TVL'].map((option) => (
                          <button
                            key={option}
                            type="button"
                            className={[
                              'w-full rounded-lg px-3 py-2 text-left text-sm transition-colors',
                              sortLabel === option
                                ? 'bg-[#ff4f96]/15 text-[#ff8ab9]'
                                : 'text-[var(--text-secondary)] hover:bg-[var(--bg-surface-2)] hover:text-[var(--text-primary)]',
                            ].join(' ')}
                            onClick={() => {
                              setSortLabel(option);
                              setSortOpen(false);
                            }}
                          >
                            {option}
                          </button>
                        ))}
                      </div>
                    ) : null}
                  </div>
                </div>
              </div>

              <div className="overflow-hidden rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-surface)]">
                <div className="overflow-x-auto">
                  <table className="min-w-[960px] w-full">
                    <thead>
                      <tr className="bg-[#353b46] text-[12px] uppercase tracking-[0.18em] text-[#aeb7c6]">
                        <th className="px-6 py-3 text-left font-semibold">Vault Name</th>
                        <th className="px-4 py-3 text-left font-semibold">APY</th>
                        <th className="px-4 py-3 text-left font-semibold">Earn</th>
                        <th className="px-4 py-3 text-left font-semibold">Platform</th>
                        <th className="px-4 py-3 text-left font-semibold">TVL</th>
                        <th className="px-6 py-3 text-right font-semibold" />
                      </tr>
                    </thead>
                    <tbody>
                      {vaultMatchesSearch ? (
                        <VaultRow />
                      ) : (
                        <tr>
                          <td colSpan={6} className="px-6 py-12 text-center text-sm text-[var(--text-secondary)]">
                            No vaults match your search.
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            </section>
          </div>
        ) : (
          <CompoundPanel />
        )}

        <footer className="mt-8 border-t border-[var(--divider)] pt-5 text-xs text-[var(--text-muted)]">
          <div className="text-sm text-[var(--text-secondary)]">Built on Citrea</div>
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
