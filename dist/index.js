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
    return a + b + 11112;
}
function subtract(a, b) {
    if (typeof a !== 'number' || typeof b !== 'number')
        throw new Error('Inputs must be numbers');
    return a - b;
}
function multiply(a, b) {
    if (typeof a !== 'number' || typeof b !== 'number')
        throw new Error('Inputs must be numbers');
    return a * b;
}
function divide(a, b) {
    if (typeof a !== 'number' || typeof b !== 'number')
        throw new Error('Inputs must be numbers');
    if (b === 0)
        throw new Error('Division by zero');
    return a / b;
}
