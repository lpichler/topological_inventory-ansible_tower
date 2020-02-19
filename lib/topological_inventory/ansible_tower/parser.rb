module TopologicalInventory::AnsibleTower
  class Parser < TopologicalInventory::Providers::Common::Collector::Parser
    require "topological_inventory/ansible_tower/parser/service_credential"
    require "topological_inventory/ansible_tower/parser/service_instance"
    require "topological_inventory/ansible_tower/parser/service_instance_node"
    require "topological_inventory/ansible_tower/parser/service_inventory"
    require "topological_inventory/ansible_tower/parser/service_plan"
    require "topological_inventory/ansible_tower/parser/service_offering"
    require "topological_inventory/ansible_tower/parser/service_offering_node"
    require "topological_inventory/ansible_tower/parser/service_credential_type"

    include TopologicalInventory::AnsibleTower::Parser::ServiceInstance
    include TopologicalInventory::AnsibleTower::Parser::ServiceInstanceNode
    include TopologicalInventory::AnsibleTower::Parser::ServiceInventory
    include TopologicalInventory::AnsibleTower::Parser::ServicePlan
    include TopologicalInventory::AnsibleTower::Parser::ServiceOffering
    include TopologicalInventory::AnsibleTower::Parser::ServiceOfferingNode
    include TopologicalInventory::AnsibleTower::Parser::ServiceCredential
    include TopologicalInventory::AnsibleTower::Parser::ServiceCredentialType

    def initialize(tower_url:)
      super()
      self.tower_url = if tower_url.to_s.index('http').nil?
                         File.join('https://', tower_url)
                       else
                         tower_url
                       end
    end

    def parse_base_item(entity)
      props = { :resource_timestamp => resource_timestamp }
      props[:name]              = entity.name    if entity.respond_to?(:name)
      props[:source_created_at] = entity.created if entity.respond_to?(:created)
      props
    end

    protected

    attr_accessor :tower_url
  end
end
