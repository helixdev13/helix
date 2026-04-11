'use client';

import { useEffect, useState } from 'react';

import { ConnectWalletButton } from '@/components/ConnectWalletButton';

type DashboardTab = 'vaults' | 'compound';

function tabFromHash(hash: string): DashboardTab {
  return hash.replace('#', '') === 'compound' ? 'compound' : 'vaults';
}

function HelixMark() {
  return (
    <svg aria-hidden="true" viewBox="0 0 24 24" className="h-6 w-6 text-[#ff4f96]">
      <path
        d="M7 6.5c2.3-2.3 7.7-2.3 10 0M7 17.5c2.3 2.3 7.7 2.3 10 0"
        fill="none"
        stroke="currentColor"
        strokeLinecap="round"
        strokeWidth="1.6"
      />
      <path d="M9 4.5 15 19.5" fill="none" stroke="currentColor" strokeLinecap="round" strokeWidth="1.6" />
      <circle cx="6.5" cy="6.5" r="1.3" fill="currentColor" />
      <circle cx="17.5" cy="6.5" r="1.3" fill="currentColor" />
      <circle cx="6.5" cy="17.5" r="1.3" fill="currentColor" />
      <circle cx="17.5" cy="17.5" r="1.3" fill="currentColor" />
    </svg>
  );
}

export function Navbar() {
  const [activeTab, setActiveTab] = useState<DashboardTab>('vaults');

  useEffect(() => {
    const syncFromHash = () => setActiveTab(tabFromHash(window.location.hash));
    syncFromHash();
    window.addEventListener('hashchange', syncFromHash);
    return () => window.removeEventListener('hashchange', syncFromHash);
  }, []);

  const changeTab = (tab: DashboardTab) => {
    if (typeof window !== 'undefined') {
      window.location.hash = tab;
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
    setActiveTab(tab);
  };

  const tabClassName = (tab: DashboardTab) =>
    [
      'relative rounded-full px-3 py-1.5 text-[15px] font-medium transition-[background-color,color] duration-150',
      activeTab === tab
        ? 'bg-[rgba(255,79,150,0.08)] text-[#ff4f96] after:absolute after:inset-x-3 after:-bottom-0.5 after:h-px after:bg-[#ff4f96]'
        : 'text-[var(--text-muted)] hover:bg-[rgba(255,255,255,0.03)] hover:text-[var(--text-secondary)]',
    ].join(' ');

  return (
    <header className="sticky top-0 z-50 border-b border-[var(--divider)] bg-[var(--bg-header)]">
      <div className="mx-auto flex max-w-[1240px] flex-col gap-3 px-6 py-3 lg:flex-row lg:items-center lg:justify-between">
        <button type="button" onClick={() => changeTab('vaults')} className="flex items-center gap-2 self-start">
          <HelixMark />
          <span className="bg-gradient-to-r from-[#ff4f96] to-[#ff4f96] bg-clip-text text-[17px] font-bold tracking-[0.14em] text-transparent">
            HELIX
          </span>
        </button>

        <nav className="flex items-center gap-7 self-start lg:self-center">
          <button type="button" onClick={() => changeTab('vaults')} className={tabClassName('vaults')}>
            Vaults
          </button>
          <button type="button" onClick={() => changeTab('compound')} className={tabClassName('compound')}>
            Compound
          </button>
        </nav>

        <div className="flex flex-col gap-2.5 sm:flex-row sm:items-center lg:justify-end">
          <div className="inline-flex h-8 items-center gap-2 rounded-lg border border-[var(--border-subtle)] bg-[var(--bg-surface-2)] px-3 text-sm text-[var(--text-secondary)]">
            <span className="h-2.5 w-2.5 rounded-full bg-[#42c3ff]" />
            Citrea
          </div>
          <ConnectWalletButton className="w-full min-w-0 sm:w-auto sm:min-w-[164px]" />
        </div>
      </div>
    </header>
  );
}
