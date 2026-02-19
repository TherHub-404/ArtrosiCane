import React from 'react';
import {AbsoluteFill, interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {brand, layout} from '../Brand';
import {Background} from './Background';

const cards = [
  {title: 'Profilo cane', detail: 'Eta, peso, mobilita e storia clinica'},
  {title: 'Quiz guidato', detail: 'Valutazione strutturata dei sintomi'},
  {title: 'Routine quotidiana', detail: 'Camminate, esercizi e monitoraggio'},
];

export const FeatureStrip: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  return (
    <AbsoluteFill>
      <Background />
      <AbsoluteFill style={{padding: `${layout.safeY}px ${layout.safeX}px`, fontFamily: 'Montserrat, Avenir, Helvetica, Arial, sans-serif'}}>
        <div style={{fontSize: 68, fontWeight: 800, color: brand.primaryBlue}}>Dal sintomo alla routine</div>
        <div style={{fontSize: 30, fontWeight: 500, marginTop: 14, color: '#2B5E97'}}>Visual pensate per spiegare il flusso in 1 slide</div>

        <div style={{display: 'flex', gap: 26, marginTop: 56}}>
          {cards.map((card, i) => {
            const progress = spring({
              fps,
              frame: frame - i * 8,
              config: {damping: 200},
              durationInFrames: 32,
            });

            const y = interpolate(progress, [0, 1], [36, 0]);
            const opacity = interpolate(progress, [0, 1], [0, 1]);

            return (
              <div
                key={card.title}
                style={{
                  flex: 1,
                  minHeight: 380,
                  borderRadius: 34,
                  border: `2px solid ${brand.borderSoft ?? '#E9ECF3'}`,
                  padding: '34px 30px',
                  backgroundColor: 'rgba(255,255,255,0.8)',
                  boxShadow: '0 16px 42px rgba(54, 66, 114, 0.16)',
                  transform: `translateY(${y}px)`,
                  opacity,
                }}
              >
                <div
                  style={{
                    width: 54,
                    height: 54,
                    borderRadius: '50%',
                    backgroundColor: i % 2 === 0 ? brand.warmOrange : brand.accentBlue,
                    opacity: 0.9,
                  }}
                />
                <div style={{fontSize: 42, fontWeight: 800, marginTop: 24, color: '#1E2D62'}}>{card.title}</div>
                <div style={{fontSize: 28, lineHeight: 1.28, marginTop: 16, color: '#0E2044'}}>{card.detail}</div>
              </div>
            );
          })}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
