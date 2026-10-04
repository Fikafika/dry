process.env.NODE_ENV = process.env.NODE_ENV || 'production'

const { merge } = require('shakapacker')
const webpack = require("webpack")
const webpackConfig = require('./base')

const customConfig = {
  plugins: [
    new webpack.IgnorePlugin({ resourceRegExp: /^mock-xmlhttprequest$/ })
  ]
}

module.exports = merge(webpackConfig, customConfig)
