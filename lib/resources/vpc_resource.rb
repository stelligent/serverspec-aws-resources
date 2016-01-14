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
              action: entry.rule_action
            }
          end
        end

        expected_rules_arr = [
          {rule_number: 100, protocol: "-1", port_range: nil, cidr_block: '0.0.0.0/0', action: "allow"},
          {rule_number: 32767,  protocol: "-1", port_range: nil, cidr_block: '0.0.0.0/0', action: "deny"},
          {rule_number: 100, protocol: "-1", port_range: nil, cidr_block: '0.0.0.0/0', action: "allow"},
          {rule_number: 32767, protocol: "-1", port_range: nil, cidr_block: '0.0.0.0/0', action: "deny"}
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
        @vpc = Aws::EC2::Vpc.new(vpc_id)
        raise "#{@vpc_id} does not exist" unless @vpc.exists?
        @vpc
      end

      def ec2_client
        Aws::EC2::Client.new  #TODO: FIGURE OUT HOW TO HANDLE REGION
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
        content.state == "available"
      end

      def pending?
        content.state == "pending"
      end

      def cidr_block
        content.cidr_block
      end

      def attached_to_an_internet_gateway?
        not content.internet_gateways.first.nil?
      end

      def attached_to_an_virtual_private_gateway?
        not ec2_client.describe_vpn_gateways.vpn_gateways.empty?
      end

      def virtual_private_gateway
        raise 'there is no virtual private gateway attached to vpc' unless attached_to_an_virtual_private_gateway?
        VPNGateway.new ec2_client.describe_vpn_gateways.vpn_gateways.first.vpn_gateway_id
      end

      def dhcp_options
        content.dhcp_options.dhcp_configurations
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

      #TODO: FIND A BETTER WAY TO EXPRESS THIS
      def nat_gateways
        default_routes = content.route_tables.collect {|rt| rt.routes.select {|r| r.destination_cidr_block=="0.0.0.0/0" }}
        default_routes.reject! {|route| route == []}
        default_routes.collect {|r| r[0].nat_gateway_id}.compact
      end

      def public_ec2_instances
        public_instances  = compute_public_instances
        public_instances.map { |instance| EC2Instance.new(instance.id) }
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
      #TODO:  Not sure this is working as intended.  Seems to only return the first private subnet found.
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
          if not route.gateway_id.nil? and route.gateway_id.start_with? 'igw'
            return true
          end
        end
        false
      end

      #TODO: Makes the assumption that you are using the a managed NAT Gateway
      def has_route_to_nat(subnet)
        route_table_for_subnet(subnet).routes.each do |route|
            return true unless route.nat_gateway_id.nil?
        end
        false
      end

      def route_table_for_subnet(subnet)
        content.route_tables.each do |route_table|
          route_table.associations.each do |association|
            unless association.subnet.nil?
              return route_table if association.subnet.id == subnet.id
            end
          end
        end
        raise 'should never fall through to here since all subnets have a route table'
      end

    end

    #this is how the resource is called out in a spec
    def vpc(vpc_id)
      VPC.new(vpc_id)
    end
  end
end



include Serverspec::Type