#This change is for adding an odd number of pages and other cosmetic changes to the will_paginate gem version 3.0.0
#This change also removes GET paramters from links
require 'will_paginate/view_helpers/action_view' #This is required because otherwise the action_view is loaded after this, and this tweak will not take effect
require 'will_paginate/view_helpers/link_renderer_base'
module WillPaginate
  module ViewHelpers
    class LinkRenderer < LinkRendererBase
      def windowed_page_numbers
        inner_window, outer_window = @options[:inner_window].to_i, @options[:outer_window].to_i
        window_from = current_page - 4
        window_to = current_page + 5
        
        # adjust lower or upper limit if other is out of bounds
        if window_to > total_pages
          window_from -= window_to - total_pages
          window_to = total_pages
        end
        if window_from < 1
          window_to += 1 - window_from
          window_from = 1
          window_to = total_pages if window_to > total_pages
        end
        
        # these are always visible
        middle = window_from..window_to

        # left window
        if outer_window + 3 < middle.first # there's a gap
          left = (1..(outer_window + 1)).to_a
          left << :gap
        else # runs into visible pages
          left = 1...middle.first
        end

        # right window
        if total_pages - outer_window - 2 > middle.last # again, gap
          right = ((total_pages - outer_window)..total_pages).to_a
          right.unshift :gap
        else # runs into visible pages
          right = (middle.last + 1)..total_pages
        end
        
        left.to_a + middle.to_a + right.to_a
      end
    end
  end
  module ActionView
    protected
    class LinkRenderer < ViewHelpers::LinkRenderer
      protected
      def merge_get_params(url_params)
        url_params
      end
    end
  end
end