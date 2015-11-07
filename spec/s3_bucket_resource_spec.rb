require 'spec_helper'

describe Serverspec::Type::S3Bucket do
  before(:each) do
    @mock_s3_bucket_resource = double('Aws::S3::Bucket')

    @mock_logging = double('Aws::S3::BucketLogging')
    allow(@mock_s3_bucket_resource).to receive(:logging)
                                   .and_return @mock_logging

    @mock_website = double('Aws::S3::BucketWebsite')
    allow(@mock_s3_bucket_resource).to receive(:website)
                                         .and_return @mock_website

    @mock_policy = double('Aws::S3::BucketPolicy')
    allow(@mock_s3_bucket_resource).to receive(:policy)
                                   .and_return @mock_policy

    @mock_versioning = double('Aws::S3::BucketVersioning')
    allow(@mock_s3_bucket_resource).to receive(:versioning)
                                   .and_return @mock_versioning

    @bucket_ss_resource = Serverspec::Type::S3Bucket.new 'bucketname'
    allow(@bucket_ss_resource).to receive(:content)
                              .and_return(@mock_s3_bucket_resource)
  end

  describe '#versioned?' do

    context 'versioning disabled' do
      before(:each) do
        allow(@mock_versioning).to receive(:status)
                               .and_return 'Suspended'
      end

      it 'returns false' do
        expect(@bucket_ss_resource.versioned?).to eq false
      end
    end

    context 'versioning enabled' do
      before(:each) do
        allow(@mock_versioning).to receive(:status)
                               .and_return 'Enabled'
      end

      it 'returns true' do
        expect(@bucket_ss_resource.versioned?).to eq true
      end
    end
  end

  describe '#website?' do

    context 'website disabled' do
      before(:each) do
        allow(@mock_website).to receive(:error_document)
                            .and_raise Aws::S3::Errors::NoSuchWebsiteConfiguration.new('dontcare1', 'dontcare2')
      end

      it 'returns false' do
        expect(@bucket_ss_resource.website?).to eq false
      end
    end

    context 'website enabled' do
      before(:each) do
        allow(@mock_website).to receive(:error_document)
                            .and_return Object.new
      end

      it 'returns true' do
        expect(@bucket_ss_resource.website?).to eq true
      end
    end
  end

  describe 'logging predicates' do

    context 'logging disabled' do
      before(:each) do
        allow(@mock_logging).to receive(:logging_enabled)
                            .and_return(nil)
      end

      describe '#logging?' do
        it 'returns false' do
          expect(@bucket_ss_resource.logging?).to eq false
        end
      end

    end

    context 'logging enabled' do
      before(:each) do
        allow(@mock_logging).to receive(:logging_enabled)
                            .and_return({target_prefix: 'some-prefix', target_bucket: 'loggingbucket'})

      end

      describe '#logging?' do
        it 'returns true' do
          expect(@bucket_ss_resource.logging?).to eq true
        end
      end

      describe '#has_logging_target_bucket?' do
        context 'target bucket is correct' do
          it 'returns false' do
            expect(@bucket_ss_resource.has_logging_target_bucket?('loggingbucket')).to eq true
          end
        end

        context 'target bucket is wrong' do
          it 'returns false' do
            expect(@bucket_ss_resource.has_logging_target_bucket?('loggingbucket1')).to eq false
          end
        end
      end

      describe '#has_logging_prefix?' do
        context 'prefix is correct' do
          it 'returns false' do
            expect(@bucket_ss_resource.has_logging_prefix?('some-prefix')).to eq true
          end
        end

        context 'prefix is wrong' do
          it 'returns false' do
            expect(@bucket_ss_resource.has_logging_prefix?('some-prefix1')).to eq false
          end
        end
      end
    end
  end

  describe '#policy' do

    context 'no policy' do
      before(:each) do
        allow(@mock_policy).to receive(:policy)
                           .and_raise(Aws::S3::Errors::NoSuchBucketPolicy.new('dontcare1','dontcare2'))
      end

      it 'returns false' do
        dummy_policy = <<-END
        {
          "Version":"2012-10-17",
          "Statement":[
            {
              "Sid":"AddCannedAcl",
              "Effect":"Allow",
              "Principal": {"AWS": ["arn:aws:iam::111122223333:root","arn:aws:iam::444455556666:root"]},
              "Action":["s3:PutObject","s3:PutObjectAcl"],
              "Resource":["arn:aws:s3:::examplebucket/*"],
              "Condition":{"StringEquals":{"s3:x-amz-acl":["public-read"]}}
            }
          ]
        }
        END
        expect(@bucket_ss_resource.policy).to_not eq dummy_policy
      end
    end

    context 'mismatched policy' do
      before(:each) do
        actual_policy = <<-END
        {
          "Version":"2012-10-17",
          "Statement":[
            {
              "Sid":"AddCannedAcl",
              "Effect":"Allow",
              "Principal": {"AWS": ["arn:aws:iam::111122223333:root","arn:aws:iam::444455556666:root"]},
              "Action":["s3:PutObject","s3:PutObjectAcl"],
              "Resource":["arn:aws:s3:::examplebucket2/*"]
            }
          ]
        }
        END

        allow(@mock_policy).to receive(:policy)
                           .and_return(actual_policy)
      end

      it 'returns false' do
        expected_policy = <<-END
        {
          "Version":"2012-10-17",
          "Statement":[
            {
              "Sid":"AddCannedAcl",
              "Effect":"Allow",
              "Principal": {"AWS": ["arn:aws:iam::111122223333:root","arn:aws:iam::444455556666:root"]},
              "Action":["s3:PutObject","s3:PutObjectAcl"],
              "Resource":["arn:aws:s3:::examplebucket/*"]
            }
          ]
        }
        END
        expect(@bucket_ss_resource.policy).to_not eq expected_policy
      end
    end

    context 'matched policy by string' do
      before(:each) do
        actual_policy = <<-END
        {
          "Version":"2012-10-17",
          "Statement":[
            {
              "Sid":"AddCannedAcl",
              "Effect":"Allow",
              "Principal": {"AWS": ["arn:aws:iam::111122223333:root","arn:aws:iam::444455556666:root"]},
              "Action":["s3:PutObject","s3:PutObjectAcl"],
              "Resource":["arn:aws:s3:::examplebucket/*"]
            }
          ]
        }
        END

        allow(@mock_policy).to receive(:policy)
                           .and_return(actual_policy)
      end

      it 'returns true' do
        expected_policy = <<-END
        {
          "Version":"2012-10-17",
          "Statement":[
            {
              "Sid":"AddCannedAcl",
              "Resource":["arn:aws:s3:::examplebucket/*"],
              "Effect":"Allow",
              "Principal": {"AWS": ["arn:aws:iam::111122223333:root","arn:aws:iam::444455556666:root"]},
              "Action":["s3:PutObject","s3:PutObjectAcl"]
            }
          ]
        }
        END
        expect(@bucket_ss_resource.policy).to eq expected_policy
      end
    end

    context 'matched policy by hash' do
      before(:each) do
        actual_policy = <<-END
        {
          "Version":"2012-10-17",
          "Statement":[
            {
              "Sid":"AddCannedAcl",
              "Effect":"Allow",
              "Principal": {"AWS": ["arn:aws:iam::111122223333:root","arn:aws:iam::444455556666:root"]},
              "Action":["s3:PutObject","s3:PutObjectAcl"],
              "Resource":["arn:aws:s3:::examplebucket/*"]
            }
          ]
        }
        END

        allow(@mock_policy).to receive(:policy)
                           .and_return(actual_policy)
      end

      #symbols versus strings!!!!!
      it 'returns false' do
        expected_policy = {
          'Version': '2012-10-17',
          'Statement':[
            {
              'Sid': 'AddCannedAcl',
              'Resource':['arn:aws:s3:::examplebucket/*'],
              'Effect': 'Allow',
              'Principal': {'AWS': %w(arn:aws:iam::111122223333:root arn:aws:iam::444455556666:root)},
              'Action': %w(s3:PutObject s3:PutObjectAcl)
            }
          ]
        }
        expect(@bucket_ss_resource.policy).to_not eq expected_policy
      end

      it 'returns true' do
        expected_policy = {
          'Version' => '2012-10-17',
          'Statement'=>[
            {
              'Sid'=> 'AddCannedAcl',
              'Resource'=>['arn:aws:s3:::examplebucket/*'],
              'Effect'=> 'Allow',
              'Principal'=> {'AWS' => %w(arn:aws:iam::111122223333:root arn:aws:iam::444455556666:root)},
              'Action'=> %w(s3:PutObject s3:PutObjectAcl)
            }
          ]
        }
        expect(@bucket_ss_resource.policy).to eq expected_policy
      end
    end
  end


end
