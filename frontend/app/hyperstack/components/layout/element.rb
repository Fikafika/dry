require 'components/layout'

class Layout::Element < ::HyperComponent

  collect_other_params_as :other_params

  render { content }

  def content
    yield if block_given?
  end

end
