const { generateWebpackConfig } = require('shakapacker')

const defaultWebpackConfig = generateWebpackConfig()

const app_path_prefix = process.env.APP_PATH_PREFIX || ""

const webpack = require("webpack")

const customConfig = {
  optimization: {
    splitChunks: false // TODO find a way to make chunks work
  },
  resolve: {
    extensions: [
      '.mjs',
      '.js',
      '.sass',
      '.scss',
      '.css',
      '.module.sass',
      '.module.scss',
      '.module.css',
      '.png',
      '.svg',
      '.gif',
      '.jpeg',
      '.jpg'
    ],
    alias: {
      jquery: require.resolve("jquery"),
      React: 'react',
      ReactDOM: 'react-dom',
    },
  },
  output: {
    publicPath: app_path_prefix + defaultWebpackConfig.output.publicPath
  },
  plugins: [
    new webpack.DefinePlugin({
      APP_PATH_PREFIX: JSON.stringify(app_path_prefix)
    }),
    new webpack.DefinePlugin({
      'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV)
    })
  ],
  module: {
    rules: [
      {
        test: require.resolve("jquery"),
        loader: "expose-loader",
        options: {
          exposes: ["$", "jQuery"]
        }
      },
      {
        test: /channels\/consumer\.js/,
        loader: "expose-loader",
        options: {
          exposes: [{
            moduleLocalName: "default",
            globalName: "ApiCable"
          }]
        }
      },
      {
        test: /activestorage.js/,
        loader: "expose-loader",
        options: {
          exposes: ["ActiveStorage"]
        }
      },
      {
        test: require.resolve("quill"),
        loader: "expose-loader",
        options: {
          exposes: {
            globalName: "Quill",
            override: true,
          },
        },
      },
    ]
  },
}

module.exports = generateWebpackConfig(customConfig)
