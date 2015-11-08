require 'serverspec_helper'

describe 'a vanilla bucket' do
  bucket_name = "vanillabucket#{Time.now.to_i}"

  before(:all) do
    @stack_name = stack(stack_name: 'vanilla',
                        path_to_stack: 'serverspec/localhost/s3_bucket/vanilla_bucket_cfndsl.rb',
                        bindings: { bucket_name: bucket_name })
  end

  describe s3_bucket(bucket_name) do
    it { should_not have_logging }
    it { should_not be_website }
    it { should_not be_versioned }

    its(:policy) { should eq Hash.new }
  end

  after(:all) do
    cleanup @stack_name unless @stack_name.nil?
  end
end

# describe s3_bucket('vanilla_bucket') do
#   it { should_not have_logging }
#   it { should_not be_website }
#   it { should_not be_versioned }
#
#   its(:policy) { should eq Hash.new }
# end
#
# describe s3_bucket('website_bucket') do
#   it { should have_website }
# end
#
# describe s3_bucket('vesrioning_bucket') do
#   it { should be_versioned }
# end
#
# describe s3_bucket('logging_bucket') do
#   it { should have_logging }
#   it { should have_logging_target_bucket 'super_cool_logging_bucket' }
#   it { should has_logging_prefix 'prefix_abc' }
# end
#
# describe s3_bucket('policy_bucket') do
#   its(:policy) do
#     should eq {
#
#            }
#   end
# end