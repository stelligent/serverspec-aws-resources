module Serverspec
  module Type

    class S3Bucket < Base

      def initialize(bucket_name)
        @bucket_name = bucket_name
      end

      def content
        s3 = AWS::S3.new
        s3.buckets[@bucket_name]
      end

      def versioned?
        content.versioning_state == :enabled
      end

      def website?
        content.website?
      end

      def to_s
        "s3 bucket: #{@bucket_name}"
      end
    end

    #this is how the resource is called out in a spec
    def s3_bucket(bucket_name)
      S3Bucket.new(bucket_name)
    end
  end
end

include Serverspec::Type