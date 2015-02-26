module SerialNumberField
  class Format < Redmine::FieldFormat::Unbounded
    NAME = 'serial_number'

    add NAME
    self.searchable_supported = true
    self.customized_class_names = %w(Issue)
    self.form_partial = 'custom_fields/formats/serial_number'

    field_attributes :target_on, :serial_number_format

    def formatted_value(view, custom_field, value, customized = nil, html = false)
      # TODO
      # valid format
    end

    def possible_values_options(custom_field, object=nil)
      [
        [],
        [::I18n.t('field_created_on'), 'created_on']
      ]
    end

    def edit_tag(view, tag_id, tag_name, custom_value, options={})
      # TODO
      # display: none
      view.text_field_tag(tag_name, custom_value.value, options.merge(:id => tag_id, :disabled => true))
    end

    def generate_value
      # TODO
    end

  end
end