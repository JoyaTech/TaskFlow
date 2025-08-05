module.exports = {
  env: {
    browser: true,
    commonjs: true,
    es2021: true,
    node: true
  },
  extends: [
    'eslint:recommended',
    'plugin:node/recommended',
    'prettier'
  ],
  parserOptions: {
    ecmaVersion: 'latest'
  },
  rules: {
    'no-console': 'off',
    'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    'prefer-const': 'error',
    'no-var': 'error'
  }
};
