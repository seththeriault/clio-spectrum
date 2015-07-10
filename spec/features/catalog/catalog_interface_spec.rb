require 'spec_helper'

describe 'Catalog Interface' do

  # NEXT-779 - Some 880 fields not showing up
  it 'MARC 880 note field should display', js: true do
    # visit this specific item
    visit catalog_path('7814900')

    # Find the 880 data for bib 7814900 within the info display
    expect(find('.info')).to have_content('Other Information: Leaf 1 contains laws on the Torah reading')
  end

  # NEXT-765 - MARC 787 field (Related To) not showing up
  it "MARC 787 'Related To' field should display", js: true do
    # visit this specific item
    visit catalog_path('7419929')

    # Find the 787 data for bib 7419929
    expect(find('.info')).to have_content('Related To Xia intelligenteArchitektur')
  end

  # NEXT-917 - Summary showing up twice for video records
  it 'Video Records should show Summary only once', js: true do
    visit catalog_index_path('q' => 'summary')
    within all('div.facet_limit.blacklight-format.panel').first do
      find('a.more_facets_link').click
    end
    within '.facet_extended_list' do
      click_link('Video')
    end

    within all('.result.document').first do
      all('a').first.click
    end
    expect(page).to have_css('div.field', text: 'Summary', count: 1)
  end

  # NEXT-551 - display 'version of resource' and 'related resource' notes
  # this test is awefully tight - any cataloging/labeling change will break it.
  it "Item Links should show 'version of resource' and 'related resource'", js: true do
    # on the search-results page
    visit catalog_index_path('q' => 'Introduction to high-energy astrophysics stephan rosswog')
    expect(page).to have_text('Table of contents (version of resource)')
    expect(page).to have_text('Publisher description (related resource)')

    # on the item-detail page
    click_link('Introduction to high-energy astrophysics')
    expect(page).to have_text('Table of contents (version of resource)')
    expect(page).to have_text('Publisher description (related resource)')
  end

  # NEXT-619 - improvements to 'Manuscript' facet
  it 'Should find many Manuscripts for Call Number range X893', js: true do
    visit catalog_index_path('q' => 'X893')
    within '.search_box.catalog' do
      find('btn.dropdown-toggle').click
      within '.dropdown-menu' do
        click_link('Call Number')
      end
      find('button[type=submit]').click
    end
    within 'div.blacklight-format .facet-content .panel-body' do
      click_link('Manuscript/Archive')
    end
    # exact count depends on default items-per-page, today, 25
    expect(page).to have_css('.result.document', count: 25)
    # matching "1", or "1N", or "1NN"...  the value today is actually 1504
    expect(page).to have_text('1 - 25 of 1')
  end

  # NEXT-640 - Records in CLIO should include links to Hathi Trust
  #  Full View examples:  513297, 1862548, 2081553
  #  Limited examples:  70744 (?), 4043762, 2517624
  it "Should show CLIO, Google, and 'Full' & 'Limited' Hathi Trust links", js: true do
    page.driver.allow_url("hathitrust.org")
    page.driver.allow_url("books.google.com")

    # visit this specific item
    visit catalog_path('513297')
    expect(page).to have_css('.holdings-container .holdings #clio_holdings')
    expect(page).to have_css('.holdings-container .holdings #google_holdings')
    expect(page).to have_css('.holdings-container .holdings #hathi_holdings', wait: 3)

    # Should see the 'Full View' message in the Hathi Holdings box
    expect(find('#hathi_holdings #hathi_data')).to have_content('Full view')

    # visit this specific item
    visit catalog_path('4043762')
    expect(page).to have_css('.holdings-container .holdings #clio_holdings')
    expect(page).to have_css('.holdings-container .holdings #google_holdings')
    expect(page).to have_css('.holdings-container .holdings #hathi_holdings', wait: 3)

    # Should see the 'Limited (search-only)' message in the Hathi Holdings box
    expect(find('#hathi_holdings #hathi_data')).to have_content('Limited (search-only)')
  end

  # NEXT-931 - Online Links in Holdings (not in the Bib) should display
  it 'Online links from Bib or Holdings should show up within correct block', js: true do
    # visit this specific item
    visit catalog_path('382300')

    # within CLIO HOLDINGS, not the regular Online div...
    # ... should see an 'Online' block
    expect(find('div#clio_holdings')).to have_content('Online')
    # ... should see the specific URL...
    expect(find('div#clio_holdings')).to have_content('http://www.neighborhoodpreservationcenter.org/')

    # And, contrariwise, other Avery Online material, which does not have
    # an 856 URL in the Holdings record, should display 'Online' within the
    # visit this specific item
    visit catalog_path('10099362')

    # within ONLINE HOLDINGS, SHOULD see an 'Online' block
    expect(find('div#online_holdings')).to have_content('Online')

    # within CLIO HOLDINGS, should NOT see an 'Online' block
    # expect(find('div#clio_holdings')).not_to have_content("Online")
    # Now, Online-Only items no longer have any CLIO Holdings div at all!
    expect(page).to have_no_selector('div#clio_holdings')

  end

  # Valid Voyager locations include angle-brackets.
  # CLIO should escape these (NOT treat them like markup)
  # NEXT-593, NEXT-928
  it 'Locations with embedded angle-brackets should work', js: true do
    target1 = 'Avery obituary index of architects and artists'
    troublesome1 = 'Offsite <Avery> (Non-Circulating) Place Request for delivery'
    target2 = 'Notes for the Breitenau room'
    troublesome2 = 'Offsite <Fine Arts> (Non-Circ) Place Request for delivery'

    # go to the search-results page..
    visit catalog_index_path(q: target1, search_field: 'title_starts_with')

    # should see the full location
    expect(find('#documents')).to have_content(troublesome1)

    # go to the item-detail page..
    click_link(target1)

    # within CLIO HOLDINGS, should get the full location data
    expect(find('div#clio_holdings')).to have_content(troublesome1)

    # And again, with slightly different sample...

    # go to the search-results page..
    visit catalog_index_path('q' => target2)

    # should see the full location
    expect(find('#documents')).to have_content(troublesome2)

    # go to the item-detail page..
    click_link(target2)

    # within CLIO HOLDINGS, should get the full location data
    expect(find('div#clio_holdings')).to have_content(troublesome2)
  end

  it "supports alternative viewstyle options ('Standard' or 'Compact')", js: true do
    visit catalog_index_path('q' => "the'end")

    click_link 'Display Options'
    click_link 'Standard View'

    # make sure the standard results have loaded
    find('.result.document .row .title', match: :first)

    expect(all('.result.document').first.text).to match(/Author.*Published.*Location/)

    click_link 'Display Options'
    click_link 'Compact View'

    # make sure the compact results have loaded
    find('.boxed_search_results', match: :first)

    expect(all('.result.document').first.text).not_to match /Author/
    expect(all('.result.document').first.text).not_to match /Published/
    expect(all('.result.document').first.text).not_to match /Location/

    click_link 'Display Options'
    click_link 'Standard View'

    # make sure the standard results have loaded
    find('.result.document .row .title', match: :first)

    expect(all('.result.document').first.text).to match(/Author.*Published.*Location/)
  end

  describe 'share by email' do
    it 'supports an email function, directly' do
      visit email_catalog_path(id: 12_345)
      expect(page).to have_text('Share selected item(s) via email')
      within '#email_form' do
        fill_in 'to', with: 'marquis@columbia.edu'
        fill_in 'message', with: 'testing'
        find('button[type=submit]').click
      end
    end

    it 'supports an email function, via JS modal', js: true do
      visit catalog_path(1234)
      within '#show_toolbar' do
        click_link 'Email'
      end

      expect(page).to have_css('.modal-dialog .modal-content .modal-header')

      # NEXT 910 - Add directions, email and Name, to the email form
      expect(find('.modal-header')).to have_text('Share selected item(s) via email')

      within '#email_form' do
        fill_in 'to', with: 'marquis@columbia.edu'
        fill_in 'message', with: 'testing'
        find('button[type=submit]').click
      end
    end
  end

  it 'supports a debug mode', js: true do
    visit catalog_index_path('q' => 'prim')

    expect(page).to_not have_css('div.debug_instruction')
    expect(page).to_not have_css('div.debug_entries')

    visit catalog_index_path('q' => 'sneak', 'debug_mode' => 'on')
    # save_and_open_page # debug

    # We should still NOT have a debug session, since this only works for
    # authenticated users who are in the admin group
    expect(page).to_not have_css('div.debug_instruction')
    expect(page).to_not have_css('div.debug_entries')

    # Login as a site admin account....
    @test_site_manager = FactoryGirl.create(:user, login: 'test_site_manager')
    feature_login @test_site_manager

    visit catalog_index_path('q' => 'approved', 'debug_mode' => 'on')

    expect(page).to have_css('div.debug_instruction')
    expect(page).to have_css('div.debug_entries')
    expect(find('.debug_instruction')).to have_text('Debug mode is on. Turn it off')
    within('div.debug_instruction') do
      click_link 'off'
    end

    # clicking "off" should reload the page automatically
    expect(page).to_not have_css('div.debug_instruction')
    expect(page).to_not have_css('div.debug_entries')

  end

    # NEXT-1015 - next from MARC
  it 'should support next/previous navigation from MARC view', js: true do

    # locate a fairly static set of records for a stable test suite
    visit catalog_index_path('q' => 'maigret simenon')
    within '#facets' do
      find('.panel-heading', text: 'Publication Date').click
      fill_in 'range[pub_date_sort][end]', with: '1950'
      find('button[type=submit]').click
    end

    expect(page).to have_text '1 - 9 of 9'

    click_link('The patience of Maigret')
    expect(page).to have_text 'Back to Results | 1 of 9 | Next'
    expect(page).to have_text 'Title The patience of Maigret'

    click_link('Display In')
    click_link('MARC View')
    expect(page).to have_text 'Back to Results | 1 of 9 | Next'
    expect(page).to have_text '245 1 4 |a The patience of Maigret'

    within '#show_toolbar' do
      click_link('Next')
    end
    expect(page).to have_text 'Back to Results | « Previous | 2 of 9 | Next »'
    expect(page).to have_text '245 1 4 |a Les vacances de Maigret'

    click_link('Return to Patron View')
    expect(page).to have_text 'Back to Results | « Previous | 2 of 9 | Next »'
    expect(page).to have_text 'Title Les vacances de Maigret'

  end


  # NEXT-1054 - In the single item display menu, change "Services" to "Requests"
  it 'should show menu-option "Request(s)"', :js => true do
    visit catalog_path('10905238')
    # Should use consistent language
    expect(find('#show_toolbar')).to have_text "Requests"
    expect(find('#clio_holdings')).to have_text "Request"
  end


  # NEXT-1081 - Apostrophe in the title bar renders incorrectly
  it 'shows apostrophes within title element', js: true do
    visit catalog_path(6217943)
    expect(page).to have_title "L'image de l'Orient"

    visit catalog_path(6094212)
    expect(page).to have_title "Al-Qur'an"
  end

  # NEXT-1127 - Apostrophe in the title bar (in MARC view)
  it 'shows apostrophes within title element', js: true do
    visit librarian_view_catalog_path(10877875)
    expect(page).to have_title "One woman's war: Da"

    visit librarian_view_catalog_path(6217943)
    expect(page).to have_title "L'image de l'Orient"

    visit librarian_view_catalog_path(6094212)
    expect(page).to have_title "Al-Qur'an"
  end

  # NEXT-1069 - 505s for Journals/Periodicals
  it 'shows apostrophes within title element' do
    visit catalog_path(10213578)
    expect(page).to have_text "Contents
    ISSUE 1
    Introduction
    Annette Funicello"
  end

  # Validate all the fields of series statements
  # NEXT-1080 - Add 490 series statement to displays
  # (8X0s were already there, now add the 490)
  it 'shows series statements, from 490 and 8X0 fields' do
    # 490
    visit catalog_path(10735763)
    expect(page).to have_text "Series Bullettino della Commissione archeologica comunale di Roma. Supplementi ; 21"
    # 800
    visit catalog_path(10840)
    expect(page).to have_text "Series Abusch, Alexander. Works. Selections ; Bd. 1."
    # 810
    visit catalog_path(11638)
    expect(page).to have_text "Series Freemasons. Quatuor Coronati-Loge (Bayreuth, Germany). Quellenkundliche Arbeit der Freimaurerischen Forschungsgesellschaft Quatuor Coronati e.V., Bayreuth ; Nr. 8."
    # 811
    visit catalog_path(6974)
    expect(page).to have_text "Series Sagamore Army Materials Research Conference. Sagamore Army Materials Research Conference proceedings ; 21st."
    # 830
    visit catalog_path(8887)
    expect(page).to have_text "Series Studi risorgimentali ; 12."
