# backtick_javascript: true

class Form
  class FakeForm

    attr_accessor :page_counter
    attr_accessor :default_values
    attr_accessor :condition_attrs_to_clean
    attr_accessor :association_min
    attr_accessor :association_max
    attr_accessor :input_ids

    def initialize(dynamic_form = nil, tree = nil)
      @dynamic_form = dynamic_form
      @tree = tree
      @page_counter = 1
      @default_values = {}
      @condition_attrs_to_clean = {}
      @association_min = {}
      @association_max = {}
      @elements_waiting_for_data = {}
      @input_ids = Set.new
    end

    def dynamic_form
      @dynamic_form
    end

    def other_params
      {}
    end

    def mode
      @dynamic_form&.mode
    end

    def page_count
      result = 0
      `
        #{@tree}.children_attributes.forEach((e) => {
          if (e.type === 'Layout::Page') { #{ result += 1 } }
        })
      `
      return result == 0 ? 1 : result
    end

    def page_of(uuid)
      return 1 if `#{@tree}.children_attributes[0] && #{@tree}.children_attributes[0].type !== 'Layout::Page'`

      unless @page_of_func
        `
          this.page_of_func = function page_of_(elements, uuid, page) {
            for(let i = 0; i < elements.length; i++) {
              let e = elements[i];
              if (e.type === 'Layout::Page')
                page++;

              if (e.id === uuid)
                return page;

              let page_ = page_of_(e.children_attributes, uuid, page);
              if (page_ != 0)
                return page_;
            }
            return 0
          }
        `
      end
      result = `#{@page_of_func}(#{@tree}.children_attributes, #{uuid}, 0)`
      return result == 0 ? 1 : result
    end

    def submission
      @submission ||= ::Form::Submission.new
    end

    def enabled?
      true
    end

    def method_missing(m)
    end

    def init_default_value(element, path)
      return unless path
      if element.default_value.nil?
        submission.delete(path)
      elsif element.default_value
        if element.type.start_with?('Association')
          submission.write_association(path, element.default_value)
        else
          submission.write_from_db(path, element.default_value)
        end
      end
    end
  end
end
