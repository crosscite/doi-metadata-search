require 'spec_helper'

describe OrcidClaim do
  subject { OrcidClaim.new(nil) }

  context 'as_json' do
    it 'true' do
      string = '{ "word": "abc" }'
      expect(subject.as_json(string)).to eq("word" => "abc")
    end

    it 'false' do
      string = "abc"
      expect(subject.as_json(string)).to be false
    end
  end

  context 'as_xml' do
    it 'true' do
      string = "<word>abc</word>"
      expect(subject.as_xml(string)).to eq("word" => "abc")
    end

    it 'false' do
      string = "abc"
      expect(subject.as_xml(string)).to be false
    end
  end

  context 'force_utf8' do
    it 'true' do
      string = "fön  "
      expect(subject.force_utf8(string)).to eq("fön")
    end
  end
end
