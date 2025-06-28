
import React from 'react';

interface ChartDataPoint {
  label: string;
  value: number;
  color: string;
}

interface ChartProps {
  data: ChartDataPoint[];
  title?: string;
  type?: 'bar' | 'pie' | 'line';
  className?: string;
}

export const Chart: React.FC<ChartProps> = ({ 
  data, 
  title, 
  type = 'bar', 
  className = '' 
}) => {
  const maxValue = Math.max(...data.map(d => d.value));

  if (type === 'bar') {
    return (
      <div className={`bg-white border-4 border-[#232946] shadow-[8px_8px_0px_0px_#232946] p-6 ${className}`}>
        {title && (
          <h3 className="text-2xl font-black mb-6 text-[#232946]">{title}</h3>
        )}
        <div className="space-y-4">
          {data.map((item, index) => (
            <div key={index} className="flex items-center gap-4">
              <div className="w-20 text-sm font-bold text-[#232946] truncate">
                {item.label}
              </div>
              <div className="flex-1 relative">
                <div 
                  className="h-8 border-4 border-[#232946] shadow-[4px_4px_0px_0px_#232946] flex items-center px-2"
                  style={{
                    backgroundColor: item.color,
                    width: `${(item.value / maxValue) * 100}%`,
                    minWidth: '60px'
                  }}
                >
                  <span className="text-sm font-bold text-white">
                    {item.value}
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (type === 'pie') {
    const total = data.reduce((sum, item) => sum + item.value, 0);
    let cumulativePercentage = 0;

    return (
      <div className={`bg-white border-4 border-[#232946] shadow-[8px_8px_0px_0px_#232946] p-6 ${className}`}>
        {title && (
          <h3 className="text-2xl font-black mb-6 text-[#232946]">{title}</h3>
        )}
        <div className="flex items-center gap-8">
          <div className="relative">
            <svg width="200" height="200" className="border-4 border-[#232946] shadow-[4px_4px_0px_0px_#232946]">
              {data.map((item, index) => {
                const percentage = (item.value / total) * 100;
                const startAngle = cumulativePercentage * 3.6;
                const endAngle = (cumulativePercentage + percentage) * 3.6;
                
                const x1 = 100 + 80 * Math.cos((startAngle - 90) * Math.PI / 180);
                const y1 = 100 + 80 * Math.sin((startAngle - 90) * Math.PI / 180);
                const x2 = 100 + 80 * Math.cos((endAngle - 90) * Math.PI / 180);
                const y2 = 100 + 80 * Math.sin((endAngle - 90) * Math.PI / 180);
                
                const largeArcFlag = percentage > 50 ? 1 : 0;
                
                const pathData = [
                  `M 100 100`,
                  `L ${x1} ${y1}`,
                  `A 80 80 0 ${largeArcFlag} 1 ${x2} ${y2}`,
                  'Z'
                ].join(' ');

                cumulativePercentage += percentage;
                
                return (
                  <path
                    key={index}
                    d={pathData}
                    fill={item.color}
                    stroke="#232946"
                    strokeWidth="2"
                  />
                );
              })}
            </svg>
          </div>
          <div className="space-y-3">
            {data.map((item, index) => (
              <div key={index} className="flex items-center gap-3">
                <div 
                  className="w-6 h-6 border-2 border-[#232946]"
                  style={{ backgroundColor: item.color }}
                />
                <span className="font-bold text-[#232946]">
                  {item.label}: {item.value}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return null;
};
