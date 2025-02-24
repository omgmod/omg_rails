const path = require("path")
const webpack = require("webpack")

// Extracts CSS into .css file
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
// Removes exported JavaScript files from CSS-only entries
// in this example, entry.custom will create a corresponding empty custom.js file
const RemoveEmptyScriptsPlugin = require('webpack-remove-empty-scripts');

const mode = process.env.NODE_ENV === 'development' ? 'development' : 'production';

module.exports = {
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        exclude: /node_modules/,
        use: ['babel-loader'],
      },
      {
        test: /\.(?:sa|sc|c)ss$/i,
        use: [MiniCssExtractPlugin.loader, 'css-loader', 'sass-loader'],
      },
      {
        test: /\.(png|jpe?g|gif|eot|woff2|woff|ttf|svg)$/i,
        use: [
          {
            loader: "file-loader",
            options: {
              name: "[name]-[hash].digested.[ext]",
            },
          },
        ],
      },
    ]
  },
  mode: mode,
  optimization: {
    moduleIds: 'deterministic',
  },
  entry: {
    application: [
      "./app/javascript/packs/application.js",
      "./app/javascript/packs/index.js",
      "./app/assets/stylesheets/application.css",
      "./app/assets/stylesheets/admin.css",
    ]
  },
  resolve: {
    extensions: ['.js', '.jsx', '.css', '.scss']
  },
  output: {
    filename: "[name].js",
    sourceMapFilename: "[file].map",
    chunkFormat: "module",
    path: path.resolve(__dirname, '..', '..', 'app/assets/builds')
  },
  plugins: [
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1
    }),
    new RemoveEmptyScriptsPlugin(),
    new MiniCssExtractPlugin(),
  ]
}
