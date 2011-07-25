class BestbuyPaginationLinkRenderer < WillPaginate::ViewHelpers::LinkRenderer
  # Process it! This method returns the complete HTML string which contains
      # pagination links. Feel free to subclass LinkRenderer and change this
      # method as you see fit.
      def to_html
        html = pagination.map do |item|
          item.is_a?(Fixnum) ?
            page_number(item) :
            send(item)
        end.join(@options[:separator])
        
        @options[:container] ? html_container(html) : html
      end
    protected
    
      # Calculates visible page numbers using the <tt>:inner_window</tt> and
      # <tt>:outer_window</tt> options.
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
      
      def page_number(page)
        unless page == current_page
          link(page, page, :rel => rel_value(page))
        else
          tag(:strong, page)
        end
      end

end
