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

const Row: React.FC<{label: string; value: string; delay: number}> = ({label, value, delay}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const progress = spring({fps, frame: frame - delay, config: {damping: 220}, durationInFrames: 26});

  return (
    <div
      style={{
        borderRadius: 18,
        backgroundColor: '#FFFFFF',
        border: `1.5px solid ${brand.borderSoft}`,
        padding: '14px 16px',
        marginBottom: 12,
        opacity: progress,
        transform: `translateY(${interpolate(progress, [0, 1], [18, 0])}px)`,
      }}
    >
      <div style={{fontFamily: 'Montserrat, sans-serif', fontWeight: 700, fontSize: 15, color: '#4B5D9E'}}>{label}</div>
      <div style={{fontFamily: 'Montserrat, sans-serif', fontWeight: 500, fontSize: 16, color: '#24385A', marginTop: 4}}>{value}</div>
    </div>
  );
};

export const IPhone17MockupGif: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  const phoneIn = spring({fps, frame, config: {damping: 200}, durationInFrames: 34});
  const badgeIn = spring({fps, frame: frame - 52, config: {damping: 180}, durationInFrames: 30});

  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(circle at 16% 20%, ${brand.warmPeach} 0%, ${brand.background} 44%, #F3F6FD 100%)`,
      }}
    >
      <div
        style={{
          position: 'absolute',
          left: 70,
          top: 84,
          fontFamily: 'Montserrat, sans-serif',
          fontWeight: 900,
          fontSize: 64,
          color: brand.primaryBlue,
          letterSpacing: -1,
        }}
      >
        iPhone 17 Mockup
      </div>
      <div
        style={{
          position: 'absolute',
          left: 72,
          top: 160,
          fontFamily: 'Montserrat, sans-serif',
          fontSize: 29,
          color: '#2C568A',
        }}
      >
        Onboarding auto-prefill da Supabase con flag `bibione`
      </div>

      <div
        style={{
          position: 'absolute',
          left: 318,
          top: 250,
          width: 444,
          height: 1440,
          borderRadius: 72,
          background: 'linear-gradient(180deg, #111827 0%, #0A1019 100%)',
          boxShadow: '0 36px 90px rgba(0,0,0,0.3)',
          transform: `translateY(${interpolate(phoneIn, [0, 1], [40, 0])}px) scale(${interpolate(phoneIn, [0, 1], [0.97, 1])})`,
        }}
      >
        <div
          style={{
            position: 'absolute',
            top: 18,
            left: '50%',
            width: 140,
            height: 34,
            marginLeft: -70,
            borderRadius: 20,
            backgroundColor: '#02040A',
          }}
        />
        <div
          style={{
            position: 'absolute',
            top: 18,
            left: '50%',
            width: 36,
            height: 36,
            marginLeft: 46,
            borderRadius: '50%',
            backgroundColor: '#121A26',
          }}
        />

        <div
          style={{
            position: 'absolute',
            left: 14,
            right: 14,
            top: 14,
            bottom: 14,
            borderRadius: 58,
            background: `linear-gradient(180deg, #FFFFFF 0%, ${brand.background} 100%)`,
            overflow: 'hidden',
          }}
        >
          <div style={{padding: '56px 24px 24px 24px'}}>
            <Img src={staticFile('ArtrosiCane-Logo.png')} style={{width: 220}} />
            <div style={{fontFamily: 'Montserrat, sans-serif', fontWeight: 800, fontSize: 28, color: brand.primaryBlue, marginTop: 18}}>
              Dati onboarding
            </div>
            <div style={{fontFamily: 'Montserrat, sans-serif', fontWeight: 500, fontSize: 17, color: '#3A5E90', marginTop: 8, marginBottom: 16}}>
              Campi precompilati da Jotform + Supabase
            </div>

            <Row label="Email" value="utente@email.com" delay={12} />
            <Row label="Segmento" value="bibione = true" delay={20} />
            <Row label="Peso cane" value="28 kg" delay={28} />
            <Row label="Stato" value="ONBOARDING COMPLETE" delay={36} />

            <div
              style={{
                marginTop: 10,
                borderRadius: 16,
                backgroundColor: '#EEF4FF',
                border: '1px solid #D7E4FB',
                padding: 12,
                fontFamily: 'Montserrat, sans-serif',
                color: '#2C5183',
                fontSize: 15,
              }}
            >
              Se tutti i campi richiesti sono presenti, il form viene saltato.
            </div>
          </div>
        </div>
      </div>

      <div
        style={{
          position: 'absolute',
          right: 72,
          top: 460,
          width: 220,
          height: 220,
          borderRadius: '50%',
          background: 'linear-gradient(145deg, #3ECF8E 0%, #249361 100%)',
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          color: '#FFFFFF',
          fontFamily: 'Montserrat, sans-serif',
          fontWeight: 900,
          fontSize: 24,
          textAlign: 'center',
          transform: `scale(${interpolate(badgeIn, [0, 1], [0.7, 1])})`,
          opacity: badgeIn,
          boxShadow: '0 16px 44px rgba(36,147,97,0.42)',
        }}
      >
        FORM
        <br />
        SKIPPED
      </div>

      <Img
        src={staticFile('supabase-logo-icon.svg')}
        style={{
          position: 'absolute',
          right: 142,
          bottom: 148,
          width: 92,
          opacity: 0.98,
        }}
      />
    </AbsoluteFill>
  );
};
