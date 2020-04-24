RSpec.describe TopologicalInventory::AnsibleTower::Collector do
  let(:source_uid) { '7b901ca3-5414-4476-8d48-a722c1493de0' }
  let(:logger) { double('Logger').as_null_object }
  let(:client) { double('Ingress API Client')}

  subject do
    metrics = double("Metrics")
    allow(metrics).to receive(:record_error)
    described_class.new(source_uid,
                        'tower.example.com',
                        'user',
                        'passwd',
                        metrics, poll_time: 0)
  end

  let(:connection) { double("Connection") }

  let(:entity_types) { subject.send(:service_catalog_entity_types) }

  before do
    allow(subject).to receive(:logger).and_return(logger)
    allow(subject).to receive(:ingress_api_client).and_return(client)
    parser = double(TopologicalInventory::AnsibleTower::Parser)
    allow(parser).to receive(:collections).and_return({})

    allow(subject).to receive(:sweep_inventory)
    allow(TopologicalInventory::AnsibleTower::Parser).to receive(:new).with(tower_url: 'tower.example.com').and_return(parser)

    entity_types.each do |entity|
      allow(subject).to receive(:connection_for_entity_type).with(entity).and_return(connection)
    end
  end

  it "calls heartbeat method during collection" do
    entity_types.each do |entity|
      method = "get_#{entity}"
      allow(subject).to receive(method).with(connection).and_return([])
    end

    allow(subject).to receive(:sleep).with(0) do |_|
      subject.stop
    end

    expect(subject.send(:heartbeat_queue)).to receive(:run_thread_with_timeout).exactly(8)

    subject.collect!
  end
end
