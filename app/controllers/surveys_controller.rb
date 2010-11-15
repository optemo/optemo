class SurveysController < ApplicationController
  layout false
  
  def new
    @RandomQuestions = (1..Survey::TotalQuestions).sort_by{rand}
    @survey = Survey.new
  end

  def create
    values = params[:survey]
    return if values.nil?
    oSurvey = Survey.new(values)
    oSurvey.session_id = Session.current.id
    # Save the Survey answers
    oSurvey.save
  end
end