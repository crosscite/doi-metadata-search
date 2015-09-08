require 'spec_helper'

describe OrcidClaim do
  subject { OrcidClaim.new(nil) }

  let(:url) { "http://example.org" }
  let(:data) { { "name" => "Fred" } }
  let(:post_data) { { "name" => "Jack" } }

  context "get_result" do
    it "get json" do
      stub = stub_request(:get, url).to_return(:body => data.to_json, :status => 200, :headers => { "Content-Type" => "application/json" })
      response = subject.get_result(url)
      expect(response).to eq(data)
    end

    it "get xml" do
      stub = stub_request(:get, url).to_return(:body => data.to_xml, :status => 200, :headers => { "Content-Type" => "application/xml" })
      response = subject.get_result(url, content_type: 'xml')
      expect(response).to eq('hash' => data)
    end

    it "get html" do
      stub = stub_request(:get, url).to_return(:body => data.to_s, :status => 200, :headers => { "Content-Type" => "text/html" })
      response = subject.get_result(url, content_type: 'html')
      expect(response).to eq(data.to_s)
    end

    it "post xml" do
      stub = stub_request(:post, url).with(:body => post_data.to_xml).to_return(:body => data.to_xml, :status => 200, :headers => { "Content-Type" => "text/html" })
      subject.get_result(url, content_type: 'xml', data: post_data.to_xml) { |response| expect(Hash.from_xml(response.to_s)["hash"]).to eq(data) }
    end
  end

  context "empty response" do
    it "get json" do
      stub = stub_request(:get, url).to_return(:body => nil, :status => 200, :headers => { "Content-Type" => "application/json" })
      response = subject.get_result(url)
      expect(response).to be_blank
    end

    it "get xml" do
      stub = stub_request(:get, url).to_return(:body => nil, :status => 200, :headers => { "Content-Type" => "application/xml" })
      response = subject.get_result(url, content_type: 'xml')
      expect(response).to be_blank
    end

    it "get html" do
      stub = stub_request(:get, url).to_return(:body => nil, :status => 200, :headers => { "Content-Type" => "text/html" })
      response = subject.get_result(url, content_type: 'html')
      expect(response).to be_blank
    end

    it "post xml" do
      stub = stub_request(:post, url).with(:body => post_data.to_xml).to_return(:body => nil, :status => 200, :headers => { "Content-Type" => "application/xml" })
      subject.get_result(url, content_type: 'xml', data: post_data.to_xml) { |response| expect(response).to be_nil }
    end
  end

  context "not found" do
    let(:error) { { error: "resource not found", status: 404 } }

    it "get json" do
      stub = stub_request(:get, url).to_return(:body => error.to_json, :status => [404], :headers => { "Content-Type" => "application/json" })
      expect(subject.get_result(url)).to eq(error)
    end

    it "get xml" do
      stub = stub_request(:get, url).to_return(:body => error.to_xml, :status => [404], :headers => { "Content-Type" => "application/xml" })
      expect(subject.get_result(url, content_type: 'xml')).to eq(error)
    end

    it "get html" do
      stub = stub_request(:get, url).to_return(:body => error.to_s, :status => [404], :headers => { "Content-Type" => "text/html" })
      expect(subject.get_result(url, content_type: 'html')).to eq(error)
    end

    it "post xml" do
      stub = stub_request(:post, url).with(:body => post_data.to_xml).to_return(:body => error.to_xml, :status => [404], :headers => { "Content-Type" => "application/xml" })
      subject.get_result(url, content_type: 'xml', data: post_data.to_xml) { |response| expect(Hash.from_xml(response.to_s)["hash"]).to eq(error) }
    end
  end

  context "request timeout" do
    it "get json" do
      stub = stub_request(:get, url).to_return(:status => [408])
      response = subject.get_result(url)
      expect(response).to eq(error: "execution expired", status: 408)
    end

    it "get xml" do
      stub = stub_request(:get, url).to_return(:status => [408])
      response = subject.get_result(url, content_type: 'xml')
      expect(response).to eq(error: "execution expired", status: 408)
    end

    it "get html" do
      stub = stub_request(:get, url).to_return(:status => [408])
      response = subject.get_result(url, content_type: 'html')
      expect(response).to eq(error: "execution expired", status: 408)
    end

    it "post xml" do
      stub = stub_request(:post, url).with(:body => post_data.to_xml).to_return(:status => [408])
      subject.get_result(url, content_type: 'xml', data: post_data.to_xml) { |response| expect(response).to be_nil }
    end
  end

  context "request timeout internal" do
    it "get json" do
      stub = stub_request(:get, url).to_timeout
      response = subject.get_result(url)
      expect(response).to eq(error: "execution expired", status: 408)
    end

    it "get xml" do
      stub = stub_request(:get, url).to_timeout
      response = subject.get_result(url, content_type: 'xml')
      expect(response).to eq(error: "execution expired", status: 408)
    end

    it "get html" do
      stub = stub_request(:get, url).to_timeout
      response = subject.get_result(url, content_type: 'html')
      expect(response).to eq(error: "execution expired", status: 408)
    end

    it "post xml" do
      stub = stub_request(:post, url).with(:body => post_data.to_xml).to_timeout
      subject.get_result(url, content_type: 'xml', data: post_data.to_xml) { |response| expect(response).to be_nil }
    end
  end

  context "redirect requests" do
    let(:redirect_url) { "http://www.example.org/redirect" }

    it "redirect" do
      stub_request(:get, url).to_return(status: 301, headers: { location: redirect_url })
      stub_request(:get, redirect_url).to_return(status: 200, body: "Test")
      response = subject.get_result(url)
      expect(response).to eq("Test")
    end

    it "redirect four times" do
      stub_request(:get, url).to_return(status: 301, headers: { location: redirect_url })
      stub_request(:get, redirect_url).to_return(status: 301, headers: { location: redirect_url + "/x" })
      stub_request(:get, redirect_url+ "/x").to_return(status: 301, headers: { location: redirect_url + "/y" })
      stub_request(:get, redirect_url+ "/y").to_return(status: 301, headers: { location: redirect_url + "/z" })
      stub_request(:get, redirect_url + "/z").to_return(status: 200, body: "Test")
      response = subject.get_result(url)
      expect(response).to eq("Test")
    end
  end

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
