require 'aws-sdk-v1'
require 'serverspec'

require_relative 'vpn_gateway_resource'
require_relative 'subnets_resource'
require_relative 'ec2_instance_resource'

module Serverspec
  module Type

    class NetworkAcls < Base

      def initialize(network_acls)
        @network_acls = network_acls
      end

      def has_default_rules?
        actual_rules_arr = []

        @network_acls.each do |network_acl|
          network_acl.entries.each do |entry|
            actual_rules_arr << {
              rule_number: entry.rule_number,
              protocol: entry.protocol,
              port_range: entry.port_range,
              cidr_block: entry.cidr_block,
              action: entry.action
            }
          end
        end

        expected_rules_arr = [
          {rule_number: 100, protocol: -1, port_range: nil, cidr_block: '0.0.0.0/0', action: :allow},
          {rule_number: 32767,  protocol: -1, port_range: nil, cidr_block: '0.0.0.0/0', action: :deny},
          {rule_number: 100, protocol: -1, port_range: nil, cidr_block: '0.0.0.0/0', action: :allow},
          {rule_number: 32767, protocol: -1, port_range: nil, cidr_block: '0.0.0.0/0', action: :deny}
        ]

        Set.new(actual_rules_arr) == Set.new(expected_rules_arr)
      end


      def size
        @network_acls.size
      end

    end

    class VPC < Base

      def initialize(vpc_id)
        raise 'must set a vpc_id' if vpc_id.nil?
        @vpc_id = vpc_id
      end

      def content
        @vpc = AWS::EC2.new.vpcs[@vpc_id]
        raise "#{@vpc_id} does not exist" unless @vpc.exists?
        @vpc
      end

      def to_s
        "vpc: #{@vpc_id}"
      end

      def default_tenancy?
        content.instance_tenancy == :default
      end

      def dedicated_tenancy?
        not default_tenancy?
      end

      def available?
        content.state == :available
      end

      def pending?
        content.state == :pending
      end

      def cidr_block
        content.cidr_block
      end

      def attached_to_an_internet_gateway?
        not content.internet_gateway.nil?
      end

      def attached_to_an_virtual_private_gateway?
        not content.vpn_gateway.nil?
      end

      def virtual_private_gateway
        raise 'there is no virtual private gateway attached to vpc' unless attached_to_an_virtual_private_gateway?
        VPNGateway.new content.vpn_gateway
      end

      def dhcp_options
        content.dhcp_options.configuration
      end

      def size
        compute_subnets.size
      end

      def network_acls
        NetworkAcls.new compute_network_acls
      end

      def subnets
        Subnets.new compute_subnets
      end

      def public_subnets
        Subnets.new compute_public_subnets
      end

      def natted_subnets
        Subnets.new compute_natted_subnets
      end

      def private_subnets
        Subnets.new compute_private_subnets
      end

      def nats
        nat_instances.map { |nat| EC2Instance.new(nat.id) }
      end

      def public_ec2_instances
        public_instances  = compute_public_instances
        public_instances.map { |instance| EC2Instance.new(instance.id) }
      end

      def public_non_nat_ec2_instances
        public_instances  = compute_public_instances
        result =  public_instances.select { |instance| instance unless nats_ids.include? instance.id }
        result.map { |instance| EC2Instance.new(instance.id) }
      end

      private

      def compute_public_instances
        compute_public_subnets.inject([]) { |instances, subnet| instances + collection_to_arr(subnet.instances) }
      end

      def collection_to_arr(collection)
        arr = []
        collection.each { |element| arr << element }
        arr
      end

      def compute_network_acls
        collection_to_arr(content.network_acls)
      end

      def compute_subnets
        collection_to_arr(content.subnets)
      end

      def compute_public_subnets
        subnet_arr = []
        compute_subnets.each { |subnet| subnet_arr << subnet if has_route_to_igw(subnet) }
        subnet_arr
      end

      def compute_natted_subnets
        subnet_arr = []
        compute_subnets.each { |subnet| subnet_arr << subnet if has_route_to_nat(subnet) }
        subnet_arr
      end

      #anything that isnt natted or igw
      #could be only local to vpc, or connected via a peering or vpn
      def compute_private_subnets
        private_subnet_ids = subnet_ids(compute_subnets) - subnet_ids(compute_public_subnets) - subnet_ids(compute_natted_subnets)
        private_subnets = []
        content.subnets.each { |subnet| private_subnets << subnet if private_subnet_ids.include? subnet.id }
        private_subnets
      end

      def subnet_ids(subnets)
        subnets.map { |subnet| subnet.subnet_id }
      end

      def has_route_to_igw(subnet)
        route_table_for_subnet(subnet).routes.each do |route|
          if not route.internet_gateway.nil? and route.internet_gateway.exists?
            return true
          end
        end
        false
      end

      def has_route_to_nat(subnet)
        route_table_for_subnet(subnet).routes.each do |route|
          unless route.instance.nil?
            return true if nats_ids.include? route.instance.id
          end
        end
        false
      end

      def route_table_for_subnet(subnet)

        content.route_tables.each do |route_table|
          route_table.subnets.each do |subnet_iter|
            if subnet_iter.subnet_id == subnet.subnet_id
              return route_table
            end
          end
        end
        raise 'should never fall through to here since all subnets have a route table'
      end

      def nat_instances
        content.instances.select { |instance| instance.image.name.match /^amzn-ami-vpc-nat.*/ }
      end


      def nats_ids
        nat_instances.map { |instance| instance.id }
      end

    end

    #this is how the resource is called out in a spec
    def vpc(vpc_id)
      VPC.new(vpc_id)
    end
  end
end



include Serverspec::Type