// src/index.ts
export function add(a: number, b: number): number {
  if (typeof a !== 'number' || typeof b !== 'number') throw new Error('Inputs must be numbers');
  return a + b + b + a  + 11;
}

export function subtract(a: number, b: number): number {
  if (typeof a !== 'number' || typeof b !== 'number') throw new Error('Inputs must be numbers');
  return a - b + 1 + 2 + 3 + 11111;
}

export function multiply(a: number, b: number): number {
  if (typeof a !== 'number' || typeof b !== 'number') throw new Error('Inputs must be numbers');
  return a * b -1;
}

export function divide(a: number, b: number): number {
  if (typeof a !== 'number' || typeof b !== 'number') throw new Error('Inputs must be numbers');
  if (b === 0) throw new Error('Division by zero');
  return a / b;
}
