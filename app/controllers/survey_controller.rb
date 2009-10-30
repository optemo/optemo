class SurveyController < ApplicationController

def decision
  @@session.update_attribute('offeredsurvey',true)
end

def index
  @RandomQuestions = []
  randomQuestions = []
  while randomQuestions.length < Survey::SurveyQuestionCount
    randomno  = rand(Survey::TotalQuestions) + 1
    if randomQuestions.index(randomno).nil?
      randomQuestions << randomno
    end    
  end
  @RandomQuestions = randomQuestions
end

def submit
  values = params[:survey]
  if values.nil?
    return
  end
  oSurvey = Survey.new
  oSurvey.session_id = @@session.id
  # Save the Survey answers
  columnname = ""
  (1..Survey::TotalQuestions).each do |quesno|
    columnname = "Question" + (quesno).to_s
    oSurvey[columnname] = values[("q" + (quesno+1).to_s).intern]
  end
  oSurvey["suggestions"] = values[:qlast]
  oSurvey.save
end

end