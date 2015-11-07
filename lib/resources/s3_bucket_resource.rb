require 'aws-sdk-v1'
require 'serverspec'
require 'rspec'
require 'json'

module Serverspec
  module Type

    class S3Bucket < Base

      ##
      #
      # * *Args*    :
      #   - +bucket_name+ -> the name of the bucket to measure the properties of
      #
      def initialize(bucket_name)
        @bucket_name = bucket_name
      end

      ##
      # Try to wrap up actual calls to AWS SDK in as few calls as possibl (this one)
      # to allow some partial mocking to test this resource
      #
      # Likely don't want anyone outside of this object to call this???
      def content
        s3 = Aws::S3::Resource.new
        s3.bucket @bucket_name
      end

      ##
      # Is versioning enabled, or suspended, on the bucket?
      #
      def versioned?
        content.versioning.status == 'Enabled'
      end

      ##
      # Does the bucket back up a web site?
      #
      def website?
        begin
          content.website.error_document
          true
        rescue Aws::S3::Errors::NoSuchWebsiteConfiguration
          false
        end
      end

      ##
      # Is access logging enabled for this bucket?
      #
      def logging?
        logging_enabled = content.logging.logging_enabled
        not logging_enabled.nil?
      end

      def has_logging_target_bucket?(target_bucket_name)
        logging_enabled = content.logging.logging_enabled
        if logging_enabled.nil?
          false
        else
          logging_enabled[:target_bucket] == target_bucket_name
        end
      end

      def has_logging_prefix?(prefix)
        logging_enabled = content.logging.logging_enabled
        if logging_enabled.nil?
          false
        else
          logging_enabled[:target_prefix] == prefix
        end
      end

      ##
      # fought this a long while
      # just return an object that can compare toe hash or string and let
      # the caller do the vanilla rspec matcher for diffs and all that
      def policy
        begin
          policy_string = content.policy.policy
          Policy.new(policy_string)
        rescue Aws::S3::Errors::NoSuchBucketPolicy
          Policy.new('{}')
        end
      end

      def to_s
        "s3 bucket: #{@bucket_name}"
      end

      private

      def convert_bucket_policy_to_hash(bucket_policy)
        if bucket_policy.is_a? String
          JSON.parse(bucket_policy)
        elsif bucket_policy.is_a? Hash
          bucket_policy
        else
          raise ArgumentError.new "#{bucket_policy} must be String or Hash, not #{bucket_policy.class}"
        end
      end

      class Policy
        attr_accessor :actual_policy_string

        def initialize(policy_string)
          @actual_policy_string = policy_string
        end

        def ==(other_policy)
          if other_policy.is_a? Hash
            JSON.parse(@actual_policy_string) == other_policy
          elsif other_policy.is_a? String
            JSON.parse(@actual_policy_string) == JSON.parse(other_policy)
          else
            raise 'not a string or a hash'
          end
        end

        def inspect
          JSON.parse(@actual_policy_string).to_s
        end
      end
    end

    ##
    # Factory method to create the s3 bucket resource
    #
    # This is the method that is the entry point to bring up this resource as
    # a subject in a serverspec test
    def s3_bucket(bucket_name)
      S3Bucket.new(bucket_name)
    end
  end
end

include Serverspec::Type