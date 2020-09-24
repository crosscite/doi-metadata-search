const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const JSLoader = {
  test: /\.(t|j)sx?$/,
  exclude: /node_modules/,
  use: {
    loader: 'babel-loader',
    options: {
      presets: ["@babel/preset-env", "@babel/preset-react"]
    }
  }
};

const ESLintLoader = {
  test: /\.js$/,
  enforce: 'pre',
  exclude: /node_modules/,
  use: {
    loader: 'eslint-loader',
    options: {
      configFile: '.eslintrc.js'
    },
  }
};

const FileLoader = {
  test: /\.(png|jpe?g|gif)$/i,
  use: [
    {
      loader: 'file-loader',
    },
  ],
};

const CSSLoader = {
  test: /\.(sa|sc|c)ss$/,
  exclude: /node_modules/,
  use: [{
      loader: MiniCssExtractPlugin.loader,
      options: {
        publicPath: __dirname + '/stylesheets/',
        sourceMap: true
      }
    },
    // Not to be used in conjunction with MiniCssExtract
    // {
    //   loader: 'style-loader',
    //   options: {
    //     sourceMap: true
    //   }
    // },
    {
      loader: 'css-loader',
      options: {
        sourceMap: true
      }
    },
    {
      loader: 'postcss-loader',
      options: {
        sourceMap: true,
        config: {
          path: __dirname + '/postcss.config.js'
        }
      }
    },
    {
      loader: 'sass-loader',
      options: {
        sourceMap: true
      }
    }
  ],
};

module.exports = {
  JSLoader: JSLoader,
  ESLintLoader: ESLintLoader,
  CSSLoader: CSSLoader,
  FileLoader: FileLoader
};
