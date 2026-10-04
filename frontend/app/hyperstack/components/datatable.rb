# backtick_javascript: true

class Datatable < HyperComponent
  extend Native::Helpers

  class Api < Native::Object
    alias_native :draw
    alias_native :index

    def element
      ::Element.find(self.node.to_n)
    end

  end

  class Scroller < Api
    alias_native :measure, :measure, as: Api
  end

  class Column < Api
    alias_native :order, :order, as: Api
  end

  class Columns < Api
    alias_native :adjust, :adjust, as: Api

    def indexes
      `#{@native}[0]`
    end
  end

  class FixedColumns < Api
    alias_native :left
    alias_native :right

    def left=(value)
      ::Native.call(@native, 'left', ::Native.convert(value))
    end
    def right=(value)
      ::Native.call(@native, 'right', ::Native.convert(value))
    end
  end

  class Cell < Api
    alias_native :columns, :columns, as: Columns
  end

  class Rows < Api
    def indexes
      `#{@native}[0]`
    end
  end

  class Row < Api
  end

  alias_native :fixedColumns, :fixedColumns, as: FixedColumns
  alias_native :scroller, :scroller, as: Scroller
  alias_native :columns, :columns, as: Columns
  alias_native :column, :column, as: Column
  alias_native :cell, :cell, as: Cell
  alias_native :rows, :rows, as: Rows
  alias_native :row, :row, as: Row

  alias_native :draw
  alias_native :search
  alias_native :clear
  alias_native :destroy
  alias_native :colReorder
  alias_native :order
  #alias_native :get_nodes, :fnGetNodes

  alias_native :native_on, :on
  alias_native :native_off, :off

  def ajax_reload
    `#{@native}.ajax.reload()`
  end

  private

  def set_datatable_err_mode
    `$.fn.dataTable.ext.errMode = 'throw'`
  end

  def workaround_remove_child
    `$('.dataTables_wrapper').each(function() {
      if (!this.parentNode.originalRemoveChild) {
        this.parentNode.originalRemoveChild = this.removeChild;
        this.parentNode.removeChild = function(child) {
          var result;
          try {
            result = this.originalRemoveChild.apply(this, arguments);
          } catch(error) {
            console.warn('workaround removeChild crash: datatable has changed dom after react');
          }
          return result
        }
      }
    })`
  end

end
