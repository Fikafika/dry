# frozen_string_literal: true

class AddReservedTables < ActiveRecord::Migration[8.0]

  def up
    mountable = []
    travel_in_constants(::Dynamic) do |c|
      if c < ::Dynamic::Mount && c.base_class == c
        mountable << c
      end
    end;1

    Dynamic::Schema.find_each do |schema|
      mountable.each do |c|
        table_name = old_build_reserved_table_name(schema.permalink, c.name)
        if ActiveRecord::Base.connection.data_sources.include?(table_name)
          klass_name = c.send(:dynamic_klass_base_name)
          next if schema.reserved_tables.where(klass_name: klass_name, table_name: table_name).exists?
          schema.reserved_tables.create!(klass_name: klass_name, table_name: table_name)
        end
      end
    end
  end

  def down
    #raise ActiveRecord::IrreversibleMigration
  end

  private

  def travel_in_constants(mod, done = Set.new, &block)
    return if done.include?(mod)
    done << mod
    mod.constants.each do |c|
      next if c.in?([
        :ClassMethods,
        :User, # why Dynamic::Permission::User ? a buggy autoload ?
        :PresenceInGroup, # TODO remove
      ])
      d = mod.const_get(c) rescue nil
      case d
      when ::Module
        yield(d)
        travel_in_constants(d, done, &block)
      end
    end
  end

  def old_build_reserved_table_name(permalink, klass_name)
    "d_#{permalink.gsub(/\-/,'_')}_r_#{klass_name.gsub(/^Dynamic::/, '').gsub(/::Base$/, '').gsub('::', '_').tableize}"
  end

end