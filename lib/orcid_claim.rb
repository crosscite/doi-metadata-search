require 'nokogiri'
require 'oauth2'
require 'log4r'

require_relative 'data'
require_relative 'helpers'


class OrcidClaim

  # Map of DataCite work types to the CASRAI-based ORCID type vocabulary
  TYPE_OF_WORK = {

    'Audiovisual' => 'other',
    'Collection' => 'other',
    'Dataset' =>  'data-set',
    'Event' => 'other',
    'Image' => 'other',
    'InteractiveResource' => 'online-resource',
    'Model' => 'other',
    'PhysicalObject' => 'other' ,
    'Service' => 'other',
    'Software' => 'other',
    'Sound' => 'other',
    'Text' => 'other',
    'Workflow' => 'other',
    'Other' => 'other',

    # Legacy types from older schema versions
    'Film' => 'other',
    # pick up other legacy types as we go along
  }

 # Map of DataCite work types to ORCID original BibTeX-based type vocabulary. Derived from
  # DataCite metadata schema v3 (current as of Nov 2013)

  TYPE_OF_WORK_DISABLED = {
    'Audiovisual' => 'audiovisual',
    'Collection' => 'other',
    'Dataset' =>  'other',
    'Event' => 'other',
    'Image' => 'digital-image',
    'InteractiveResource' => 'other',
    'Model' => 'other',
    'PhysicalObject' => 'other' ,
    'Service' => 'other',
    'Software' => 'software',
    'Sound' => 'other',
    'Text' => 'other',
    'Workflow' => 'other',
    'Other' => 'other',

    # Legacy types from older schema versions
    'Film' => 'film-movie',

  }


  @queue = :orcid

  def logger
    Log4r::Logger['test']
  end

  def initialize oauth, work
    @oauth = oauth
    @work = work
  end

  def self.perform oauth, work
    OrcidClaim.new(oauth, work).perform
  end

  def logger
    Log4r::Logger['test']
  end

  def perform
    oauth_expired = false

    logger.info "Performing claim with @oauth and @work:"
    logger.debug {@oauth.ai}
    logger.debug {@work.ai}
    logger.debug "Works XML: " + to_xml

    # Need to check both since @oauth may or may not have been serialized back and forth from JSON.
    uid = @oauth[:uid] || @oauth['uid']

    opts = { site: ENV['ORCID_API_URL'] }
    logger.info "Connecting to ORCID OAuth API at site #{opts[:site]} to post claim data"

    client = OAuth2::Client.new(ENV['ORCID_CLIENT_ID'], ENV['ORCID_CLIENT_SECRET'], opts)
    token = OAuth2::AccessToken.new(client, @oauth['credentials']['token'])
    headers = {'Accept' => 'application/json'}
    response = token.post("/v1.2/#{uid}/orcid-works") do |post|
      post.headers['Content-Type'] = 'application/orcid+xml'
      post.body = to_xml
    end
    logger.debug "response obj=" + response.ai

    # Raise firm exception if we do NOT get an a-OK response back from the POST operation
    if response.status == 201
      return response.status
    else
      raise OAuth2::Error "Bad response from ORCID API: HTTP status=#{response.status}, error message=" + response.body
    end
  end

  def has_path? hsh, path
    loc = hsh
    path.each do |path_item|
      if loc[path_item]
        loc = loc[path_item]
      else
        loc = nil
        break
      end
    end
    loc != nil
  end

  # Heuristic for determing the type of the work based on A) the general, high-level label
  # from the `resourceTypeGeneral field` (controlled list) and B)) the value of the  more specific
  # `resourceType` field which is not from a controlled list but rather free-form input from data centres.
  def orcid_work_type internal_work_type, internal_work_subtype
    logger.debug "Determining ORCID work type term from  #{internal_work_type} / #{internal_work_subtype}"
    type =  case  internal_work_type
            when "Text"
              case internal_work_subtype
              when /^(Article|Articles|Journal Article|JournalArticle)$/i
                "journal-article"
              when /^(Book|ebook|Monografie|Monograph\w*|)$/i
                "book"
              when /^(chapter|chapters)$/i
                "book-chapter"
              when /^(Project report|Report|Research report|Technical Report|TechnicalReport|Text\/Report|XFEL.EU Annual Report|XFEL.EU Technical Report)$/i
                "report"
              when /^(Dissertation|thesis|Doctoral thesis|Academic thesis|Master thesis|Masterthesis|Postdoctoral thesis)$/i
                "dissertation"
              when /^(Conference Abstract|Conference extended abstract)$/i
                "conference-abstract"
              when /^(Conference full text|Conference paper|ConferencePaper)$/i
                "conference-paper"
              when /^(poster|Conference poster)$/i
                "conference-poster"
              when /^(working paper|workingpaper|preprint)$/i
                "working-paper"
              when /^(dataset$)/i
                "data-set"
              end

            when "Collection"
              case internal_work_subtype
              when /^(Collection of Datasets|Data Files|Dataset|Supplementary Collection of Datasets)$/i
                "data-set"
              when "Report"
                "report"
              end
            end  # double CASE statement ends

    if type.nil?
      logger.info "Got nothing from heuristic, falling back on generic type mapping for '#{internal_work_type}' or else defaulting to other"
      type = TYPE_OF_WORK[internal_work_type] || 'other'
    end

    logger.debug "Final work type mapping: #{internal_work_type||'undef'} / #{internal_work_subtype||'undef'} => #{type || 'undef'}"
    return type
  end

  def pad_date_item item
    result = nil
    if item
      begin
        item_int = item.strip.to_i
        if item_int >= 0 && item_int <= 11
          item_str = item_int.to_s
          if item_str.length < 2
            result = "0" + item_str
          elsif item_str.length == 2
            result = item_str
          end
        end
      rescue StandardError => e
        # Ignore type conversion errors
      end
    end
    result
  end

  def insert_id xml, type, value
    xml.send(:'work-external-identifier') {
      xml.send(:'work-external-identifier-type', type)
      xml.send(:'work-external-identifier-id', value)
    }
  end

  def insert_ids xml
     xml.send(:'work-external-identifiers') {
      insert_id(xml, 'doi', @work['doi'])
      insert_id(xml, 'isbn', @work['proceedings']['isbn']) if has_path?(@work, ['proceedings', 'isbn'])
      insert_id(xml, 'issn', @work['journal']['issn']) if has_path?(@work, ['journal', 'issn'])
    }
  end

  def insert_pub_date xml
    month_str = pad_date_item(@work['published']['month'])
    day_str = pad_date_item(@work['published']['day'])
    if @work['published']
      xml.send(:'publication-date') {
        xml.year(@work['published']['year'].to_i.to_s)
        xml.month(month_str) if month_str
        xml.day(day_str) if day_str
      }
    end
  end

  def insert_type xml
    xml.send(:'work-type', orcid_work_type(@work['type'], @work['subtype']))
  end

  def insert_titles xml
    subtitle = case @work['type']
               when 'journal_article'
                 if has_path?(@work, ['journal', 'full_title'])
                   @work['journal']['full_title']
                 else
                   nil
                 end
               when 'conference_paper'
                 if has_path?(@work, ['proceedings', 'title'])
                   @work['proceedings']['title']
                 else
                   nil
                 end
               else
                 nil
               end

    if subtitle || @work['title']
      xml.send(:'work-title') {
        xml.title(@work['title']) if @work['title']
        xml.subtitle(subtitle) if subtitle
      }
    end
  end

  def insert_contributors xml
    if @work['contributors'] && !@work['contributors'].count.zero?
      xml.send(:'work-contributors') {
        @work['contributors'].each do |contributor|
          full_name = ""
          full_name = contributor['given_name'] if contributor['given_name']
          full_name += " " + contributor['surname'] if contributor['surname']
          if !full_name.empty?
            xml.contributor {
              xml.send(:'credit-name', full_name)
              # TODO Insert contributor roles and sequence once available
              # in 'dois' mongo collection.
              #xml.send(:'contributor-attributes') {
              #  xml.send(:'contributor-role', 'author')
              #}
            }
          end
        end
      }
    end
  end

  def insert_citation xml
    conn = Faraday.new
    logger.info "Retrieving citation for #{@work['doi']}"
    response = conn.get "http://data.datacite.org/#{@work['doi']}", {}, {
      #'Accept' => 'text/x-bibliography'
      'Accept' => 'application/x-bibtex'
    }

    #citation = response.body
    citation = response.body.sub(/^@data{/, '@misc{datacite')

    logger.debug "Got citation:\n #{citation}"

    if response.status == 200
      xml.send(:'work-citation') {
        #xml.send(:'work-citation-type', 'formatted-apa')
        xml.send(:'work-citation-type', 'bibtex')
        xml.citation {
          xml.cdata(citation)
        }
      }
    end
  end

  def to_xml
    root_attributes = {
      :'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      :'xsi:schemaLocation' => 'http://www.orcid.org/ns/orcid http://orcid.github.com/ORCID-Parent/schemas/orcid-message/1.2/orcid-message-1.2.xsd',
      :'xmlns' => 'http://www.orcid.org/ns/orcid'
    }

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.send(:'orcid-message', root_attributes) {
        xml.send(:'message-version', '1.2')
        xml.send(:'orcid-profile') {
          xml.send(:'orcid-activities') {
            xml.send(:'orcid-works') {
              xml.send(:'orcid-work') {
                insert_titles(xml)
                insert_citation(xml)
                insert_type(xml)
                insert_pub_date(xml)
                insert_ids(xml)
                insert_contributors(xml)
              }
            }
          }
        }
      }
    end.to_xml
  end

end
