# frozen_string_literal: true

module RuboCop
  module Cop
    class RubyInterpolationInTranslation < RuboCop::Cop::Cop
      MSG = "Don't use ruby interpolation \#{} inside translated strings, instead use \%{}"

      TRANSLATION_METHODS = %w[:_ :s_ :N_ :n_].join(' ').freeze
      RUBY_INTERPOLATION_REGEX = /.*\#\{.*\}/

      def_node_matcher :translation_method?, <<~PATTERN
          (send nil? ${#{TRANSLATION_METHODS}} $(dstr ...) ...)
      PATTERN

      def_node_matcher :plural_translation_method?, <<~PATTERN
          (send nil? ${:n_} $(str ...) $(dstr ...) ...)
      PATTERN

      def on_send(node)
        matches = translation_method?(node) || plural_translation_method?(node)
        return unless matches

        arguments = matches.last.to_a

        if arguments.any? { |argument| argument.type != :str }
          add_offense(node, location: :expression, message: MSG)
        end
      end
    end
  end
end