# I have not yet found any example bibs for this test...
    # # 840
    # visit catalog_path(99)
    # expect(page).to have_text "xx"
  end

  # NEXT-977 - Series Title does not display via basic search
  it "should show Series Title when searching by Series Title" do
    # Basic Search
    visit catalog_index_path('q' => 'Black Sea', 'search_field' => 'series_title')
    expect(page).to have_text('Series Title Black Sea studies')

    # Advanced Search
    series_title_clause = {"field" => "series_title", "value" => "black sea"}
    adv_search_fields = {"1" => series_title_clause}
    visit catalog_index_path('search_field' => 'advanced', 'adv' => adv_search_fields)
    # save_and_open_page
    expect(page).to have_text('Series Title Black Sea studies')
  end

  # NEXT-1043 - Better handling of extremely long queries
  # CatalogController.index() has maxLetters = 200
  it "should truncate queries with too many letters" do
    # This will be 10 x 20 = 200, plus 1 == 201 
    too_long = "123456789 " * 20 + "X"
    visit catalog_index_path(q: too_long)
    expect(page).to have_text ("Your query was automatically truncated to the first 200 letters")
  end

  # NEXT-1043 - Better handling of extremely long queries
  # CatalogController.index() has maxTerms = 30
  it "should truncate queries with too many words" do
    # This will be 1 x 30 = 30, plus 1 == 31 
    too_long = "asdf " * 30 + "X"
    visit catalog_index_path(q: too_long)
    expect(page).to have_text ("Your query was automatically truncated to the first 30 words")
  end

  it "supports 'random query' feature" do
    visit catalog_index_path(random_q: true)
    expect(page).to have_css('li.datasource_link.selected[source="catalog"]')
    expect(page).to have_css('span.constraints-label', text: "You searched for:")
  end

  #   NEXT-1140 - Special character not sorting properly
  it "Title sort should disregard diacritics" do
    rizq = 'Rizq, Yūnān Labīb'.mb_chars.normalize(:d)
    yahud = 'al-Yahūd fī Miṣr'.mb_chars.normalize(:d)

    visit catalog_index_path(q: rizq, search_field: 'author', sort: 'title_sort desc', rows: 10)
    expect(page).to have_css('#documents .document.result')

    # The title-sort of this record begins with "Yahud".
    # It should be alphabetically second-to-last of the Rizq titles.
    expect( all('#documents .document.result').first ).to have_text yahud
  end

  #   NEXT-1140 - Special character not sorting properly
  it "Author sort should disregard diacritics" do
    ahmad = 'Aḥmad Muḥammad ʻAbd al-ʻĀl'.mb_chars.normalize(:d)
    # Hooray, there are alternative unicode forms returned!
    # Use an either/or "satisfy" block below.
    abd1 = 'ʻAbd al-ʻĀl, Aḥmad Muḥammad'.mb_chars.normalize(:d)
    abd2 = 'ʼAbd al-ʼĀl, Aḥmad Muḥammad'.mb_chars.normalize(:d)

    # There should be at least 10 records with this author, and they
    # should be first alphabetically.
    visit catalog_index_path(q: ahmad, sort: 'author_sort asc', rows: 10)
    expect(page).to have_css('#documents .document.result')
    all('#documents .document.result .row .details').each do |details|
      expect(details.text).to satisfy { |detail_text|
        detail_text.match(/#{abd1}/) ||
        detail_text.match(/#{abd2}/)
      }
    end
  end


  # NEXT-1157 - Quotation mark not sorting properly
  it "Title sort should disregard punctuation" do
    visit catalog_index_path(q: 'Cairo papers in social science', search_field: 'title', sort: 'title_sort asc', rows: 10)
    expect(page).to have_css('#documents .document.result')
    expect( all('#documents .document.result').first ).to_not have_text "Just a gaze"
  end

  # NEXT-1163 - Add subfield f to title display
  it "Titles should include dates from 245 $f" do
    visit catalog_path('8540370')
    expect( find('.show-document .title')).to have_text "Composers' Forum concert [electronic resource], 1958 January 18"

    visit catalog_path('4079060')
    expect( find('.show-document .title')).to have_text "Papers, 1958-1968"
  end


  # NEXT-934 - question/not improvement: old key symbol?
  it "shows 'Restricted' note in any datasource" do
    restricted = "This resource is available only to current faculty, staff and students of Columbia University"

    visit catalog_path(7000423)
    expect(page).to have_text restricted

    visit databases_show_path(7000423)
    expect(page).to have_text restricted

    visit journals_show_path(7000423)
    expect(page).to have_text restricted

    visit archives_show_path(7000423)
    expect(page).to have_text restricted

    visit new_arrivals_show_path(7000423)
    expect(page).to have_text restricted
  end


  # NEXT-1099 - Acquisition Date facet cannot be negated
  it "allows acquisition date to be negated" do
    visit catalog_index_path(q: 'kittens', 'f[acq_dt][]' => 'years_1')
    expect(page).to have_css('#documents .document.result')
    recent_title = all('#documents .document.result .row .title').first.text

    # Now, inverse "Law" to "Not Law"
    within find('.constraint-box', text: 'Acquisition Date') do
      find('.dropdown', text: 'Is').click
      find('a', text: 'Is Not').click
    end
    expect(page).to have_css('#documents .document.result')
    older_title = all('#documents .document.result .row .title').first.text

    expect(recent_title).to_not eq older_title
  end


end


# email_catalog_path(:id => id)
# describe 'Catalog item view', :caching => true do
#
#   it "supports an email function", :js => true do
#     visit catalog_path(1234567)
#     within '#show_toolbar' do
#       click_link 'Email'
#     end
#
#     expect(page).to have_css('.modal-scrollable .modal .modal-header')
#     # puts find('.modal-header').text.inspect #expect.to have_text('Email Item(s)')
#     expect(find('.modal-header')).to have_text('Email Item(s)')
#
#     within '#email_form' do
#       fill_in 'to', :with => 'delete@library.columbia.edu'
#       fill_in 'message', :with => 'testing'
#       find('button[type=submit]').click()
#     end
#
#   end
#
# end
#
