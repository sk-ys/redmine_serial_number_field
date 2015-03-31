module SerialNumberField
  class Format < Redmine::FieldFormat::Base
    NAME = 'serial_number'

    add NAME
    self.searchable_supported = true
    self.customized_class_names = %w(Issue)
    self.form_partial = 'custom_fields/formats/serial_number'

    MATCHERS = {
      :TOW_DIGIT_NUMBER => /\d{2}/,
      :FOUR_DIGIT_NUMBER => /\d{4}/,
      :FORMAT_WRAPPER => /\{(.+?)\}/
    }

    DATE_FORMATS = {
      :'yyyy' => { :strftime => '%Y', :financial_year => false, :regexp => MATCHERS[:FOUR_DIGIT_NUMBER] },
      :'yy'   => { :strftime => '%y', :financial_year => false, :regexp => MATCHERS[:TOW_DIGIT_NUMBER] },
      :'YYYY' => { :strftime => '%Y', :financial_year => true, :regexp => MATCHERS[:FOUR_DIGIT_NUMBER] },
      :'YY'   => { :strftime => '%y', :financial_year => true, :regexp => MATCHERS[:TOW_DIGIT_NUMBER] }
    }

    def validate_custom_field(custom_field)
      value = custom_field.regexp
      errors = []

      errors << [:regexp, :end_must_numeric_format_in_serial_number] unless value =~ /\{0+\}\Z/
      replace_format_value(custom_field) do |format_value|
        unless format_value =~ /\A0+\Z/
          errors << [:regexp, :invalid_format_in_serial_number] unless date_format_keys.include?(format_value)
        end
      end

      errors.uniq
    end

    def generate_value(custom_field, issue)
      datetime = issue.created_on.to_datetime || DateTime.now
      value = max_custom_value(custom_field, issue, datetime)

      if value.present?
        value.next
      else
        generate_first_value(custom_field, datetime)
      end
    end

    private

      def date_format_keys
        DATE_FORMATS.stringify_keys.keys
      end

      def max_custom_value(custom_field, issue, datetime)
        matcher = generate_matcher(custom_field, datetime)
        custom_values = custom_field.custom_values.where(
          customized_id: issue.project.issues.map(&:id)).map(&:value)

        custom_values.select { |value| value =~ matcher }.sort.last
      end

      def replace_format_value(custom_field)
        if block_given?
          custom_field.regexp.gsub(MATCHERS[:FORMAT_WRAPPER]) do |format_value_with_brace|
            yield($1.clone)
          end
        end
      end

      def generate_matcher(custom_field, datetime)
        matcher_str = replace_format_value(custom_field) do |format_value|
          if date_format_keys.include?(format_value)
            generate_date_value(format_value, datetime)
          else
            generate_number_matcher(format_value)
          end
        end

        Regexp.new(matcher_str)
      end

      def generate_number_matcher(format_value)
        ['\d', '{', format_value.size.to_s, '}'].join
      end

      def generate_first_value(custom_field, datetime)
        replace_format_value(custom_field) do |format_value|
          if date_format_keys.include?(format_value)
            generate_date_value(format_value, datetime)
          else
            generate_number_value(format_value)
          end
        end
      end

      def generate_date_value(format_value, datetime)
        parse_conf = DATE_FORMATS[format_value.to_sym]
        if parse_conf.key?(:financial_year) && parse_conf[:financial_year]
          DateTime.fiscal_zone = :japan
          datetime = datetime.beginning_of_financial_year
        end

        datetime.strftime(parse_conf[:strftime])
      end

      def generate_number_value(format_value)
        '1'.rjust(format_value.size, '0')
      end

  end
end
