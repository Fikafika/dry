class Crm
  module Filters
    module Merge

      def merge(base, to_merge)
        return simplify(merge_normalized(normalize(base), normalize(to_merge)))
      end

      private

      def merge_normalized(base, to_merge) # assume arguments are normalized
        raise "arguments are not hashs" unless base.is_a?(Hash) && to_merge.is_a?(Hash)

        if has_op?(base) && !has_op?(to_merge)
          return merge_normalized(base, {'and' => [to_merge]})
        elsif !has_op?(base) && has_op?(to_merge)
          return merge_normalized({'and' => [base]}, to_merge)
        elsif !has_op?(base) && !has_op?(to_merge)
          return merge_normalized({'and' => [base]}, {'and' => [to_merge]})
        else
          base_op = op_from_hash(base)
          to_merge_op = op_from_hash(to_merge)
          if base_op == to_merge_op
            op = base_op
            result = {}
            result[op] = base[op].deep_dup + to_merge[op].deep_dup
            return result
          else
            if base_op == 'and'
              result = base.deep_dup
              result[base_op] << to_merge.deep_dup
              return result
            else
              result = {'and' => []}
              result['and'] << base.deep_dup
              result['and'] << to_merge.deep_dup
              return result
            end
          end
        end

      end

    end
  end
end
