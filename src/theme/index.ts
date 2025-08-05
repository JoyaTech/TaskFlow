import { DefaultTheme } from 'styled-components';

// ADHD-Friendly Color Psychology
export const colors = {
  // Calming base colors - reduce overstimulation
  primary: {
    50: '#f0f9ff',   // Very light blue - reduces anxiety
    100: '#e0f2fe',  // Light blue - maintains focus
    500: '#0ea5e9',  // Sky blue - promotes clarity
    600: '#0284c7',  // Deeper blue - enhances concentration
    700: '#0369a1',  // Strong blue - decision making
  },
  
  // Warm secondary colors - boost motivation
  secondary: {
    50: '#fef3c7',   // Warm yellow - enhances mood
    100: '#fde68a',  // Light amber - increases energy
    500: '#f59e0b',  // Amber - motivational
    600: '#d97706',  // Orange - action-oriented
    700: '#b45309',  // Deep orange - completion satisfaction
  },
  
  // Success colors - dopamine reward system
  success: {
    50: '#ecfdf5',   // Very light green
    100: '#d1fae5',  // Light green - achievement
    500: '#10b981',  // Green - completion reward
    600: '#059669',  // Deep green - major milestone
    700: '#047857',  // Forest green - mastery
  },
  
  // Warning colors - gentle attention without alarm
  warning: {
    50: '#fffbeb',   // Very light orange
    100: '#fef3c7',  // Light peach - soft alert
    500: '#f59e0b',  // Warm orange - needs attention
    600: '#d97706',  // Orange - important notice
    700: '#b45309',  // Deep orange - urgent but not alarming
  },
  
  // Error colors - supportive, not punitive
  error: {
    50: '#fef2f2',   // Very light red
    100: '#fee2e2',  // Light pink - gentle correction
    500: '#ef4444',  // Red - needs fixing
    600: '#dc2626',  // Strong red - important error
    700: '#b91c1c',  // Deep red - critical issue
  },
  
  // Neutral grays - reduce cognitive load
  neutral: {
    50: '#f9fafb',   // Almost white
    100: '#f3f4f6',  // Very light gray - backgrounds
    200: '#e5e7eb',  // Light gray - borders
    300: '#d1d5db',  // Medium light - inactive elements
    400: '#9ca3af',  // Medium gray - placeholder
    500: '#6b7280',  // Gray - secondary text
    600: '#4b5563',  // Dark gray - primary text
    700: '#374151',  // Very dark gray - headers
    800: '#1f2937',  // Near black - emphasis
    900: '#111827',  // Black - maximum contrast
  },
  
  // ADHD-specific functional colors
  focus: {
    ring: '#3b82f6',     // Focus ring - clear indication
    background: '#eff6ff', // Focus background - subtle highlight
  },
  
  hyperfocus: {
    border: '#8b5cf6',   // Purple border - deep work mode
    background: '#f3e8ff', // Purple tint - concentration zone
  },
  
  break: {
    background: '#fef3c7', // Warm yellow - break reminder
    border: '#f59e0b',     // Amber border - rest time
  },
  
  achievement: {
    background: '#ecfdf5', // Light green - success feedback
    border: '#10b981',     // Green border - completion
    text: '#047857',       // Dark green text - achievement
  }
};

// Hebrew Typography System
export const typography = {
  fonts: {
    // Hebrew fonts with proper fallbacks
    hebrew: {
      sans: '"Noto Sans Hebrew", "Arial Hebrew", "Tahoma", sans-serif',
      serif: '"Noto Serif Hebrew", "Times New Roman Hebrew", serif',
      display: '"Assistant", "Noto Sans Hebrew", sans-serif',
      mono: '"JetBrains Mono", "Courier New Hebrew", monospace'
    },
    
    // Latin fonts for mixed content
    latin: {
      sans: '"Inter", "Helvetica Neue", sans-serif',
      serif: '"Crimson Text", "Georgia", serif',
      display: '"Poppins", "Inter", sans-serif',
      mono: '"JetBrains Mono", "Monaco", monospace'
    }
  },
  
  // ADHD-optimized font sizes (larger for better readability)
  sizes: {
    xs: '0.875rem',   // 14px
    sm: '1rem',       // 16px - minimum for ADHD readability
    base: '1.125rem', // 18px - preferred base size
    lg: '1.25rem',    // 20px
    xl: '1.375rem',   // 22px
    '2xl': '1.5rem',  // 24px
    '3xl': '1.875rem', // 30px
    '4xl': '2.25rem',  // 36px
    '5xl': '3rem',     // 48px
  },
  
  // Line heights optimized for Hebrew and ADHD
  lineHeights: {
    tight: 1.25,    // For headers
    normal: 1.5,    // For body text - ADHD optimal
    relaxed: 1.625, // For long-form content
    loose: 2,       // For spacing-sensitive content
  },
  
  // Letter spacing for Hebrew readability
  letterSpacing: {
    tighter: '-0.025em',
    tight: '-0.0125em',
    normal: '0em',
    wide: '0.025em',
    wider: '0.05em',
    widest: '0.1em',
  },
  
  // Font weights
  weights: {
    light: 300,
    normal: 400,
    medium: 500,
    semibold: 600,
    bold: 700,
    extrabold: 800,
  }
};

