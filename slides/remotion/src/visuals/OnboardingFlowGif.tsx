import React from 'react';
import {
  AbsoluteFill,
  Img,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import {brand} from '../Brand';

const Card: React.FC<{
  title: string;
  subtitle: string;
  x: number;
  y: number;
  width: number;
  height: number;
  dark?: boolean;
  children?: React.ReactNode;
}> = ({title, subtitle, x, y, width, height, dark = false, children}) => {
  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width,
        height,
        borderRadius: 36,
        background: dark ? '#0F1720' : 'rgba(255,255,255,0.92)',
        border: dark ? '1px solid #1F2A37' : `2px solid ${brand.borderSoft}`,
        boxShadow: dark ? '0 20px 60px rgba(2, 6, 23, 0.32)' : '0 20px 60px rgba(54, 66, 114, 0.14)',
        padding: 32,
      }}
    >
      <div style={{fontFamily: 'Montserrat, sans-serif', fontSize: 30, fontWeight: 800, color: dark ? '#FFFFFF' : brand.primaryBlue}}>{title}</div>
      <div style={{fontFamily: 'Montserrat, sans-serif', fontSize: 20, marginTop: 10, color: dark ? '#C9D4E3' : '#2A4F7C'}}>{subtitle}</div>
      {children}
    </div>
  );
};

export const OnboardingFlowGif: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  const reveal = spring({
    frame,
    fps,
    config: {damping: 200},
    durationInFrames: 38,
  });

  const flowX = interpolate(frame, [26, 140], [260, 1360], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const loopPulse = 0.45 + 0.55 * Math.sin((frame / fps) * Math.PI * 2.4);

  return (
    <AbsoluteFill
      style={{
        backgroundColor: 'transparent',
      }}
    >
      <Card title="Jotform" subtitle="Input esterno utente" x={86} y={84} width={540} height={912}>
        <div style={{marginTop: 30, borderRadius: 20, border: `2px solid ${brand.borderSoft}`, padding: 18, backgroundColor: '#fff'}}>
          <div style={{fontFamily: 'Montserrat, sans-serif', fontSize: 18, color: '#3C4D6F'}}>Email</div>
          <div style={{fontFamily: 'Montserrat, sans-serif', fontSize: 20, marginTop: 6, color: '#162847'}}>utente@email.com</div>
        </div>
        <div style={{marginTop: 20, borderRadius: 20, border: `2px solid ${brand.borderSoft}`, padding: 18, backgroundColor: '#fff'}}>
          <div style={{fontFamily: 'Montserrat, sans-serif', fontSize: 18, color: '#3C4D6F'}}>Flag</div>
          <div style={{fontFamily: 'Montserrat, sans-serif', fontSize: 20, marginTop: 6, color: '#162847'}}>bibione = true</div>
        </div>
      </Card>

      <Card title="Supabase" subtitle="Source of truth" x={690} y={84} width={540} height={912} dark>
        <Img
          src={staticFile('supabase-logo-wordmark--dark.svg')}
          style={{width: 280, marginTop: 24, opacity: 0.95}}
        />
        <div
          style={{
            marginTop: 28,
            borderRadius: 20,
            border: '1px solid #304155',
            backgroundColor: '#15202D',
            padding: 18,
            color: '#D5DFEA',
            fontFamily: 'ui-monospace, SFMono-Regular, Menlo, monospace',
            fontSize: 19,
            lineHeight: 1.35,
          }}
        >
          profile.onboarding_status = COMPLETE
          <br />
          profile.bibione = true
          <br />
          profile.pet_weight = 28kg
        </div>
      </Card>

      <Card title="App Artrosi Cane" subtitle="Prefill + skip" x={1294} y={84} width={540} height={912}>
        <Img src={staticFile('ArtrosiCane-Logo.png')} style={{width: 300, marginTop: 12}} />
        <div
          style={{
            marginTop: 28,
            borderRadius: 20,
            backgroundColor: '#FFFFFF',
            border: `2px solid ${brand.borderSoft}`,
            padding: 18,
            fontFamily: 'Montserrat, sans-serif',
            fontSize: 19,
            color: '#25466F',
            lineHeight: 1.35,
          }}
        >
          Campi gia compilati da Supabase.
          <br />
          Onboarding nascosto automaticamente.
        </div>
      </Card>

      <div
        style={{
          position: 'absolute',
          left: flowX,
          top: 598,
          width: 28,
          height: 28,
          borderRadius: '50%',
          backgroundColor: '#3ECF8E',
          boxShadow: `0 0 0 ${12 + loopPulse * 10}px rgba(62,207,142,0.22)`,
        }}
      />

      <div
        style={{
          position: 'absolute',
          left: 620,
          top: 608,
          width: 84,
          height: 8,
          borderRadius: 999,
          backgroundColor: '#3ECF8E',
          opacity: 0.8,
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: 1224,
          top: 608,
          width: 84,
          height: 8,
          borderRadius: 999,
          backgroundColor: '#3ECF8E',
          opacity: 0.8,
        }}
      />
    </AbsoluteFill>
  );
};
