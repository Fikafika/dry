# this file is a copy of dynamic-filters/lib/dynamic/filters/normalization.rb
# it is tested in dynamic-filters gem

class Crm
  module Filters
    module Normalization

      def simplify(hash)
        result = simplify_(hash)
        result = nil if is_base_hash?(hash)
        return result
      end

      def normalize(hash)
        return unless hash.class == Hash
        return dereorganize(hash)
      end

      def hash_to_array(hash, normalize: true, convert_attr: nil)
        return [] unless hash.class == Hash
        hash = normalize(hash) if normalize
        return [] unless hash
        hash = {'and' => [hash]} unless has_op?(hash) # should be part of normalization ?
        return normalized_to_array(hash, convert_attr: convert_attr)
      end

      def array_to_hash(array, convert_attr: nil)
        return nil unless array.class == Array
        return array_to_hash_(array, convert_attr: convert_attr)
      end

      def nested_array_to_hash(array, variable = nil)
        return unless array&.any?

        result = nil
        or_count = 0
        and_count = 0

        array.each_with_index do |a, i|
          h = {a[1] => a[2]}
          h = {variable => h} if variable

          if i == 0
            result = h
          else
            case a[0]
            when 'or'
              or_count += 1
              and_count = 0 # reset
              if or_count == 1
                result = {'or' => [result]}
              end
            when 'and'
              and_count += 1
              if and_count == 1
                if or_count == 0
                  result = {'and' => [result]}
                else
                  if result['or'][or_count]
                    result['or'][or_count] = {'and' => [result['or'][or_count]]}
                  else
                    result['or'][or_count]['and'] = []
                  end
                end
              end
            end

            if or_count != 0 && and_count != 0
              result['or'][or_count]['and'].push(h)
            elsif or_count == 0
              result['and'].push(h)
            else
              result['or'].push(h)
            end
          end
        end

        return result
      end

      private

      def simplify_(hash)
        op = op_from_hash(hash)
        if op
          if hash[op].length == 1
            return simplify_(hash[op][0])
          else
            return reorganize(hash, op)
          end
        end
        return hash
      end

      def op_from_hash(hash)
        return hash.keys.detect{|k| k == 'and' || k == 'or'}
      end

      def has_op?(hash)
        hash.class == Hash && (hash.has_key?('and') || hash.has_key?('or'))
      end

      def is_base_hash?(hash)
        h = hash
        while true
          return false unless has_op?(h)
          a = h[h.keys.first]
          return true if a.length == 0
          h = a.first
        end
        return true
      end

      def reorganize(hash, op)
        array = hash[op].map do |a|
          simplify_(a)
        end
        key = uniq_key(array)
        if key
          return {key => {op => array.map{|a| a.values }.flatten}}
        else
          if op == 'and'
            return compact_and(array)
          else
            return {op => array}
          end
        end
      end

      def uniq_key(array)
        current_key = nil
        array.each do |a|
          next unless a.class == Hash
          a.keys.each do |k|
            return nil if k == 'and' || k == 'or'
            return nil if !current_key.nil? && current_key != k
            current_key = k
          end
        end
        return current_key
      end

      def compact_and(array)
        result = {}
        not_possible = false
        array.each do |a|
          break if not_possible
          if has_op?(a)
            not_possible = true
            break
          end
          a.each do |k, v|
            if result.has_key?(k)
              not_possible = true
              result = {'and' => array}
              break
            else
              result[k] = v
            end
          end
        end
        if not_possible
          return {'and' => array }
        else
          return result
        end
      end

      def dereorganize(hash, attr = nil)
        if has_op?(hash)
          if attr
            return hash
          else
            op = op_from_hash(hash)
            r = dereorganize_array(hash[op], attr)
            return {op => r}
          end
        elsif hash.keys.length <= 1
          if hash.values.detect{|v| has_op?(v) }
            result = {}
            hash.each do |k, v|
              v.each do |op, filters|
                result[op] = dereorganize_array(filters, k)
              end
            end
            return result
          else
            return hash
          end
        else
          return hash if hash.empty?
          result = {'and' => []}
          hash.each do |k, v|
            d = dereorganize({k => v}, k)
            result['and'] << d
          end
          return result
        end
      end

      def dereorganize_array(array, attr)
        result = array.map do |f|
          if attr
            t = dereorganize({attr => f}, attr)
          else
            t = dereorganize(f, attr)
          end

          op = op_from_hash(t)
          if op && t[op].length == 1
            t[op].first
          else
            t
          end
        end

        if result.detect{|v| has_op?(v) }
          # correct missing operator
          result = result.map do |r|
            has_op?(r) ? r : {'and' => [r]}
          end
        end

        return result
      end

      def find_attr(o)
        case o
        when ::Array
          o.each do |e|
            n = find_attr(e)
            return n if n
          end
        when ::Hash
          o.each do |k, v|
            if k != 'and' && k != 'or'
              return k
            else
              n = find_attr(v)
              return n if n
            end
          end
        end
        return nil
      end

      def normalized_to_array(hash, convert_attr: nil)
        return [] unless hash.class == Hash
        return normalized_to_array_(hash, convert_attr)
      end

      def normalized_to_array_(hash, convert_attr, result = [], prev = {})
        hash.each do |op, o|
          o.each_with_index do |v, i|
            attr = find_attr(v)
            if attr
              if has_op?(v)
                prev[:op] = op
                prev[:i] = i
                normalized_to_array_(v, convert_attr, result, prev)
              else
                filter_operator = v[attr].keys.first
                filter_value = v[attr].values.first

                attr = convert_attr.call(attr) if convert_attr

                if result.empty?
                  op_ = 'and'
                else
                  op_ = (i == 0) ? (prev[:op] || op) : op
                end

                if prev[:filters] && attr == prev[:filters][1]
                  prev[:i] = nil
                  prev[:filters][2] << [op_, filter_operator, filter_value]
                else
                  if op_ == 'and' && prev[:filters] && prev[:filters][0] == 'or'
                    result << ['separator']
                  end
                  a = [op_, attr, [['and', filter_operator, filter_value]]]
                  result << a
                  prev[:filters] = a
                end
              end
            else
              # ?
            end
          end
        end
        return result
      end

      def array_to_hash_(array, convert_attr: nil)
        hash = {}
        hash = {'or' => []}
        or_count = 0

        array.each_with_index do |a, i|

          if a[0] == 'separator'
            hash = {'or' => [{'and' => [hash]}]}
            or_count = 0
          end

          h = nested_array_to_hash(a[2])
          next unless h

          or_count += 1 if i != 0 && a[0] == 'or'
          hash['or'][or_count] ||= {}
          hash['or'][or_count]['and'] ||= []

          attr = convert_attr ? convert_attr.call(a[1]) : a[1]

          hash['or'][or_count]['and'] << {attr => h}
        end

        return simplify(hash)
      end

    end
  end
end
