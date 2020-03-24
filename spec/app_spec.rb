require 'spec_helper'

describe 'app', vcr: true do
  
  it '/' do
    get '/'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"].to_i).to be > 1000
  end

  it '/works' do
    get '/works'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"].to_i).to be > 1000

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.results").text.strip).to eq("269,029 Works")
  end

  it '/works?query=climate' do
    get '/works?query=climate'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"].to_i).to be > 1000

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.results").text.strip).to eq("6,057 Works")
  end

  it '/works/10.1594/ieda/100037' do
    get '/works/10.1594/ieda/100037'
    
    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"].to_i).to be > 1000
    expect(last_response.headers["Link"]).to eq("<https://doi.org/10.1594/ieda/100037> ; rel=\"identifier\", <https://doi.org/10.1594/ieda/100037> ; rel=\"describedby\" ; type=\"application/vnd.datacite.datacite+xml\", <https://doi.org/10.1594/ieda/100037> ; rel=\"describedby\" ; type=\"application/vnd.citationstyles.csl+json\", <https://doi.org/10.1594/ieda/100037> ; rel=\"describedby\" ; type=\"application/x-bibtex\"")
  
    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.work a").text.strip).to eq("LauBasin_TUIM05MV_Mottl")
  end

  let!(:user_agent) { {'HTTP_USER_AGENT'=>'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.96 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)' } }

  it '/works/10.7272/q6g15xs4 as Googlebot' do
    get '/works/10.7272/q6g15xs4', nil, user_agent
    
    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at("#myTabContent")).to be_nil
  end

  it '/people' do
    get '/people'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"].to_i).to be > 1000

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.results").text.strip).to eq("66,528 People")
  end

  it '/people?query=fenner' do
    get '/people?query=fenner'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"].to_i).to be > 1000

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.results").text.strip).to eq("5 People")
  end

  it '/people/0000-0001-6528-2027' do
    get '/people/0000-0001-6528-2027'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"].to_i).to be > 1000
    expect(last_response.headers["Link"]).to eq("<https://orcid.org/0000-0001-6528-2027> ; rel=\"identifier\"")
  
    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.work a").text.strip).to eq("Martin Fenner")
  end

  it '/repositories' do
    get '/repositories'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"].to_i).to be > 1000

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.results").text.strip).to eq("2,067 Repositories")
  end

  it '/repositories?query=dryad' do
    get '/repositories?query=dryad'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"].to_i).to be > 1000

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.results").text.strip).to eq("2 Repositories")
  end

  it '/repositories/dryad.dryad' do
    get '/repositories/dryad.dryad'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"].to_i).to be > 1000

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.work a").text.strip).to eq("DRYAD")
  end

  it '/members' do
    get '/members'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"].to_i).to be > 1000

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.results").text.strip).to eq("391 Members")
  end

  it '/members?query=university' do
    get '/members?query=university'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"].to_i).to be > 1000

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.results").text.strip).to eq("106 Members")
  end

  it '/members/dryad' do
    get '/members/dryad'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"].to_i).to be > 1000

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.work a").text.strip).to eq("Dryad")
  end
end
