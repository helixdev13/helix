import { formatUnits } from 'viem';

function addThousandsSeparator(value: string) {
  return value.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function formatTokenAmount(amount: bigint, decimals: number, maxFractionDigits: number) {
  const raw = formatUnits(amount, decimals);
  const [whole, fraction = ''] = raw.split('.');
  const trimmedFraction = fraction.slice(0, maxFractionDigits).replace(/0+$/, '');
  return trimmedFraction.length > 0
    ? `${addThousandsSeparator(whole)}.${trimmedFraction}`
    : addThousandsSeparator(whole);
}

export function formatUsdce(amount: bigint) {
  return formatTokenAmount(amount, 6, 2);
}

export function formatHlx(amount: bigint) {
  return formatTokenAmount(amount, 18, 4);
}

export function formatBps(bps: number) {
  const percent = bps / 100;
  const rounded = Number.isInteger(percent)
    ? percent.toFixed(0)
    : percent.toFixed(2).replace(/\.?0+$/, '');
  return `${rounded}%`;
}

export function formatTimestamp(ts: bigint) {
  if (ts <= 0n) {
    return 'Never';
  }

  const now = BigInt(Math.floor(Date.now() / 1000));
  const delta = now > ts ? now - ts : 0n;

  if (delta < 60n) {
    return delta === 0n ? 'just now' : `${delta}s ago`;
  }

  if (delta < 3_600n) {
    return `${delta / 60n}m ago`;
  }

  if (delta < 86_400n) {
    return `${delta / 3_600n}h ago`;
  }

  return `${delta / 86_400n}d ago`;
}

export function formatCountdown(seconds: bigint) {
  if (seconds <= 0n) {
    return '0s';
  }

  const hours = seconds / 3_600n;
  const minutes = (seconds % 3_600n) / 60n;
  const remainingSeconds = seconds % 60n;

  if (hours > 0n) {
    return `${hours}h ${minutes}m ${remainingSeconds}s`;
  }

  if (minutes > 0n) {
    return `${minutes}m ${remainingSeconds}s`;
  }

  return `${remainingSeconds}s`;
}

export function truncateAddress(address: string, chars = 4) {
  if (address.length <= chars * 2 + 2) {
    return address;
  }

  return `${address.slice(0, chars + 2)}...${address.slice(-chars)}`;
}
