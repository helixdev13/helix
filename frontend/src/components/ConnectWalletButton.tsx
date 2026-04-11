'use client';

import { useEffect, useRef, useState } from 'react';

import { useAccount, useBalance, useConnect, useDisconnect, useSwitchChain } from 'wagmi';

import { GradientButton } from '@/components/GradientButton';
import { citrea } from '@/config/chains';
import { truncateAddress } from '@/lib/format';

type ConnectWalletButtonProps = {
  className?: string;
};

export function ConnectWalletButton({ className = '' }: ConnectWalletButtonProps) {
  const wrapperRef = useRef<HTMLDivElement>(null);
  const [mounted, setMounted] = useState(false);
  const [isConnectorModalOpen, setIsConnectorModalOpen] = useState(false);
  const [isAccountMenuOpen, setIsAccountMenuOpen] = useState(false);
  const [connectingConnectorId, setConnectingConnectorId] = useState<string | null>(null);

  const { address, chain, isConnected } = useAccount();
  const { connectors, connect, isPending } = useConnect();
  const { disconnect } = useDisconnect();
  const { switchChain, isPending: isSwitchingChain } = useSwitchChain();
  const balance = useBalance({
    address,
    chainId: citrea.id,
    query: { enabled: Boolean(address) },
  });

  const isWrongChain = Boolean(isConnected && chain && chain.id !== citrea.id);
  const balanceLabel = balance.data ? `${balance.data.formatted} ${balance.data.symbol ?? 'cBTC'}` : '—';

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (isConnected) {
      setIsConnectorModalOpen(false);
      return;
    }
    setIsAccountMenuOpen(false);
  }, [isConnected]);

  useEffect(() => {
    if (!isPending) {
      setConnectingConnectorId(null);
    }
  }, [isPending]);

  useEffect(() => {
    function handlePointerDown(event: PointerEvent) {
      if (!wrapperRef.current?.contains(event.target as Node)) {
        setIsAccountMenuOpen(false);
      }
    }

    if (isAccountMenuOpen) {
      document.addEventListener('pointerdown', handlePointerDown);
    }

    return () => document.removeEventListener('pointerdown', handlePointerDown);
  }, [isAccountMenuOpen]);

  useEffect(() => {
    function handleEscape(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        setIsConnectorModalOpen(false);
        setIsAccountMenuOpen(false);
      }
    }

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, []);

  if (!mounted) {
    return (
      <div ref={wrapperRef} className="relative w-full">
        <GradientButton className={className} disabled>
          Connect Wallet
        </GradientButton>
      </div>
    );
  }

  return (
    <div ref={wrapperRef} className="relative w-full">
      <GradientButton
        className={className}
        disabled={isSwitchingChain}
        onClick={() => {
          if (!isConnected) {
            setIsConnectorModalOpen((current) => !current);
            return;
          }

          if (isWrongChain) {
            switchChain?.({ chainId: citrea.id });
            return;
          }

          setIsAccountMenuOpen((current) => !current);
        }}
      >
        {!isConnected
          ? 'Connect Wallet'
          : isWrongChain
            ? isSwitchingChain
              ? 'Switching...'
              : 'Switch to Citrea'
            : `Connected · ${address ? truncateAddress(address) : '0x0000...0000'}`}
      </GradientButton>

      {!isConnected && isConnectorModalOpen ? (
        <div
          className="fixed inset-0 z-[70] flex items-center justify-center bg-black/15 px-4 backdrop-blur-sm"
          onClick={() => setIsConnectorModalOpen(false)}
        >
          <div
            className="w-full max-w-sm rounded-2xl border border-[#F0E8E8] bg-white p-4 shadow-[0_20px_60px_rgba(0,0,0,0.12)]"
            onClick={(event) => event.stopPropagation()}
          >
            <div className="space-y-1">
              <div className="text-lg font-semibold text-[#333333]">Connect wallet</div>
              <div className="text-sm text-[#666666]">Choose a wallet to connect to Citrea.</div>
            </div>
            <div className="mt-4 space-y-2">
              {connectors.map((connector) => (
                <button
                  key={connector.uid}
                  type="button"
                  className="flex w-full items-center justify-between rounded-xl border border-[#F0E8E8] bg-[#FFF8F6] px-4 py-3 text-left text-sm font-medium text-[#333333] transition hover:border-[#D4797F] hover:bg-white"
                  onClick={() => {
                    setConnectingConnectorId(connector.uid);
                    connect({ connector });
                    setIsConnectorModalOpen(false);
                  }}
                >
                  <span>{connector.name}</span>
                  <span className="text-xs uppercase tracking-[0.22em] text-[#D4797F]">
                    {isPending && connectingConnectorId === connector.uid ? 'Connecting' : 'Select'}
                  </span>
                </button>
              ))}
            </div>
          </div>
        </div>
      ) : null}

      {isConnected && !isWrongChain && isAccountMenuOpen ? (
        <div className="absolute right-0 top-full z-[70] mt-3 w-full min-w-[260px] sm:w-[320px]">
          <div className="rounded-2xl border border-[#F0E8E8] bg-white p-4 shadow-[0_20px_60px_rgba(0,0,0,0.12)]">
            <div className="space-y-3">
              <div>
                <div className="text-xs uppercase tracking-[0.22em] text-[#999999]">Wallet</div>
                <div className="mt-1 text-sm font-semibold text-[#333333]">
                  {address ? truncateAddress(address) : '—'}
                </div>
              </div>
              <div>
                <div className="text-xs uppercase tracking-[0.22em] text-[#999999]">Balance</div>
                <div className="mt-1 text-sm font-semibold text-[#333333]">{balanceLabel}</div>
              </div>
              <button
                type="button"
                className="w-full rounded-xl border border-[#F0E8E8] bg-[#FFF8F6] px-4 py-3 text-sm font-medium text-[#333333] transition hover:border-[#D4797F] hover:bg-white"
                onClick={() => {
                  disconnect();
                  setIsAccountMenuOpen(false);
                }}
              >
                Disconnect
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
