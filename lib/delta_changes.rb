require "delta_changes/version"

module DeltaChanges
  module Extension
    def self.included(base)
      base.extend(ClassMethods)
      base.cattr_accessor :delta_changes_options
      base.attribute_method_suffix '_delta_changed?', '_delta_change', '_delta_was', '_delta_will_change!'
      if ::ActiveRecord.version < Gem::Version.new('5.2')
        base.send(:prepend, InstanceMethodsLegacy)
      else
        base.send(:prepend, InstanceMethods)
      end
    end

    module ClassMethods
      def delta_changes(options)
        self.delta_changes_options = options
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

            define_method("#{tracked_attribute}_delta_will_change!") do
              attribute_delta_will_change!(tracked_attribute)
            end
          end
        end
      end
    end

    # Rails < 5.2
    module InstanceMethodsLegacy
      # Wrap write_attribute to remember original attribute value.
      def write_attribute(attr, value)
        attr = attr.to_s

        unless self.class.delta_changes_options[:columns].include?(attr)
          return super(attr, value)
        end

        # The attribute already has an unsaved change.
        if delta_changed_attributes.include?(attr)
          old = delta_changed_attributes[attr]
          super(attr, value)
          delta_changed_attributes.delete(attr) unless delta_changes_field_changed?(attr, old, value)
        else
          old = respond_to?(:clone_attribute_value) ? clone_attribute_value(:read_attribute, attr) : read_attribute(attr).dup
          super(attr, value)
          delta_changed_attributes[attr] = old if delta_changes_field_changed?(attr, old, value)
        end
      end
    end

    module InstanceMethods
      def _write_attribute(attr, value)
         attr = attr.to_s

        unless self.class.delta_changes_options[:columns].include?(attr)
          return super(attr, value)
        end

        # The attribute already has an unsaved change.
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
        options[:from] || respond_to?(:clone_attribute_value) ? clone_attribute_value(:read_attribute, attr) : read_attribute(attr).dup
      end
      delta_changed_attributes[attr] = attribute_value
    end

    def delta_changes_field_changed?(attr, old, value)
      return true if !old.present? && value.present?

      if ActiveRecord::VERSION::STRING < '4.2.0'
        _field_changed?(attr, old, value)
      elsif ActiveRecord::VERSION::MAJOR < 5
        _field_changed?(attr, old)
      else
        self[attr] != old
      end
    end
  end
end
