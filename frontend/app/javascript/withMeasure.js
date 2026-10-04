/* NOTE: this is compatible with react-measure up to 1.4.7 only */
import React from 'react'
import Measure from 'react-measure'

const withMeasure = (
  dimensionsToInject = ['width', 'height', 'top', 'right', 'bottom', 'left'],
  props = {}
) => WrappedComponent => wrappedComponentProps => (
  React.createElement(Measure, props,
    (dimensions) => {
      const injectedDimensions = {}
      dimensionsToInject.forEach(key => {
        injectedDimensions[key] = dimensions[key]
      })
      return (
        React.createElement(WrappedComponent, {...wrappedComponentProps, ...injectedDimensions}, null)
      )
    }
  )
)

export default withMeasure
