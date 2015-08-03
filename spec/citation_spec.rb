require 'spec_helper'

describe 'citation' do
  let(:doi) { '10.5281/ZENODO.21430' }

  it 'format bibtex' do
    get "/citation?doi=#{doi}&format=bibtex"
    expect(last_response).to be_ok
    expect(last_response.body).to match('author = {Martin Fenner; Karl Jonathan Ward; Gudmundur A. Thorisson; Robert Peters; }')
  end

  it 'format ris' do
    get "/citation?doi=#{doi}&format=ris"
    output = <<-EOS.strip_heredoc
      TY  - DATA
      T1  - DataCite-ORCID: 1.0
      AU  - Martin Fenner; Karl Jonathan Ward; Gudmundur A. Thorisson; Robert Peters;
      PY  - 2015
      PB  - Zenodo
      UR  - http://dx.doi.org/10.5281/ZENODO.21430
      ER  -
    EOS
    expect(last_response).to be_ok
    expect(last_response.body).to eq(output.strip)
  end

  it 'format apa' do
    get "/citation?doi=#{doi}&format=apa"
    expect(last_response).to be_ok
    expect(last_response.body).to eq('Martin Fenner, Karl Jonathan Ward, Gudmundur A. Thorisson, & Robert Peters. (2015). DataCite-ORCID: 1.0. Zenodo. http://doi.org/10.5281/ZENODO.21430')
  end

  it 'format harvard' do
    get "/citation?doi=#{doi}&format=harvard"
    expect(last_response).to be_ok
    expect(last_response.body).to eq('Martin Fenner et al., 2015. DataCite-ORCID: 1.0. Available at: http://dx.doi.org/10.5281/ZENODO.21430.')
  end

  it 'format ieee' do
    get "/citation?doi=#{doi}&format=ieee"
    expect(last_response).to be_ok
    expect(last_response.body).to eq('[1]Martin Fenner, Karl Jonathan Ward, Gudmundur A. Thorisson, and Robert Peters, “DataCite-ORCID: 1.0.” Zenodo, 2015.')
  end

  it 'format mla' do
    get "/citation?doi=#{doi}&format=ieee"
    expect(last_response).to be_ok
    expect(last_response.body).to eq('[1]Martin Fenner, Karl Jonathan Ward, Gudmundur A. Thorisson, and Robert Peters, “DataCite-ORCID: 1.0.” Zenodo, 2015.')
  end

  it 'format vancouver' do
    get "/citation?doi=#{doi}&format=vancouver"
    expect(last_response).to be_ok
    expect(last_response.body).to eq('1. Martin Fenner, Karl Jonathan Ward, Gudmundur A. Thorisson, Robert Peters. DataCite-ORCID: 1.0 [Internet]. Zenodo; 2015. Available from: http://dx.doi.org/10.5281/ZENODO.21430')
  end

  it 'format chicago' do
    get "/citation?doi=#{doi}&format=chicago"
    expect(last_response).to be_ok
    expect(last_response.body).to eq('Martin Fenner, Karl Jonathan Ward, Gudmundur A. Thorisson, and Robert Peters. “DataCite-ORCID: 1.0.” Zenodo, 2015. doi:10.5281/ZENODO.21430.')
  end

  it 'missing DOI' do
    get '/citation'
    expect(last_response.status).to eq(422)
    body = JSON.parse(last_response.body)
    expect(body).to eq('status' => 'error',
                       'message' => 'DOI missing or wrong format.')
  end

  it 'malformed DOI' do
    doi = '10.5281'
    get "/citation?doi=#{doi}&format=apa"
    expect(last_response.status).to eq(422)
    body = JSON.parse(last_response.body)
    expect(body).to eq('status' => 'error',
                       'message' => 'DOI missing or wrong format.')
  end

  it 'missing format' do
    get "/citation?doi=#{doi}"
    expect(last_response.status).to eq(415)
    body = JSON.parse(last_response.body)
    expect(body).to eq('status' => 'error',
                       'message' => 'Format missing or not supported.')
  end

  it 'unsupported format' do
    get "/citation?doi=#{doi}&format=plos"
    expect(last_response.status).to eq(415)
    body = JSON.parse(last_response.body)
    expect(body).to eq('status' => 'error',
                       'message' => 'Format missing or not supported.')
  end
end
