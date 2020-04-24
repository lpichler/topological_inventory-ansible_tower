require "manageiq-messaging"
require "topological_inventory/ansible_tower/logging"
require "topological_inventory/ansible_tower/operations/processor"
require "topological_inventory/ansible_tower/operations/source"
require "topological_inventory/providers/common/heartbeat"

module TopologicalInventory
  module AnsibleTower
    module Operations
      class Worker
        include Logging
        include TopologicalInventory::Providers::Common::HeartbeatQueue

        def initialize(messaging_client_opts = {})
          self.messaging_client_opts = default_messaging_opts.merge(messaging_client_opts)

          self.current_heartbeat = heartbeat('operations')
        end

        def run
          # Open a connection to the messaging service
          client = ManageIQ::Messaging::Client.open(messaging_client_opts)

          logger.info("Topological Inventory AnsibleTower Operations worker started...")
          client.subscribe_topic(queue_opts) do |message|
            log_with(message.payload&.fetch_path('request_context','x-rh-insights-request-id')) do
              model, method = message.message.to_s.split(".")
              logger.info("Received message #{model}##{method}, #{message.payload}")

              current_heartbeat.run_in_parallel_with do
                process_message(message)
              end
            end
          end
        rescue => err
          logger.error("#{err.cause}\n#{err.backtrace.join("\n")}")
        ensure
          client&.close
        end

        def self.default_messaging_opts
          {
              :protocol   => :Kafka,
              :client_ref => "topological-inventory-operations-ansible-tower",
              :group_ref  => "topological-inventory-operations-ansible-tower"
          }
        end

        private

        attr_accessor :messaging_client_opts, :current_heartbeat

        def process_message(message)
          Processor.process!(message)
        rescue StandardError => err
          model, method = message.message.to_s.split(".")
          task_id = message.payload&.fetch_path('params','task_id')
          logger.error("#{model}##{method}: Task(id: #{task_id}) #{err.cause}\n#{err}\n#{err.backtrace.join("\n")}")
          raise
        ensure
          message.ack
        end

        def queue_name
          "platform.topological-inventory.operations-ansible-tower"
        end

        def queue_opts
          {
            :auto_ack    => false,
            :max_bytes   => 50_000,
            :service     => queue_name,
            :persist_ref => "topological-inventory-operations-ansible-tower"
          }
        end

        def default_messaging_opts
          self.class.default_messaging_opts
        end
      end
    end
  end
end
