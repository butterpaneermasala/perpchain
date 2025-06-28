import React from 'react';

interface State { hasError: boolean; error: any; }

export class ErrorBoundary extends React.Component<{children: React.ReactNode}, State> {
  constructor(props: {children: React.ReactNode}) {
    super(props);
    this.state = { hasError: false, error: null };
  }
  static getDerivedStateFromError(error: any) {
    return { hasError: true, error };
  }
  componentDidCatch(error: any, info: any) {
    // Log error to service if needed
    // console.error(error, info);
  }
  render() {
    if (this.state.hasError) {
      return (
        <div style={{background:'#fff0f0',border:'3px solid #e63946',borderRadius:12,padding:32,margin:32,color:'#e63946',fontWeight:700}}>
          <h2>Something went wrong.</h2>
          <pre style={{whiteSpace:'pre-wrap'}}>{String(this.state.error)}</pre>
        </div>
      );
    }
    return this.props.children;
  }
}
