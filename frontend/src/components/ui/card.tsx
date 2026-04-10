import type { HTMLAttributes } from 'react';

type DivProps = HTMLAttributes<HTMLDivElement>;

export function Card({ className = '', ...props }: DivProps) {
  return (
    <div
      className={[
        'rounded-3xl border border-white/10 bg-white/5 shadow-2xl backdrop-blur-xl',
        className,
      ].join(' ')}
      {...props}
    />
  );
}

export function CardHeader({ className = '', ...props }: DivProps) {
  return <div className={['flex flex-col space-y-1.5 p-6', className].join(' ')} {...props} />;
}

export function CardTitle({ className = '', ...props }: DivProps) {
  return <h3 className={['text-lg font-semibold tracking-tight text-white', className].join(' ')} {...props} />;
}

export function CardDescription({ className = '', ...props }: DivProps) {
  return <p className={['text-sm text-slate-400', className].join(' ')} {...props} />;
}

export function CardContent({ className = '', ...props }: DivProps) {
  return <div className={['p-6 pt-0', className].join(' ')} {...props} />;
}
