require 'spec_helper'

describe DiffLineSerializer do
  let(:line) { Gitlab::Diff::Line.new('hello world', 'new', 1, nil, 1) }
  let(:serializer) { described_class.new.represent(line) }

  describe '#to_json' do
    subject { serializer.to_json }

    it 'matches the schema' do
      expect(subject).to match_schema('entities/diff_line')
    end
  end
end
