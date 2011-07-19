require 'ransack/visitor'

module Ransack
  class Context
    attr_reader :search, :object, :klass, :base, :engine, :arel_visitor
    attr_accessor :auth_object

    class << self

      def for(object)
        context = Class === object ? for_class(object) : for_object(object)
        context or raise ArgumentError, "Don't know what context to use for #{object}"
      end

      def for_class(klass)
        if klass < ActiveRecord::Base
          Adapters::ActiveRecord::Context.new(klass)
        end
      end

      def for_object(object)
        case object
        when ActiveRecord::Relation
          Adapters::ActiveRecord::Context.new(object.klass)
        end
      end

    end

    def initialize(object)
      @object = object.scoped
      @klass = @object.klass
      @join_dependency = join_dependency(@object)
      @base = @join_dependency.join_base
      @engine = @base.arel_engine
      @arel_visitor = Arel::Visitors.visitor_for @engine
      @default_table = Arel::Table.new(@base.table_name, :as => @base.aliased_table_name, :engine => @engine)
      @bind_pairs = Hash.new do |hash, key|
        parent, attr_name = get_parent_and_attribute_name(key.to_s)
        if parent && attr_name
          hash[key] = [parent, attr_name]
        end
      end
    end

    # Convert a string representing a chain of associations and an attribute
    # into the attribute itself
    def contextualize(str)
      parent, attr_name = @bind_pairs[str]
      table_for(parent)[attr_name]
    end

    def bind(object, str)
      object.parent, object.attr_name = @bind_pairs[str]
    end

    def traverse(str, base = @base)
      str ||= ''

      if (segments = str.split(/_/)).size > 0
        association_parts = []
        found_assoc = nil
        while !found_assoc && segments.size > 0 && association_parts << segments.shift do
          # Strip the _of_Model_type text from the association name, but hold
          # onto it in klass, for use as the next base
          assoc, klass = unpolymorphize_association(association_parts.join('_'))
          if found_assoc = get_association(assoc, base)
            base = traverse(segments.join('_'), klass || found_assoc.klass)
          end
        end
        raise UntraversableAssociationError, "No association matches #{str}" unless found_assoc
      end

      klassify(base)
    end

    def association_path(str, base = @base)
      base = klassify(base)
      str ||= ''
      path = []
      segments = str.split(/_/)
      association_parts = []
      if (segments = str.split(/_/)).size > 0
        while segments.size > 0 && !base.columns_hash[segments.join('_')] && association_parts << segments.shift do
          assoc, klass = unpolymorphize_association(association_parts.join('_'))
          if found_assoc = get_association(assoc, base)
            path += association_parts
            association_parts = []
            base = klassify(klass || found_assoc)
          end
        end
      end

      path.join('_')
    end

    def unpolymorphize_association(str)
      if (match = str.match(/_of_(.+?)_type$/))
        [match.pre_match, Kernel.const_get(match.captures.first)]
      else
        [str, nil]
      end
    end

    def ransackable_attribute?(str, klass)
      klass.ransackable_attributes(auth_object).include? str
    end

    def ransackable_association?(str, klass)
      klass.ransackable_associations(auth_object).include? str
    end

    def searchable_attributes(str = '')
      traverse(str).ransackable_attributes(auth_object)
    end

    def searchable_associations(str = '')
      traverse(str).ransackable_associations(auth_object)
    end

  end
end