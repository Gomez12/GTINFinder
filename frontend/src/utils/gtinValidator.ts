/**
 * GTIN Validation Utilities
 * Supports GTIN-8, GTIN-12, GTIN-13, and GTIN-14 formats
 */

export interface GTINValidationResult {
  isValid: boolean;
  gtin: string;
  type: 'GTIN-8' | 'GTIN-12' | 'GTIN-13' | 'GTIN-14' | 'INVALID';
  checksum: number;
  calculatedChecksum: number;
  error?: string;
}

/**
 * Validate GTIN format and checksum
 */
export const validateGTIN = (input: string): GTINValidationResult => {
  // Remove any non-digit characters
  const cleanGTIN = input.replace(/[^0-9]/g, '');
  
  // Check length
  const validLengths = [8, 12, 13, 14];
  if (!validLengths.includes(cleanGTIN.length)) {
    return {
      isValid: false,
      gtin: cleanGTIN,
      type: 'INVALID',
      checksum: -1,
      calculatedChecksum: -1,
      error: `Invalid GTIN length. Expected 8, 12, 13, or 14 digits, got ${cleanGTIN.length}`
    };
  }
  
  // Get the type
  const type = getGTINType(cleanGTIN.length);
  
  // Calculate checksum
  const calculatedChecksum = calculateChecksum(cleanGTIN);
  const actualChecksum = parseInt(cleanGTIN.slice(-1));
  
  const isValid = calculatedChecksum === actualChecksum;
  
  return {
    isValid,
    gtin: cleanGTIN,
    type,
    checksum: actualChecksum,
    calculatedChecksum,
    error: isValid ? undefined : `Invalid checksum. Expected ${calculatedChecksum}, got ${actualChecksum}`
  };
};

/**
 * Get GTIN type based on length
 */
const getGTINType = (length: number): GTINValidationResult['type'] => {
  switch (length) {
    case 8:
      return 'GTIN-8';
    case 12:
      return 'GTIN-12';
    case 13:
      return 'GTIN-13';
    case 14:
      return 'GTIN-14';
    default:
      return 'INVALID';
  }
};

/**
 * Calculate GTIN checksum
 */
const calculateChecksum = (gtin: string): number => {
  const digits = gtin.slice(0, -1).split('').map(Number);
  
  // Multipliers depend on GTIN length
  let multipliers: number[];
  
  switch (gtin.length) {
    case 8: // GTIN-8
      multipliers = [3, 1, 3, 1, 3, 1, 3];
      break;
    case 12: // GTIN-12
      multipliers = Array(6).fill(0).flatMap((_i, _index) => [1, 3]);
      break;
    case 13: // GTIN-13
      multipliers = Array(6).fill(0).flatMap((_i, _index) => [1, 3]);
      multipliers.push(1); // Extra multiplier for position 13
      break;
    case 14: // GTIN-14
      multipliers = Array(7).fill(0).flatMap((_) => [3, 1]);
      break;
    default:
      return -1;
  }
  
  // Calculate sum
  const sum = digits.reduce((acc, digit, index) => {
    return acc + (digit * multipliers[index]);
  }, 0);
  
  // Calculate checksum
  return (10 - (sum % 10)) % 10;
};

/**
 * Format GTIN for display
 */
export const formatGTIN = (gtin: string): string => {
  const cleanGTIN = gtin.replace(/[^0-9]/g, '');
  
  switch (cleanGTIN.length) {
    case 8:
      return cleanGTIN;
    case 12:
      return `${cleanGTIN.slice(0, 1)}-${cleanGTIN.slice(1, 6)}-${cleanGTIN.slice(6)}`;
    case 13:
      return `${cleanGTIN.slice(0, 1)}-${cleanGTIN.slice(1, 7)}-${cleanGTIN.slice(7)}`;
    case 14:
      return `${cleanGTIN.slice(0, 2)}-${cleanGTIN.slice(2, 8)}-${cleanGTIN.slice(8)}`;
    default:
      return cleanGTIN;
  }
};

/**
 * Check if GTIN is properly formatted for input
 */
export const isValidGTINInput = (input: string): boolean => {
  const cleanGTIN = input.replace(/[^0-9]/g, '');
  const validLengths = [8, 12, 13, 14];
  return validLengths.includes(cleanGTIN.length);
};

/**
 * Get GTIN validation message
 */
export const getGTINValidationMessage = (result: GTINValidationResult): string => {
  if (result.isValid) {
    return `Valid ${result.type}: ${formatGTIN(result.gtin)}`;
  }
  
  return result.error || 'Invalid GTIN format';
};
