# Goal:

Monkey patch the [Liquid gem](https://github.com/Shopify/liquid/) to keep a list of missing variables and missing filters.

liquid_ext_test.rb contains tests for some of Liquid's existing functionality, and two failing tests for the new functionality.

# Notes:

- Feel free to add new tests
- Please make the change as small as possible
- If the monkey patch is more than 20 lines, then make changes to this liquid fork instead of a monkey patch (https://github.com/apeckham/liquid/)

# To run tests:

`ruby liquid_ext_test.rb`

# Related links:

* https://github.com/jekyll/jekyll/issues/3008
* https://github.com/Shopify/liquid/issues/490
* https://github.com/bluerail/liquid/commit/a7796ff431e5b3b7b8107251d59335a6a0154f99
