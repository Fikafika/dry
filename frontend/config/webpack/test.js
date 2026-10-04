process.env.NODE_ENV = process.env.NODE_ENV || 'test'

const { merge } = require('shakapacker')
const webpackConfig = require('./base')

const customConfig = {
  module: {
    rules: [
      {
        test: /mock\-xmlhttprequest/,
        loader: "expose-loader",
        options: {
          exposes: ["MockXMLHttpRequest"]
        }
      }
    ]
  }
}

module.exports = merge(webpackConfig, customConfig)
