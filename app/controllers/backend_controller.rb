class BackendController < ApplicationController

  def holdings
    @holdings = JSON.parse(HTTPClient.get_content("http://rossini.cul.columbia.edu/voyager_backend/holdings/retrieve/#{params[:id]}"))[params[:id]]
    @id = params[:id]

    render "backend/holdings", :layout => false
  end

  def holdings_mail

    @holdings = JSON.parse(HTTPClient.get_content("http://rossini.cul.columbia.edu/voyager_backend/holdings/retrieve/#{params[:id]}"))[params[:id]]
    @id = params[:id]

    render "backend/_holdings_mail", :layout => false
  end

  #
  # marquis, 5/2013 - obsolete?
  #
  # def retrieve_book_jackets
  #   isbns = params["isbns"].listify
  #   results = {}
  #   hc = HTTPClient.new
  #
  #   begin
  #     isbns.each do |isbn|
  #       unless results[isbn]
  #         query_url = 'http://books.google.com/books/feeds/volumes'
  #         logger.info("retrieving #{query_url}?q=isbn:#{isbn}")
  #         xml = Nokogiri::XML(hc.get_content(query_url, :q => "isbn:" + isbn))
  #         image_node = xml.at_css("feed>entry>link[@type^='image']")
  #         results[isbn] = image_node.attributes["href"].content.gsub(/zoom=./,"zoom=1") if image_node
  #       end
  #     end
  #   rescue Exception => e
  #     logger.warn("exception retrieving google book search: #{e.message}")
  #   end
  #
  #   render :json => results
  # end


end
