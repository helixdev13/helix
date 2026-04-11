import type { HTMLAttributes } from 'react';

type DivProps = HTMLAttributes<HTMLDivElement>;

export function Card({ className = '', ...props }: DivProps) {
  return (
    <div
      className={[
        'rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-surface)] shadow-none',
        className,
      ].join(' ')}
      {...props}
    />
  );
}

export function CardHeader({ className = '', ...props }: DivProps) {
  return <div className={['flex flex-col space-y-1.5 p-5 sm:p-6', className].join(' ')} {...props} />;
}

export function CardTitle({ className = '', ...props }: DivProps) {
  return <h3 className={['text-lg font-semibold tracking-tight text-[var(--text-primary)]', className].join(' ')} {...props} />;
}

export function CardDescription({ className = '', ...props }: DivProps) {
  return <p className={['text-sm text-[var(--text-secondary)]', className].join(' ')} {...props} />;
}

export function CardContent({ className = '', ...props }: DivProps) {
  return <div className={['p-5 pt-0 sm:p-6 sm:pt-0', className].join(' ')} {...props} />;
}
