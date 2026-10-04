# frozen_string_literal: true
require 'progress_bar'

class NilifyBlankDynamicRecords < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |s|
      s.load
      s.klasses.each do |k|
        puts k.const_absolute_name
        scope = scope_for_klass(k.const, k.nilifiable_attributes)
        nilify_all(scope, k.nilifiable_attributes)
        if k.const.const_defined?(:Translation)
          scope = scope_for_klass(k.const::Translation, k.nilifiable_translated_attributes)
          nilify_all(scope, k.nilifiable_translated_attributes)
        end
      end
    end
  end

  def scope_for_klass(klass, nilifiable_attributes)
    first_where = true
    scope = klass
    nilifiable_attributes.each do |a|
      scope = first_where ? klass.where(a => '') : scope.or(klass.where(a => ''))
      first_where = false
    end
    return scope
  end

  def nilify_all(scope, nilifiable_attributes)
    progress = ProgressBar.new(scope.count)
    scope.find_each do |r|
      h = {}
      r.attributes.each do |a, v|
        next unless v == '' && nilifiable_attributes.include?(a)
        h[a] = nil
      end
      r.update(h) if h.any?
      progress.increment!
    end
  end

  def down
  end
end
