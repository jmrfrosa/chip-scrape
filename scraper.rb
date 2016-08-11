require 'mechanize'
require 'csv'
require 'open-uri'

CHIPTEC_BASE = "http://www.chiptec.net/"
CHIPTEC_SECTION = "componentes-para-computadores"
CHIPTEC_OPTIONS = "?dir=asc&mode=list&limit=25&order=price"
CSV_NAME = "chiptec_list.csv"

def scrape_page(link)
	page = Mechanize.new.get(link)
end

def parse_page(page, current_page_n=1)

	product_page = page

	product_name_list = product_page.css('.category-products .product-name a').map {|e| e.text}

	# Convert discounts to regular prices for easier parsing
	product_page.css('.category-products .special-price').add_class('regular-price')

	# Method chain strips the price string of all extras for clean float conversion
	product_price_list = product_page.css('.category-products .regular-price .price').map {|e|
		e.text.gsub(',','.').gsub('€','').gsub(' ','').to_f }

	# Order table [[name, price]]
	chiptec_table = [product_name_list, product_price_list].transpose

	write_csv(chiptec_table)

	# Get total item number and find how many pages to iterate
	# fdiv method returns float division
	# ceil method returns higher integer, so 111.2 becomes 112

	item_n = product_page.at_css('div.pager .amount').text[/\d+/].to_f
	page_total = (item_n / 25).ceil

	# Get link to next page and move there
	next_href = page.xpath("//a[@class='next i-next']").first['href']
	next_page = page.links_with(:href => next_href).first.click

	puts "Parsing page #{current_page_n} of #{page_total}."
	current_page_n += 1

	sleep(3+rand(5))
	page_iterate(next_page,page_total,current_page_n)

end

def page_iterate(next_page, page_total, current_page_n)
	if current_page_n < page_total
		parse_page(next_page, current_page_n)
	else
		abort("Finished.")
	end
end

def write_csv(table)
	CSV.open("#{CSV_NAME}", "ab") do |csv|
		table.each do |e|
			csv << e
		end
	end
end

def csv_header
	CSV.open("#{CSV_NAME}", "w") do |csv|
		csv << ["Product Name","#{Time.now}"]
		csv << [""]
	end
end

html = scrape_page("#{CHIPTEC_BASE}#{CHIPTEC_SECTION}#{CHIPTEC_OPTIONS}")

csv_header()
parse_page(html)