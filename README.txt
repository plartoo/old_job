Some of the code that I wrote for my old job. Many of the sensitive/necessary files are deleted to protect my former employer's trade secrets.

1. "/checkout" contains code that I wrote to help users check out products (fashion and clothing items) directly from my old employer's site.
The user will save credit card info with my employer and we will automate the process of payment to main retailers.
However, each retailer has a slightly different way of handling the payment process and not every retailer provide (at least in 2010-11) an API to do that easily.
The software library's purpose is to help programmers write easy scripts in Ruby that can be tuned to the interface of each retailer and in the background, the library will simulate the user checking out from the retailer's website.

2. "/fetchers" is to collect product information across different (~200) retailers in both US and UK on their websites.
The library helps programmer write simple scripts to scrape the price, size, color, etc. information of every product that exists on retailer's websites.