const env = process.env.MIX_ENV === 'prox' ? 'production' : 'development'
const Webpack = require('webpack')
const ExtractTextPlugin = require('extract-text-webpack-plugin')
const CopyPlugin = require('copy-webpack-plugin')
const path = require('path')

const plugins = {
  production: [
    new Webpack.optimize.UglifyJsPlugin({compress: {warnings: false}})
  ],
  development: []
}

module.exports = {
  entry: [
    './web/static/js/index.js',
    './web/static/css/app.css'
  ],
  output: {
    path: path.resolve('./priv/static'),
    filename: 'js/app.js',
    publicPath: '/'
  },
  resolve: {
    extensions: ['.js', '.jsx', '.css'],
    alias: {
      styles: path.join(__dirname, 'web/static/css')
    }
  },
  plugins: [
    new Webpack.DefinePlugin({
      'process.env': {
        'NODE_ENV': JSON.stringify(env)
      }
    }),
    new ExtractTextPlugin('css/app.css'),
    new CopyPlugin([{from: './web/static/assets'}])
  ].concat(plugins[env]),
  module: {
    loaders: [
      {
        test: /\.jsx?$/,
        exclude: /node_modules/,
        loader: 'babel-loader',
        query: {
          plugins: [],
          presets: ['react', 'es2015']
        }
      }, {
        test: /\.css$/,
        loader: ExtractTextPlugin.extract({ fallback: 'style-loader', use: 'css-loader' })
      }, {
        test: /\.png$/,
        loader: 'url?' + [
          'limit=100000',
          'mimetype=image/png'
        ].join('&')
      }, {
        test: /\.gif$/,
        loader: 'url?' + [
          'limit=100000',
          'mimetype=image/gif'
        ].join('&')
      }, {
        test: /\.jpg$/,
        loader: 'file?name=images/[name].[ext]'
      }, {
        test: /\.(woff|woff2)$/,
        loader: 'url?' + [
          'limit=10000',
          'mimetype=application/font-woff',
          'name=fonts/[name].[ext]'
        ].join('&')
      }, {
        test: /\.ttf$/,
        loader: 'url?' + [
          'limit=10000',
          'mimetype=application/octet-stream',
          'name=fonts/[name].[ext]'
        ].join('&')
      }, {
        test: /\.eot$/,
        loader: 'url?' + [
          'limit=10000',
          'name=fonts/[name].[ext]'
        ].join('&')
      }, {
        test: /\.svg$/,
        loader: 'url?' + [
          'limit=10000',
          'mimetype=image/svg+xml',
          'name=images/[name].[ext]'
        ].join('&')
      }
    ]
  }
}
