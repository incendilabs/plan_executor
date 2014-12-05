module Crucible
  module Tests
    module Assertions

      def assert(test, message="assertion failed, no message", data="")
        unless test
          raise AssertionException.new message, data
        end
      end

      def assert_equal(expected, actual, message="", data="")
        unless expected == actual
          message += " Expected: #{expected}, but found: #{actual}."
          raise AssertionException.new message, data
        end
      end

      def assert_response_ok(response)
        unless [200, 201].include? response.code
          raise AssertionException.new "Bad response code expected 200, 201, but found: #{response.code}", response.body
        end
      end

      def assert_response_gone(response)
        unless [410].include? response.code
          raise AssertionException.new "Bad response code expected 410, but found: #{response.code}", response.body
        end
      end

      def assert_response_not_found(response)
        unless [404].include? response.code
          raise AssertionException.new "Bad response code expected 404, but found: #{response.code}", response.body
        end
      end

      def assert_navigation_links(bundle)
        unless bundle.first_link && bundle.last_link && bundle.next_link
          raise AssertionException.new "Expecting first, next and last link to be present"
        end
      end

      def skip
        raise SkipException.new
      end

    end

    class AssertionException < Exception
      attr_accessor :data
      def initialize(message, data=nil)
        super(message)
        @data = data
      end
    end

    class SkipException < Exception
    end

  end
end