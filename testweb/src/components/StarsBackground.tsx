// Neobrutalism stars SVG background
import React from 'react';

const StarsBackground: React.FC<{ style?: React.CSSProperties }> = ({ style }) => (
  <svg
    width="100%"
    height="100%"
    style={{
      position: 'absolute',
      top: 0,
      left: 0,
      zIndex: 0,
      pointerEvents: 'none',
      ...style,
    }}
    viewBox="0 0 1200 800"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    preserveAspectRatio="none"
  >
    <g opacity="0.18">
      <circle cx="100" cy="120" r="2.5" fill="#eebbc3" />
      <circle cx="300" cy="200" r="1.5" fill="#b8c1ec" />
      <circle cx="600" cy="80" r="2" fill="#eebbc3" />
      <circle cx="900" cy="150" r="2.5" fill="#b8c1ec" />
      <circle cx="1100" cy="300" r="1.5" fill="#eebbc3" />
      <circle cx="200" cy="700" r="2" fill="#b8c1ec" />
      <circle cx="800" cy="600" r="2.5" fill="#eebbc3" />
      <circle cx="400" cy="500" r="1.5" fill="#b8c1ec" />
      <circle cx="1000" cy="700" r="2" fill="#eebbc3" />
      <circle cx="600" cy="400" r="1.5" fill="#b8c1ec" />
      <polygon points="350,350 355,360 345,360" fill="#eebbc3" />
      <polygon points="1050,250 1055,260 1045,260" fill="#b8c1ec" />
      <polygon points="700,700 705,710 695,710" fill="#eebbc3" />
    </g>
  </svg>
);

export default StarsBackground;
