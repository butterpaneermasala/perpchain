import React, { useState } from 'react';

export interface AccordionItem {
  title: string;
  content: React.ReactNode;
}

export default function Accordion({ items }: { items: AccordionItem[] }) {
  const [open, setOpen] = useState<number | null>(null);
  return (
    <div style={{borderRadius:12,boxShadow:'6px 6px 0 #eebbc3',background:'#fff',border:'3px solid #232946',padding:8}}>
      {items.map((item, i) => (
        <div key={i} style={{marginBottom:8}}>
          <button
            onClick={() => setOpen(open === i ? null : i)}
            style={{
              width: '100%',
              textAlign: 'left',
              background: open === i ? '#eebbc3' : '#f7f8fa',
              color: '#232946',
              border: '2px solid #232946',
              borderRadius: 8,
              fontWeight: 700,
              fontSize: 18,
              padding: '0.7em 1.2em',
              cursor: 'pointer',
              marginBottom: 2,
              boxShadow: open === i ? '4px 4px 0 #232946' : 'none',
              transition: 'all 0.15s',
            }}
            aria-expanded={open === i}
          >
            {item.title}
          </button>
          {open === i && (
            <div style={{padding:'1em 1.2em',background:'#fffbe6',border:'2px solid #eebbc3',borderRadius:8,marginTop:2}}>
              {item.content}
            </div>
          )}
        </div>
      ))}
    </div>
  );
}
