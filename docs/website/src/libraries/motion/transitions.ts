/**
 * Common animation variants using Framer Motion.
 * Import `motion` / `AnimatePresence` where a Vue island or hybrid React
 * island needs shared motion tokens (design hub demos, page transitions).
 */
import { motion, AnimatePresence } from 'framer-motion';

export const fadeVariants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1 },
  exit: { opacity: 0 },
};

export const slideUpVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: -20 },
};

export { motion, AnimatePresence };
