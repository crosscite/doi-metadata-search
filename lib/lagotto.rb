require 'sinatra/base'
require 'json'
require 'maremma'

module Sinatra
  module Lagotto
    SOURCES = {
      "bmc_fulltext" => "BioMed Central",
      "citeulike" => "CiteULike",
      "datacite_related" => "DataCite",
      "datacite_github" => "DataCite",
      "europe_pmc_fulltext" => "Europe PMC",
      "orcid" => "ORCID",
      "nature_opensearch" => "Nature OpenSearch",
      "plos_fulltext" => "PLOS",
      "wikipedia" => "Wikipedia"
    }

    # query Link Store server, fetch references, discard information coming from DataCite
    def get_relations(dois)
      return {} unless dois.present? && ENV["LAGOTTO_URL"].present?

      response = Maremma.post "#{ENV['LAGOTTO_URL']}/api/relations", content_type: "text/html", data: work_ids_as_string(dois)
      response = {} if response["errors"].present?

      response.fetch("data", {}).fetch("relations", []).map do |reference|
        source = reference.fetch("source_id", nil)
        source = SOURCES.fetch(source, source)

        { doi: reference.fetch("work_id", "")[15..-1],
          id: reference.fetch("id", ""),
          relation: reference.fetch("relation_type_id", "references").camelize,
          source: source,
          title: reference.fetch("title", nil),
          container_title: reference.fetch("container-title", nil),
          author: reference.fetch("author", nil),
          issued: reference.fetch("issued", nil) }
      end.uniq.select { |item| item[:source] !~ /orcid.*/ }.group_by { |item| item[:doi] }
    end

    def work_ids_as_string(dois)
      "work_ids=" + dois.map { |doi| "http://doi.org/#{doi}" }.join(",")
    end
  end

  helpers Lagotto
end
