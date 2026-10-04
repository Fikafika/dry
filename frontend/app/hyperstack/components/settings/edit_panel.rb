class ::Settings::EditPanel < ::Stackable::FormPanel
  include Hyperstack::Router::Helpers

  param :record
  param :path
  collect_other_params_as :others

  def content
    observe record if record
    if record.new_record? || !record.loading?
      super
    end
  end

  def header
    ::Stackable::Toolbar() do
      ::Stackable::PageHeader(title: record.new_record? ? I18n.t('shared.new') : (record.try(:human_name) || record&.name), back: back_location)
    end
  end

  def record_location
    return interpolate_path(path, {id: record.class.api_id(record)})
  end

  def back_location
    return path.gsub(/\/:id$/, '')
  end

  def children_list
    return if record.new_record?
    children = children_items
    return if children.empty?

    DIV class: 'row' do
      ::Stackable::PanelLinkList({
        location: record_location,
        items: children
      })
    end
  end

  def children_items
    return [] unless self.class.parent.respond_to?(:children_items)
    return self.class.parent.children_items
  end

  def form_footer
    DIV(class: 'pr-3 pl-3 pt-3') do
      Form::Footer()
    end
  end

end
