desc "Move Camera Table to Product Table"
task :move_cameras => :environment do
  Camera.all.each do |p|
    #Transfer info into new product table
    prod = Product.new({
      :product_type => "camera_us",
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
      :manufacturerurl => p.manufacturerurl
    })
    prod.save
    
    create_specs(
     [:price,
      :itemwidth,
      :itemlength,
      :itemheight,
      :itemweight,
      :packageheight,
      :packagelength,
      :packagewidth,
      :packageweight,
      :digitalzoom,
      :opticalzoom,
      :maximumresolution,
      :displaysize,
      :maximumfocallength,
      :minimumfocallength,
      :bestoffer],ContSpec,p,prod,"camera_us")
     
     create_specs(
     [:brand,
      :dimensions,
      :resolution,
      :batterydescription,
      :connectivity,
      :includedsoftware], CatSpec,p,prod,"camera_us")
     
     create_specs(
     [:slr,
      :waterproof,
      :batteriesincluded,
      :hasredeyereduction],BinSpec,p,prod, "camera_us")
     
     create_specs(
     [:detailpageurl,
       :reviewtext],TextSpec,p,prod,"camera_us")
    end
end

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
     :itemweight],ContSpec,p,prod,"printer_us")
     
     create_specs(
     [:brand,
     :resolution,
     :warranty,
     :duplex,
     :papersize,
     :dimensions,
     :connectivity,
     :special,
     :platform], CatSpec,p,prod,"printer_us")
     
     create_specs(
     [:scanner,
     :printserver,
     :colorprinter,
     :fax,
     :iseligibleforsupersavershipping],BinSpec,p,prod,"printer_us")
     
     create_specs(
     [:feature],TextSpec,p,prod,"printer_us")
    end
end

def create_specs(array,model,p,prod, product_type)
  array.each do |f|
      next if p[f].nil?
      #Price now stored as float
      if f == :price
        model.new({
          :created_at => p.created_at,
          :product_id => prod.id,
          :name => f.to_s,
          :value => p[f].to_f/100,
          :product_type => product_type
        }).save
      else
        model.new({
          :created_at => p.created_at,
          :product_id => prod.id,
          :name => f.to_s,
          :value => p[f],
          :product_type => product_type
        }).save
      end
  end
end
