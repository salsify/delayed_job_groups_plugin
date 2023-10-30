# frozen_string_literal: true

# This can be removed when we only support Rails 7.1+ because Rails 7.1 add a serialization
# option for unsafe YAML loads
module Delayed
  module JobGroups
    module YamlLoader
      def self.load(yaml)
        return yaml unless yaml.is_a?(String) && /^---/.match(yaml)

        YAML.load_dj(yaml)
      end

      def self.dump(object)
        return if object.nil?

        YAML.dump(object)
      end
    end
  end
end
