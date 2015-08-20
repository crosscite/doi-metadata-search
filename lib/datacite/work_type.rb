module Sinatra
  module WorkType
    # Map of DataCite work types to the CASRAI-based ORCID type vocabulary
    # https://members.orcid.org/api/supported-work-types
    TYPE_OF_WORK = {

      'Audiovisual' => 'other',
      'Collection' => 'other',
      'Dataset' =>  'data-set',
      'Event' => 'other',
      'Image' => 'other',
      'InteractiveResource' => 'online-resource',
      'Model' => 'other',
      'PhysicalObject' => 'other',
      'Service' => 'other',
      'Software' => 'other',
      'Sound' => 'other',
      'Text' => 'other',
      'Workflow' => 'other',
      'Other' => 'other',

      # Legacy types from older schema versions
      'Film' => 'other'
      # pick up other legacy types as we go along
    }

    # Heuristic for determing the type of the work based on A) the general, high-level label
    # from the `resourceTypeGeneral field` (controlled list) and B)) the value of the more specific
    # `resourceType` field which is not from a controlled list but rather free-form input from data centres.
    def orcid_work_type(internal_work_type, internal_work_subtype)
      type =  case  internal_work_type
              when 'Text'
                case internal_work_subtype
                when /^(Article|Articles|Journal Article|JournalArticle)$/i
                  'journal-article'
                when /^(Book|ebook|Monografie|Monograph\w*|)$/i
                  'book'
                when /^(chapter|chapters)$/i
                  'book-chapter'
                when /^(Project report|Report|Research report|Technical Report|TechnicalReport|Text\/Report|XFEL.EU Annual Report|XFEL.EU Technical Report)$/i
                  'report'
                when /^(Dissertation|thesis|Doctoral thesis|Academic thesis|Master thesis|Masterthesis|Postdoctoral thesis)$/i
                  'dissertation'
                when /^(Conference Abstract|Conference extended abstract)$/i
                  'conference-abstract'
                when /^(Conference full text|Conference paper|ConferencePaper)$/i
                  'conference-paper'
                when /^(poster|Conference poster)$/i
                  'conference-poster'
                when /^(working paper|workingpaper|preprint)$/i
                  'working-paper'
                when /^(dataset$)/i
                  'data-set'
                end

              when 'Collection'
                case internal_work_subtype
                when /^(Collection of Datasets|Data Files|Dataset|Supplementary Collection of Datasets)$/i
                  'data-set'
                when 'Report'
                  'report'
                end
              end  # double CASE statement ends

      type || TYPE_OF_WORK[internal_work_type] || 'other'
    end
  end

  helpers WorkType
end
