require 'sinatra/base'
require 'json'
require_relative 'network'

module Sinatra
  module Lagotto
    include Sinatra::Network

    SOURCES = {
      "bmc_fulltext" => "BioMed Central",
      "citeulike" => "CiteULike",
      "europe_pmc_fulltext" => "Europe PMC",
      "orcid" => "ORCID",
      "nature_opensearch" => "Nature OpenSearch",
      "plos_fulltext" => "PLOS",
      "wikipedia" => "Wikipedia"
    }

    # query DLM server, fetch references, discard information coming from DataCite
    def get_references(dois)
      return [] unless dois.present? && ENV["LAGOTTO_URL"].present?

      url = "#{ENV['LAGOTTO_URL']}/api/references"
      response = get_result(url, content_type: "text/html", data: dois_as_string(dois))

      references = response.fetch("references", []).map do |reference|
        doi = reference.fetch("work_id", "")[15..-1].upcase
        relation = reference.fetch("relation_type_id", "references").camelize
        source = reference.fetch("source_id", nil)
        source = SOURCES.fetch(source, source)

        if text = reference.fetch("DOI", nil)
          text = text.upcase
          id = "DOI"
        else
          text = reference.fetch("URL", nil)
          id = "URL"
        end

        { doi: doi,
          relation: relation,
          id: id,
          text: text,
          source: source }
      end.select { |item| item[:text].present? && item[:source] !~ /datacite_data/ }.group_by { |item| item[:doi] }
    end

    def dois_as_string(dois)
      "work_ids=" + dois.map { |doi| "http://doi.org/#{doi}" }.join(",")
    end
  end
end
