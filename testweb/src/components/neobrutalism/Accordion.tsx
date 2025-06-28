import React, { useState } from 'react';

export interface AccordionItemProps {
  title: string;
  children: React.ReactNode;
}

export const AccordionItem: React.FC<AccordionItemProps> = ({ title, children }) => {
  const [open, setOpen] = useState(false);
  return (
    <div style={{
      border: '2px solid #232946',
      borderRadius: '8px',
      marginBottom: '12px',
      background: open ? '#eebbc3' : '#fff',
      transition: 'background 0.2s',
      boxShadow: open ? '4px 4px 0 #232946' : '2px 2px 0 #232946',
    }}>
      <button
        onClick={() => setOpen(!open)}
        style={{
          width: '100%',
          textAlign: 'left',
          background: 'none',
          border: 'none',
          padding: '16px',
          fontWeight: 700,
          fontSize: '1.1em',
          color: '#232946',
          cursor: 'pointer',
        }}
      >
        {title}
      </button>
      {open && (
        <div style={{ padding: '16px', color: '#232946', fontSize: '1em' }}>
          {children}
        </div>
      )}
    </div>
  );
};

export interface AccordionProps {
  children: React.ReactNode;
}

const Accordion: React.FC<AccordionProps> = ({ children }) => {
  return <div>{children}</div>;
};

export default Accordion; 