// Spacing system based on cognitive load principles
export const spacing = {
  px: '1px',
  0: '0',
  0.5: '0.125rem',  // 2px
  1: '0.25rem',     // 4px
  1.5: '0.375rem',  // 6px
  2: '0.5rem',      // 8px
  2.5: '0.625rem',  // 10px
  3: '0.75rem',     // 12px
  3.5: '0.875rem',  // 14px
  4: '1rem',        // 16px - base unit
  5: '1.25rem',     // 20px
  6: '1.5rem',      // 24px - comfortable spacing
  7: '1.75rem',     // 28px
  8: '2rem',        // 32px - section spacing
  9: '2.25rem',     // 36px
  10: '2.5rem',     // 40px
  11: '2.75rem',    // 44px
  12: '3rem',       // 48px - large spacing
  14: '3.5rem',     // 56px
  16: '4rem',       // 64px - extra large
  20: '5rem',       // 80px - maximum spacing
};

// Border radius for friendly, approachable design
export const borderRadius = {
  none: '0',
  sm: '0.125rem',   // 2px
  base: '0.25rem',  // 4px
  md: '0.375rem',   // 6px
  lg: '0.5rem',     // 8px - preferred for ADHD
  xl: '0.75rem',    // 12px
  '2xl': '1rem',    // 16px
  '3xl': '1.5rem',  // 24px
  full: '9999px',   // Pills and circles
};

// Shadows for depth perception (important for ADHD users)
export const shadows = {
  sm: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
  base: '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)',
  md: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
  lg: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
  xl: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
  '2xl': '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
  inner: 'inset 0 2px 4px 0 rgba(0, 0, 0, 0.06)',
  focus: '0 0 0 3px rgba(59, 130, 246, 0.5)', // Prominent focus indicator
  none: 'none',
};

// Animation durations and easings for ADHD-friendly motion
export const animations = {
  durations: {
    fast: '150ms',      // Quick feedback
    normal: '200ms',    // Standard transitions
    slow: '300ms',      // Deliberate animations
    slower: '500ms',    // Emphasis animations
  },
  
  easings: {
    easeOut: 'cubic-bezier(0, 0, 0.2, 1)',        // Natural deceleration
    easeIn: 'cubic-bezier(0.4, 0, 1, 1)',         // Gentle acceleration
    easeInOut: 'cubic-bezier(0.4, 0, 0.2, 1)',    // Smooth both ways
    bounce: 'cubic-bezier(0.68, -0.55, 0.265, 1.55)', // Playful feedback
  }
};

// Breakpoints for responsive design
export const breakpoints = {
  sm: '640px',
  md: '768px',
  lg: '1024px',
  xl: '1280px',
  '2xl': '1536px',
};

// Z-index scale for layering
export const zIndex = {
  hide: -1,
  auto: 'auto',
  base: 0,
  docked: 10,
  dropdown: 1000,
  sticky: 1100,
  banner: 1200,
  overlay: 1300,
  modal: 1400,
  popover: 1500,
  skipLink: 1600,
  toast: 1700,
  tooltip: 1800,
};

// Complete theme object
export const theme: DefaultTheme = {
  colors,
  typography,
  spacing,
  borderRadius,
  shadows,
  animations,
  breakpoints,
  zIndex,
  
  // RTL-specific properties
  rtl: {
    direction: 'rtl' as const,
    textAlign: 'right' as const,
    floatStart: 'right' as const,
    floatEnd: 'left' as const,
    marginStart: 'marginRight' as const,
    marginEnd: 'marginLeft' as const,
    paddingStart: 'paddingRight' as const,
    paddingEnd: 'paddingLeft' as const,
    borderStartWidth: 'borderRightWidth' as const,
    borderEndWidth: 'borderLeftWidth' as const,
  },
  
  // ADHD-specific theme properties
  adhd: {
    focusIndicatorWidth: '3px',
    minimumTouchTarget: '44px',
    preferredLineLength: '45ch', // Optimal reading length
    breakReminder: {
      interval: 25 * 60 * 1000, // 25 minutes in milliseconds
      duration: 5 * 60 * 1000,  // 5 minute break
    },
    rewardSystem: {
      colors: colors.achievement,
      animations: {
        celebration: 'bounce 0.6s ease-in-out',
        progress: 'pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      }
    }
  }
};

export default theme;
