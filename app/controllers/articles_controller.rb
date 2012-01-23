require 'blacklight/catalog'

class ArticlesController < ApplicationController
  layout "quicksearch"
  
  include Blacklight::Catalog

  def index
    @new_search = true
    begin
      @summon = SerialSolutions::SummonAPI.new('new_search' => true, 'category' => 'articles')
    rescue Exception => e
      @error = e.message
    end
  end
  def search
    @new_search = !params.has_key?('category') || (params['new_search'] && params['new_search'] != '')
    begin
      @summon = SerialSolutions::SummonAPI.new(params)
    rescue Exception => e
      @error = e
    end
  end
  

  def show
    @document = SerialSolutions::Link360.new(params[:openurl])

    render "show", :layout => "no_sidebar"
  end

end
