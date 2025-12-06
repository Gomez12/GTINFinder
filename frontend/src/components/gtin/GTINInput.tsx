import React, { useState, useCallback } from 'react';
import { validateGTIN, formatGTIN } from '../../utils/gtinValidator';
import type { GTINValidationResult } from '../../utils/gtinValidator';

interface GTINInputProps {
  value: string;
  onChange: (value: string, validation: GTINValidationResult) => void;
  placeholder?: string;
  disabled?: boolean;
  showValidation?: boolean;
}

export const GTINInput: React.FC<GTINInputProps> = ({
  value,
  onChange,
  placeholder = 'Enter GTIN (8, 12, 13, or 14 digits)',
  disabled = false,
  showValidation = true,
}) => {
  const [validation, setValidation] = useState<GTINValidationResult | null>(null);
  const [isDirty, setIsDirty] = useState(false);

  const handleChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const inputValue = e.target.value;
    setIsDirty(true);
    
    // Validate if we have enough characters
    const cleanValue = inputValue.replace(/[^0-9]/g, '');
    let validationResult: GTINValidationResult;
    
    if (cleanValue.length === 0) {
      validationResult = {
        isValid: false,
        gtin: '',
        type: 'INVALID',
        checksum: -1,
        calculatedChecksum: -1,
      };
    } else if ([8, 12, 13, 14].includes(cleanValue.length)) {
      validationResult = validateGTIN(inputValue);
    } else {
      validationResult = {
        isValid: false,
        gtin: cleanValue,
        type: 'INVALID',
        checksum: -1,
        calculatedChecksum: -1,
        error: `Expected 8, 12, 13, or 14 digits, got ${cleanValue.length}`
      };
    }
    
    setValidation(validationResult);
    onChange(inputValue, validationResult);
  }, [onChange]);

  const getValidationColor = () => {
    if (!isDirty || !validation) return 'border-gray-300';
    if (validation.isValid) return 'border-green-500 focus:ring-green-500';
    return 'border-red-500 focus:ring-red-500';
  };

  const getValidationMessage = () => {
    if (!isDirty || !validation || !showValidation) return null;
    
    if (validation.isValid) {
      return (
        <p className="text-green-600 text-sm mt-1">
          ✓ Valid {validation.type}: {formatGTIN(validation.gtin)}
        </p>
      );
    }
    
    return (
      <p className="text-red-500 text-sm mt-1">
        ✗ {validation.error}
      </p>
    );
  };

  return (
    <div className="space-y-2">
      <label htmlFor="gtin-input" className="block text-sm font-medium text-gray-700">
        GTIN Code
      </label>
      <input
        id="gtin-input"
        type="text"
        value={value}
        onChange={handleChange}
        disabled={disabled}
        placeholder={placeholder}
        className={`input ${getValidationColor()}`}
        maxLength={17} // Allow for formatting characters
      />
      {getValidationMessage()}
      {showValidation && (
        <p className="text-gray-500 text-xs">
          Supports GTIN-8, GTIN-12, GTIN-13, and GTIN-14 formats
        </p>
      )}
    </div>
  );
};
