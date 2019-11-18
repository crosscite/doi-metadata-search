require 'spec_helper'

describe 'app', vcr: true do
  it '/' do
    get '/'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"]).to eq("6837")
  end

  it '/works' do
    get '/works'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"]).to eq("47613")

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.results").text.strip).to eq("246,576 Works")
  end

  it '/works?query=climate' do
    get '/works?query=climate'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"]).to eq("48630")

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.results").text.strip).to eq("3,538 Works")
  end

  it '/works/10.1594/ieda/100037' do
    get '/works/10.1594/ieda/100037'
    
    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"]).to eq("27526")
    expect(last_response.headers["Link"]).to eq("<https://doi.org/10.1594/ieda/100037> ; rel=\"identifier\", <https://doi.org/10.1594/ieda/100037> ; rel=\"describedby\" ; type=\"application/vnd.datacite.datacite+xml\", <https://doi.org/10.1594/ieda/100037> ; rel=\"describedby\" ; type=\"application/vnd.citationstyles.csl+json\", <https://doi.org/10.1594/ieda/100037> ; rel=\"describedby\" ; type=\"application/x-bibtex\"")
  
    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.work a").text.strip).to eq("LauBasin_TUIM05MV_Mottl")
  end

  it '/people' do
    get '/people'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"]).to eq("15583")

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.results").text.strip).to eq("62,429 People")
  end

  it '/people?query=fenner' do
    get '/people?query=fenner'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"]).to eq("8529")

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.results").text.strip).to eq("5 People")
  end

  it '/people/0000-0001-6528-2027' do
    get '/people/0000-0001-6528-2027'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"]).to eq("7012")
    expect(last_response.headers["Link"]).to eq("<https://orcid.org/0000-0001-6528-2027> ; rel=\"identifier\"")
  
    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.work a").text.strip).to eq("Martin Fenner")
  end

  it '/repositories' do
    get '/repositories'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"]).to eq("21223")

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.results").text.strip).to eq("1,868 Repositories")
  end

  it '/repositories?query=dryad' do
    get '/repositories?query=dryad'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"]).to eq("10102")

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.results").text.strip).to eq("2 Repositories")
  end

  it '/repositories/dryad.dryad' do
    get '/repositories/dryad.dryad'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"]).to eq("39919")

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.work a").text.strip).to eq("DRYAD")
  end

  it '/members' do
    get '/members'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"]).to eq("17852")

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.results").text.strip).to eq("237 Members")
  end

  it '/members?query=university' do
    get '/members?query=university'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"]).to eq("17075")

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.results").text.strip).to eq("49 Members")
  end

  it '/members/dryad' do
    get '/members/dryad'

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/html;charset=utf-8")
    expect(last_response.headers["Content-Length"]).to eq("8322")

    doc = Nokogiri::HTML(last_response.body)
    expect(doc.at_css("h3.work a").text.strip).to eq("Dryad")
  end
end
