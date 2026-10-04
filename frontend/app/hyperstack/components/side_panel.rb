# backtick_javascript: true

class SidePanel < HyperComponent
  param :title, default: nil
  param :id, default: '', type: String
  param :side, default: 'left', type: String
  param :backdrop, default: true, type: Boolean
  param :size, default: 'sm', type: String
  param :bg_color, default: 'light-yiq',  type: String
  param :className, default: nil
  param :under_expanding_side_bar, default: false

  fires :close
  fires :open

  render do
    DIV(
      id: id.to_s,
      class: "modal px-0 side-panel side-panel-#{size} side-panel-#{side} fade #{'pl-1' if side == 'right' } overflow-auto border-1 #{'under-expanding-side-bar' if under_expanding_side_bar}",
      role: 'dialog',
      'data-dismiss': 'modal',
      'data-backdrop': backdrop,
      'data-focus': false, # prevent unwanted blur in tinyMce
      'data-keyboard': false, # prevent close when press escape
    ) do
      DIV(class: "modal-dialog m-0 mw-100 modal-dialog float-#{side} shadow-sm", role: 'document') do
        DIV(class: "modal-content border-top-0 border-bottom-0 border-#{side}-0 rounded-0", style: {minHeight: '100vh'}) do
          if title
            DIV(class: 'modal-header') do
              H5(class: 'modal-title') do
                title
              end
            end
          end
          DIV(class: "modal-body p-0 bg-#{bg_color} #{className}") do
            children.render
          end
        end
      end
    end.on(:click) do
      focus
    end
  end

  before_unmount do
    self.jq_node.modal('hide')
  end

  after_mount do
    self.jq_node.on('hidden.bs.modal') do |e|
      close!
    end
    self.jq_node.on('show.bs.modal') do
      self.jq_node.add_class('overflow-hidden') if side == 'left' # prevent scrollbar
      focus
      open!
    end
    self.jq_node.on('shown.bs.modal') do
      self.jq_node.remove_class('overflow-hidden') if side == 'left' # prevent scrollbar
    end
  end

  after_update do
    self.jq_node.off('focus.bs.modal').on('focus.bs.modal') do
      focus
    end
  end

  def focus
    if under_expanding_side_bar
      ::Element[".side-panel-#{opposite}.under-expanding-side-bar"].css(zIndex: 1037)
      ::Element[".side-panel-#{side}.under-expanding-side-bar"].css(zIndex: 1038)
    end
  end

  def opposite
    side == 'left' ? 'right' : 'left'
  end

end
