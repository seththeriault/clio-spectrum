
module SerialSolutions
  class SummonAPI
    include Rails.application.routes.url_helpers
    Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options
    
    attr_reader :service, :search, :query

    DEFAULT_OPTIONS = {
      'articles' =>  {'spellcheck' => true, 's.cmd' => 'addFacetValueFilters(ContentType, Newspaper Article:t)', 's.ff' => ['ContentType,or','SubjectTerms,or','Language,or']},
      'ebooks' => {'spellcheck' => true, 's.cmd' => 'addFacetValueFilters(ContentType, Newspaper Article:t)', 's.fvf' => ['ContentType,eBook'], 's.ff' => ['ContentType,or,1,15','SubjectTerms,or,1,15','Language,or,1,15']}
        }
        
    def initialize(in_options = {}) 
      options = in_options.clone
      @config = options.delete('config') || APP_CONFIG[:summon]

      unless options.delete('new_search').to_s.empty?
        category = options.delete('category') || 'articles'
        options = DEFAULT_OPTIONS[category].merge('s.q' => options['s.q'])
      end

      @service = Summon::Service.new(@config)

      #normalize strings to ISO-8859-1
      #options.each_pair do |k,v| 
        #if v.kind_of?(Array)
          #options[k] = v.collect { |v| v.kind_of?(String) ? v.force_encoding("ISO-8859-1") : v  }
        #else
          #options[k] = v.kind_of?(String) ? v.force_encoding("ISO-8859-1") : v
        #end
      #end

      @search = @service.search(options)
      @query = @search.query
      @query_hash = @query.to_hash
    end

    def previous_page
      set_page(@query_hash['s.pn'].to_i - 1)
    end

    def next_page
      set_page(@query_hash['s.pn'].to_i + 1)
    end

    def set_page(page)
      new_page = [[1, page.to_i].max, @search.page_count].min
      search_merge('s.pn' => new_page)
    end

    private

    def search_merge(params={})
      article_search_path(@query_hash.merge(params))
    end
  end
end