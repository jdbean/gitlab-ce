require 'fast_spec_helper'

require_dependency 'active_model'

describe Gitlab::Ci::Config do
  let(:config) do
    described_class.new(yml)
  end

  context 'when config is valid' do
    let(:yml) do
      <<-EOS
        image: ruby:2.2

        rspec:
          script:
            - gem install rspec
            - rspec
      EOS
    end

    describe '#to_hash' do
      it 'returns hash created from string' do
        hash = {
          image: 'ruby:2.2',
          rspec: {
            script: ['gem install rspec',
                     'rspec']
          }
        }

        expect(config.to_hash).to eq hash
      end

      describe '#valid?' do
        it 'is valid' do
          expect(config).to be_valid
        end

        it 'has no errors' do
          expect(config.errors).to be_empty
        end
      end
    end
  end

  context 'when using extendable hash' do
    let(:yml) do
      <<-EOS
        image: ruby:2.2

        rspec:
          script: rspec

        test:
          extends: rspec
          image: ruby:alpine
      EOS
    end

    it 'correctly extends the hash' do
      hash = {
        image: 'ruby:2.2',
        rspec: { script: 'rspec' },
        test: {
          extends: 'rspec',
          image: 'ruby:alpine',
          script: 'rspec'
        }
      }

      expect(config).to be_valid
      expect(config.to_hash).to eq hash
    end
  end

  context 'when config is invalid' do
    context 'when yml is incorrect' do
      let(:yml) { '// invalid' }

      describe '.new' do
        it 'raises error' do
          expect { config }.to raise_error(
            described_class::ConfigError,
            /Invalid configuration format/
          )
        end
      end
    end

    context 'when config logic is incorrect' do
      let(:yml) { 'before_script: "ls"' }

      describe '#valid?' do
        it 'is not valid' do
          expect(config).not_to be_valid
        end

        it 'has errors' do
          expect(config.errors).not_to be_empty
        end
      end

      describe '#errors' do
        it 'returns an array of strings' do
          expect(config.errors).to all(be_an_instance_of(String))
        end
      end
    end
  end
end
