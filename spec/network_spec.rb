require 'spec_helper'

describe OrcidClaim do
  subject { OrcidClaim.new(nil) }

  context 'parse_error_response' do
    it 'json' do
      string = '{ "error": "An error occured." }'
      expect(subject.parse_error_response(string)).to eq("An error occured.")
    end

    it 'json not error' do
      string = '{ "customError": "An error occured." }'
      expect(subject.parse_error_response(string)).to eq("customError"=>"An error occured.")
    end

    it 'xml' do
      string = '<error>An error occured.</error>'
      expect(subject.parse_error_response(string)).to eq("An error occured.")
    end
  end

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
