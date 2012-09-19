require "delta_changes/version"

module DeltaChanges
  module Extension
    def self.included(base)
      base.extend(ClassMethods)
      base.cattr_accessor :delta_changes_options
      base.attribute_method_suffix '_delta_changed?', '_delta_change', '_delta_was', '_delta_will_change!'
      base.alias_method_chain :write_attribute, :delta_changes
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
          class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
            def #{tracked_attribute}_delta_changed?
              attribute_delta_changed?('#{tracked_attribute}')
            end

            def #{tracked_attribute}_delta_change
              attribute_delta_change('#{tracked_attribute}')
            end

            def #{tracked_attribute}_delta_was
              attribute_delta_was('#{tracked_attribute}')
            end

            def #{tracked_attribute}_delta_will_change!
              attribute_delta_will_change!('#{tracked_attribute}')
            end
          RUBY
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
        options[:from] || clone_attribute_value(:read_attribute, attr)
      end
      delta_changed_attributes[attr] = attribute_value
    end

    # Wrap write_attribute to remember original attribute value.
    def write_attribute_with_delta_changes(attr, value)
      attr = attr.to_s

      if self.class.delta_changes_options[:columns].include?(attr)
        # The attribute already has an unsaved change.
        if delta_changed_attributes.include?(attr)
          old = delta_changed_attributes[attr]
          delta_changed_attributes.delete(attr) unless field_changed?(attr, old, value)
        else
          old = clone_attribute_value(:read_attribute, attr)
          delta_changed_attributes[attr] = old if field_changed?(attr, old, value)
        end
      end

      # Carry on.
      write_attribute_with_dirty(attr, value) # TODO this looks like it should be write_attribute_without_delta_changes
    end
  end
end
