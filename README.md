# Goal:

Monkey patch the [Liquid gem](https://github.com/Shopify/liquid/) to keep a list of missing variables and missing filters.

liquid_ext_test.rb contains tests for some of Liquid's existing functionality, and two failing tests for the new functionality.

# Notes:

- Feel free to add new tests
- Feel free to change the way that "missing filters" and "missing variables" are returned. For example, you could create a new method "render_debug" that returns [rendered_string, {used_variables, missing_variables, used_filters, missing_filters, included_files}]
- Please make the patch as short as possible
- If the changes are large, then make changes to my liquid fork instead of monkey patching (https://github.com/apeckham/liquid/)

# To run tests:

`ruby liquid_ext_test.rb`

# Related links:

* https://github.com/jekyll/jekyll/issues/3008
* https://github.com/Shopify/liquid/issues/490
* https://github.com/bluerail/liquid/commit/a7796ff431e5b3b7b8107251d59335a6a0154f99
