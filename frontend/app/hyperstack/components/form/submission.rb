require 'components/form'

class Form
  class Submission

    attr_accessor :values
    attr_accessor :associations
    attr_accessor :errors
    attr_accessor :check_important
    attr_accessor :status_code
    attr_accessor :data
    attr_accessor :disabled
    attr_accessor :original_values

    def initialize(*args)
      @values = {}
      @associations = {}
      @errors = {}.with_indifferent_access
      @data = {}.with_indifferent_access
      @disabled = {}
      @check_important = true
      @original_values = {}
      write_initial_params(args[0]) if args[0].is_a?(Hash)
    end

    def clean_klass_params!(klass, element_path) # TODO test
      values.keys.each do |path| # each or each_key will crash since we iterate on a hash that we are modifying
        next unless array_start_with?(path, element_path)
        k = path.last
        if !klass.attribute_names.include?(k) && !klass.reflect_on_association(k) && !klass.reflect_on_attachment(k) && !klass.globalize_accessor_names.include?(k)
          delete(path)
        end
      end
    end

    def page
      @page ||= 1
    end

    def page=(v)
      @page = v
    end

    def has_key?(path)
      values.has_key?(path) || associations.has_key?(path)
    end

    def read(path)
      r = values[path]
      r = associations[path] if r.nil?
      return r
    end

    def write(path, value) # TODO make it private and only use: write_from_user, write_from_db
      values[path] = value
      index = path[-2]

      if index.is_a?(Integer)
        associations[path[0...-2]] ||= []
        association_values = associations[path[0...-2]]
        attr = path.last
        association_values[index] ||= {}
        association_values[index][attr] = value
      end
    end

    def read_id(path)
      v = read(path) # TODO clarify read return type. It should not return an array for belongs_to
      case v
      when NilClass
        nil
      when ::String
        v
      when ::Hash
        v['id']
      when ::Array
        v.first.try(:[], 'id')
      else
        nil
      end
    end

    def read_ids(path)
      v = read(path) # TODO clarify read return type
      case v
      when NilClass
        []
      when ::Array
        r = []
        v.each do |e|
          if e.is_a?(::Hash)
            next if e['_destroy']
            r << e['id']
          else
            r << e
          end
        end
        r
      when ::String
        [v]
      when ::Hash
        [v['id']]
      else
        []
      end
    end

    def write_from_user(path, value)
      original_values[path] = read(path) if !original_values.has_key?(path)
      write(path, value)
    end

    def write_from_db(path, value)
      original_values.delete(path)
      write(path, value)
    end

    def was(path)
      original_values.has_key?(path) ? original_values[path] : values[path]
    end

    def restore(path)
      return unless original_values.has_key?(path)
      write_from_db(original_values[path])
    end

    def swap(path1, path2)
      i1 = path1.last
      i2 = path2.last

      # swap in associations
      assoc = read_association(path1[0...-1])
      return unless assoc
      v = assoc[i1]
      assoc[i1] = assoc[i2]
      assoc[i2] = v

      # swap in values
      i = path1.length - 1
      values.each do |path, v|
        if array_start_with?(path, path1)
          path[i] = i2
        elsif array_start_with?(path, path2)
          path[i] = i1
        end
      end
    end

    def params
      {}.with_indifferent_access
    end

    def destroy(path)
      write(path + ['_destroy'], 1)
    end

    def delete(path, association_min = nil)
      to_delete = []
      values.each do |p, v|
        to_delete << p if array_start_with?(p, path)
      end
      to_delete.each do |p|
        values.delete(p)
        associations.delete(p)
        if p[-2].is_a?(Integer)
          read_association(p[0...-2]).try(:[], p[-2])&.delete(p.last)
        end
      end

      if association_min # TODO should not be an optional param
        associations_to_delete = []
        associations.each do |p, values|
          next unless array_start_with?(p, path)
          min = association_min[p] || 0
          if values.length > min
            associations[p] = values[0...min] || []
          end
          associations_to_delete << p if associations[p].empty? && min == 0
        end

        associations_to_delete.each do |p|
          associations.delete(p)
        end
      end
    end

    def has_association?(path)
      associations.has_key?(path)
    end

    def write_association(path, values)
      associations[path] = values
    end

    def read_association(path, options = {})
      values = associations[path]
      return values
    end

    def write_association_values(path, values, force_cleanse = true)
      self.values.keep_if{|k, v| path != k[0..path.size - 1]} if force_cleanse
      values&.each_with_index do |attrs, i|
        attrs.each do |attr, value|
          self.values[path + [i, attr]] = value
        end
      end
    end

    def new_position(path)
      values = read_association(path)
      last = values&.sort_by{|v| v[:position] || 0}&.last
      return 0 unless last.try(:[], :position)
      return last[:position] + 1
    end

    def write_initial_params(params)
      raise 'Not implemented'
    end

    def disable(path)
      @disabled[path] = true
    end

    def enable(path)
      @disabled[path] = false
    end

    def descendant_of_disabled?(path)
      @disabled.keys.detect{|k| @disabled[k] && array_start_with?(path, k) }
    end

    private

    def array_start_with?(a, b)
      return false if b.size > a.size

      i = 0
      b.each do |el|
        return false if a[i] != el
        i += 1
      end

      true
    end

  end

  class DynamicFormSubmission < Submission

    attr_accessor :record_for_input_prefix

    def params
      result = {}.with_indifferent_access
      values.each do |path, value|
        polymorphic = value.is_a?(Hash)
        if path.length == 1
          result[path.last] = value
        else
          k = normalize_input_prefix(path, polymorphic)
          if polymorphic
            result[k] = value
          else
            result[k] ||= {}.with_indifferent_access
            result[k][path.last] = value
          end
        end
      end
      return result
    end

    def normalize_input_prefix(path, polymorphic = false)
      r = []
      path.each_with_index do |p, i|
        next if i == path.length - (polymorphic ? 0 : 1)
        next if p.is_a?(Integer)

        n = path[i + 1]
        if n.is_a?(Integer)
          r << "#{p}@#{n}"
        else
          r << "#{p}@0"
        end
      end
      return r.join('.')
    end

    def write_initial_params(params)
      params.each do |input_prefix, values|
        path = path_from_input_prefix(input_prefix)
        next unless path
        values.each do |k, v|
          write_from_db(path + [k], v)
        end
      end
    end

    def nested_errors(prefix_path) # TODO bidouillish, normalize error keys properly in dynamic-form
      return unless self.errors.any?
      r = []
      r2 = []
      prefix_path.each_with_index do |e, i|
        next if e.is_a?(Integer)
        if i == 0
          # bidouille
          r << e
          r2 << e
        else
          n = prefix_path[i + 1]
          r << "#{e}@#{n.is_a?(Integer) ? n : '0'}"
          r2 << ((n.is_a?(Integer) && n != 0) ? "#{e}@#{n}" : e)
        end
      end
      r = r.join('.')
      r2 = r2.join('.')
      if self.errors.has_key?(r)
        return self.errors[r]
      elsif self.errors.has_key?(r2)
        return self.errors[r2]
      end
      return nil
    end

    private

    def path_from_input_prefix(input_prefix)
      input_prefix.split(/\.|@/).map{|e| e =~ /\A\d+\z/ ? e.to_i : e }
    end

  end

  class RecordSubmission < Submission

    def params
      result = {}.with_indifferent_access
      values.each do |path, value|
        params = result
        path.each_with_index do |p, i|
          case p
          when Integer
            while params.length <= p
              params << {}.with_indifferent_access
            end
          when String, Symbol
            if path[i + 1].is_a?(Integer)
              p = "#{p}_attributes"
              params[p] ||= []
            else
              params[p] ||= {}.with_indifferent_access
            end
          end
          if i == path.length - 1
            params[p] = value
          else
            params = params[p]
          end
        end
      end
      return result
    end

    def write_initial_params(params, path_prefix = [])
      params.each do |k, values|
        next unless k.is_a?(String)
        if k.end_with?('_attributes')
          path = path_prefix + [k.gsub(/_attributes$/, '')]
          values.each_with_index do |v, i|
            write_initial_params(v, path + [i])
          end
        else
          if values.is_a?(Hash)
            write_initial_params(values, path_prefix + [k])
          else
            write_from_db(path_prefix + [k], values)
          end
        end
      end
    end

    def nested_errors(prefix_path)
      return unless self.errors.any?
      prefix_path_ = prefix_path[1..-1].map{|a| a.is_a?(Integer) ? "[#{a}]" : a}.join + '.' # TODO join properly
      result = {}
      self.errors.each do |k, v|
        next unless k.start_with?(prefix_path_)
        result[k.gsub(prefix_path_, '')] = v
      end
      return result.any? ? result : nil
    end

  end
end
