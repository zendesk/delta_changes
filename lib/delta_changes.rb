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

    def delta_changed
      delta_changed_attributes.keys
    end

    def delta_changes
      delta_changed.inject({}) { |h, attr| h[attr] = attribute_delta_change(attr); h }
    end

    ####################################

    # Reset attribute changes
    def reset_delta_changes
      delta_changed_attributes.clear
    end

    def attributes_changed?
      !delta_changed_attributes.empty?
    end

    def was(field)
      self.send(field.to_s + '_delta_was')
    end

    def updated?(field)
      self.send(field.to_s + '_delta_changed?')
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
      write_attribute_with_dirty(attr, value)
    end

    def field_changed?(attr, old, value)
      if column = column_for_attribute(attr)
        if column.type == :integer && column.null && (old.nil? || old == 0)
          # For nullable integer columns, NULL gets stored in database for blank (i.e. '') values.
          # Hence we don't record it as a change if the value changes from nil to ''.
          # If an old value of 0 is set to '' we want this to get changed to nil as otherwise it'll
          # be typecast back to 0 (''.to_i => 0)
          value = nil if value.blank?
        else
          value = column.type_cast(value)
        end
      end

      if column && column.type == :integer
        old != column.type_cast(value)
      else
        old != value
      end
    end
  end
end
