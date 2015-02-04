// This note is supposed to help someone get started on writing fetchers.  It's not intended to be comprehensive.
// Below is my best attempt to describe common patterns that occur.  As always, there are always exceptions. If get stuck, reach me out at my personal email and I'll always be ready to help. :)
// - phyo

1. Beginning
=============
# generate fetcher template
rake generate:fetcher VENDOR_CLASS=AlexanderWang

# generate categories (after writing category fetching code)
rake generate:categories VENDOR_CLASS=AlexanderWang I18N_VERSION=us

Note: "fetchers/katespade.rb" has a couple of ways that I usually use to write category scraping code. "fetchers/alexander_wang.rb" is also a relatively simple example

2. Index Scraping
==================
# good examples to look at "AlexanderWang" (for a typical fetcher) and "Bloomingdales" (for an odd-ball fetcher where the framework fails to parse their DOM correctly for some unknown reason)

# IMAGE: if the image tags on the retailer site have the "width" and "height" info -
    product_image do
      is 'img'
    end

OR if they don't -
    product_image do
      is 'img'
      width 150
      height 150
    end

# PRICE: be aware that the HTML class names for original_price can be different based on whether the item is on sale or is full-price; I recommend that we use "original_price_custom" block to handle these varying class names. I also recommend using Utils.get_price_str to parse price strings with currency signs in it.

# PAGINATION: it can be as easy as appending an extra query parameter at the end of the index page URL such as
    pagination do
      view_all_append "&view=all"
    end

OR could be matching a pattern in the original index URL and modifying it for pagewise increment such as (as can be seen in "fetchers/tessabit.rb"
    pagination do
      preprocess do |url|
        url += '?pagedep0=1'
      end

      url_pattern /(pagedep0=)\d+/
      increment_step 1
      increment_start 1
      max_page_limit 20
    end

# OTHER: To sanity check the items, use 'post_process' block as below.
    post_process do |item,cat|
      pp item
      debugger # this will stop at each item and let you see item's properties; that way you can inspect if any of the item's ESSENTIAL data is missing.  Make sure to return the "item" at the end of this block
      item
    end

# OTHER: 'modify_item_parse_agent' method used in 'LordAndTaylor' and 'Jcrew' allows us to manipulate the state of the index page before we actually start scraping items; it is introduce to help with pagination in retailers like Jcrew and LordAndTaylor

3. Size-color scraping
=======================
# I prefer using SCCCustomScraper because it allows me do whatever I want with the detail page data; more often than not, different retailers have different ways of presenting size color data, and it's always nice to have control over things.  Here, I'll assume that we're using SCCCustomScraper.

# In 'give_me' block, we must specify what part of the detail page's DOM that we need to process for custom scraping

# 'all_at_once' block tells the framework that we'll return the size-color pairs in an array as opposed to individually returning them.  That is, [[s1,c1],[s2,c2],...] vs. [s1,c1] (loop over the process call) [s2,c2] and so on

# We have the detail page in the 'process' block.  We should scrape neccessary parameters to make extra request to get size-color data OR if we are lucky, the size-color data is right on the page.

# 'extended_description_data', 'related_vendor_keys', 'additional_images', 'scc_label_value_pairings' are all used in full-price scraping or for assisted checkout projects.  They're pretty self-explanatory.

# To add size-color mappings, check out "fetchers/jcrew/jcrew.rb" as an example.


# OTHER: Business/Dev team will sometimes wants to add extra notices to items based on some feature(s) on the detail page (such as the presence of "Final Sale").  So you'll see a bunch of WTF code chunks in SCC scraping that are NOT related to its purpose.

# OTHER: You may also see things like using prefix strings to modify size strings.  Those are because some retailers aren't careful of distinguishing the maternity/petite/plus size strings carefully on their site (as in the case of Jcrew), and we have to handle it for them.


Test running
============
# fetch
rake fetch VENDOR_CLASS=AlexanderWang I18N_VERSION=us

# test size color fetching part only (can add EXTENDED_DESC=1 at the end of command below to turn on detail image/full description)
rake test:sccs VENDOR_CLASS=AlexanderWang I18N_VERSION=us DEPT=womens CLOTHING_TYPE=DRESS URL=""




Miscellaneous
==============
# Currently, the framework can filter out brands if the forbidden brand file such as 'neimanmarcus_forbidden_brands.us.yml' is provided.

Size Mapping
=============
# If you have too many valid items failing to go through detail scraping, move the log file under "fetchers/log/retailer_name.log" to "fetchers/tools" folder (or do it through shell script).  Then, run:
$ ruby collectInvalidSize.rb BergdorfGoodman_us.log

Final Note
===========
Reading how fetchers are written as example is the best way to improve the efficiency of writing/troubleshooting fetchers.
