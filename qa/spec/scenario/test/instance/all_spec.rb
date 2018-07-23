describe QA::Scenario::Test::Instance::All do
  context '#perform' do
    let(:arguments) { spy('Runtime::Scenario') }
    let(:release) { spy('Runtime::Release') }
    let(:runner) { spy('Specs::Runner') }

    before do
      stub_const('QA::Runtime::Release', release)
      stub_const('QA::Runtime::Scenario', arguments)
      stub_const('QA::Specs::Runner', runner)

      allow(runner).to receive(:perform).and_yield(runner)
    end

    it 'runs smoke tests'

    it 'sets an address of the subject' do
      subject.perform("hello")

      expect(arguments).to have_received(:define)
        .with(:gitlab_address, "hello")
    end

    context 'no paths' do
      it 'should call runner with default arguments' do
        subject.perform("test")

        expect(runner).to have_received(:options=)
          .with(::File.expand_path('../../../../qa/scenario/specs/features', __dir__))
      end
    end

    context 'specifying paths' do
      it 'should call runner with paths' do
        subject.perform('test', 'path1', 'path2')

        expect(runner).to have_received(:options=).with(%w[path1 path2])
      end
    end
  end
end
