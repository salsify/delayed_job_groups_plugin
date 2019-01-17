# frozen_string_literal: true

module Delayed
  module JobGroups
    module YamlLoader
      def self.load(yaml)
        return yaml unless yaml.is_a?(String) && /^---/.match?(yaml)
        YAML.load_dj(yaml)
      end

      def self.dump(object)
        return if object.nil?
        YAML.dump(object)
      end
    end
  end
end
