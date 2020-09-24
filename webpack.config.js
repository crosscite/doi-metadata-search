const path = require('path');
const loaders = require('./webpack/loaders.js');
const plugins = require('./webpack/plugins.js');

module.exports = {
  mode: 'production',
  entry: {
    usage: './public/stylesheets/sass/usage.scss',
  },
  module: {
    rules: [
      loaders.JSLoader,
      loaders.ESLintLoader,
      loaders.CSSLoader,
      loaders.FileLoader,
    ]
  },
  plugins: [
    plugins.MiniCssExtractPlugin,
  ],
  output: {
    filename: 'public/javascripts/[name].js',
    path: path.resolve(__dirname, '.tmp/dist')
  }
};
