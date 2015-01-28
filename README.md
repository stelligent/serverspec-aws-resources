# serverspec-aws-resources
Some serverspec resources to allow testing AWS resources.

## Installation (when you have previous serverspec experience)

The presumption here is that you have a "project" in which you have, or are intending to have
serverspec specifications to test infrastructure of some kind.  In other words, you've
run serverspec-init against that project.  For more information on serverspec, please see: http://serverspec.org/

0. AWS credentials are injected into the environment through the method of your choice (~/.aws/credentials or ENV vars like AWS_ACCESS_KEY_ID).
   These credentials need to have authorization to issue any of the describe/read AWS API calls e.g. ec2:Describe*

1. To make these aws types available for serverspec's use, add the line to your project's Gemfile:

        gem 'serverspec-aws-resources', :github => 'stelligent/serverspec-aws-resources'

2. Run bundle install

3. Add a require statement to spec_helper.rb in your project

        require 'serverspec-aws-resources'

Start hacking.... jump to [Usage](#Usage) for information on how to use these AWS resource types.

## Installation (when you have DO NOT have previous serverspec experience)

Please refer to http://serverspec.org/ for in-depth information on how to install and user serverspec.

I have found that when installing serverspec, it can clash with existing versions of RSpec.  Presuming that RVM is installed,
here is a list of commands to get everything bootstrapped.  For more information on rvm, please see: https://rvm.io/

    rvm use 2.1.1@fresh_serverspec --create

    mkdir test-project
    cd test-project

    cat - > Gemfile <<END
    source 'https://rubygems.org'

    gem 'serverspec'
    gem 'serverspec-aws-resources', :github => 'stelligent/serverspec-aws-resources'
    END

    bundle install

    serverspec-init

Answer the questions with: UNIX and exec.

Finally, add a requirement statement to spec/spec_helper.rb:

    require 'serverspec-aws-resources'

## Usage<a name="Usage"></a>

1. Create a file vpc_example_spec.rb under spec/default or spec/localhost or in the folder of whichever "host" you'd like to associate the test with.

2. Add the content:

        require_relative 'spec_helper'

        describe 'the example network' do

          describe vpc('vpc-12345') do
            it { should be_default_tenancy }
          end
        end

3. Run the command:

        bundle exec rake spec

   and you should see a failure that vpc-12345 doesn't exist:

        RuntimeError:
          vpc-12345 does not exist

5. Create a vpc and back-fill its id into vpc_example_spec in place of 12345, e.g. 64d123ff

6. Run the command:

        bundle exec rake spec

   and it should success with a message like:

        the example network
          vpc: vpc-64d123ff
            should be default tenancy

## Resources

What questions you can ask each resource should be fairly self-explanatory from examining the code per resource under lib/resources/*_resource.rb,
but here is a quick summary of what is currently implemented.

### vpc

#### basic predicates
* be_default_tenancy
* be_dedicated_tenancy
* be_available
* be_pending
* be_attached_to_an_internet_gateway
* be_attached_to_an_virtual_private_gateway

#### basic accessors
* cidr_block
* dhcp_options
* size

#### accessors that return other resources

* network_acls
    * this returns a NetworkAcls resource

* virtual_private_gateway
    * this returns a vpn_gateway resource

* subnets
* public_subnets
* natted_subnets
* private_subnets
    * these all return the subnets resource

* nats
* public_ec2_instances
* public_non_nat_ec2_instances
    * these all return array of ec2_instance resources

### subnets

* have_cidr_blocks
* size
* be_evenly_split_across_az(num_az)

### ec2_instance

* have_source_dest_checking_disabled
* have_elastic_ip
* have_ingress_rules?(expected_ingress_rules)
* have_egress_rules?(expected_egress_rules)

## Known Room for Improvment

The vpc resource doesn't support any predicates for peering, and it doesn't support predicates for testing network acl beyond
confirming a vpc has the default nacl set.

## Extending

be_something requires that something? method be defined on the resource object

have_some_attribute requires that has_some_attributed? method defined on the resource object

lib/resources/*_resource.rb should each contain the resource of with the obvious name
