class Crm
  class DocGen < HyperComponent

    render(DIV) { content }

    def content
      ::Crm::DocGen::Modal(id: 'docgen-modal')
    end

  end
end
