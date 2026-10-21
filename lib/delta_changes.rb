require "delta_changes/version"
require "active_record/version"

module DeltaChanges
  AR_GTE_82 = ActiveRecord.version >= Gem::Version.new("8.2.a")

  module Extension
    def self.included(base)
      base.extend(ClassMethods)
      base.cattr_accessor :delta_changes_options
      base.attribute_method_suffix '_delta_changed?', '_delta_change', '_delta_was', '_delta_will_change!'
      base.prepend(InstanceMethods)
    end

    module ClassMethods
      def delta_changes(options)
        self.delta_changes_options = options
        if AR_GTE_82
          # Default Rails 8.2+ setters generated before configuration will bypass DeltaChanges. Remove existing
          # attribute methods so they can be re-generated to call `_write_attribute` and be tracked.
          undefine_attribute_methods if options[:columns].any?
        end
        define_virtual_attribute_delta_methods
      end

      #
      # Provide for delta tracking of virtual (non-column) attributes.
      #
      def define_virtual_attribute_delta_methods
        delta_changes_options[:attributes].each do |tracked_attribute|
          class_eval do
            define_method("#{tracked_attribute}_delta_changed?") do
              attribute_delta_changed?(tracked_attribute)
            end

            define_method("#{tracked_attribute}_delta_change") do
              attribute_delta_change(tracked_attribute)
            end

            define_method("#{tracked_attribute}_delta_was") do
              attribute_delta_was(tracked_attribute)
            end

            define_method("#{tracked_attribute}_delta_will_change!") do |*args|
              attribute_delta_will_change!(tracked_attribute, *args)
            end
          end
        end
      end

      if AR_GTE_82
        # Rails calls `define_method_attribute=` to dynamically create assignment methods based on database columns.
        # These methods used to call `_write_attribute`, which called `@attributes.write_from_user`. Rails changed the
        # generated methods to call `@attributes.write_from_user` directly instead. This improved performance by
        # eliminating a readonly check at runtime, but it also bypasses DeltaChanges' tracking. To keep tracking
        # working, we define assignment methods to call `_write_attribute` again. We lose the performance improvement,
        # but we need it to make tracking work and it's no less-performant than the original Rails 8.1 behavior.
        #
        # Ref: https://github.com/rails/rails/commit/0f6c0a05e2064b56f759677d94f060f057d89c66
        def define_method_attribute=(canonical_name, owner:, **options)

          unless delta_changes_options && delta_changes_options[:columns].include?(canonical_name)
            # If a column isn't tracked, delegate setter method generation to Rails
            return super
          end

          as = options.fetch(:as, canonical_name)
          ActiveModel::AttributeMethods::AttrNames.define_attribute_accessor_method(
            canonical_name, writer: true,
          ) do |temp_method_name, attr_name_expr|
            owner.define_cached_method(temp_method_name, as: "#{as}=", namespace: :delta_changes) do |batch|
              batch << <<~RUBY
                def #{temp_method_name}(value)
                  _write_attribute(#{attr_name_expr}, value)
                end
              RUBY
            end
          end
        end
        private :define_method_attribute=
      end
    end

    module InstanceMethods
      def _write_attribute(attr, value)
         attr = attr.to_s

        unless self.class.delta_changes_options[:columns].include?(attr)
          return super(attr, value)
        end

        # The attribute already has a delta-tracked change.
        if delta_changed_attributes.include?(attr)
          old = delta_changed_attributes[attr]
          super(attr, value)
          delta_changed_attributes.delete(attr) unless delta_changes_field_changed?(attr, old, value)
        else
          old = read_attribute(attr).dup
          super(attr, value)
          delta_changed_attributes[attr] = old if delta_changes_field_changed?(attr, old, value)
        end
      end
    end

    def delta_changes
      delta_changed_attributes.keys.inject({}) { |h, attr| h[attr] = attribute_delta_change(attr); h }
    end

    def delta_changes?
      delta_changed_attributes.keys.present?
    end

    ####################################

    def reset_delta_changes!
      delta_changed_attributes.clear
    end

    private

    # Map of change attr => original value.
    def delta_changed_attributes
      @delta_changed_attributes ||= {}
    end

    # Handle *_delta_changed? for method_missing.
    def attribute_delta_changed?(attr)
      delta_changed_attributes.include?(attr)
    end

    # Handle *_delta_change for method_missing.
    def attribute_delta_change(attr)
      [delta_changed_attributes[attr], __send__(attr)] if attribute_delta_changed?(attr)
    end

    # Handle *_delta_was for method_missing.
    def attribute_delta_was(attr)
      attribute_delta_changed?(attr) ? delta_changed_attributes[attr] : __send__(attr)
    end

    # Handle <tt>*_will_change!</tt> for +method_missing+.
    def attribute_delta_will_change!(attr, options = {})
      attribute_value = if self.class.delta_changes_options[:attributes].include?(attr)
        value = send(attr)
        value.duplicable? ? value.clone : value
      else
        options[:from] || (respond_to?(:clone_attribute_value) ? clone_attribute_value(:read_attribute, attr) : read_attribute(attr).dup)
      end
      delta_changed_attributes[attr] = attribute_value
    end

    def delta_changes_field_changed?(attr, old, value)
      return true if !old.present? && value.present?

      self[attr] != old
    end
  end
end
