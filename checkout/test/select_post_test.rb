  get '/test' do
    html = drop_down_script
#    html += "<form onsubmit=\"return dropdown(this.gourl)\" method=\"POST\" action=\"/\">"
    html = "<form method=\"post\" action=\"/purchase\">"

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />first_name: <input type='text' name='first_name' value='Alice' size='40' />"
    html += "<br /><br />last_name: <input type='text' name='last_name' value='Lee' size='40' />"
    html += "<br /><br />address_1: <input type='text' name='address_1' value='410 Townsend St.' size='40' />"
    html += "<br /><br />address_2: <input type='text' name='address_2' value='Ste 150' size='40' />"
    html += "<br /><br />city: <input type='text' name='city' value='San Francisco' size='40' />"
    html += "<br /><br />state: <input type='text' name='state' value='CA' size='40' />"
    html += "<br /><br />zip: <input type='text' name='zip' value='94107' size='40' />"
    html += "<br /><br />phone: <input type='text' name='phone' value='415-796-0031' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />separate_billing_address: <input type='text' name='separate_billing_address' value='true' size='40' />"
    html += "</div>"

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />billing_first_name: <input type='text' name='billing_first_name' value='Charles' size='40' />"
    html += "<br /><br />billing_last_name: <input type='text' name='billing_last_name' value='Graham' size='40' />"
    html += "<br /><br />billing_address_1: <input type='text' name='billing_address_1' value='3467 Fillmore St' size='40' />"
    html += "<br /><br />billing_address_2: <input type='text' name='billing_address_2' value='' size='40' />"
    html += "<br /><br />billing_city: <input type='text' name='billing_city' value='San Francisco' size='40' />"
    html += "<br /><br />billing_state: <input type='text' name='billing_state' value='CA' size='40' />"
    html += "<br /><br />billing_country: <input type='text' name='billing_country' value='NOT BEING USED' size='40' />"
    html += "<br /><br />billing_zip: <input type='text' name='billing_zip' value='94123' size='40' />"
    html += "<br /><br />billing_phone: <input type='text' name='billing_phone' value='415-796-0031' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />email_address: <input type='text' name='email_address' value='phyo@xxx.com' size='40' />"
    html += "</div>"

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />credit_card_type: <input type='text' name='credit_card_type' value='Visa' size='40' />"
    html += "<br /><br />credit_card_num: <input type='text' name='credit_card_num' value='4147735702533164' size='40' />"
    html += "<br /><br />credit_card_month: <input type='text' name='credit_card_month' value='11' size='40' />"
    html += "<br /><br />credit_card_year: <input type='text' name='credit_card_year' value='2011' size='40' />"
    html += "<br /><br />credit_card_ccv: <input type='text' name='credit_card_ccv' value='255' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />url: <input type='text' name='url' value='http://www1.bloomingdales.com/catalog/product/index.ognc?ID=455052' size='40' />"
    html += "<br /><br />product_url: <input type='text' name='product_url' value='http://www1.bloomingdales.com/catalog/product/index.ognc?ID=531820&CategoryID=20892' size='60' />"
    html += "<br /><br />affiliate_url: <input type='text' name='affiliate_url' value='http://www1.bloomingdales.com/catalog/product/index.ognc?ID=455052' size='60' />"
    html += "<br /><br />Final Category Path (from detail page scraping): <input type='text' name='coremetricsDepthPath' value='Leggings' size='40' />" # from detail page <input id="coremetricsDepthPath">
    html += "<br /><br />Size Name (from detail page scraping): <input type='text' name='size_name' value='Medium' size='40' />"
    html += "<br /><br />Color Name (from detail page scraping): <input type='text' name='color_name' value='Silver' size='40' />" # from the detail page
    html += "<br /><br />Product Size-Color Pairing ID (from detail page scraping): <input type='text' name='vendor_scc_value' value='798311' size='40' />" # from javascript of the detail page
    html += "</div>"

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />expected_description: <input type='text' name='expected_description' value='Daddy Long Legs Black Leggings with Zipper Sides' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />testing (ignore this as a tester): <input type='text' name='testing' value='true' size='40' />"
    html += "<br /><br /><input type='hidden' name='checkout_id' value='rootyroot_test' size='40' />"
    html += "</div>"

    html += "retailer: <input type='text' name='retailer' value='bloomingdales' size='40' /> <br>"
    html += "<select name=\"gourl\">"
    html += "<option value="">Choose a method</option>"
    html += "<option value=\"/fetch_detail\">fetch_detail</option>"
    html += "<option value=\"/add_to_bag\">add_to_bag</option>"
    html += "<option value=\"/fetch_order_data\">fetch_order_data</option>"
    html += "<option value=\"/purchase\">fetch_detail</option>"
    html += "</select>"
    html += "<br /><br /><input type='submit' name='Submit' value='Submit' />"
    html += "</form>"

    html
  end
