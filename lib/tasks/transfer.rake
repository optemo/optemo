desc "Move Printer Table to Product Table"
task :move_printers => :environment do
  Printer.all.each do |p|
    #Transfer info into new product table
    
    prod = Product.new({
      :product_type => "printer_us",
      :created_at => p.created_at,
      :title => p.title,
      :model => p.model,
      :mpn => p.mpn,
      :instock => p.instock,
      :imgsurl => p.imagesurl,
      :imgsw => p.imageswidth,
      :imgsh => p.imagesheight,
      :imgmurl => p.imagemurl,
      :imgmw => p.imagemwidth,
      :imgmh => p.imagemheight,
      :imglurl => p.imagelurl,
      :imglw => p.imagelwidth,
      :imglh => p.imagelheight,
      :avgreviewrating => p.averagereviewrating,
      :totalreviews => p.totalreviews,
      :manufacturerurl => p.manufacturerproducturl
    })
    prod.save
    
    create_specs(
     [:ppm,
     :resolutionmax,
     :paperinput,
     :listprice,
     :price,
     :displaysize,
     :ttp,
     :paperoutput,
     :dutycycle ,
     :ppmcolor,
     :itemheight,
     :itemlength,
     :itemwidth,
     :itemweight],ContSpec,p,prod)
     
     create_specs(
     [:brand,
     :resolution,
     :warranty,
     :duplex,
     :papersize,
     :dimensions,
     :connectivity,
     :special,
     :platform], CatSpec,p,prod)
     
     create_specs(
     [:scanner,
     :printserver,
     :colorprinter,
     :fax,
     :iseligibleforsupersavershipping],BinSpec,p,prod)
     
     create_specs(
     [:feature],TextSpec,p,prod)
    end
end

def create_specs(array,model,p,prod)
  array.each do |f|
      next if p[f].nil?
      model.new({
        :created_at => p.created_at,
        :product_id => prod.id,
        :name => f.to_s,
        :value => p[f],
        :product_type => "printer_us"
      }).save
  end
end