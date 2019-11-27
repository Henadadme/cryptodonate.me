class DonationsController <  ApplicationController
  layout "donation"

  RQRCode::Export::SVG.module_eval do

    def anchor_class(r,c, dimension)
      o_top = r == 0 || r == dimension - 7
      o_bottom = r == 6 || r == dimension - 1
      o_left = c == 0 || c == dimension - 7
      o_right = c == 6 || c == dimension - 1

      i_top = r == 2 || r == dimension - 5
      i_bottom = r == 4 || r == dimension - 3
      i_left = c == 2 || c == dimension - 5
      i_right = c == 4 || c == dimension - 3

      clazz = ""
      if o_top && o_left || i_top && i_left
        clazz << "rounded-tl"
      end
      if o_top && o_right || i_top && i_right
        clazz << "rounded-tr"
      end
      if o_bottom && o_left || i_bottom && i_left
        clazz << "rounded-bl"
      end
      if o_bottom && o_right || i_bottom && i_right
        clazz << "rounded-br"
      end
      clazz << " outter" if o_top || o_bottom || o_left || o_right
      clazz << " inner" if i_top || i_bottom || i_left || i_right
      clazz
    end

    def as_svg(options={})
      offset = options[:offset].to_i || 0
      color = options[:color] || "000"
      shape_rendering = options[:shape_rendering] || "crispEdges"
      module_size = options[:module_size] || 11
      standalone = options[:standalone].nil? ? true : options[:standalone]

      # height and width dependent on offset and QR complexity
      dimension = (@qrcode.module_count*module_size) + (2*offset)

      xml_tag = %{<?xml version="1.0" standalone="yes"?>}
      open_tag = %{<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:ev="http://www.w3.org/2001/xml-events" width="#{dimension}" height="#{dimension}" shape-rendering="#{shape_rendering}">}
      close_tag = "</svg>"

      result = []
      @qrcode.modules.each_index do |c|
        tmp = []
        @qrcode.modules.each_index do |r|
          y = c*module_size + offset
          x = r*module_size + offset

          next unless @qrcode.checked?(c, r)

          # the radius is 5 dots, and not pixels!
          radius = 5
          center = @qrcode.module_count / 2
          # center of circle represents 0|0
          p_r = -r + center
          p_c = -c + center
          # p "c: #{c}, r: #{r} results to p_c:#{p_c} p_r: #{p_r}"
          next if (p_r ** 2) +  (p_c**2) < radius ** 2

          byte_color = "444"
          anchor_outside_color = "f7931a"
          anchor_inside_color = "444"
          clazz = anchor_class(r, c, @qrcode.module_count)

          anchor = (r < 7 && c < 7) || (r >= @qrcode.module_count - 7 && c < 7) || (r < 7 && c >= @qrcode.module_count - 7 )
          color = if anchor
            if clazz.include?("outter")
              anchor_outside_color
            else
              anchor_inside_color
            end
          else
            byte_color
          end

          rounding = !anchor ? 50 : 0

          # TODO
          # set color to orange if it's outside anchor
          # set color to gret if it's inside anchor
          # don't make it round if it's anchor at all

          tmp << %{<rect width="#{module_size}" height="#{module_size}" x="#{x}" y="#{y}" rx="#{rounding}%" style="fill:##{color}"/>}
        end
        result << tmp.join
      end

      if options[:fill]
        result.unshift %{<rect width="#{dimension}" height="#{dimension}" x="0" y="0" rx="#{rounding}%" style="fill:##{options[:fill]}"/>}
      end



       # result << "<circle r='40'  cx='#{dimension / 2 }' cy='#{dimension / 2 }' style='fill:red' />"
       result << "<image xlink:href='/icons/btc.png'  x='#{dimension / 2 - 24}' y='#{dimension / 2 - 24}'  width='48' height='48' clip-path='url(#sweetclip)' />"



      if standalone
        result.unshift(xml_tag, open_tag)
        result << close_tag
      end

      result.join("\n")
    end

  end










  def new
    @donation = streamer.donations.new
  end

  def create
    @donation = streamer.donations.new(create_params)
    if @donation.save
      redirect_to donation_path(@donation.streamer.donation_url, @donation.uuid)
    else
      render action: :new
    end
  end

  def show
    @donation = streamer.donations.find_by!(uuid: params[:uuid])
  end

  private

  def streamer
    @streamer ||= Streamer.find_by!(donation_url: params[:donation_url ])
  end

  def create_params
    params.require(:donation).permit(:coin_id, :name, :message, :currency, :amount)
  end

end
