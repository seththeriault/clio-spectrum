# encoding: utf-8
require 'spec_helper'

describe 'Spectrum::SearchEngines::Summon', :vcr do

  describe 'with parameters' do

    it 'should default to a clean search' do

      sum = Spectrum::SearchEngines::Summon.new
      expect(sum.source).to be_nil

      # We always have our facets applied...
      expect(sum.params).to have_key('s.ff')
      # but not yet our source-specifics...
      expect(sum.params).to_not have_key('s.ho')

    end

    it 'should load in default options as necessary' do
      # should not load in options unless it's a new search
      sum = Spectrum::SearchEngines::Summon.new('source' => 'articles')
      expect(sum.source).to eq('articles')
      # should always have our facets applied...
      expect(sum.params).to have_key('s.ff')
      # but not yet our source-specifics...
      expect(sum.params).to_not have_key('s.ho')

      # should load in options with a new search
      sum = Spectrum::SearchEngines::Summon.new('source' => 'articles', 'new_search' => true)
      expect(sum.source).to eq('articles')
      # should have, as always, facets applied...
      expect(sum.params).to have_key('s.ff')
      # and finally also our source-specifics...
      expect(sum.params).to have_key('s.ho')

    end
  end

  describe 'basic articles search' do
    before(:each) do
      @sum = Spectrum::SearchEngines::Summon.new('source' => 'articles', 's.q' => 'hardnose dictator', 'new_search' => true)
    end

    it 'should find results', :xfocus do
      expect(@sum.documents).to_not be_empty
    end

    it 'should find a matching title result' do
      expect(@sum.documents.first.title).to match /Hardnose/
    end

    it 'should not include newspaper articles' do
      expect(@sum.search.query.facet_value_filters).to be_any { |f| f.negated? && f.value == 'Newspaper Article' }
      @sum.documents.each do |doc|
        expect(doc.content_type).to_not eq('Newspaper Article')
      end

    end
  end

  describe 'Spectrum::SearchEngines::Summon Exception Handling' do

    it 'should catch error when auth fails' do
      APP_CONFIG['summon']['secret_key'] = 'BROKEN'
      sum = Spectrum::SearchEngines::Summon.new('source' => 'articles', 's.q' => 'Dog')
      expect(sum.successful?).to be false
      expect(sum.errors).to eq('401: Unauthorized')
    end

    it 'methods should handle broken Summon @search object' do
      APP_CONFIG['summon']['secret_key'] = 'BROKEN'
      sum = Spectrum::SearchEngines::Summon.new('source' => 'articles', 's.q' => 'Dog')
      expect(sum.total_items).to eq 0
    end

  end

end
