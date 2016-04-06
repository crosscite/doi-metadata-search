require 'sinatra/base'
require 'json'
require 'maremma'

module Sinatra
  module Lagotto
    SOURCES = {
      "bmc_fulltext" => "BioMed Central",
      "citeulike" => "CiteULike",
      "datacite_related" => "DataCite (RelatedIdentifier)",
      "datacite_github" => "DataCite (Github)",
      "europe_pmc_fulltext" => "Europe PMC (Fulltext)",
      "orcid" => "ORCID",
      "nature_opensearch" => "Nature (OpenSearch)",
      "plos_fulltext" => "PLOS (Fulltext)",
      "wikipedia" => "Wikipedia"
    }

    # query Event Data server, fetch relations
    def get_events(dois)
      return {} unless dois.present? && ENV["LAGOTTO_URL"].present?

      response = Maremma.get "#{ENV['LAGOTTO_URL']}/api/works?#{ids_as_string(dois)}&type=doi"
      response = {} if response["errors"].present?

      response.fetch("data", {}).fetch("works", []).map do |reference|
        signposts = reference.fetch("events", {}).map do |k, v|
          { title: SOURCES.fetch(k, k),
            total: v,
            name: k }
        end

        { doi: reference.fetch("DOI", nil),
          signposts: signposts }
      end.group_by { |item| item[:doi] }
    end

    def ids_as_string(dois)
      "ids=" + dois.join(",")
    end
  end

  helpers Lagotto
end
