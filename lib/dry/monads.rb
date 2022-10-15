# frozen_string_literal: true

require "concurrent/map"
require "zeitwerk"
require "dry/core"
require "dry/monads/constants"
require "dry/monads/errors"
require "dry/monads/registry"

module Dry
  # Common, idiomatic monads for Ruby
  #
  # @api public
  module Monads
    # @api private
    def self.loader
      @loader ||= Zeitwerk::Loader.new.tap do |loader|
        root = File.expand_path("..", __dir__)
        loader.tag = "dry-monads"
        loader.inflector = Zeitwerk::GemInflector.new("#{root}/dry-monads.rb")
        loader.push_dir(root)
        loader.ignore(
          "#{root}/dry-monads.rb",
          "#{root}/dry/monads/{all,constants,errors,registry,version}.rb",
          "#{root}/json/**/*.rb"
        )
      end
    end

    # @private
    def self.included(base)
      if all_loaded?
        base.include(*constructors)
      else
        raise "Load all monads first with require 'dry/monads/all'"
      end
    end

    # Build a module with cherry-picked monads.
    # It saves a bit of typing when you add multiple
    # monads to one class. Not loaded monads get loaded automatically.
    #
    # @example
    #   require 'dry/monads'
    #
    #   class CreateUser
    #     include Dry::Monads[:result, :do]
    #
    #     def initialize(repo, send_email)
    #       @repo = repo
    #       @send_email = send_email
    #     end
    #
    #     def call(name)
    #       if @repo.user_exist?(name)
    #         Failure(:user_exists)
    #       else
    #         user = yield @repo.add_user(name)
    #         yield @send_email.(user)
    #         Success(user)
    #       end
    #     end
    #   end
    #
    # @param [Array<Symbol>] monads
    # @return [Module]
    # @api public
    def self.[](*monads)
      monads.sort!
      @mixins.fetch_or_store(monads.hash) do
        monads.each { load_monad(_1) }
        mixins = monads.map { registry.fetch(_1) }
        ::Module.new { include(*mixins) }.freeze
      end
    end

    loader.setup
  end
end
