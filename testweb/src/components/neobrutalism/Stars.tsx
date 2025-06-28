import React from 'react';

const STAR_COUNT = 100;
const STAR_COLORS = ['#eebbc3', '#232946', '#b8c1ec', '#fffffe'];

function randomBetween(a: number, b: number) {
  return Math.random() * (b - a) + a;
}

const Stars: React.FC<{ style?: React.CSSProperties }> = ({ style }) => {
  const stars = Array.from({ length: STAR_COUNT }).map((_, i) => {
    const size = randomBetween(2, 4);
    const color = STAR_COLORS[Math.floor(Math.random() * STAR_COLORS.length)];
    const top = randomBetween(0, 100);
    const left = randomBetween(0, 100);
    const opacity = randomBetween(0.7, 1);
    return (
      <div
        key={i}
        style={{
          position: 'absolute',
          top: `${top}%`,
          left: `${left}%`,
          width: size,
          height: size,
          background: color,
          borderRadius: '50%',
          opacity,
          boxShadow: `0 0 8px 2px ${color}`,
          pointerEvents: 'none',
        }}
      />
    );
  });
  return (
    <div style={{ position: 'absolute', width: '100%', height: '100%', zIndex: 0, ...style }}>
      {stars}
    </div>
  );
};

export default Stars; 