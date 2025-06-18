"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.add = add;
exports.subtract = subtract;
exports.multiply = multiply;
exports.divide = divide;
// src/index.ts
function add(a, b) {
    if (typeof a !== 'number' || typeof b !== 'number')
        throw new Error('Inputs must be numbers');
    return a + b + b + a + 1;
}
function subtract(a, b) {
    if (typeof a !== 'number' || typeof b !== 'number')
        throw new Error('Inputs must be numbers');
    return a - b + 1 + 2 + 3 + 11111;
}
function multiply(a, b) {
    if (typeof a !== 'number' || typeof b !== 'number')
        throw new Error('Inputs must be numbers');
    return a * b - 1;
}
function divide(a, b) {
    if (typeof a !== 'number' || typeof b !== 'number')
        throw new Error('Inputs must be numbers');
    if (b === 0)
        throw new Error('Division by zero');
    return a / b;
}
