class AjaxController < ApplicationController
  # In the past, this was in GlobalDeclarations.rb, but I think that it related to the weight calculations
  # that go on in this controller, maybe? Kept here purely for archeological reasons. ZAT August 2010
  
  # Parameter that decides how much difference in values (of a feature for different products) is considered significant
  # $margin = 10    # in %
  # A threshold that decides whether a feature is important to the user or not. This is used when displaying important 
  # qualities about compared products in the comparison matrix.
  # $SignificantFeatureThreshold = 0.2
  
  def preference
    mypreferences = params[:mypreference]
    s = Session
    s.continuous["filter"].each do |f|
      s.features.update_attribute(f+"_pref", mypreferences[f+"_pref"])
    end
    # To stay on the current page 
    render :nothing => true
  end
    
  def buildrelations
    # Define weights assigned to user navigation tasks that determine preferences
    weight = Hash.new("sim" => 1, "saveit" => 2, "unsave" => 3, "unsaveComp" => 4) 

    source = params[:source]
    itemId = params[:itemId]
    # Convert the parameter string into an array of integers
    otherItems = params[:otherItems].split(",").collect{ |s| s.to_i }
    for otherItem in 0..otherItems.count-1
      # If the source is unsave i.e. a saved product has been dropped, then
      # create relations with lower as the dropped item and higher as all other saved items 
      if source == "unsave" || source == "unsaveComp"
        PreferenceRelation.createBinaryRelation(otherItems[otherItem], itemId, Session.id, weight[source])
      else
        PreferenceRelation.createBinaryRelation(itemId, otherItems[otherItem], Session.id, weight[source])
      end
    end    
    render :nothing => true
  end
  def product_review
    id = params[:id]
    render :text => Iconv.iconv('ascii//translit', 'utf-8', '{"currentPage": 1,"total": 10,"customerRating": 4.46,"customerRatingCount": 33,"customerRatingAttributes":{"Picture Quality": 3.52,"Features": 4.43,"Design": 2.48,"Ease of Use": 3.43,"Value": 4.28},"reviews": [{"rating": 5.00,"ratingAttributes":{},"title": "Very very easy to use. Even for my father thats 72","comment": "MY family and I love this camera. Its so eassy to use. My father toght me how to use it. and he is 72y-old. The camera takes great picks of our new born son. We love the cammera as much as we love him. We are luck that we got this camera to be abel to share such good quolity and sound","submissionTime": "December 22, 2010","reviewerName": "Bill","reviewerLocation": "Anderson"},{"rating": 5.00,"ratingAttributes":{},"title": "What a camera!!!","comment": "I have had this model for over a year now. Excellent battery life even though they are AA\'s, but that being said there is something about being able to run to the local shop and get new ones when you out on vacation or a shoot. Amazing zoom capability and clarity. I have traveled the world with this camera now and there is something to be said for being able to get the shoot you want from a distance. You will love this one. The SX30IS will probably be a good choice too.","submissionTime": "December 20, 2010","reviewerName": "Patrick McVeigh","reviewerLocation": "Trenton, Ontario"},{"rating": 5.00,"ratingAttributes":{},"title": "GREAT CAMERA","comment": "I LIKE THE PICTURE QUALITY ONLY THING THAT I DONT LIKE IS THAT YOU HAVE TO TAKE LENSE COVER OFF AND THERE IS NO WAY TO ATTACH WITH THE CAMERA. \r\nOVERALL GREAT BUY GOOD PICTURE AND DESIGN.","submissionTime": "December 1, 2010","reviewerName": "RAMAN","reviewerLocation": "TORONTO"},{"rating": 1.00,"ratingAttributes":{},"title": "Canon Powershot SX20IS 12.1MP","comment": "This is a very good camera it is so easy to use . The zoom power is unbelievable. Takes very good pictures up close or far away. I would highly recommend you buy this camera.","submissionTime": "November 30, 2010","reviewerName": "Donna Frank","reviewerLocation": "Gunn Alberta"},{"rating": 4.00,"ratingAttributes":{},"title": "video is not as good as a camcorder","comment": "Comment on video quality: \r\nPros: very quiet AF motor. so no noise issue like some other camera with HD video;  sound quality is superb. \r\nCons:   AF  works very well at wide angle and in good light, but gets significantly slower at the tele end of the zoom and low light .  when the light gets really dim the AF gives up completely.  Image stabilizer is not as good as expected. noticeble shaking of image is shown when filming at tele zooming. \r\nall in all, an excellent camera for taking photo, but if you are a fan of filming, better to get a camcorder.","submissionTime": "November 26, 2010","reviewerName": "shawn","reviewerLocation": "Markham"},{"rating": 5.00,"ratingAttributes":{},"title": "Canon SX 20 is","comment": "Like some of the other posts i spent most of the winter comparing this camera to its closest rival and due to alot of the features and reviews on this model from experts decided to get it in April. Recently took some photos of a coyote in the wild at approx 30yds hand held \r\nat 8 mega pixel and have had it enlarged to 16 x 20 . the detail and color are much better than I ever hoped for. Also took a jhummingbird picture in flight and caught him in mid flight with  his wings stopped This is an excellent camera for wildlife /nature photo buffs","submissionTime": "November 19, 2010","reviewerName": "Robert Lange","reviewerLocation": "Big Island, Nova scotia"},{"rating": 5.00,"ratingAttributes":{},"title": "Canon SX20IS","comment": "This is the best camera I\"ve ever owned. I like that I can use the view finder or the screen to take my pictures and that the screen rotates, that feature\'s great. I like the zoom and that you can take rapid sequence pictures. The features and choices show up on the screen or view finder and stay there as long as you want so you have a chance to read them and for those over 40, you don\'t need your reading glasses to read them.","submissionTime": "September 25, 2010","reviewerName": "judy hodgson","reviewerLocation": "london ont."},{"rating": 5.00,"ratingAttributes":{},"title": "Just Awsome!","comment": "This camera is the best ive ever owned. pictures are great. HD video is by far the best ive seen from any digital or camcorder.  The only down I have about this camera is that video records in MOV. Other than that Awsome!","submissionTime": "April 27, 2010","reviewerName": "Greg","reviewerLocation": "Toronto"},{"rating": 4.00,"ratingAttributes":{"Picture Quality": 5.00,"Features": 4.00,"Design": 4.00,"Ease of Use": 4.00,"Value": 5.00},"title": "Canona SX20 IS","comment": "I really wanted to buy a DSLR (Canon XSI or Nikon D90) but I figured that for my needs, this was a little too much for my budget.  I checked out lots of reviews and settled on the Canon SX20 is.  Shots of a swallow in a tree had superb sharpness and image quality.  On some other shots zoomed in at 80x you can still make out people\'s faces from about 1/4 mile away. \r\n\r\nPros: Fun to use Camera. Excellent picture and movie quality. Amazing 20x + 4x digital zoom feature.\r\n\r\nCons: Not able to get close enough for macro shots in zoom mode.  About 1 second delay between pictures.  Lens hood does not lock on tight enough and easily twists off.\r\n\r\nOther than the few inconveniences I highly recommend this camera and think it is an excellent choice for price vs quality.","submissionTime": "April 3, 2010","reviewerName": "GM","reviewerLocation": "Sherbrooke, Quebec"},{"rating": 4.00,"ratingAttributes":{},"title": "Great Camera","comment": "I bought this camera about a week ago and LOVE it For the most part it takes great pictures and I love that I also have the opportunity to take HD video as well. Its nice to have something that does both. I did my research before purchasing this camera and this was the one that always came out on top in my comparisons","submissionTime": "September 14, 2009","reviewerName": "Momof3","reviewerLocation": "Alberta"}]}')
  end
end
